use strict;
use warnings;
package Lingua::Metadata;

use LWP::Simple;

our $VERSION = '0.005'; # VERSION

# ABSTRACT: Returns information about languages.

use constant SERVICE_URL => 'http://w2c.martin.majlis.cz/language/';

our %cache_iso = ();
our %cache_metadata = ();


sub get_iso
{
    my $label = shift;

    if ( ! defined($label) ) {
        return;
    }

    if ( ! defined($cache_iso{$label}) ) {
        my $url = SERVICE_URL . '?alias=' . $label;
        $cache_iso{$label} = get($url);
    }

    return $cache_iso{$label};
}


sub get_language_metadata
{
    my $language = shift;

    my %result = ();
    my $iso = get_iso($language);

    if ( ! defined($iso) ) {
        return $iso;
    } elsif ( $iso eq '' ) {
        return \%result;
    }

    my $url = SERVICE_URL . '?action=GET&format=TXT&lang=' . $iso;

    if ( ! defined($cache_metadata{$iso}) ) {
        my $content = get($url);

        if ( $content ) {
            for my $line ( split(/\n/, $content) ) {
                chomp $line;
                my @parts = split(/\t/, $line);
                $result{$parts[1]} = $parts[2];
            }
        }
        $cache_metadata{$iso} = \%result;
    }

    return $cache_metadata{$iso};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Metadata - Returns information about languages.

=head1 VERSION

version 0.005

=head1 SYNOPSIS

This package queries L<Language Metadata Service|http://w2c.martin.majlis.cz/language/>
to retrieve various information about languages.

=head1 METHODS

=head2 get_iso ($langage)

Returns an ISO 639-3 code for language.

=head4 Returns $iso

=over 4

=item * It returns undef, if the service is down or undef is passed as an argument.

=item * It returns empty string, if the language couldn't be converted.

=item * It returns ISO 639-3 otherwise.

=back

=head2 get_language_metadata ($langage)

Returns all metadata for specified language.

=head4 Examples

  my $ces_metadata = Lingua::Metadata::get_language_metadata("ces");
  my $cs_metadata = Lingua::Metadata::get_language_metadata("cs");
  my $czech_metadata = Lingua::Metadata::get_language_metadata("czech");
  my $cestina_metadata = Lingua::Metadata::get_language_metadata("čeština");


  ( $ces_metadata{'iso 639-3'} eq $cs_metadata{'iso 639-3'} and
    $cs_metadata{'iso 639-3'} eq $czech_metadata{'iso 639-3'} and
    $czech_metadata{'iso 639-3'} eq $cestina_metadata{'iso 639-3'} and
    $cestina_metadata{'iso 639-3'} eq 'ces' ) or die;

=head4 Returns \%metadata = { key1 => value1, ... }

=over 4

=item * It returns undef, if the service is down or undef is passed as an argument.

=item * It returns reference to the hash containing all metadata.

=back

=head1 AUTHOR

Martin Majlis <martin@majlis.cz>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Martin Majlis.

This is free software, licensed under:

  The (three-clause) BSD License

=head1 AUTHOR

Martin Majlis <martin@majlis.cz>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Martin Majlis.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
