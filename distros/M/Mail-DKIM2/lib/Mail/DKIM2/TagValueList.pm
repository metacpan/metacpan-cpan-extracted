package Mail::DKIM2::TagValueList;
use strict;
use warnings;

our $VERSION = '0.18';

# Simple tag=value list as defined in draft-ietf-dkim-dkim2-spec-06 Sections 6 and 7.
# Preserves insertion order for serialization.

sub new {
    my ($class) = @_;
    return bless { tags => {}, order => [] }, $class;
}

# A constructor: always a fresh object, even when called on an existing one
# (parsing into one left its old tags and duplicate flag behind).
sub parse {
    my ($class, $string) = @_;
    my $self = (ref($class) || $class)->new();

    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    my @order;
    my %seen;
    # Tag names keep their original case and order, and values their
    # internal whitespace; as_string() writes "name=value" joined by "; ",
    # so the whitespace around "=" and ";" and a trailing ";" are not kept.
    # That is harmless for signing input: §9.6 deletes all WSP from these
    # fields before hashing. get_tag() does the case-insensitive lookup
    # required by spec-06 §8.
    for my $part (split /\s*;\s*/, $string) {
        next unless $part =~ /^(\w+)\s*=\s*(.*)/s;
        my ($name, $val) = ($1, $2);
        $val =~ s/\s+$//;
        # §8: "there MUST be only one of each kind" — flag any repeat.
        $self->{_duplicate} = lc($name) if $seen{lc $name}++;
        $self->{tags}{$name} = $val;
        push @order, $name;
    }
    $self->{order} = \@order;
    return $self;
}

# §8: tag identifiers are case-insensitive.  Try an exact match first (the
# common case), then fall back to a case-insensitive scan.
sub get_tag {
    my ($self, $name) = @_;
    return $self->{tags}{$name} if exists $self->{tags}{$name};
    my $lc = lc $name;
    for my $k (keys %{$self->{tags}}) {
        return $self->{tags}{$k} if lc($k) eq $lc;
    }
    return undef;
}

# The lowercased tag name that appeared more than once, if any (spec-06 §8).
sub duplicate_tag { return $_[0]->{_duplicate} }

sub set_tag {
    my ($self, $name, $value) = @_;
    unless (exists $self->{tags}{$name}) {
        push @{$self->{order}}, $name;
    }
    $self->{tags}{$name} = $value;
}

sub as_string {
    my ($self) = @_;
    return join('; ', map { "$_=$self->{tags}{$_}" } @{$self->{order}});
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::TagValueList - The tag=value list a DKIM2 header is made of

=head1 SYNOPSIS

    use Mail::DKIM2::TagValueList;

    my $tvl = Mail::DKIM2::TagValueList->parse("i=1; d=example.com");
    say $tvl->get_tag('d');   # "example.com"

    $tvl->set_tag('t', time);
    say $tvl->as_string;      # "i=1; d=example.com; t=1740000000"

=head1 DESCRIPTION

A semicolon-separated list of C<tag=value> pairs (spec-06 section 2.12 and
8). Tag names keep their original case and order, and values their
internal whitespace; serialisation joins C<name=value> pairs with C<; >, so
the whitespace around C<=> and C<;> and a trailing C<;> are normalised
(harmless for signing input, which section 9.6 strips of all whitespace).
Lookups are case-insensitive. L<Mail::DKIM2::Signature> is a subclass.

=head1 CONSTRUCTORS

=head2 new()

An empty list.

=head2 parse($string)

Parses a list into a new object (also when called on an existing one),
trimming whitespace around names and values. A tag given twice (in any
case) is reported by C<duplicate_tag>; the verifier rejects such a field.

=head1 METHODS

=head2 get_tag($name)

The value of the tag, matched case-insensitively, or undef.

=head2 set_tag($name, $value)

Sets a tag, appending it to the order if new.

=head2 duplicate_tag()

The lowercased name of a tag that appeared more than once in the parsed
input, or undef. Section 8 allows one of each; the Verifier reports a
repeat as a permerror.

=head2 as_string()

The list serialised in its original order, C<"; "> between pairs.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
