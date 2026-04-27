package MARC::Field008::L10N;

use base qw(Locale::Maketext);
use strict;
use warnings;

our $VERSION = 0.01;

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Field008::L10N - Localization framework for MARC::Field008.

=head1 SYNOPSIS

 use MARC::Field008::L10N;

 my $lh = MARC::Field008::L10N->get_handle([$lang_code]);
 my $text = $lh->maketext($key);

=head1 METHODS

=head2 C<get_gandle>

 my $lh = MARC::Field008::L10N->get_handle([$lang_code]);

Get handle object.

Argument C<$lang_code> is optional, default value is language from locales.
Language code is ISO 639-1 code.

Returns instance of translation object in case that language code exists.
Returns undef in case that language code doesn't exists.

=head2 C<run>

 my $text = $lh->maketext($key);

Return translation of text for text defined as C<$key>.

Returns string.

=head1 EXAMPLE

=for comment filename=print_lang_text.pl

 use strict;
 use warnings;

 use MARC::Field008::L10N;
 use Unicode::UTF8 qw(encode_utf8);

 if (@ARGV < 1) {
         print STDERR "Usage: $0 lang_code\n";
         exit 1;
 }
 my $lang_code = $ARGV[0];

 my $lh = MARC::Field008::L10N->get_handle($lang_code);

 print encode_utf8($lh->maketext('Date entered on file'))."\n";

 # Output for cs.
 # Datum uložení do souboru

 # Output for en.
 # Date entered on file

=head1 DEPENDENCIES

L<Locale::Maketext>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/MARC-Field008-L10N>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2026 Michal Josef Špaček

BSD 2-Clause License

=head1 ACKNOWLEDGEMENTS

Development of this software has been made possible by institutional support
for the long-term strategic development of the National Library of the Czech
Republic as a research organization provided by the Ministry of Culture of
the Czech Republic (DKRVO 2024–2028), Area 11: Linked Open Data.

=head1 VERSION

0.01

=cut
