package Koha::Contrib::ValueBuilder::RepeatableAutocomplete::RDA;
use strict;
use warnings;
use utf8;

# ABSTRACT: Values for MARC21 based on RDA

our $VERSION = '1.002'; # VERSION

use Koha::Contrib::ValueBuilder::RepeatableAutocomplete;
use Exporter 'import';

our @EXPORT_OK = qw(creator other_agent);

sub creator {
    my $lang = lc(shift) || 'de';
    Koha::Contrib::ValueBuilder::RepeatableAutocomplete->build_builder_inline(
        {   target => '4',
            data   => _get_values( 'creator', $lang ),
        }
    );
}

sub other_agent {
    my $lang = lc(shift) || 'de';
    Koha::Contrib::ValueBuilder::RepeatableAutocomplete->build_builder_inline(
        {   target => '4',
            data   => _get_values( 'other_agent', $lang ),
        }
    );
}

my %VALUES = (
    'creator' => { # http://koha-wiki.thulb.uni-jena.de/erschliessung/katalogisierung/handbuecher/100-haupteintragung-personenname/#Beziehungskennzeichnungen_fuer_Geistige_Schoepfer
        de => [
            { label => 'ArchitektIn',                        value => 'arc' },
            { label => 'BerichterstatterIn',                 value => 'oth' },
            { label => 'BildhauerIn',                        value => 'scl' },
            { label => 'BuchkünstlerIn',                     value => 'oth' },
            { label => 'ChoreografIn',                       value => 'chr' },
            { label => 'DesignerIn',                         value => 'dsr' },
            { label => 'DrehbuchautorIn',                    value => 'aus' },
            { label => 'ErfinderIn',                         value => 'inv' },
            { label => 'FilmemacherIn',                      value => 'fmk' },
            { label => 'FotografIn',                         value => 'pht' },
            { label => 'GeistigeR SchöpferIn',               value => 'cre' },
            { label => 'InterviewerIn',                      value => 'ivr' },
            { label => 'InterviewteR',                       value => 'ive' },
            { label => 'KalligrafIn',                        value => 'cll' },
            { label => 'KartografIn',                        value => 'ctg' },
            { label => 'KomponistIn',                        value => 'cmp' },
            { label => 'KünstlerIn',                         value => 'art' },
            { label => 'LandschaftsarchitektIn',             value => 'lsa' },
            { label => 'LibrettistIn',                       value => 'lbt' },
            { label => 'Normerlassende Gebietskörperschaft', value => 'enj' },
            { label => 'Präses',                             value => 'pra' },
            { label => 'ProgrammiererIn',                    value => 'prg' },
            { label => 'RespondentIn',                       value => 'rsp' },
            { label => 'TextdichterIn',                      value => 'lyr' },
            { label => 'VerfasserIn',                        value => 'aut' },
            { label => 'ZusammenstellendeR',                 value => 'com' },
        ]
    },
    'other_agent' => { # http://koha-wiki.thulb.uni-jena.de/erschliessung/katalogisierung/handbuecher/700-nebeneintragung-personenname/#Beziehungskennzeichnungen_fuer_sonstige_Personen_Familien_und_Koerperschaften_die_mit_einer_Ressource_in_Verbindung_stehen
        de => [
            { label => 'AdressatIn',                                      value => 'rcp' },
            { label => 'AkademischeR BetreuerIn',                         value => 'dgs' },
            { label => 'AngeklagteR/Beklagte',                            value => 'dfd' },
            { label => 'ArchitektIn',                                     value => 'arc' },
            { label => 'ArrangeurIn',                                     value => 'arr' },
            { label => 'Art Director',                                    value => 'adi' },
            { label => 'AusführendeR',                                    value => 'prf' },
            { label => 'BeraterIn',                                       value => 'csl' },
            { label => 'BerichterstatterIn',                              value => 'oth' },
            { label => 'BerufungsbeklagteR/RevisionsbeklagteR',           value => 'ape' },
            { label => 'BerufungsklägerIn/RevisionsklägerIn',             value => 'apl' },
            { label => 'BildhauerIn',                                     value => 'scl' },
            { label => 'BildregisseurIn',                                 value => 'vdg' },
            { label => 'BrailleschriftprägerIn',                          value => 'brl' },
            { label => 'BuchgestalterIn',                                 value => 'bkd' },
            { label => 'BuchkünstlerIn',                                  value => 'oth' },
            { label => 'BühnenregisseurIn',                               value => 'sgd' },
            { label => 'ChoreografIn',                                    value => 'chr' },
            { label => 'CutterIn',                                        value => 'edm' },
            { label => 'DesignerIn',                                      value => 'dsr' },
            { label => 'DirigentIn',                                      value => 'cnd' },
            { label => 'DiskussionsteilnehmerIn',                         value => 'pan' },
            { label => 'DrehbuchautorIn',                                 value => 'aus' },
            { label => 'DruckerIn',                                       value => 'prt' },
            { label => 'DruckformherstellerIn',                           value => 'plt' },
            { label => 'DruckgrafikerIn',                                 value => 'prm' },
            { label => 'Durch Verfahrensvorschriften geregeltes Gericht', value => 'cou' },
            { label => 'ErfinderIn',                                      value => 'inv' },
            { label => 'ErzählerIn',                                      value => 'nrt' },
            { label => 'FernsehproduzentIn',                              value => 'tlp' },
            { label => 'FernsehregisseurIn',                              value => 'tld' },
            { label => 'FilmemacherIn',                                   value => 'fmk' },
            { label => 'FilmproduzentIn',                                 value => 'fmp' },
            { label => 'FilmregisseurIn',                                 value => 'fmd' },
            { label => 'Filmvertrieb',                                    value => 'fds' },
            { label => 'FormgießerIn',                                    value => 'cas' },
            { label => 'FotografIn',                                      value => 'pht' },
            { label => 'Gastgebende Institution',                         value => 'his' },
            { label => 'GastgeberIn',                                     value => 'hst' },
            { label => 'GefeierteR',                                      value => 'hnr' },
            { label => 'GeistigeR SchöpferIn',                            value => 'cre' },
            { label => 'Geregelte Gebietskörperschaft',                   value => 'jug' },
            { label => 'GerichtsstenografIn',                             value => 'crt' },
            { label => 'GeschichtenerzählerIn',                           value => 'stl' },
            { label => 'Grad-verleihende Institution',                    value => 'dgg' },
            { label => 'Herausgebendes Organ',                            value => 'isb' },
            { label => 'HerausgeberIn',                                   value => 'edt' },
            { label => 'HerstellerIn',                                    value => 'mfr' },
            { label => 'HörfunkproduzentIn',                              value => 'rpc' },
            { label => 'HörfunkregisseurIn',                              value => 'rdd' },
            { label => 'IllustratorIn',                                   value => 'ill' },
            { label => 'InstrumentalmusikerIn',                           value => 'itr' },
            { label => 'InterviewerIn',                                   value => 'ivr' },
            { label => 'InterviewteR',                                    value => 'ive' },
            { label => 'KalligrafIn',                                     value => 'cll' },
            { label => 'KartografIn',                                     value => 'ctg' },
            { label => 'KommentarverfasserIn',                            value => 'wac' },
            { label => 'KommentatorIn',                                   value => 'cmm' },
            { label => 'KomponistIn',                                     value => 'cmp' },
            { label => 'KostümbildnerIn',                                 value => 'cst' },
            { label => 'KünstlerIn',                                      value => 'art' },
            { label => 'KürzendeR',                                       value => 'abr' },
            { label => 'LandschaftsarchitektIn',                          value => 'lsa' },
            { label => 'LandvermesserIn',                                 value => 'srv' },
            { label => 'LehrerIn',                                        value => 'tch' },
            { label => 'Letterer',                                        value => 'oth' },
            { label => 'LibrettistIn',                                    value => 'lbt' },
            { label => 'LichtdruckerIn',                                  value => 'clt' },
            { label => 'LichtgestalterIn',                                value => 'lgd' },
            { label => 'LithografIn',                                     value => 'ltg' },
            { label => 'Medium',                                          value => 'med' },
            {   label => 'Mitglied eines Ausschusses, der akademische Grade vergibt',
                value => 'oth'
            },
            { label => 'MitwirkendeR',                              value => 'ctb' },
            { label => 'ModeratorIn',                               value => 'mod' },
            { label => 'MusikalischeR LeiterIn',                    value => 'msd' },
            { label => 'Normerlassende Gebietskörperschaft',        value => 'enj' },
            { label => 'On-screen PräsentatorIn',                   value => 'osp' },
            { label => 'PapiermacherIn',                            value => 'ppm' },
            { label => 'PräsentatorIn',                             value => 'pre' },
            { label => 'Präses',                                    value => 'pra' },
            { label => 'Produktionsfirma',                          value => 'prn' },
            { label => 'ProduzentIn',                               value => 'pro' },
            { label => 'ProgrammiererIn',                           value => 'prg' },
            { label => 'ProtokollantIn',                            value => 'mtk' },
            { label => 'PuppenspielerIn',                           value => 'ppt' },
            { label => 'RadiererIn',                                value => 'etr' },
            { label => 'RednerIn',                                  value => 'spk' },
            { label => 'RegisseurIn',                               value => 'drt' },
            { label => 'RespondentIn',                              value => 'rsp' },
            { label => 'RichterIn',                                 value => 'jud' },
            { label => 'SängerIn',                                  value => 'sng' },
            { label => 'SchauspielerIn',                            value => 'act' },
            { label => 'Sender',                                    value => 'brd' },
            { label => 'Sonstige Person, Familie und Körperschaft', value => 'oth' },
            { label => 'Special-effects-Provider',                  value => 'oth' },
            { label => 'SponsorIn',                                 value => 'spn' },
            { label => 'StecherIn',                                 value => 'egr' },
            { label => 'SynchronsprecherIn',                        value => 'vac' },
            { label => 'SzenenbildnerIn',                           value => 'prs' },
            { label => 'TänzerIn',                                  value => 'dnc' },
            { label => 'TechnischeR ZeichnerIn',                    value => 'drn' },
            { label => 'TextdichterIn',                             value => 'lyr' },
            { label => 'TongestalterIn',                            value => 'sds' },
            { label => 'ToningenieurIn',                            value => 'rce' },
            { label => 'TonmeisterIn',                              value => 'rcd' },
            { label => 'TranskribiererIn',                          value => 'trc' },
            { label => 'TrickfilmzeichnerIn',                       value => 'anm' },
            { label => 'ÜbersetzerIn',                              value => 'trl' },
            { label => 'VeranstalterIn',                            value => 'orm' },
            { label => 'VerfasserIn',                               value => 'aut' },
            { label => 'VerfasserIn einer Einleitung',              value => 'win' },
            { label => 'VerfasserIn eines Geleitwortes',            value => 'aui' },
            { label => 'VerfasserIn eines Nachworts',               value => 'aft' },
            { label => 'VerfasserIn eines Postscriptums',           value => 'oth' },
            { label => 'VerfasserIn eines Vorworts',                value => 'wpr' },
            { label => 'VerfasserIn von ergänzendem Text',          value => 'est' },
            { label => 'VerfasserIn von zusätzlichen Lyrics',       value => 'wal' },
            { label => 'VerfasserIn von Zusatztexten',              value => 'wat' },
            { label => 'Verlag',                                    value => 'pbl' },
            { label => 'VertragspartnerIn',                         value => 'ctr' },
            { label => 'Vertrieb',                                  value => 'dst' },
            { label => 'Visual-effects-Provider',                   value => 'oth' },
            { label => 'WidmendeR',                                 value => 'dto' },
            { label => 'WidmungsempfängerIn',                       value => 'dte' },
            { label => 'ZivilklägerIn',                             value => 'ptf' },
            { label => 'ZusammenstellendeR',                        value => 'com' },
        ]
    }
);

sub _get_values {
    my ( $field, $lang ) = @_;
    return $VALUES{$field}->{$lang};
}

q{ listening to: Fatima Spar & JOV: The Voice Within };

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ValueBuilder::RepeatableAutocomplete::RDA - Values for MARC21 based on RDA

=head1 VERSION

version 1.002

=head1 SYNOPSIS

  # value_builder_autocomplete_100.pl
  use Koha::Contrib::ValueBuilder::RepeatableAutocomplete::RDA qw(creator);
  return creator('de');

=head1 DESCRIPTION

MARC21 field 100, 110, 111 and 700, 710 autocompletes based on RDA data for
C<Creator> and C<Other agent associated with a work>.

=head2 Usage in Koha

=over

=item * Copy L<example/autocomplete_creator.pl> and
L<example/autocomplete_other_agent.pl> to
F</usr/share/koha/intranet/cgi-bin/cataloguing/value_builder>

=item * In Koha, got to "Administration" - "MARC Frameworks", select
the framework, select field 100 (or 700), go to "edit subfields",
select subfield "e", and select C<autocomplete_creator.pl>
(or C<autocomplete_other_agent.pl>) for "Plugin"

=item When cataloguing, enter subfield C<e> and start typing. After 3
letters, an autocomplete-selectbox will show up, where you can select
an entry. The short code will be stored in subfield C<4>, the long
value in subfield C<e>.

=back

=head2 Data source

We got the (german) values from

=over

=item * L<http://koha-wiki.thulb.uni-jena.de/erschliessung/katalogisierung/handbuecher/100-haupteintragung-personenname/#Beziehungskennzeichnungen_fuer_Geistige_Schoepfer>

=item * L<http://koha-wiki.thulb.uni-jena.de/erschliessung/katalogisierung/handbuecher/700-nebeneintragung-personenname/#Beziehungskennzeichnungen_fuer_sonstige_Personen_Familien_und_Koerperschaften_die_mit_einer_Ressource_in_Verbindung_stehen>

=back

=head1 AUTHORS

=over 4

=item *

Thomas Klausner <domm@plix.at>

=item *

Mark Hofstetter <cpan@trust-box.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
