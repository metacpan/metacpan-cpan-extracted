package Mail::DKIM2::TagValueList;
use strict;
use warnings;

our $VERSION = '0.25';

# Simple tag=value list as defined in draft-ietf-dkim-dkim2-spec-07 Section 8.
# Preserves insertion order for serialization.

sub new {
    my ($class) = @_;
    return bless { tags => {}, order => [] }, $class;
}

# The tag-list grammar shared by every DKIM2 field (-07 §8): a tag
# name is ALPHA *(ALPHA / DIGIT / "_"), and a value is printable ASCII other
# than ";" with FWS only between characters (x-tag-value). The known tags'
# own grammars are all narrower than that, so a field that fails it is
# malformed (§14.2) whatever its tags are. DKIM1 key records use the same
# value characters (RFC 6376 §3.2 VALCHAR).
our $TAG_NAME  = qr/[A-Za-z][A-Za-z0-9_]*/;
our $TAG_VALUE = qr/(?:[\x21-\x3A\x3C-\x7E]+(?:[ \t\r\n]+[\x21-\x3A\x3C-\x7E]+)*)?/;

# Split a tag-list into [name, value] pairs, the whitespace around names and
# values trimmed. A trailing ";" is allowed. Returns
# (\@pairs, $ok): $ok is false if an empty spec comes before the end
# (";;"), any other spec is not name=value, or a
# value has a character the grammar does not allow. The pairs still hold
# every spec that did parse, for diagnostics.
sub split_tag_list {
    my ($string) = @_;
    my (@pairs, $bad);
    my @specs = split /;/, $string, -1;
    # -07 section 8: one ";" may end the list; an empty spec anywhere else
    # (";;", a leading ";") is a syntax error.
    pop @specs if @specs && $specs[-1] =~ /\A[ \t\r\n]*\z/;
    for my $spec (@specs) {
        if ($spec =~ /\A[ \t\r\n]*\z/) { $bad = 1; next }
        my ($name, $val) = $spec =~ /\A[ \t\r\n]*($TAG_NAME)[ \t\r\n]*=[ \t\r\n]*(.*?)[ \t\r\n]*\z/s
            or do { $bad = 1; next };
        $bad = 1 unless $val =~ /\A$TAG_VALUE\z/;
        push @pairs, [$name, $val];
    }
    return (\@pairs, !$bad);
}

# A constructor: always a fresh object, even when called on an existing one
# (parsing into one left its old tags and duplicate flag behind).
sub parse {
    my ($class, $string) = @_;
    my $self = (ref($class) || $class)->new();

    # Tag names keep their original case and order, and values their
    # internal whitespace; as_string() writes "name=value" joined by "; ",
    # so the whitespace around "=" and ";" and a trailing ";" are not kept.
    # That is harmless for signing input: §12.8 deletes all WSP from these
    # fields before hashing. get_tag() does the case-insensitive lookup
    # required by -07 §8. A spec that is not a tag is never silently
    # dropped from what is verified: it makes the whole field a syntax
    # error (follow-up review F3).
    my ($pairs, $ok) = split_tag_list($string);
    $self->{_syntax_error} = 1 unless $ok;
    my (@order, %seen);
    for my $p (@$pairs) {
        my ($name, $val) = @$p;
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

# The lowercased tag name that appeared more than once, if any (-07 §8).
sub duplicate_tag { return $_[0]->{_duplicate} }

# True if the parsed field did not match the tag-list grammar.
sub syntax_error { return $_[0]->{_syntax_error} }

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

A semicolon-separated list of C<tag=value> pairs (-07 section 2.12 and
8). Tag names keep their original case and order, and values their
internal whitespace; serialisation joins C<name=value> pairs with C<; >, so
the whitespace around C<=> and C<;> and a trailing C<;> are normalised
(harmless for signing input, which -07 section 12.8 strips of all whitespace).
Lookups are case-insensitive. L<Mail::DKIM2::Signature> is a subclass.

=head1 CONSTRUCTORS

=head2 new()

An empty list.

=head2 parse($string)

Parses a list into a new object (also when called on an existing one),
trimming whitespace around names and values. A tag given twice (in any
case) is reported by C<duplicate_tag>, and a field that is not a valid tag
list by C<syntax_error>; the verifier rejects either.

=head1 METHODS

=head2 get_tag($name)

The value of the tag, matched case-insensitively, or undef.

=head2 set_tag($name, $value)

Sets a tag, appending it to the order if new.

=head2 duplicate_tag()

The lowercased name of a tag that appeared more than once in the parsed
input, or undef. Section 8 allows one of each; the Verifier reports a
repeat as a permerror.

=head2 syntax_error()

True if the parsed input did not match the tag-list grammar (-07 section
8): an empty fragment before the end (C<;;>; one trailing C<;> is fine), a
fragment that is not C<name=value>, a name not starting
with a letter, or a value with a character outside printable ASCII or a
C<;>. The well-formed tags are still available, for diagnostics.

=head2 as_string()

The list serialised in its original order, C<"; "> between pairs.

=head1 FUNCTIONS

=head2 split_tag_list($string)

Splits a tag list into an arrayref of C<[name, value]> pairs, whitespace
trimmed, and returns it with a flag that is false if any fragment was
malformed: C<my ($pairs, $ok) = split_tag_list($s)>.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
