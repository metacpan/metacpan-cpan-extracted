package Langertha::Raider::Detect;
# ABSTRACT: Internal evaluator for declarative pack detection rules
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Path::Tiny;


my @CLAUSES   = qw( must may must_not );
my @COND_KEYS = qw( file dir contains matches );


has root => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);


has max_depth => (
  is      => 'ro',
  isa     => 'Int',
  default => 8,
);


has max_entries => (
  is      => 'ro',
  isa     => 'Int',
  default => 5000,
);


has max_bytes => (
  is      => 'ro',
  isa     => 'Int',
  default => 65536,
);

has _real_root => (
  is         => 'ro',
  lazy_build => 1,
);

sub _build__real_root {
  my ( $self ) = @_;
  my $root = path($self->root);
  return unless -d $root;
  return $root->realpath;
}


sub validate_rule {
  my ( $self, $rule, $label ) = @_;
  $label //= 'rule';
  my $fail = sub { croak 'Invalid detect rule '.$_[0].': '.$_[1] };
  $fail->($label, 'a rule must be a map') unless ref $rule eq 'HASH';
  my %clause = map { $_ => 1 } @CLAUSES;
  for my $key (sort keys %$rule) {
    $fail->($label, "unknown key '".$key."' (allowed: ".join(', ', @CLAUSES).')') unless $clause{$key};
  }
  my %cond_key = map { $_ => 1 } @COND_KEYS;
  for my $clause (@CLAUSES) {
    next unless exists $rule->{$clause};
    my $list = $rule->{$clause};
    $fail->($label.'.'.$clause, 'must be a list of conditions') unless ref $list eq 'ARRAY';
    for my $i (0 .. $#$list) {
      my $at   = $label.'.'.$clause.'['.$i.']';
      my $cond = $list->[$i];
      $fail->($at, 'a condition must be a map') unless ref $cond eq 'HASH';
      for my $key (sort keys %$cond) {
        $fail->($at, "unknown key '".$key."' (allowed: ".join(', ', @COND_KEYS).')') unless $cond_key{$key};
      }
      $fail->($at, 'needs file or dir') unless exists $cond->{file} || exists $cond->{dir};
      for my $key (qw( contains matches )) {
        next unless exists $cond->{$key};
        $fail->($at, $key.' needs file') unless exists $cond->{file};
        $fail->($at, $key.' must be a non-empty string') unless $self->_is_text($cond->{$key});
      }
      for my $key (qw( file dir )) {
        next unless exists $cond->{$key};
        my $glob = $cond->{$key};
        $fail->($at, $key.' must be a non-empty string') unless $self->_is_text($glob);
        $fail->($at, $key.' must be relative to the workspace') if $glob =~ m{\A/};
        $fail->($at, $key." must not contain '..'") if grep { $_ eq '..' } split m{/}, $glob;
      }
      if (exists $cond->{matches}) {
        eval { qr/$cond->{matches}/; 1 }
          or $fail->($at, 'matches is not a valid regex: '.( split /\n/, $@ )[0]);
      }
    }
  }
  return 1;
}

sub _is_text {
  my ( $self, $value ) = @_;
  return defined $value && !ref $value && length $value;
}


sub describe_condition {
  my ( $self, $cond ) = @_;
  my %fmt = (
    file     => sub { 'file='.$_[0] },
    dir      => sub { 'dir='.$_[0] },
    contains => sub { 'contains="'.$_[0].'"' },
    matches  => sub { 'matches=/'.$_[0].'/' },
  );
  return join ' ', map { $fmt{$_}->($cond->{$_}) } grep { exists $cond->{$_} } @COND_KEYS;
}


sub evaluate {
  my ( $self, $rule, $label ) = @_;
  $self->validate_rule($rule, $label);
  my ( @checks, @notes, @why );
  my $done = sub {
    my ( $matched, $reason ) = @_;
    return {
      matched => $matched ? 1 : 0,
      reason  => $reason,
      checks  => \@checks,
      notes   => \@notes,
    };
  };
  my @present = grep { @{ $rule->{$_} // [] } } @CLAUSES;
  return $done->(0, 'no clauses') unless @present;
  return $done->(0, 'workspace root not found') unless defined $self->_real_root;

  my $check = sub {
    my ( $clause, $cond ) = @_;
    my $desc = $self->describe_condition($cond);
    my $hit  = $self->_condition($cond, $clause.' '.$desc);
    push @checks, {
      clause    => $clause,
      condition => $desc,
      held      => $hit->{held},
      ( defined $hit->{path} ? ( path => $hit->{path} ) : () ),
    };
    push @notes, @{ $hit->{notes} } unless $hit->{held};
    return ( $hit, $desc );
  };

  for my $cond (@{ $rule->{must} // [] }) {
    my ( $hit, $desc ) = $check->(must => $cond);
    return $done->(0, 'must '.$desc.': no match') unless $hit->{held};
    push @why, 'must '.$desc.' ('.$hit->{path}.')';
  }
  if (my @list = @{ $rule->{must_not} // [] }) {
    for my $cond (@list) {
      my ( $hit, $desc ) = $check->(must_not => $cond);
      return $done->(0, 'must_not '.$desc.': found '.$hit->{path}) if $hit->{held};
    }
    push @why, 'must_not '.join(', ', map { $self->describe_condition($_) } @list).': none';
  }
  if (my @list = @{ $rule->{may} // [] }) {
    my $held;
    for my $cond (@list) {
      my ( $hit, $desc ) = $check->(may => $cond);
      next unless $hit->{held};
      $held = 'may '.$desc.' ('.$hit->{path}.')';
      last;
    }
    return $done->(0, 'may: none of '.join(', ', map { $self->describe_condition($_) } @list).' held')
      unless $held;
    push @why, $held;
  }
  return $done->(1, join '; ', @why);
}

# One condition: { held, path, notes }. file and dir are looked up
# independently; the content checks apply to the file candidates.
sub _condition {
  my ( $self, $cond, $label ) = @_;
  my $state = { entries => 0, notes => [], seen => {}, label => $label };
  my @paths;
  if (exists $cond->{file}) {
    my $path = $self->_find($cond->{file}, 'file', $state, sub { $self->_content_ok($cond, @_, $state) });
    return { held => 0, notes => $state->{notes} } unless defined $path;
    push @paths, $path;
  }
  if (exists $cond->{dir}) {
    my $path = $self->_find($cond->{dir}, 'dir', $state, sub { 1 });
    return { held => 0, notes => $state->{notes} } unless defined $path;
    push @paths, $path;
  }
  return { held => 1, path => join(', ', @paths), notes => [] };
}

sub _note {
  my ( $self, $state, $text ) = @_;
  push @{ $state->{notes} }, $state->{label}.': '.$text unless $state->{seen}{$text}++;
  return;
}

# The segments of a glob: '.' and empty ones dropped, a trailing ** made
# to match everything below.
sub _segments {
  my ( $self, $glob ) = @_;
  my @segs = grep { length && $_ ne '.' } split m{/}, $glob;
  push @segs, '*' if @segs && $segs[-1] eq '**';
  return map {
    $_ eq '**'   ? { globstar => 1 }
    : /[*?]/     ? { re => $self->_segment_re($_), dot => /\A\./ ? 1 : 0 }
    :              { literal => $_ }
  } @segs;
}

sub _segment_re {
  my ( $self, $seg ) = @_;
  my $re = join '', map { $_ eq '*' ? '[^/]*' : $_ eq '?' ? '[^/]' : quotemeta } split /([*?])/, $seg;
  return qr/\A$re\z/;
}

# First path (relative to the root) of type $want matching $glob for which
# $accept returns true, or undef.
sub _find {
  my ( $self, $glob, $want, $state, $accept ) = @_;
  my @segs = $self->_segments($glob);
  return unless @segs;
  my $found;
  $self->_walk($self->_real_root, [], \@segs, 0, 0, $want, $state, sub {
    my ( $rel, $real ) = @_;
    return 0 unless $accept->($real, $rel);
    $found = $rel;
    return 1;
  });
  return $found;
}

sub _walk {
  my ( $self, $dir, $rel, $segs, $i, $depth, $want, $state, $cb ) = @_;
  return 0 if $state->{capped};
  my $seg  = $segs->[$i];
  my $last = $i == $#$segs;

  if ($seg->{globstar}) {
    return 1 if $self->_walk($dir, $rel, $segs, $i + 1, $depth, $want, $state, $cb);
    for my $name ($self->_names($dir, $state)) {
      last if $state->{capped};
      next if $name =~ /\A\./;
      my $child = $dir->child($name);
      next if -l $child || !-d $child;
      if ($depth >= $self->max_depth) {
        $self->_note($state, '** depth capped at '.$self->max_depth);
        next;
      }
      return 1 if $self->_walk($child, [ @$rel, $name ], $segs, $i, $depth + 1, $want, $state, $cb);
    }
    return 0;
  }

  my @names;
  if (defined $seg->{literal}) {
    @names = ( $seg->{literal} ) if -e $dir->child($seg->{literal}) || -l $dir->child($seg->{literal});
  }
  else {
    @names = grep { ( $seg->{dot} || !/\A\./ ) && $_ =~ $seg->{re} } $self->_names($dir, $state);
  }
  for my $name (@names) {
    last if $state->{capped};
    my @child_rel = ( @$rel, $name );
    my $real = $self->_inside($dir->child($name), join('/', @child_rel), $state) or next;
    if ($last) {
      next unless $want eq 'dir' ? -d $real : -f $real;
      return 1 if $cb->(join('/', @child_rel), $real);
      next;
    }
    next unless -d $real;
    return 1 if $self->_walk($real, \@child_rel, $segs, $i + 1, $depth, $want, $state, $cb);
  }
  return 0;
}

# Directory entries, sorted; counts against max_entries.
sub _names {
  my ( $self, $dir, $state ) = @_;
  opendir(my $dh, "$dir") or return;
  my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
  closedir $dh;
  my @out;
  for my $name (@names) {
    if (++$state->{entries} > $self->max_entries) {
      $state->{capped} = 1;
      $self->_note($state, 'stopped after '.$self->max_entries.' entries');
      last;
    }
    push @out, $name;
  }
  return @out;
}

# The path itself when it is no symlink, else its target when that lies
# inside the root; undef (reported) when it leaves the workspace.
sub _inside {
  my ( $self, $path, $rel, $state ) = @_;
  return $path unless -l $path;
  my $real = eval { $path->realpath };
  return $real if $real && $self->_real_root->subsumes($real);
  $self->_note($state, $rel.': symlink leaves the workspace');
  return;
}

sub _content_ok {
  my ( $self, $cond, $real, $rel, $state ) = @_;
  return 1 unless exists $cond->{contains} || exists $cond->{matches};
  my $fh  = eval { $real->openr_raw } or return 0;
  my $max = $self->max_bytes;
  my $got = read($fh, my $buf, $max + 1) // 0;
  close $fh;
  my $cut = $got > $max;
  substr($buf, $max) = '' if $cut;
  my $text = $buf;
  utf8::decode($text);
  my $ok = ( !exists $cond->{contains} || index($text, $cond->{contains}) >= 0 )
        && ( !exists $cond->{matches}  || $text =~ /$cond->{matches}/m );
  $self->_note($state, $rel.': only the first '.$max.' bytes were read') if $cut && !$ok;
  return $ok ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Detect - Internal evaluator for declarative pack detection rules

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $detect = Langertha::Raider::Detect->new( root => $workspace );

    Langertha::Raider::Detect->validate_rule($rule, 'perl');   # croaks when invalid

    my $result = $detect->evaluate({
      must     => [ { file => 'cpanfile' } ],
      may      => [ { file => 'dist.ini' }, { file => 'lib/**/*.pm' } ],
      must_not => [ { file => '.raider/no-perl' } ],
    }, 'perl');

    print $result->{matched} ? 'perl: '.$result->{reason} : 'no perl';

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

Evaluates one detection rule of ADR 0012 against a workspace root. A rule
is a map of up to three clause lists:

=over

=item C<must> -- every condition holds.

=item C<may> -- when the list is non-empty, at least one condition holds.

=item C<must_not> -- no condition holds.

=back

A rule without any condition never matches. The clauses are evaluated in
the order C<must>, C<must_not>, C<may>, and evaluation stops as soon as the
outcome is decided.

A condition is a map; every key in it must hold:

=over

=item C<file: GLOB> -- a file matching the glob exists.

=item C<dir: GLOB> -- a directory matching the glob exists.

=item C<contains: STRING> -- with C<file>, a matching file contains the
literal string.

=item C<matches: REGEX> -- with C<file>, a matching file matches the regex
(multi-line: C<^> and C<$> anchor at line ends). With C<contains> as well,
both must hold in the same file.

=back

Globs are relative to the workspace root and know C<*> and C<?> (within one
path segment) and C<**> (any number of directories, including none; a
trailing C<**> matches everything below). Wildcards do not match names that
start with a dot unless the pattern segment does, so C<**> never walks
F<.git>. C<..> and absolute globs are invalid.

Evaluation is bounded: symlinks are followed only when they resolve inside
the root, and C<**> never descends into a symlinked directory; a C<**>
descends at most L</max_depth> directories; one condition looks at no more
than L</max_entries> directory entries; content checks read at most the
first L</max_bytes> of a file. Hitting a limit makes the condition false and
is reported in C<notes>, it never stops the run. Content is matched as
UTF-8 text when it decodes, as bytes otherwise.

=head2 root

The workspace root the globs are relative to. Required.

=head2 max_depth

How many directories one C<**> descends at most. Defaults to C<8>.

=head2 max_entries

How many directory entries one condition looks at before it gives up.
Defaults to C<5000>.

=head2 max_bytes

How many bytes of a file a content check reads. Defaults to C<65536>
(64 KiB).

=head2 validate_rule

    Langertha::Raider::Detect->validate_rule($rule, $label);

Croaks with C<Invalid detect rule LABEL...: problem> when C<$rule> is not a
valid rule: not a map, an unknown clause or condition key, a clause that is
not a list, a condition without C<file> or C<dir>, C<contains> or
C<matches> without C<file>, an empty, absolute or C<..> glob, or a regex
that does not compile. C<$label> (e.g. the pack name) prefixes the
location; it defaults to C<rule>. Returns true. Callable on the class.

=head2 describe_condition

    my $text = Langertha::Raider::Detect->describe_condition({ file => 'dist.ini', contains => 'GETTY' });
    # 'file=dist.ini contains="GETTY"'

One-line form of a condition, as used in C<reason> and C<checks>.
Callable on the class.

=head2 evaluate

    my $result = $detect->evaluate($rule, $label);

Validates the rule (see L</validate_rule>) and evaluates it against
L</root>:

    {
      matched => 1,
      reason  => 'must file=cpanfile (cpanfile); may file=dist.ini (dist.ini)',
      checks  => [
        { clause => 'must', condition => 'file=cpanfile', held => 1, path => 'cpanfile' },
        { clause => 'may',  condition => 'file=dist.ini', held => 1, path => 'dist.ini' },
      ],
      notes   => [],
    }

C<reason> names the conditions that decided the outcome -- what matched
and where for a match, the condition that failed (C<no match>, C<found
PATH>, C<none of ... held>) otherwise; C<no clauses> for an empty rule.
C<checks> lists every condition that was evaluated, C<notes> every limit
that was hit by a condition that did not hold.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Packs>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
