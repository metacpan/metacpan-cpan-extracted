package Encode::Safename;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

use Parse::Lex;

use base qw(Encode::Encoding);

use constant {
    COND_ENCODE => 'ENCODE',
    COND_DECODE => 'DECODE',
};

__PACKAGE__->Define(qw(safename));

=head1 NAME

Encode::Safename - An encoding for safe filenames.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

An encoding to encode filenames to safe filenames, that is filenames
that are valid on all filesystems.

    use Encode qw(decode encode);
    use Encode::Safename;

    $encoded = encode('safename', 'Foo Bar Baz.txt');
    # $encoded is now '{f}oo_{b}ar_{b}az.txt'
    $decoded = decode('safename', $encoded);
    # $decoded is now 'Foo Bar Baz.txt'

=head1 DESCRIPTION

A filename is encoded as follows:

=over 4

=item *

A range of uppercase characters is changed to lowercase characters,
and put between braces.

    'F'   -> '{F}'
    'FOO' -> '{foo}'

=item *

A range of spaces is changed to underscores.

    ' '   -> '_'
    '   ' -> '___'

=item *

A range of safe characters (characters that are valid on all filesystems,
excluding braces, parentheses, and underscores) is left unchanged.

    'f'   -> 'f'
    'foo' -> 'foo'

=item *

All other characters are changed to their Unicode codepoint in hexadecimal
notation, and put between parentheses.

    ':'  -> '(3a)'
    ':?' -> '(3a)(3f)'

=back

Combined, this gives the following:

    'FOO: Bar Baz.txt' -> '{foo}(3a)_{b}ar_{b}az.txt'

=head1 METHODS

=head2 _process LEXER, STRING

Applies LEXER to STRING.  Returns both the processed and unprocessed
parts.

For internal use only!

=cut

Parse::Lex->inclusive('ENCODE', 'DECODE');
my $_lexer = Parse::Lex->new(
    # uppercase characters
    'ENCODE:E_UPPER' => (
        '[A-Z]+',
        sub {
            return '{' . lc $_[1] . '}';
        },
    ),
    'DECODE:D_UPPER' => (
        '\{[a-z]+\}',
        sub {
            my $text = $_[1];
            $text =~ s/\{(.*)\}/$1/;
            return uc $text;
        },
    ),

    # spaces
    'ENCODE:E_SPACES' => (
        ' +',
        sub {
            my $text = $_[1];
            $text =~ tr/ /_/;
            return $text;
        },
    ),
    'DECODE:D_SPACES' => (
        '_+',
        sub {
            my $text = $_[1];
            $text =~ tr/_/ /;
            return $text;
        },
    ),

    # safe characters
    'SAFE' => '[a-z0-9\-+!\$%&\'@~#.,^]+',

    # other characters
    'ENCODE:E_OTHER' => (
        '.',
        sub {
            return '(' . sprintf('%x', unpack('U', $_[1])) . ')';
        },
    ),
    'DECODE:D_OTHER' => (
        '\([0-9a-f]+\)',
        sub {
            my $text = $_[1];
            $text =~ s/\((.*)\)/$1/;
            return pack('U', oct('0x' . $text));
        },
    ),
);
$_lexer->skip('');

sub _process {
    # process arguments
    my ($self, $string, $condition) = @_;

    # initialize the lexer and the processed buffer
    $_lexer->from($string);
    $_lexer->start($condition);
    my $processed = '';

    while (1) {
        # infinite loop!

        # get the next token
        my $token = $_lexer->next;

        if ($_lexer->eoi || (! $token)) {
            # no more tokens; jump out of the loop
            last;
        }
        else {
            # add the token's text to the processed buffer
            $processed .= $token->text;
        }
    }

    # return the both the processed and unprocessed parts
    my $unprocessed = substr $string, $_lexer->offset;
    $_lexer->start('INITIAL');
    return ($processed, $unprocessed);
}

=head2 decode STRING, CHECK

Decoder for decoding safename.  See module L<Encode::Encoding>.

=cut

sub decode {
    # process arguments
    my ($self, $string, $check) = @_;

    # apply the lexer for decoding to the string and return the result
    my ($processed, $unprocessed) = $self->_process($string, COND_DECODE);
    $_[1] = $unprocessed if $check;
    return $processed;
}

=head2 encode STRING, CHECK

Encoder for encoding safename.  See module L<Encode::Encoding>.

=cut

sub encode {
    # process arguments
    my ($self, $string, $check) = @_;

    # apply the lexer for encoding to the string and return the result
    my ($processed, $unprocessed) = $self->_process($string, COND_ENCODE);
    $_[1] = $unprocessed if $check;
    return $processed;
}

=head1 AUTHOR

Bert Vanderbauwhede, C<< <batlock666 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-encode-safename
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Encode-Safename>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Encode::Safename

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Encode-Safename>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Encode-Safename>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Encode-Safename>

=item * Search CPAN

L<http://search.cpan.org/dist/Encode-Safename/>

=back

=head1 ACKNOWLEDGEMENTS

Based on the module safefilename from Torsten Bronger's Bobcat project
(L<https://launchpad.net/bobcat>).

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Bert Vanderbauwhede.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

See L<http://www.gnu.org/licenses/> for more information.

=cut

1; # End of Encode::Safename
