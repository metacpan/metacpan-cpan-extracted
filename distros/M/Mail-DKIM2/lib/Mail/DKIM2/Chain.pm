package Mail::DKIM2::Chain;
use strict;
use warnings;

our $VERSION = '0.33';

use Carp ();
use Mail::DKIM2::Util ();
use Mail::DKIM2::Common qw(
    MI_MISSING_M_ERROR
    MAX_CHAIN_LENGTH
    chain_length_error
    chain_number_error
    duplicate_number_error
    extract_mi_version
    mi_version_tag
    unkeyable_signature_error
    valid_sequence
);
use Mail::DKIM2::HeaderParser;
use Mail::DKIM2::Signature;
use Mail::DKIM2::MessageInstance;

# The Message-Instance and DKIM2-Signature fields of one message, numbered:
# what the Verifier, the Signer and the Gate each need to know about a chain
# before any of them looks at the content. Fields are added as the header is
# read; nothing here hashes, fetches a key or checks a signature.

sub new {
    my ($class) = @_;
    return bless {
        instance  => {},    # m => the raw field
        signature => {},    # i => { raw => the raw field, sig => Signature }
        count     => {},    # lower-cased field name => how many there were
        numbers   => { 'message-instance' => [], 'dkim2-signature' => [] },
        parsed    => {},    # m => [MessageInstance or undef, error]
    }, $class;
}

# from_fields(\@fields): a chain from header fields given whole, name and
# value, as Mail::DKIM2::HeaderParser keeps them. Other fields are ignored.
sub from_fields {
    my ($class, $fields) = @_;
    my $self = $class->new;
    for my $raw (@$fields) {
        my ($name, $value) = $raw =~ /\A([^\s:]+)[ \t]*:[ \t]*(.*)\z/s or next;
        $value =~ s/\r?\n\z//;
        $self->add_field($name, $value, $raw);
    }
    return $self;
}

# from_message($text): a chain from a message, or from its header block
# alone, as a string. Only the header fields are read.
sub from_message {
    my ($class, $text) = @_;
    Carp::croak("from_message needs a message") unless defined $text;
    my $reader = Mail::DKIM2::Chain::_Reader->new;
    $reader->PRINT($text);
    $reader->CLOSE;
    return $reader->{chain};
}

{
    # The header fields of a message, as the Signer and the Verifier split
    # them, straight into a chain; the body is not read.
    package Mail::DKIM2::Chain::_Reader;
    use parent -norequire, 'Mail::DKIM2::HeaderParser';
    sub init {
        my $self = shift;
        $self->SUPER::init;
        $self->{chain} = Mail::DKIM2::Chain->new;
    }
    sub handle_header { $_[0]{chain}->add_field(@_[1 .. 3]) }
    sub finish_header { $_[0]->stop }
}

# add_field($name, $value, $raw): take one header field -- its name, its
# value without the line break, and the whole field as it is in the
# message. True if it was a Message-Instance or DKIM2-Signature field.
#
# A field that cannot be placed in the chain is remembered as the chain's
# fault (numbering_error), never skipped: a DKIM2-Signature that does not
# parse, or has no i=, or an i= or m= that is not a chain number (1*DIGIT,
# at most two digits, no more than MAX_CHAIN_LENGTH); a Message-Instance
# without a usable m=. Past MAX_CHAIN_LENGTH fields of either kind the rest
# are counted and not read: the count alone is the fault.
sub add_field {
    my ($self, $name, $value, $raw) = @_;
    my $lc = lc $name;
    $lc =~ s/[ \t]+\z//;
    return 0 unless $lc eq 'message-instance' || $lc eq 'dkim2-signature';
    return 1 if ++$self->{count}{$lc} > MAX_CHAIN_LENGTH;
    $raw //= "$name:$value";

    if ($lc eq 'message-instance') {
        my $tag = mi_version_tag($value);
        if (!defined $tag) {
            $self->{instance_unusable} //= MI_MISSING_M_ERROR;
        }
        elsif (my $e = chain_number_error('Message-Instance', 'm', $tag)) {
            $self->{instance_unusable} //= $e;
        }
        else {
            my $m = extract_mi_version($value);    # numeric: m=01 is m=1
            push @{ $self->{numbers}{$lc} }, $m;
            $self->{instance}{$m} = $raw;
        }
        return 1;
    }

    my $sig = eval { Mail::DKIM2::Signature->parse($value) };
    die $@ if ref $@;
    my $i = $sig ? $sig->sequence : undef;
    if (!valid_sequence($i)) {
        $self->{signature_unusable} //= unkeyable_signature_error($value);
    }
    elsif (my $e = chain_number_error('DKIM2-Signature', 'i', $i)
                // chain_number_error('DKIM2-Signature', 'm', $sig->version, $i)) {
        $self->{signature_unusable} //= $e;
    }
    else {
        push @{ $self->{numbers}{$lc} }, $i;
        $self->{signature}{ $i + 0 } = { raw => $raw, sig => $sig };
    }
    return 1;
}

# --- What is in the chain ---

sub count {
    my ($self, $field) = @_;
    return $self->{count}{ lc $field } // 0;
}

sub is_empty {
    my ($self) = @_;
    return !%{ $self->{count} };
}

# (Through an array: sort in scalar context returns nothing useful, and
# "unless $chain->instance_numbers" should count them.)
sub instance_numbers  { my @n = sort { $a <=> $b } keys %{ $_[0]{instance} };  return @n }
sub signature_numbers { my @n = sort { $a <=> $b } keys %{ $_[0]{signature} }; return @n }

sub top_instance { return ($_[0]->instance_numbers)[-1] }
sub top_signature_number { return ($_[0]->signature_numbers)[-1] }

sub instance_field { return $_[0]{instance}{ $_[1] } }

# The chain's own maps, for a caller that walks all of it: m => the raw
# field, and i => { raw => the raw field, sig => the Signature }.
sub instance_fields   { return $_[0]{instance} }
sub signature_entries { return $_[0]{signature} }

sub signature {
    my ($self, $i) = @_;
    my $entry = $self->{signature}{$i} or return;
    return $entry->{sig};
}

sub signature_field {
    my ($self, $i) = @_;
    my $entry = $self->{signature}{$i} or return;
    return $entry->{raw};
}

sub signatures {
    my ($self) = @_;
    return map { $self->{signature}{$_}{sig} } $self->signature_numbers;
}

sub top_signature {
    my ($self) = @_;
    my $i = $self->top_signature_number // return;
    return $self->{signature}{$i}{sig};
}

# instance($m): the parsed Message-Instance m=, or (undef, $error) when it
# is not there or does not parse -- $error in the words the Verifier
# reports. Parsed once, however many callers ask.
sub instance {
    my ($self, $m) = @_;
    my $cached = $self->{parsed}{$m} //= do {
        my $raw = $self->{instance}{$m};
        if (!defined $raw) {
            [undef, "PERMERROR: Message-Instance m=$m missing"];
        } else {
            (my $value = $raw) =~ s/\A[^:]*:[ \t]*//;
            my $obj = eval { Mail::DKIM2::MessageInstance->parse($value) };
            die $@ if ref $@;
            $obj ? [$obj] : [undef, Mail::DKIM2::MessageInstance::_parse_error($@)];
        }
    };
    return wantarray ? @$cached : $cached->[0];
}

# covered_m(): the highest m= any signature names, or 0. A DKIM2-Signature
# with m=k covers instances 1 to k (-09 section 10.2), so every instance
# above this is one nobody has signed yet.
sub covered_m {
    my ($self) = @_;
    my $covered = 0;
    for my $sig ($self->signatures) {
        my $m = $sig->version // next;
        $covered = 0 + $m if $m > $covered;
    }
    return $covered;
}

# unsigned_instances(): the m= of every instance above covered_m, ascending.
sub unsigned_instances {
    my ($self) = @_;
    my $covered = $self->covered_m;
    my @above = grep { $_ > $covered } $self->instance_numbers;
    return @above;
}

# instances_changing($name, $above, $upto): the m= of every instance with
# $above < m <= $upto that has a header Recipe for the field named $name --
# the hops, between two signatures, that say they changed that field. One
# that does not parse says nothing. m=1 is never in it: its Recipes record
# what happened to the message before DKIM2, which no signature answers for.
sub instances_changing {
    my ($self, $name, $above, $upto) = @_;
    $above //= 0;
    $upto  //= $self->top_instance // 0;
    my @changing = grep {
        my $mi = $_ >= 2 && $_ > $above && $_ <= $upto ? $self->instance($_) : undef;
        $mi && $mi->changes_header($name);
    } $self->instance_numbers;
    return @changing;
}

# --- Whether it is a chain ---

# numbering_error(%opts): the PERMERROR for a chain whose fields cannot be
# numbered, or undef -- too many fields, a field with no usable number, a
# number given twice. In the interop contract's order (C9, a to e), so every
# verifier names the same fault first. Signatures => 0 leaves the
# DKIM2-Signature fields out of it, but for their count.
sub numbering_error {
    my ($self, %o) = @_;
    my $sigs = $o{Signatures} // 1;
    my $n = $self->{numbers};
    return chain_length_error($self->{count})                                        # a
        // $self->{instance_unusable}                                                # b
        // duplicate_number_error('Message-Instance', 'm', @{ $n->{'message-instance'} })   # c
        // ($sigs ? $self->{signature_unusable} : undef)                             # d
        // ($sigs ? duplicate_number_error('DKIM2-Signature', 'i',                   # e
                        @{ $n->{'dkim2-signature'} }) : undef);
}

# structure_error(%opts): numbering_error, then the gaps and the coverage
# the numbers give (-09 section 14.2; C9, f to h): every instance from m=1
# to the highest there is or the highest the top signature names; no
# instance above every signature's m= (unless AllowUnsigned: a signer holds
# the instance it is about to sign); every signature from i=1 to the
# highest. Signatures => 0 checks the instances alone.
sub structure_error {
    my ($self, %o) = @_;
    Mail::DKIM2::Util::check_options('structure_error', \%o, qw(Signatures AllowUnsigned));
    my $sigs = $o{Signatures} // 1;
    if (my $error = $self->numbering_error(Signatures => $sigs)) {
        return $error;
    }

    my $top_m = $self->top_instance;
    my $top_i = $sigs ? $self->top_signature_number : undef;
    my $named = defined $top_i ? ($self->signature($top_i)->version || 0) : 0;
    my $upto  = ($top_m // 0) > $named ? $top_m : $named;
    for my $m (1 .. $upto) {                                                         # f
        return "PERMERROR: Message-Instance m=$m missing" unless $self->{instance}{$m};
    }

    if (defined $top_m && $sigs && !$o{AllowUnsigned}) {                             # g
        return "PERMERROR: Message-Instance m=$top_m is not signed"
            if $top_m > $self->covered_m;
    }

    for my $i (1 .. ($top_i // 0)) {                                                 # h
        return "PERMERROR: DKIM2-Signature i=$i missing" unless $self->{signature}{$i};
    }
    return;
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::Chain - The Message-Instance and DKIM2-Signature fields of a message, numbered

=head1 SYNOPSIS

    use Mail::DKIM2::Chain;

    my $chain = Mail::DKIM2::Chain->from_message($message);

    if (my $error = $chain->structure_error) {
        ...     # "PERMERROR: DKIM2-Signature i=2 missing"
    }
    my $top = $chain->top_signature;                 # a Mail::DKIM2::Signature
    my ($mi, $why) = $chain->instance($chain->top_instance);
    my @mine = $chain->unsigned_instances;           # nobody has signed these yet

=head1 DESCRIPTION

What a message's DKIM2 fields say about themselves, before anything is
checked against the content or a key: which Message-Instance and
DKIM2-Signature fields there are, by number, whether those numbers form a
chain, and how far up the signatures reach. L<Mail::DKIM2::Verifier>,
L<Mail::DKIM2::Signer> and L<Mail::DKIM2::Gate> all read a message's chain
through one of these, so they agree on which fields count and name the same
fault first. New in 0.31.

See L<Mail::DKIM2/CONVENTIONS> for the conventions every module follows.

=head1 CONSTRUCTORS

=head2 new()

An empty chain, to be filled with L</add_field($name, $value, [$raw])>.

=head2 from_fields(\@fields)

A chain from header fields given whole (name, value and any continuation
lines), as L<Mail::DKIM2::HeaderParser> keeps them in C<< {headers} >>.
Fields of other names are ignored.

=head2 from_message($text)

A chain from a message, or just its header block, as a string. Only the
header fields are read, split as the Signer and the Verifier split them.

=head1 METHODS

=head2 add_field($name, $value, [$raw])

Adds one header field: its name, its value without the line break, and the
field as it is in the message (used for the signing input; built from the
other two if not given). Returns true if it was a Message-Instance or a
DKIM2-Signature field. A field that cannot be numbered -- a DKIM2-Signature
that does not parse or has no usable C<i=> or C<m=>, a Message-Instance
without a usable C<m=> -- is not skipped: it becomes the chain's
L</numbering_error(%options)>. After 32 fields of either kind
(L<Mail::DKIM2::Common/MAX_CHAIN_LENGTH>) the rest are counted, not read.

=head2 count($field_name)

How many fields of that name the message had.

=head2 is_empty()

True when the message has neither kind of field.

=head2 instance_numbers(), signature_numbers()

The C<m=> of every usable Message-Instance, and the C<i=> of every usable
DKIM2-Signature, ascending.

=head2 top_instance(), top_signature_number()

The highest of each, or undef.

=head2 instance_field($m), signature_field($i)

The field as it is in the message.

=head2 instance_fields(), signature_entries()

The whole of each map, as a hashref: C<m=> to the field as it is in the
message, and C<i=> to C<< { raw => $field, sig => $signature } >>. They are
the chain's own; do not change them.

=head2 instance($m)

The parsed L<Mail::DKIM2::MessageInstance>. In list context,
C<($instance)> or C<(undef, $error)>, the error in the Verifier's words
(C<PERMERROR: Message-Instance m=2 contains invalid JSON>). Each instance
is parsed once.

=head2 signature($i), signatures(), top_signature()

The parsed L<Mail::DKIM2::Signature> objects: one, all in ascending C<i=>
order, or the highest (undef if none).

=head2 covered_m()

The highest C<m=> any signature names, or 0: instances 1 to that are signed
(-09 section 10.2).

=head2 unsigned_instances()

The C<m=> of every instance above C<covered_m>: those no signature covers
yet, which the next signer answers for.

=head2 instances_changing($name, [$above], [$upto])

The C<m=> of every instance above C<$above> (default 0) and no higher than
C<$upto> (default the top) that has a header Recipe for the field named
C<$name>: the hops that say they changed it. C<m=1> never counts, and an
instance that does not parse says nothing. The Signer and the Verifier use
it to decide which signature answers for a From (-09 section 11).

=head2 numbering_error(%options)

The C<PERMERROR: ...> string for a chain whose fields cannot be numbered,
or undef: more than 32 fields of a kind, a field with no usable number, or
a number given twice. C<< Signatures => 0 >> leaves the DKIM2-Signature
fields out of it, for a caller that has had them checked already.

=head2 structure_error(%options)

C<numbering_error>, then (-09 section 14.2) a missing Message-Instance, an
instance above every signature's C<m=> ("is not signed"), and a missing
DKIM2-Signature. C<< AllowUnsigned => 1 >> permits the unsigned instance,
for a signer that holds the one it is about to sign; C<< Signatures => 0 >>
checks the instances alone.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
