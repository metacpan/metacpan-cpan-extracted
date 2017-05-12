package Lingua::Conlang::Numbers;

use 5.008_001;
use strict;
use warnings;
use Lingua::EO::Numbers       qw( :all );
use Lingua::JBO::Numbers      qw( :all );
use Lingua::TLH::Numbers      qw( :all );
use Lingua::TokiPona::Numbers qw( :all );

use base qw( Exporter );
our @EXPORT_OK = qw( num2conlang num2conlang_ordinal num2conlang_languages );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $VERSION = '0.04';

my @languages = qw< eo jbo tlh tokipona >;
my %aliases = (
    esperanto => 'eo',
    klingon   => 'tlh',
    lojban    => 'jbo',
);

sub num2conlang           { _num2conlang(q{},         @_) }
sub num2conlang_ordinal   { _num2conlang(q{_ordinal}, @_) }
sub num2conlang_languages { @languages                    }

sub _num2conlang {
    # @_ will be used with goto
    my ($suffix, $language, $number) = (shift, shift, @_);

    return unless $language;
    $language = lc $language;
    $language =~ tr{ _}{}d;

    if (grep { $_ eq $language } @languages) {
        goto &{ 'num2' . $language . $suffix };
    }
    elsif ( exists $aliases{$language} ) {
        goto &{ 'num2' . $aliases{$language} . $suffix };
    }
    else {
        return;
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Lingua::Conlang::Numbers - Convert numbers into words in various constructed languages

=head1 VERSION

This document describes Lingua::Conlang::Numbers version 0.04.

=head1 SYNOPSIS

    use Lingua::Conlang::Numbers qw(
        num2conlang num2conlang_ordinal num2conlang_languages
    );

=head1 WARNING

The interface for the C<Lingua::Conlang::Numbers> module may change in the
future, but will likely remain the same for the individual language modules
included in the C<Lingua-Conlang-Numbers> distribution.

=head1 DESCRIPTION

The C<Lingua-Conlang-Numbers> distribution includes modules for converting
numbers into words in various constructed languages, also known as planned
languages or artificial languages.

The C<Lingua::Conlang::Numbers> module provides a common interface to all of
the included modules without the need to C<use> each one.

=head1 FUNCTIONS

The following functions are provided but are not exported by default.

=over 4

=item num2conlang STRING, EXPR

If STRING is a supported language, EXPR is passed to the C<num2xx> function
from the corresponding module, which will handle the return value.

    num2conlang(eo => 3.141593);

=item num2conlang_ordinal STRING, EXPR

If STRING is a supported language, EXPR is passed to the C<num2xx_ordinal>
function from the corresponding module, which will handle the return value.

    num2conlang_ordinal(jbo => 5);

=item num2conlang_languages

Returns the list of supported language strings in list context and the number
of supported languages in scalar context.

=back

The STRING argument for C<num2conlang> or C<num2conlang_ordinal> may be the
case-insensitive language name with optional underscores (e.g., TokiPona,
tokipona, toki_pona) or the two-letter ISO 639-1 codes and three-letter ISO
639-3 codes when available (e.g., eo, epo, EO, EPO).

The C<:all> tag can be used to import all functions.

    use Lingua::Conlang::Numbers qw( :all );

=head1 MODULES

See the individual language modules for details on supported numbers and
provided output.

=over 4

=item * L<Lingua::EO::Numbers> - Esperanto (eo, epo)

=item * L<Lingua::JBO::Numbers> - Lojban (jbo)

=item * L<Lingua::TLH::Numbers> - Klingon (tlh)

=item * L<Lingua::TokiPona::Numbers> - Toki Pona

=back

=head1 TODO

Add support for additional constructed languages including, but not limited
to: Ido, Interlingua, Latino sine Flexione, Loglan, Na'vi, Occidental, Quenya,
and Volapük.

=head1 SEE ALSO

L<utf8>, L<Lingua::Any::Numbers>

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 ACKNOWLEDGEMENTS

Sean M. Burke created the current interface to L<Lingua::EN::Numbers>, which
the included modules are based on.

=head1 COPYRIGHT AND LICENSE

Copyright 2009, 2010 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
