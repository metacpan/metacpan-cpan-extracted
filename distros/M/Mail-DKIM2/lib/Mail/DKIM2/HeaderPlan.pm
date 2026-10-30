package Mail::DKIM2::HeaderPlan;
use strict;
use warnings;

our $VERSION = '0.28';

use Carp;
use Scalar::Util qw(refaddr);
use Mail::DKIM2::Common qw(parse_mime should_skip dkim2_canonicalize_header);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::BodyPlan;

# Every Message-Instance's header hash from the header fields as received
# and the header Recipes, without rebuilding any previous header.
#
# The fields are split once; a value is only unfolded and canonicalized if
# its name is in the header hash, once. For each field name an instance
# has a segment list, as Mail::DKIM2::BodyPlan has for body lines: runs of
# this name's values as received, numbered bottom up as the Recipes number
# them ([0, from, to]), and of Recipe literals ([1, from, to]). The top
# instance has every value; each instance below has its parent's lists,
# with its parent's header Recipe applied to the names that Recipe names.
# A name's list that no Recipe touched is shared, and so is its canonical
# text.

# new($header, IgnorePrefixes => \@prefixes)
#
# $header: the header fields as received, as one string, or as a list of
# fields, each with its folded lines and line break (HeaderParser's
# {headers}).
sub new {
    my ($class, $header, %opts) = @_;
    Mail::DKIM2::Common::_check_options("$class->new", \%opts, qw(IgnorePrefixes));
    my $self = bless {
        prefixes => $opts{IgnorePrefixes},
        by_m     => {},
        raw      => {},    # lc name => its fields, bottom up
        literals => [],
        raw_literals => [],
    }, $class;
    for my $raw (reverse @{ _raw_fields($header) }) {
        push @{$self->{raw}{lc substr($raw, 0, index($raw, ':'))}}, $raw;
    }
    return $self;
}

# The fields of $header (as new() takes it) as strings, each one field and
# its continuation lines, split as Email::Simple splits them (the undo
# walk's parser): a line that begins with white space, or has no colon,
# continues the field above it. HeaderParser's fields already are, as long
# as every line ends in a CRLF; any other line break goes through
# Email::Simple itself.
sub _raw_fields {
    my ($header) = @_;
    my $text = ref $header ? join('', @$header) : $header;
    # A CR or LF that is not part of a CRLF. Two patterns, not one: each
    # starts with a fixed character perl can skip to, and the alternation
    # of the two is far slower.
    if ($text =~ /(?<!\r)\n/ || $text =~ /\r(?!\n)/) {
        my @pairs = parse_mime("$text\r\n")->header_obj->header_raw_pairs;
        return [ map { "$pairs[2 * $_]:$pairs[2 * $_ + 1]\r\n" } 0 .. $#pairs / 2 ];
    }
    return $header if ref $header;
    my @fields;
    for my $line (split /\r\n/, $text) {
        next unless length $line;
        if ($line =~ /^\s+/ or $line !~ /^[^:]+:/) {
            $fields[-1] .= "$line\r\n" if @fields;
        } else {
            push @fields, "$line\r\n";
        }
    }
    return \@fields;
}

# A field's value as Email::Simple's header_raw gives it: after the colon
# and any white space, each continuation line's leading white space taken
# off and the line joined on with one space.
sub _value {
    my ($raw) = @_;
    my ($first, @more) = split /\r\n/, $raw;
    my ($value) = $first =~ /^[^:]+:\s*(.*)/;
    for my $line (@more) {
        (my $trimmed = $line) =~ s/^\s+//;
        $value .= $value =~ /\S/ ? " $trimmed" : $trimmed;
    }
    return $value;
}

# fields($header): [name, value] for every field, in order.
sub fields {
    my ($header) = @_;
    return [ map { [ substr($_, 0, index($_, ':')), _value($_) ] } @{ _raw_fields($header) } ];
}

# values($name): the values of the fields named $name, top first.
sub values {
    my ($self, $name) = @_;
    return reverse map { _value($_) } @{ $self->{raw}{lc $name} || [] };
}

# plan(@instances): the parsed Message-Instance objects, highest m= first;
# works out every instance's header hashes and header Recipe verdicts.
sub plan {
    my ($self, @mis) = @_;
    my $impl = Mail::DKIM2::MessageInstance::hash_algs();
    my $raw = $self->{raw};
    my $lists = { map { $_ => [[0, 1, scalar @{$raw->{$_}}]] } keys %$raw };
    # refaddr of a list => [the list, its canonical text]. Holding the list
    # keeps its address from being reused by a later level's list.
    my %text;
    for my $mi (@mis) {
        my $m = 0 + $mi->get_tag('m');    # m=01 is 1
        my $hashes = $mi->get_tag('hashes') || {};
        my $inst = $self->{by_m}{$m} = { lists => $lists };
        if ($lists) {
            my $data = join '', map {
                ($text{refaddr $lists->{$_}} //= [$lists->{$_}, $self->_text($_, $lists->{$_})])->[1]
            } grep { $self->_hashed($_) } sort keys %$lists;
            $inst->{hash}{$_} = Mail::DKIM2::MessageInstance::_hash_data_b64($_, $data)
                for grep { $impl->{$_} } keys %$hashes;
        }

        # The next instance down: each name this Recipe names, in turn, in
        # the order undo applies them.
        my $rh = $mi->get_tag('rh') or next;
        next unless $lists;
        my %next = %$lists;
        for my $h (sort keys %$rh) {
            my $lc = lc $h;
            $self->{rewrites_instances} = 1 if $lc eq 'message-instance';
            my $cur = $next{$lc} || [];
            my $count = 0;
            $count += $_->[2] - $_->[1] + 1 for @$cur;
            unless (eval { Mail::DKIM2::MessageInstance::_check_recipe("$h header", $rh->{$h}, $count); 1 }) {
                $inst->{error} = $@;
                $lists = undef;
                last;
            }
            my $first = @{$self->{literals}};
            $next{$lc} = Mail::DKIM2::BodyPlan::compose($cur, $rh->{$h}, $self->{literals});
            # values_at() wants them as they are.
            push @{$self->{raw_literals}}, @{$self->{literals}}[$first .. $#{$self->{literals}}];
            # Literals are values of this name: canonicalize them as such.
            $_ = dkim2_canonicalize_header("$lc: $_\r\n")
                for @{$self->{literals}}[$first .. $#{$self->{literals}}];
        }
        $lists = \%next if $lists;
    }
    return $self;
}

sub _hashed {
    my ($self, $lc) = @_;
    return $self->{hashed}{$lc} //= !should_skip($lc, $self->{prefixes});
}

# The canonical text of one name's segment list; each value as received is
# canonicalized the first time any list wants it.
sub _text {
    my ($self, $lc, $segs) = @_;
    my $canon = $self->{canon}{$lc} //= [
        map { dkim2_canonicalize_header("$lc: " . _value($_) . "\r\n") } @{ $self->{raw}{$lc} || [] }
    ];
    return join '', map {
        my ($type, $s, $e) = @$_;
        $type ? @{$self->{literals}}[$s .. $e] : @{$canon}[$s - 1 .. $e - 1]
    } @$segs;
}

# header_hash($m, $alg): the base64 header hash of instance m= by $alg, or
# undef if a header Recipe above it does not undo or it has no $alg hash-set.
sub header_hash {
    my ($self, $m, $alg) = @_;
    my $inst = $self->{by_m}{0 + $m} or return undef;
    return $inst->{hash} && $inst->{hash}{lc $alg};
}

# recipe_error($m): why instance m='s header Recipe does not undo, or undef.
sub recipe_error {
    my ($self, $m) = @_;
    my $inst = $self->{by_m}{0 + $m} or return undef;
    return $inst->{error};
}

# values_at($m, $name): the values of the fields named $name in the header
# as it was when instance m= was the highest (the header Recipes above it
# applied), each as Email::Simple's header_raw gives it; undef if a header
# Recipe on the way down does not undo. Bottom up, as Recipes number them.
sub values_at {
    my ($self, $m, $name) = @_;
    my $inst = $self->{by_m}{0 + $m} or return undef;
    my $lists = $inst->{lists} or return undef;
    my $lc = lc $name;
    my $raw = $self->{raw}{$lc} || [];
    return [ map {
        my ($type, $s, $e) = @$_;
        $type ? @{$self->{raw_literals}}[$s .. $e] : map { _value($raw->[$_ - 1]) } $s .. $e
    } @{ $lists->{$lc} || [] } ];
}

# rewrites_instances(): a header Recipe names Message-Instance. Undoing it
# changes the instances below it, which this plan does not follow.
sub rewrites_instances { return $_[0]->{rewrites_instances} ? 1 : 0 }

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::HeaderPlan - every Message-Instance's header hash without undo

=head1 SYNOPSIS

  use Mail::DKIM2::HeaderPlan;

  my $plan = Mail::DKIM2::HeaderPlan->new($header_text,
      IgnorePrefixes => \@prefixes);
  my @instances = map { Mail::DKIM2::MessageInstance->parse($_) }
                  highest_first($plan->values('Message-Instance'));
  $plan->plan(@instances);

  for my $mi (@instances) {
      my $m = $mi->get_tag('m');
      die $plan->recipe_error($m) if $plan->recipe_error($m);
      my $hh = $plan->header_hash($m, 'sha256');
  }

=head1 DESCRIPTION

The undo walk checks a chain by rebuilding each previous header from the
one above it, and canonicalizing and hashing every field again at each
level. A HeaderPlan splits the fields once, unfolds and canonicalizes a
value only if its name is in the header hash, and works out from the
header Recipes which values (as received, or Recipe literals) each
instance's fields were, name by name. A name no Recipe touches costs
nothing at the levels below. The hashes and the verdicts, in their
wording, are those of L<Mail::DKIM2::MessageInstance/undo> and C<h_digest>;
L<Mail::DKIM2::Verifier>'s C<StreamBody> option uses a HeaderPlan with a
L<Mail::DKIM2::BodyPlan>.

=head1 METHODS

=head2 new($header, %options)

C<$header> is the header fields as received: one string, each field with
its line break, or a list of fields, each with its continuation lines and
line break (as L<Mail::DKIM2::HeaderParser> collects them). Fields are
split as L<Email::Simple> splits them: a line that begins with white space
or has no colon continues the field above. C<IgnorePrefixes> is as for
L<Mail::DKIM2::Verifier>.

=head2 fields($header)

A function: C<[$name, $value]> for every field of C<$header> (as C<new>
takes it), in order, the value unfolded as L<Email::Simple>'s C<header_raw>
gives it.

=head2 values($name)

The values of the fields named C<$name> (any case), top first.

=head2 plan(@instances)

The L<Mail::DKIM2::MessageInstance> objects of the chain, highest C<m=>
first. Computes every instance's header hashes and checks each header
Recipe. Returns the plan.

=head2 header_hash($m, $alg)

The base64 header hash of instance C<$m> by C<$alg>; undef below a header
Recipe that does not undo, or for an algorithm the instance does not use.

=head2 recipe_error($m)

Why instance C<$m>'s header Recipe does not undo, in
L<Mail::DKIM2::MessageInstance/undo>'s words; undef if it does.

=head2 values_at($m, $name)

An arrayref of the values of the fields named C<$name> in the header as it
was when instance C<$m> was the highest -- the header Recipes above it
applied -- each as Email::Simple's C<header_raw> gives it, bottom up; undef
if a header Recipe on the way down does not undo. The Verifier reads each
version's From fields from it (-08 section 11). New in 0.23.

=head2 rewrites_instances()

True if a header Recipe names Message-Instance. Undoing one changes the
instances the levels below it see, which a HeaderPlan does not follow; a
caller uses the undo walk for such a message.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
