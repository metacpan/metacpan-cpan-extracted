package Mail::DKIM2::BodyPlan;
use strict;
use warnings;

our $VERSION = '0.27';

use Carp;
use MIME::Base64 qw(encode_base64);
use Mail::DKIM2::Digest;
use Mail::DKIM2::MessageInstance;

# Every Message-Instance's body hash in one forward pass over the current
# body, without rebuilding any previous body.
#
# Each instance's body is described as a list of segments, each a run of
# lines of the current body ([0, from, to], line numbers) or of Recipe
# literals ([1, from, to], indexes into one literal table). The top
# instance is the whole current body; each instance below is its parent's
# list with the parent's body Recipe applied to it -- a copy range picks
# lines out of the parent's segments, a literal adds a literal segment.
# Copy ranges ascend (-07 §5.2), so every list is in body order, and the
# body is read once, front to back, each line going to every instance whose
# list holds it. Instances with the same list (no body Recipe: an unchanged
# body) share one set of digests.

# The top instance's body: every line, however many there turn out to be.
use constant ALL_LINES => 2**52;

# Lines per regex jump when finding a line's offset in a block: under perl's
# 32766 limit on a counted quantifier.
use constant JUMP => 30000;

# new(@mi): the Message-Instance objects, highest m= first, each the parent
# of the next.
sub new {
    my ($class, @mi) = @_;
    my $self = bless {
        instances => [],
        by_m      => {},
        groups    => [],
        literals  => [],
        line      => 1,      # number of the next body line
        carry     => '',     # a line not yet ended, from the last chunk
    }, $class;

    my %group_for;    # segment list (as a string) => group
    my $impl = Mail::DKIM2::MessageInstance::hash_algs();
    my $segs = [[0, 1, ALL_LINES]];
    for my $mi (@mi) {
        my $hashes = $mi->get_tag('hashes') || {};
        my $inst = {
            m      => 0 + $mi->get_tag('m'),    # m=01 is 1
            rb     => $mi->get_tag('rb'),
            null   => $mi->unrecoverable,
            algs   => [ sort grep { $impl->{$_} } keys %$hashes ],
        };
        if ($segs) {
            my $key = join ';', map { join ',', @$_ } @$segs;
            my $g = $group_for{$key} //= do {
                push @{$self->{groups}}, _new_group($segs);
                $self->{groups}[-1];
            };
            $g->{digest}{$_} //= Mail::DKIM2::Digest->new($_) for @{$inst->{algs}};
            $inst->{group} = $g;
        }
        push @{$self->{instances}}, $inst;
        $self->{by_m}{$inst->{m}} = $inst;

        # The next instance down: the same body, none, or this Recipe's.
        if (!$segs || $inst->{null}) {
            $segs = undef;
        } elsif (defined $inst->{rb}) {
            my $ok = eval { Mail::DKIM2::MessageInstance::_check_recipe('body', $inst->{rb}); 1 };
            $segs = $ok ? compose($segs, $inst->{rb}, $self->{literals}) : undef;
        }
    }
    return $self;
}

sub _new_group {
    my ($segs) = @_;
    return {
        segs    => $segs,
        next    => 0,    # index of the next segment to emit
        digest  => {},
        pending => 0,    # blank lines not yet hashed: they may be trailing
        lines   => 0,    # lines in the body so far, blank or not
    };
}

# compose($segs, $recipe, \@literals): the segment list for the lines (or
# fields) $recipe rebuilds from those $segs lists, its literals appended to
# @literals. The copy ranges are known to ascend; one past the end of $segs
# is cut short here, for the caller to report against the real length.
# Mail::DKIM2::HeaderPlan uses it for each field name's values.
sub compose {
    my ($segs, $recipe, $literals) = @_;
    my @out;
    my ($i, $before) = (0, 0);    # $segs->[$i] starts at line $before + 1
    for my $step (@$recipe) {
        unless (ref $step) {
            push @$literals, $step;
            _append(\@out, 1, $#$literals, $#$literals);
            next;
        }
        my ($from, $to) = @$step;
        while ($from <= $to && $i < @$segs) {
            my ($type, $s, $e) = @{$segs->[$i]};
            my $len = $e - $s + 1;
            if ($from > $before + $len) {
                $before += $len;
                $i++;
                next;
            }
            my $last = $to < $before + $len ? $to : $before + $len;
            _append(\@out, $type, $s + $from - $before - 1, $s + $last - $before - 1);
            $from = $last + 1;
        }
    }
    return \@out;
}

sub _append {
    my ($out, $type, $s, $e) = @_;
    my $prev = $out->[-1];
    if ($prev && $prev->[0] == $type && $prev->[2] + 1 == $s) {
        $prev->[2] = $e;
    } else {
        push @$out, [$type, $s, $e];
    }
}

# add($bytes): the next piece of the current body, cut anywhere.
sub add {
    my $self = shift;
    croak "BodyPlan: add after finish" if $self->{done};
    return unless defined $_[0] && length $_[0];
    my $nl = rindex($_[0], "\n");
    if ($nl < 0) {
        $self->{carry} .= $_[0];
        return;
    }
    # The whole lines, read where they are when nothing is carried over and
    # the piece ends at a line end (a whole body does): copied otherwise.
    if (!length $self->{carry} && $nl == length($_[0]) - 1) {
        $self->_block(\$_[0]);
        return;
    }
    my $block = $self->{carry} . substr($_[0], 0, $nl + 1);
    $self->{carry} = substr($_[0], $nl + 1);
    $self->_block(\$block);
}

# A run of whole lines, each ending in a LF. Hashed as CRLF lines: a bare LF
# ends a line like a CRLF does, as in the Recipes' line numbering.
# The block may be the caller's own string: it is never changed in place.
sub _block {
    my ($self, $bref) = @_;
    if ($$bref =~ /(?<!\r)\n/) {
        (my $copy = $$bref) =~ s/\r\n/\n/g;
        $copy =~ s/\n/\r\n/g;
        $bref = \$copy;
    }
    my $first = $self->{line};
    my $last  = $first + ($$bref =~ tr/\n//) - 1;
    $self->{line} = $last + 1;

    # Each group's part of this block: spans of lines and literal segments.
    my (@work, %need);
    for my $g (@{$self->{groups}}) {
        my $segs = $g->{segs};
        my @ops;
        while ($g->{next} < @$segs) {
            my ($type, $s, $e) = @{$segs->[$g->{next}]};
            if ($type) {
                push @ops, [1, $s, $e];
                $g->{next}++;
                next;
            }
            last if $s > $last;
            my $from = $s > $first ? $s : $first;
            my $to   = $e < $last  ? $e : $last;
            if ($from <= $to) {
                push @ops, [0, $from, $to];
                @need{$from, $to + 1} = ();
            }
            last if $e > $last;
            $g->{next}++;
        }
        push @work, [$g, \@ops] if @ops;
    }
    return unless @work;

    # Byte offset of each line wanted, in one walk down the block.
    my %off;
    my ($line, $pos) = ($first, 0);
    for my $want (sort { $a <=> $b } keys %need) {
        for (my $k = $want - $line; $k > 0; ) {
            my $j = $k > JUMP ? JUMP : $k;
            pos($$bref) = $pos;
            $$bref =~ /\G(?:[^\n]*\n){$j}/g
                or croak "BodyPlan: line $want not in block";
            $pos = pos($$bref);
            $k -= $j;
        }
        $line = $want;
        $off{$want} = $pos;
    }

    for my $w (@work) {
        my ($g, $ops) = @$w;
        for my $op (@$ops) {
            my ($type, $s, $e) = @$op;
            if ($type) {
                _literal($g, $self->{literals}[$_]) for $s .. $e;
            } else {
                _span($g, $bref, $off{$s}, $off{$e + 1}, $e - $s + 1);
            }
        }
    }
}

# The $n whole CRLF lines of $$bref from $from to $to into $g, in one piece.
# Blank lines are held back until a non-blank line follows them (trailing
# blank lines are not hashed, -07 §6.1): those at the end of the run are
# found by looking back from its end, and counted, not hashed.
sub _span {
    my ($g, $bref, $from, $to, $n) = @_;
    $g->{lines} += $n;
    if ($to - $from == 2 * $n) {
        $g->{pending} += $n;
        return;
    }
    my ($end, $blank) = ($to, 0);
    while ($end - $from >= 4 && substr($$bref, $end - 4, 4) eq "\r\n\r\n") {
        $end -= 2;
        $blank++;
    }
    _emit($g, "\r\n" x $g->{pending}) if $g->{pending};
    _emit($g, substr($$bref, $from, $end - $from));
    $g->{pending} = $blank;
}

sub _literal {
    my ($g, $text) = @_;
    $g->{lines}++;
    if ($text eq '') {
        $g->{pending}++;
        return;
    }
    _emit($g, ("\r\n" x $g->{pending}) . "$text\r\n");
    $g->{pending} = 0;
}

sub _emit {
    my ($g) = @_;
    $_->add($_[1]) for values %{$g->{digest}};
    $g->{emitted} = 1;
}

# finish(): the body has all been added. Hashes the literals after the last
# body line, and checks each body Recipe's copy ranges against the length of
# the body it applies to.
sub finish {
    my ($self) = @_;
    return if $self->{done};
    if (length $self->{carry}) {
        my $last = delete($self->{carry}) . "\r\n";
        $self->_block(\$last);
    }
    for my $g (@{$self->{groups}}) {
        my $segs = $g->{segs};
        for (; $g->{next} < @$segs; $g->{next}++) {
            my ($type, $s, $e) = @{$segs->[$g->{next}]};
            next unless $type;
            _literal($g, $self->{literals}[$_]) for $s .. $e;
        }
        _emit($g, "\r\n") unless $g->{emitted};
        $g->{hash}{$_} = encode_base64($g->{digest}{$_}->digest, '')
            for keys %{$g->{digest}};
    }

    # The undo walk's verdicts, in its words: the first bad body Recipe
    # ends the walk, and no instance below it has a body.
    my $broken;
    for my $inst (@{$self->{instances}}) {
        delete $inst->{group} if $broken;
        next unless defined $inst->{rb};
        my $lines = $inst->{group} ? $inst->{group}{lines} : undef;
        eval { Mail::DKIM2::MessageInstance::_check_recipe('body', $inst->{rb}, $lines); 1 }
            or ($inst->{error} = $@, $broken = 1);
    }
    $self->{done} = 1;
    return;
}

# body_hash($m, $alg): the base64 body hash of instance m= by $alg, or undef
# if that instance's body cannot be rebuilt or it has no $alg hash-set.
sub body_hash {
    my ($self, $m, $alg) = @_;
    croak "BodyPlan: body_hash before finish" unless $self->{done};
    my $inst = $self->{by_m}{0 + $m} or return undef;
    my $g = $inst->{group} or return undef;
    return $g->{hash}{lc $alg};
}

# recipe_error($m): why instance m='s body Recipe does not undo, or undef.
sub recipe_error {
    my ($self, $m) = @_;
    croak "BodyPlan: recipe_error before finish" unless $self->{done};
    my $inst = $self->{by_m}{0 + $m} or return undef;
    return $inst->{error};
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::BodyPlan - every Message-Instance's body hash in one pass

=head1 SYNOPSIS

  use Mail::DKIM2::BodyPlan;

  # The parsed Message-Instance fields, highest m= first.
  my $plan = Mail::DKIM2::BodyPlan->new(@instances);
  $plan->add($chunk) while defined($chunk = next_body_chunk());
  $plan->finish;

  for my $mi (@instances) {
      my $m = $mi->get_tag('m');
      die $plan->recipe_error($m) if $plan->recipe_error($m);
      my $bh = $plan->body_hash($m, 'sha256');    # undef: no body to hash
  }

=head1 DESCRIPTION

The undo walk checks a chain by rebuilding each previous body from the one
above it and hashing it, so a chain of N instances copies and hashes the
body N times. A BodyPlan reads the body Recipes first and works out, for
every instance, which lines of the current body and which Recipe literals
make up its body, in order. Copy ranges ascend (-07 section 5.2), so
those lists are all in body order, and the current body is read once, front
to back, in pieces of any size, each line going to the digests of the
instances that hold it. No previous body is built, and the current one is
never held whole. Instances with the same body (no body Recipe) share one
set of digests.

Below a null body Recipe, or a body Recipe that does not undo, no instance
has a body hash. The verdicts and their wording are those of
L<Mail::DKIM2::MessageInstance/undo>: L<Mail::DKIM2::Verifier>'s
C<StreamBody> option uses a BodyPlan in place of the undo walk's bodies.

=head1 METHODS

=head2 new(@instances)

The L<Mail::DKIM2::MessageInstance> objects of the chain, highest C<m=>
first, each the parent of the next. Hashes are computed for each
instance's C<h=> algorithms that are implemented.

=head2 compose($segments, $recipe, \@literals)

A function, not a method: the segment list for what C<$recipe> (copy
ranges and literals, as L<Mail::DKIM2::MessageInstance/parse> gives them)
rebuilds from C<$segments>, appending its literals to C<@literals>. A
segment is C<[0, $from, $to]>, a run of the original lines (or values), or
C<[1, $from, $to]>, a run of C<@literals>. Copy ranges must already be
known to ascend; one past the end is cut short. L<Mail::DKIM2::HeaderPlan>
uses it too.

=head2 add($bytes)

The next piece of the current body, cut anywhere. A CRLF or a bare LF ends
a line.

=head2 finish()

The body has all been added. Checks each body Recipe's copy ranges against
the body it applies to.

=head2 body_hash($m, $alg)

The base64 body hash of instance C<$m> by C<$alg>, after C<finish>; undef
if that instance's body cannot be rebuilt.

=head2 recipe_error($m)

After C<finish>, why instance C<$m>'s body Recipe does not undo, in
L<Mail::DKIM2::MessageInstance/undo>'s words; undef if it does.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
