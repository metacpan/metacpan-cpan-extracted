package Lingua::EN::Number::IsOrdinal;
our $AUTHORITY = 'cpan:RKITOVER';
$Lingua::EN::Number::IsOrdinal::VERSION = '0.05';
use strict;
use warnings;
use Exporter 'import';
use Lingua::EN::FindNumber 'extract_numbers';

=encoding UTF-8

=head1 NAME

Lingua::EN::Number::IsOrdinal - detect if English number is ordinal or cardinal

=head1 SYNOPSIS

    use Lingua::EN::Number::IsOrdinal 'is_ordinal';

    ok is_ordinal('first');

    ok !is_ordinal('one');

    ok is_ordinal('2nd');

    ok !is_ordinal('2');

=head1 DESCRIPTION

This module will tell you if a number, either in words or as digits, is a
cardinal or L<ordinal
number|http://www.ego4u.com/en/cram-up/vocabulary/numbers/ordinal>.

This is useful if you e.g. want to distinguish these types of numbers found with
L<Lingua::EN::FindNumber> and take different actions.

=cut

our @EXPORT_OK = qw/is_ordinal/;

my $ORDINAL_WORDS_NUMBER_RE = qr/(?:first|second|third|th)\s*$/;

my $NUMBER_RE  = qr/^\s*(?:[+-]?)(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee](?:[+-]?\d+))?/;

my $CARDINAL_NUMBER_RE = qr/$NUMBER_RE\s*$/;

my $ORDINAL_NUMBER_RE  = qr/$NUMBER_RE(?:st|nd|rd|th)\s*$/;

=head1 FUNCTIONS

=head2 is_ordinal

Takes a number as English words or digits (with or without ordinal suffix) and
returns C<1> for ordinal numbers and C<undef> for cardinal numbers.

Checks that the whole parameter is a number using L<Lingua::EN::FindNumber> or
a regex in the case of digits, and if it isn't will throw a C<not a number>
exception.

This function can be optionally imported.

=cut

sub is_ordinal { __PACKAGE__->_is_ordinal(@_) }

=head1 METHODS

=head2 _is_ordinal

Method version of L</is_ordinal>, this is where the function is actually
implemented. Can be overloaded in a subclass.

=cut

sub _is_ordinal {
    my ($self, $num) = @_;

    die "not a number" unless $self->_is_number($num);

    if ($num =~ $ORDINAL_NUMBER_RE) {
        return 1;
    }
    elsif ($num =~ $CARDINAL_NUMBER_RE) {
        return undef;
    }
    elsif ($num =~ $ORDINAL_WORDS_NUMBER_RE) {
        return 1;
    }

    return undef; # cardinal words-number
}

=head2 _is_number

Returns C<1> if the passed in string is a word-number as detected by
L<Lingua::EN::FindNumber> or is a cardinal or ordinal number made of digits and
(for ordinal numbers) a suffix. Otherwise returns C<undef>. Can be overloaded in
a subclass.

=cut

sub _is_number {
    my ($self, $text) = @_;
    s/^\s+//, s/\s+$// for $text;
    
    my @nums = extract_numbers $text;

    if ((@nums == 1 && $nums[0] eq $text)
        || $text =~ $ORDINAL_NUMBER_RE || $text =~ $CARDINAL_NUMBER_RE) {

        return 1;
    }

    return undef;
}

=head1 SEE ALSO

=over 4

=item * L<Lingua::EN::FindNumber>

=item * L<Lingua::EN::Words2Nums>

=item * L<Lingua::EN::Inflect::Phrase>

=back

=head1 AUTHOR

Rafael Kitover <rkitover@cpan.org>

=head1 LICENSE

Copyright 2013-2015 by Rafael Kitover

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
