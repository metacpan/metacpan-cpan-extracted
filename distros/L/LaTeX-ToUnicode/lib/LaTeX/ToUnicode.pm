use strict;
use warnings;
package LaTeX::ToUnicode;
BEGIN {
  $LaTeX::ToUnicode::VERSION = '0.11';
}
#ABSTRACT: Convert LaTeX commands to Unicode (simplistically)


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( convert );

use utf8;
use LaTeX::ToUnicode::Tables;


sub convert {
    my ( $string, %options ) = @_;
    $string = _convert_commands( $string );
    $string = _convert_accents( $string );
    $string = _convert_german( $string ) if $options{german};
    $string = _convert_symbols( $string );
    $string = _convert_specials( $string );
    $string = _convert_ligatures( $string );
    $string = _convert_markups( $string );
    $string =~ s/{(\w*)}/$1/g;
    $string;
}

sub _convert_commands {
    my $string = shift;

    foreach my $command ( keys %LaTeX::ToUnicode::Tables::COMMANDS ) {
        $string =~ s/\{\\$command\}/$LaTeX::ToUnicode::Tables::COMMANDS{$command}/g;
        $string =~ s/\\$command(?=\s|\b)/$LaTeX::ToUnicode::Tables::COMMANDS{$command}/g;
    }

    $string;
}

sub _convert_accents {
    my $string = shift;
    $string =~ s/(\{\\(.)\{(\\?\w{1,2})\}\})/$LaTeX::ToUnicode::Tables::ACCENTS{$2}{$3} || $1/eg; # {\"{a}}
    $string =~ s/(\{\\(.)(\\?\w{1,2})\})/$LaTeX::ToUnicode::Tables::ACCENTS{$2}{$3} || $1/eg; # {\"a}
    $string =~ s/(\\(.)(\\?\w{1,2}))/$LaTeX::ToUnicode::Tables::ACCENTS{$2}{$3} || $1/eg; # \"a
    $string =~ s/(\\(.)\{(\\?\w{1,2})\})/$LaTeX::ToUnicode::Tables::ACCENTS{$2}{$3} || $1/eg; # \"{a}
    $string;
}

sub _convert_german {
    my $string = shift;

    foreach my $symbol ( keys %LaTeX::ToUnicode::Tables::GERMAN ) {
        $string =~ s/\Q$symbol\E/$LaTeX::ToUnicode::Tables::GERMAN{$symbol}/g;
    }
    $string;
}

sub _convert_symbols {
    my $string = shift;

    foreach my $symbol ( keys %LaTeX::ToUnicode::Tables::SYMBOLS ) {
        $string =~ s/{\\$symbol}/$LaTeX::ToUnicode::Tables::SYMBOLS{$symbol}/g;
        $string =~ s/\\$symbol\b/$LaTeX::ToUnicode::Tables::SYMBOLS{$symbol}/g;
    }
    $string;
}

# Replace \<specialchar> with <specialchar>.
sub _convert_specials {
    my $string = shift;
    my $specials = join( '|', @LaTeX::ToUnicode::Tables::SPECIALS );
    my $pattern = qr/\\($specials)/o;
    $string =~ s/$pattern/$1/g;
    $string =~ s/\\\$/\$/g;
    $string;
}

sub _convert_ligatures {
    my $string = shift;

    # have to convert these in order specified.
    my @ligs = @LaTeX::ToUnicode::Tables::LIGATURES;
    for (my $i = 0; $i < @ligs; $i+=2) {
        my $in = $ligs[$i];
        my $out = $ligs[$i+1];
        $string =~ s/\Q$in\E/$out/g;
    }
    $string;
}

# 
sub _convert_markups {
    my $string = shift;
    my $orig_string = $string;
    
    my $markups = join( '|', @LaTeX::ToUnicode::Tables::MARKUPS );
    
    # Remove \textMARKUP{...}, leaving just the {...}
    $string =~ s/\\text($markups)\b\s*//g;

    # Remove braces and \command in: {... \command ...}
    $string =~ s/(\{[^{}]+)\\(?:$markups)\s+([^{}]+\})/$1$2/g;
    #
    # Remove braces and \command in: {\command ...}
    $string =~ s/\{\\(?:$markups)\s+([^{}]*)\}/$1/g;
    #
    # Remove: {\command
    # Although this will leave unmatched } chars behind, there's no
    # alternative without full parsing, since the bib entry will often
    # look like: {\em {The TeX{}book}}. Also might, in principle, be
    # at the end of a line.
    $string =~ s/\{\\(?:$markups)\b\s*//g;

    # Ultimately we remove all braces in ltx2crossrefxml SanitizeText fns,
    # so the unmatched braces don't matter ... that code should be moved here.

    $string;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

LaTeX::ToUnicode - Convert LaTeX commands to Unicode

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  use LaTeX::ToUnicode qw( convert );

  convert( '{\"a}'           ) eq 'ä';  # true
  convert( '"a', german => 1 ) eq 'ä';  # true, `german' package syntax
  convert( '"a',             ) eq '"a';  # not enabled by default
  
  # more generally:
  my $latexstr;
  my $unistr = convert($latexstr);

=head1 DESCRIPTION

This module provides a method to convert LaTeX-style markups for accents etc.
into their Unicode equivalents. It translates commands for special characters
or accents into their Unicode equivalents and removes formatting commands.
It is not at all bulletproof or complete.

This module converts values from BibTeX files into plain text. If your
use case is different, YMMV.

In contrast to L<TeX::Encode>, this module does not create HTML of any
kind, including for HTML/XML metacharacters such as E<lt>, E<gt>, C<&>,
which can appear literally in the output. Entities are other handling
for these has to happen at another level, if need be.

=head1 FUNCTIONS

=head2 convert( $latex_string, %options )

Convert the text in C<$string> that contains LaTeX into a plain(er)
Unicode string. All escape sequences for accented and special characters
(e.g., \i, \"a, ...) are converted. Basic formatting commands (e.g. {\it
...}) are removed.

C<%options> allows you to enable additional translations. These keys are
recognized:

=over

=item C<german>

If this option is set, the commands introduced by the package `german'
(e.g. C<"a> eq C<ä>, note the missing backslash) are also
handled.

=back

=head1 AUTHOR

Gerhard Gossen <gerhard.gossen@googlemail.com> and
Boris Veytsman <boris@varphi.com>
L<https://github.com/borisveytsman/bibtexperllibs>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2020 by Gerhard Gossen and Boris Veytsman

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
