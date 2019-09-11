package MOP4Import::Util;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use Data::Dumper;
use Encode ();

use Exporter qw/import/;

sub globref {
  my $pack = shift;
  unless (defined $pack) {
    Carp::croak "undef is given to globref()";
  }
  my $symname = join("::", $pack, @_);
  no strict 'refs';
  \*{$symname};
}

sub symtab {
  *{globref(shift, '')}{HASH}
}

sub safe_globref {
  my ($pack_or_obj, $name) = @_;
  unless (defined symtab($pack_or_obj)->{$name}) {
    my $pack = ref $pack_or_obj || $pack_or_obj;
    croak "No such symbol '$name' in package $pack";
  }
  globref($pack_or_obj, $name);
}

sub fields_hash {
  my $sym = fields_symbol(@_);
  # XXX: return \%{*$sym}; # If we use this, we get "used only once" warning.
  ensure_symbol_has_hash($sym);
}

sub safe_fields_hash {
  my $sym = safe_globref($_[0], 'FIELDS');
  ensure_symbol_has_hash($sym);
}

sub fields_array {
  my $sym = fields_symbol(@_);
  ensure_symbol_has_array($sym);
}

sub fields_symbol {
  globref(ref $_[0] || $_[0], 'FIELDS');
}

#
# Just lock_keys with fields_hash
#
sub lock_keys_as {
  my ($myPack, $typeName, $hash) = @_;
  require Hash::Util;
  $hash //= +{};
  if (ref $typeName) {
    Carp::croak "Typename must be a package name: "
      . terse_dump($typeName);
  }
  my $fields = safe_fields_hash($typeName);
  if (not Hash::Util::hashref_locked($hash)) {
    Hash::Util::lock_ref_keys($hash, keys %$fields);
  } else {
    if (my @unk = grep {not exists $fields->{$_}}
        Hash::Util::legal_ref_keys($hash)) {
      Carp::croak "HASH contains illegal keys wrt type $typeName: "
        . join(" ", sort @unk);
    }
    # OK;
  }
  $hash;
}

sub isa_array {
  my $sym = globref($_[0], 'ISA');
  ensure_symbol_has_array($sym);
}

sub ensure_symbol_has_array {
  my ($sym) = @_;
  unless (*{$sym}{ARRAY}) {
    *$sym = [];
  }
  *{$sym}{ARRAY};
}

sub ensure_symbol_has_hash {
  my ($sym) = @_;
  unless (*{$sym}{HASH}) {
    *$sym = {};
  }
  *{$sym}{HASH};
}

sub define_constant {
  my ($name_or_glob, $value) = @_;
  my $glob = ref $name_or_glob ? $name_or_glob : globref($name_or_glob);
  *$glob = my $const_sub = sub () { $value };
  $const_sub;
}

# MOP4Import::Util::extract_fields_as(BASE_CLASS => $obj)
# => returns name, value pairs found in BASE_CLASS and defined in $obj.
# Note: this only extracts fields starting with [a-z].
sub extract_fields_as ($$) {
  my ($asPack, $obj) = @_;
  my $fields = fields_hash($asPack);
  map {
    if (/^[a-z]/ and defined $obj->{$_}) {
      ($_ => $obj->{$_})
    } else {
      ()
    }
  } keys %$fields
}

#
# For (shallow) copy constructor.
#
sub shallow_copy {
  if (ref $_[0] eq 'HASH') {
    +{%{$_[0]}};
  } elsif (ref $_[0] eq 'ARRAY') {
    +[@{$_[0]}];
  } elsif (ref $_[0] eq 'Regexp'
             or not ref $_[0]) {
    my $copy = $_[0];
  } elsif ($_[1]) {
    # Pass thru unknown refs if 2nd arg is true.
    $_[0];
  } else {
    croak "Unsupported data type for shallow_copy: " . ref $_[0];
  }
}

#
# Expand given item as list.
#
sub lexpand {
  if (not defined $_[0]) {
    return
  } elsif (ref $_[0] eq 'ARRAY') {
    @{$_[0]}
  } else {
    $_[0]
  }
}

sub terse_dump {
  join ", ", map {
    Data::Dumper->new([$_])->Terse(1)->Indent(0)->Dump;
  } @_;
}

#
# This may be useful to parse/take subcommand option/hash.
#
sub take_hash_opts_maybe {
  my ($pack, $list, $result, $alias) = @_;

  if (@$list and ref $list->[0] eq 'HASH') {
    # If first element of $list is HASH, take it.

    shift @$list;
  } else {
    # Otherwise, take --posix_style=options.

    $pack->parse_opts($list, $result, $alias);
  }
}

sub take_locked_opts_of {
  my ($myPack, $typeName, $list, $alias, $sink) = @_;
  $myPack->lock_keys_as($typeName, scalar $myPack->take_hash_opts_maybe(
    $list,
    $sink,
    $alias,
  ));
}

#
# posix_style long option.
#
sub parse_opts {
  my ($pack, $list, $result, $alias, $converter, %opts) = @_;
  my $wantarray = wantarray;
  unless (defined $result) {
    $result = $wantarray ? [] : {};
  }
  my $preserve_hyphen = delete $opts{preserve_hyphen} // do {
    my $sub = $pack->can("parse_opts__preserve_hyphen");
    $sub && $sub->($pack);
  };
  if (keys %opts) {
      Carp::croak("Unknown option for parse_opts(): ".join(", ", keys %opts));
  }
  while (@$list and defined $list->[0] and my ($n, $v) = $list->[0]
	 =~ m{^--$ | ^(?:--? ([\w:\-\.]+) (?: =(.*))?)$}xs) {
    shift @$list;
    last unless defined $n;
    $n =~ s/-/_/g unless $preserve_hyphen;
    $n = $alias->{$n} if $alias and $alias->{$n};
    $v = 1 unless defined $v;
    if (ref $result eq 'HASH') {
      $result->{$n} = $converter ? $converter->($v) : $v;
    } else {
      push @$result, $n, $converter ? $converter->($v) : $v;
    }
  }
  if ($converter) {
    $_ = $converter->($_) for @$list;
  }
  $wantarray && ref $result ne 'HASH' ? @$result : $result;
}

#
# posix_style long option with JSON support.
#
sub parse_json_opts {
  my ($pack, $list, $result, $alias) = @_;
  require JSON::MaybeXS;
  parse_opts($pack, $list, $result, $alias, sub {
    if (not defined $_[0]) {
      undef
    } elsif ($_[0] =~ /^(?:\[.*?\]|\{.*?\})\z/s) {
      # Arguments might be already decoded.
      my $copy = $_[0];
      Encode::_utf8_off($copy) if Encode::is_utf8($copy);
      JSON::MaybeXS::JSON()->new->utf8->relaxed->decode($copy);
    } elsif (not Encode::is_utf8($_[0]) and $_[0] =~ /\P{ASCII}/) {
      Encode::decode(utf8 => $_[0]);
    } else {
      $_[0];
    }
  });
}

#
# make style KEY=VALUE list
#
sub parse_pairlist {
  my ($pack, $aref, $do_box) = @_;
  my @res;
  while (@$aref and defined $aref->[0]
	 and $aref->[0] =~ /^([\w:\-\.]+)=(.*)/) {
    my $item = shift @$aref;
    push @res, $do_box ? [$1, $2] : ($1, $2);
  }
  @res;
}

sub function_names {
  my (%opts) = @_;
  my $packname = delete $opts{from}     // caller;
  my $pattern  = delete $opts{matching} || qr{^[A-Za-z]\w+$};
  my $except   = delete $opts{except}   // qr{^import$};
  if (keys %opts) {
    croak "Unknown arguments: ".join(", ", keys %opts);
  }
  my $symtab = *{globref($packname, '')}{HASH};
  my @result;
  foreach my $name (sort keys %$symtab) {
    next unless *{$symtab->{$name}}{CODE};
    next unless $name =~ $pattern;
    next if $except and $name =~ $except;
    push @result, $name;
  }
  @result;
}

#========================================

sub has_method_attr {
  grep {$_ eq 'method'} attributes::get($_[0])
}

#========================================

sub m4i_log_start {
  my $m4i_meta = caller;
  my $m4i_dest = caller(1);
  print STDERR "\n", "START of $m4i_meta->import() for $m4i_dest.\n";
}

sub m4i_log_end {
  my ($m4i_dest) = @_;
  my $m4i_meta = caller;
  $m4i_dest //= caller(1);
  print STDERR "END of $m4i_meta->import() for $m4i_dest.\n\n";
}

our @EXPORT = qw/globref
		 safe_globref
		 fields_hash fields_symbol lexpand terse_dump
		 fields_array
                 m4i_log_start
                 m4i_log_end
		/;
our @EXPORT_OK = function_names(from => __PACKAGE__
		   , except => qr/^(import|c\w*)$/
		 );

1;
