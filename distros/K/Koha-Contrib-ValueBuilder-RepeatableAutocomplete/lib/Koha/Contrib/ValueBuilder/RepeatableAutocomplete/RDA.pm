package Koha::Contrib::ValueBuilder::RepeatableAutocomplete::RDA;
use strict;
use warnings;
use utf8;

# ABSTRACT: Values for MARC21 based on RDA

our $VERSION = '1.006'; # VERSION

use Koha::Contrib::ValueBuilder::RepeatableAutocomplete;
use Exporter 'import';

our @EXPORT_OK = qw(creator other_agent);

my $CREATORS;
my $OTHER_AGENTS;
my %VALUES = get_values();

sub creator {
    my $lang = lc(shift) || 'de';

    unless ($CREATORS) {
        my @list;
        for my $type (qw(creator other_agent)) {
            for my $data (@{$VALUES{$lang}->{$type}}) {
                my $label = $data->{label};
                $label.= ' (Geistige*r Schöpfer*in)' if $type eq 'creator';
                my $item = { value_for_target => $data->{value}, value_for_input => $data->{label}, label => $label };
                push(@list, $item);
            }
        }
        $CREATORS = \@list;
    }

    Koha::Contrib::ValueBuilder::RepeatableAutocomplete->build_builder_inline(
        {   target => '4',
            data   => $CREATORS,
        }
    );
}

sub other_agent {
    my $lang = lc(shift) || 'de';

    unless ($OTHER_AGENTS) {
        my @list;
        for my $type (qw(creator other_agent)) {
            for my $data (@{$VALUES{$lang}->{$type}}) {
                my $item = { value_for_target => $data->{value}, value_for_input => $data->{label}, label => $data->{label} };
                push(@list, $item);
            }
        }
        $OTHER_AGENTS = \@list;
    }

    Koha::Contrib::ValueBuilder::RepeatableAutocomplete->build_builder_inline(
        {   target => '4',
            data   => $OTHER_AGENTS
        }
    );
}

# type: creator
# https://koha-wiki.thulb.uni-jena.de/erschliessung/katalogisierung/handbuecher/100-haupteintragung-personenname/#Beziehungskennzeichnungen_fuer_Geistige_Schoepfer
# https://wiki.dnb.de/download/attachments/106042227/AH-017.pdf

# type: other_agent
# https://koha-wiki.thulb.uni-jena.de/erschliessung/katalogisierung/handbuecher/700-nebeneintragung-personenname/#Beziehungskennzeichnungen_fuer_sonstige_Personen_Familien_und_Koerperschaften_die_mit_einer_Ressource_in_Verbindung_stehen
# https://wiki.dnb.de/download/attachments/106042227/AH-017.pdf

sub get_values {
    return (
    de => {
        'creator' => [
            { label => 'AquarellistIn',                                             value => 'oth' },
            { label => 'ArchitektIn',                                               value => 'arc' },
            { label => 'Archiv',                                                    value => 'oth' },
            { label => 'BaumeisterIn',                                              value => 'oth' },
            { label => 'BerichterstatterIn',                                        value => 'cre' },
            { label => 'BestandsbildnerIn',                                         value => 'oth' },
            { label => 'Bildagentur',                                               value => 'oth' },
            { label => 'BildhauerIn',                                               value => 'scl' },
            { label => 'BuchhändlerIn',                                             value => 'oth' },
            { label => 'BuchkünstlerIn',                                            value => 'art' },
            { label => 'BühnenbildnerIn',                                           value => 'oth' },
            { label => 'ChoreografIn',                                              value => 'chr' },
            { label => 'Corresponding author',                                      value => 'oth' },
            { label => 'DesignerIn',                                                value => 'dsr' },
            { label => 'DrehbuchautorIn',                                           value => 'aus' },
            { label => 'EmailmalerIn',                                              value => 'oth' },
            { label => 'EntwerferIn',                                               value => 'oth' },
            { label => 'ErfinderIn',                                                value => 'inv' },
            { label => 'FilmemacherIn',                                             value => 'fmk' },
            { label => 'FormschneiderIn',                                           value => 'oth' },
            { label => 'Fotoatelier',                                               value => 'oth' },
            { label => 'FotografIn',                                                value => 'pht' },
            { label => 'FotohändlerIn',                                             value => 'oth' },
            { label => 'GalanteriewarenherstellerIn',                               value => 'oth' },
            { label => 'GartenarchitektIn',                                         value => 'oth' },
            { label => 'GeistigeR SchöpferIn',                                      value => 'cre' },
            { label => 'GemmenschneiderIn',                                         value => 'oth' },
            { label => 'GesprächsteilnehmerIn',                                     value => 'oth' },
            { label => 'GießerIn',                                                  value => 'oth' },
            { label => 'GlasmalerIn',                                               value => 'oth' },
            { label => 'GoldschmiedIn',                                             value => 'oth' },
            { label => 'GrafikerIn',                                                value => 'oth' },
            { label => 'GraveurIn',                                                 value => 'oth' },
            { label => 'HolzbildhauerIn',                                           value => 'oth' },
            { label => 'HolzschneiderIn',                                           value => 'oth' },
            { label => 'InterviewerIn',                                             value => 'ivr' },
            { label => 'InterviewteR',                                              value => 'ive' },
            { label => 'KalligrafIn',                                               value => 'cll' },
            { label => 'KarikaturistIn',                                            value => 'oth' },
            { label => 'KartografIn',                                               value => 'ctg' },
            { label => 'KeramikerIn',                                               value => 'oth' },
            { label => 'KomponistIn',                                               value => 'cmp' },
            { label => 'Klischeeanstalt',                                           value => 'oth' },
            { label => 'KorrespondenzpartnerIn',                                    value => 'oth' },
            { label => 'KunsthandwerkerIn',                                         value => 'oth' },
            { label => 'KunsthändlerIn',                                            value => 'oth' },
            { label => 'KupferstecherIn',                                           value => 'oth' },
            { label => 'KünstlerIn',                                                value => 'art' },
            { label => 'KünstlerischeR LeiterIn',                                   value => 'oth' },
            { label => 'LandschaftsarchitektIn',                                    value => 'lsa' },
            { label => 'LaudatorIn',                                                value => 'oth' },
            { label => 'LayouterIn',                                                value => 'oth' },
            { label => 'LibrettistIn',                                              value => 'lbt' },
            { label => 'LinolschneiderIn',                                          value => 'oth' },
            { label => 'Lithografische Anstalt',                                    value => 'oth' },
            { label => 'MalerIn',                                                   value => 'oth' },
            { label => 'MedailleurIn',                                              value => 'oth' },
            { label => 'MiniaturmalerIn',                                           value => 'oth' },
            { label => 'Modeatelier',                                               value => 'oth' },
            { label => 'ModelleurIn',                                               value => 'oth' },
            { label => 'ModeschöpferIn',                                            value => 'ctb' },
            { label => 'Nachrichtenagentur',                                        value => 'oth' },
            { label => 'Normerlassende Gebietskörperschaft',                        value => 'enj' },
            { label => 'ProgrammiererIn',                                           value => 'prg' },
            { label => 'Präses',                                                    value => 'pra' },
            { label => 'PuppenkünstlerIn',                                          value => 'oth' },
            { label => 'Remix Artist',                                              value => 'cre' },
            { label => 'RespondentIn',                                              value => 'rsp' },
            { label => 'RezensentIn',                                               value => 'oth' },
            { label => 'SchabkünstlerIn',                                           value => 'oth' },
            { label => 'SchneiderIn',                                               value => 'oth' },
            { label => 'SchriftkünstlerIn',                                         value => 'oth' },
            { label => 'SchriftsetzerIn',                                           value => 'oth' },
            { label => 'SilhouettenkünstlerIn',                                     value => 'oth' },
            { label => 'StahlstecherIn',                                            value => 'oth' },
            { label => 'SteinmetzIn',                                               value => 'oth' },
            { label => 'StickerIn',                                                 value => 'oth' },
            { label => 'TextdichterIn',                                             value => 'lyr' },
            { label => 'TextilkünstlerIn',                                          value => 'oth' },
            { label => 'TischlerIn',                                                value => 'oth' },
            { label => 'UhrmacherIn',                                               value => 'oth' },
            { label => 'UrheberIn',                                                 value => 'oth' },
            { label => 'VerfasserIn',                                               value => 'aut' },
            { label => 'VortragendeR',                                              value => 'oth' },
            { label => 'WachsbossiererIn',                                          value => 'oth' },
            { label => 'Werbeagentur',                                              value => 'oth' },
            { label => 'Werkstatt',                                                 value => 'oth' },
            { label => 'XylografIn',                                                value => 'oth' },
            { label => 'Xylografische Anstalt',                                     value => 'oth' },
            { label => 'ZeichnerIn',                                                value => 'oth' },
            { label => 'ZusammenstellendeR',                                        value => 'com' },
        ],
        'other_agent'=> [
            { label => 'Abgebildet',                                                value => 'oth' },
            { label => 'AbsenderIn',                                                value => 'oth' },
            { label => 'AdressatIn',                                                value => 'rcp' },
            { label => 'AkademischeR BetreuerIn',                                   value => 'dgs' },
            { label => 'AktenbildnerIn',                                            value => 'oth' },
            { label => 'AngeklagteR/Beklagte',                                      value => 'dfd' },
            { label => 'annotierende Person',                                       value => 'ann' },
            { label => 'ArrangeurIn',                                               value => 'arr' },
            { label => 'Art Director',                                              value => 'adi' },
            { label => 'AssistentIn',                                               value => 'oth' },
            { label => 'AuftraggeberIn',                                            value => 'pat' },
            { label => 'ausfertigende Institution',                                 value => 'oth' },
            { label => 'AusführendeR',                                              value => 'prf' },
            { label => 'BearbeiterIn',                                              value => 'oth' },
            { label => 'BegründerIn eines Werks',                                   value => 'oth' },
            { label => 'Behandelt',                                                 value => 'oth' },
            { label => 'BeiträgerIn',                                               value => 'oth' },
            { label => 'BeraterIn',                                                 value => 'csl' },
            { label => 'BerufungsbeklagteR/RevisionsbeklagteR',                     value => 'ape' },
            { label => 'BerufungsklägerIn/RevisionsklägerIn',                       value => 'apl' },
            { label => 'beschriftende Person',                                      value => 'ins' },
            { label => 'Beteiligt',                                                 value => 'oth' },
            { label => 'BildregisseurIn',                                           value => 'vdg' },
            { label => 'BrailleschriftprägerIn',                                    value => 'brl' },
            { label => 'BuchbinderIn',                                              value => 'bnd' },
            { label => 'BuchgestalterIn',                                           value => 'bkd' },
            { label => 'BühnenregisseurIn',                                         value => 'sgd' },
            { label => 'Casting Director',                                          value => 'oth' },
            { label => 'ChefredakteurIn',                                           value => 'pbd' },
            { label => 'ChorleiterIn',                                              value => 'cnd' },
            { label => 'ColoristIn',                                                value => 'clr' },
            { label => 'CutterIn',                                                  value => 'edm' },
            { label => 'DJ/DJane',                                                  value => 'ctb' },
            { label => 'DirigentIn',                                                value => 'cnd' },
            { label => 'DiskussionsteilnehmerIn',                                   value => 'pan' },
            { label => 'Dokumentiert',                                              value => 'oth' },
            { label => 'DonatorIn',                                                 value => 'oth' },
            { label => 'DramaturgIn',                                               value => 'oth' },
            { label => 'DruckerIn',                                                 value => 'prt' },
            { label => 'DruckformherstellerIn',                                     value => 'plt' },
            { label => 'DruckgrafikerIn',                                           value => 'prm' },
            { label => 'Durch Verfahrensvorschriften geregeltes Gericht',           value => 'cou' },
            { label => '(gegenwärtigeR) EigentümerIn',                              value => 'own' },
            { label => 'Erwähnt',                                                   value => 'oth' },
            { label => 'ErzählerIn',                                                value => 'nrt' },
            { label => 'FernsehproduzentIn',                                        value => 'tlp' },
            { label => 'FernsehregisseurIn',                                        value => 'tld' },
            { label => 'FestrednerIn',                                              value => 'oth' },
            { label => 'FilmproduzentIn',                                           value => 'fmp' },
            { label => 'FilmregisseurIn',                                           value => 'fmd' },
            { label => 'Filmvertrieb',                                              value => 'fds' },
            { label => 'FormgießerIn',                                              value => 'cas' },
            { label => 'ForscherIn',                                                value => 'res' },
            { label => 'frühereR EigentümerIn',                                     value => 'fmo' },
            { label => 'Gastgebende Institution',                                   value => 'his' },
            { label => 'GastgeberIn',                                               value => 'hst' },
            { label => 'Geehrt',                                                    value => 'oth' },
            { label => 'GefeierteR',                                                value => 'hnr' },
            { label => 'Geregelte Gebietskörperschaft',                             value => 'jug' },
            { label => 'GerichtsstenografIn',                                       value => 'crt' },
            { label => 'Gesammelt',                                                 value => 'oth' },
            { label => 'GeschichtenerzählerIn',                                     value => 'stl' },
            { label => 'Grad-verleihende Institution',                              value => 'dgg' },
            { label => 'GraduierteR',                                               value => 'oth' },
            { label => 'Herausgebendes Organ',                                      value => 'isb' },
            { label => 'HerausgeberIn',                                             value => 'edt' },
            { label => 'HerstellerIn',                                              value => 'mfr' },
            { label => 'HörfunkproduzentIn',                                        value => 'rpc' },
            { label => 'HörfunkregisseurIn',                                        value => 'rdd' },
            { label => 'IlluminatorIn',                                             value => 'ilu' },
            { label => 'IllustratorIn',                                             value => 'ill' },
            { label => 'InhaberIn',                                                 value => 'oth' },
            { label => 'InstrumentalmusikerIn',                                     value => 'itr' },
            { label => 'KalligrafIn',                                               value => 'cll' },
            { label => 'KommentarverfasserIn',                                      value => 'wac' },
            { label => 'KommentatorIn',                                             value => 'cmm' },
            { label => 'KorrektorIn',                                               value => 'oth' },
            { label => 'KostümbildnerIn',                                           value => 'cst' },
            { label => 'KuratorIn',                                                 value => 'cur' },
            { label => 'KürzendeR',                                                 value => 'abr' },
            { label => 'LandvermesserIn',                                           value => 'srv' },
            { label => 'LehrerIn',                                                  value => 'tch' },
            { label => 'LeihgeberIn',                                               value => 'dpt' },
            { label => 'LeihnehmerIn',                                              value => 'oth' },
            { label => 'LektorIn',                                                  value => 'oth' },
            { label => 'Letterer',                                                  value => 'ill' },
            { label => 'LichtdruckerIn',                                            value => 'clt' },
            { label => 'LichtgestalterIn',                                          value => 'lgd' },
            { label => 'LithografIn',                                               value => 'ltg' },
            { label => 'MaskenbildnerIn',                                           value => 'ctb' },
            { label => 'Medium',                                                    value => 'med' },
            { label => 'MischtontechnikerIn',                                       value => 'ctb' },
            { label => 'MitarbeiterIn',                                             value => 'oth' },
            { label => 'Mitglied eines Ausschusses, der akademische Grade vergibt', value => 'oth' },
            { label => 'Mitglied eines Graduierungsausschusses',                    value => 'oth' },
            { label => 'MitunterzeichnerIn',                                        value => 'oth' },
            { label => 'MitwirkendeR',                                              value => 'ctb' },
            { label => 'ModeratorIn',                                               value => 'mod' },
            { label => 'Musik-ProgrammiererIn',                                     value => 'ctb' },
            { label => 'MusikalischeR LeiterIn',                                    value => 'msd' },
            { label => 'On-Screen-TeilnehmerIn',                                    value => 'ctb' },
            { label => 'On-screen PräsentatorIn',                                   value => 'osp' },
            { label => 'OrchesterleiterIn',                                         value => 'cnd' },
            { label => 'OrganisatorIn',                                             value => 'oth' },
            { label => 'PapiermacherIn',                                            value => 'ppm' },
            { label => 'Produktionsfirma',                                          value => 'prn' },
            { label => 'ProduzentIn einer Tonaufnahme',                             value => 'pro' },
            { label => 'ProduzentIn',                                               value => 'pro' },
            { label => 'ProgrammgestalterIn',                                       value => 'oth' },
            { label => 'ProtokollantIn',                                            value => 'mtk' },
            { label => 'PräsentatorIn',                                             value => 'pre' },
            { label => 'PuppenspielerIn',                                           value => 'ppt' },
            { label => 'RadiererIn',                                                value => 'etr' },
            { label => 'RechnungslegerIn',                                          value => 'oth' },
            { label => 'RedakteurIn',                                               value => 'oth' },
            { label => 'RednerIn',                                                  value => 'spk' },
            { label => 'RegieassistentIn',                                          value => 'oth' },
            { label => 'RegisseurIn',                                               value => 'drt' },
            { label => 'RegistrarIn',                                               value => 'cor' },
            { label => 'RichterIn',                                                 value => 'jud' },
            { label => 'SammlerIn',                                                 value => 'col' },
            { label => 'SchauspielerIn',                                            value => 'act' },
            { label => 'SchreiberIn',                                               value => 'oth' },
            { label => 'Sender',                                                    value => 'brd' },
            { label => 'SoftwareentwicklerIn',                                      value => 'ctb' },
            { label => 'Sonstige Person, Familie und Körperschaft',                 value => 'oth' },
            { label => 'Special-effects-ProviderIn',                                value => 'ctb' },
            { label => 'SponsorIn',                                                 value => 'spn' },
            { label => 'SprecherIn',                                                value => 'oth' },
            { label => 'StecherIn',                                                 value => 'egr' },
            { label => 'StifterIn',                                                 value => 'dnr' },
            { label => 'SynchronregisseurIn',                                       value => 'ctb' },
            { label => 'SynchronsprecherIn',                                        value => 'vac' },
            { label => 'SzenenbildnerIn',                                           value => 'prs' },
            { label => 'SängerIn',                                                  value => 'sng' },
            { label => 'TechnikerIn',                                               value => 'oth' },
            { label => 'TechnischeR ZeichnerIn',                                    value => 'drn' },
            { label => 'TongestalterIn',                                            value => 'sds' },
            { label => 'ToningenieurIn',                                            value => 'rce' },
            { label => 'TonmeisterIn',                                              value => 'rcd' },
            { label => 'TonregisseurIn',                                            value => 'oth' },
            { label => 'TontechnikerIn',                                            value => 'ctb' },
            { label => 'TranskribiererIn',                                          value => 'trc' },
            { label => 'TrickfilmzeichnerIn',                                       value => 'anm' },
            { label => 'TänzerIn',                                                  value => 'dnc' },
            { label => 'ÜbersetzerIn',                                              value => 'trl' },
            { label => 'UnterzeichnerIn',                                           value => 'ato' },
            { label => 'VeranstalterIn',                                            value => 'orm' },
            { label => 'VerfasserIn einer Einleitung',                              value => 'win' },
            { label => 'VerfasserIn eines Geleitwortes',                            value => 'aui' },
            { label => 'VerfasserIn eines Nachworts',                               value => 'aft' },
            { label => 'VerfasserIn eines Postscriptums',                           value => 'oth' },
            { label => 'VerfasserIn eines Vorworts',                                value => 'wpr' },
            { label => 'VerfasserIn von Zusatztexten',                              value => 'wat' },
            { label => 'VerfasserIn von ergänzendem Text',                          value => 'est' },
            { label => 'VerfasserIn von zusätzlichen Lyrics',                       value => 'wal' },
            { label => 'VerkäuferIn',                                               value => 'sll' },
            { label => 'Verlag',                                                    value => 'pbl' },
            { label => 'VerlegerIn',                                                value => 'oth' },
            { label => 'verleihende Institution',                                   value => 'oth' },
            { label => 'VertragspartnerIn',                                         value => 'ctr' },
            { label => 'Vertrieb',                                                  value => 'dst' },
            { label => 'VerwahrerIn',                                               value => 'oth' },
            { label => 'Visual-effects-Provider',                                   value => 'oth' },
            { label => 'Visual-effects-ProviderIn',                                 value => 'ctb' },
            { label => 'VorbesitzerIn',                                             value => 'oth' },
            { label => 'WidmendeR',                                                 value => 'dto' },
            { label => 'WidmungsempfängerIn',                                       value => 'dte' },
            { label => 'ZensorIn',                                                  value => 'cns' },
            { label => 'Zitiert',                                                   value => 'oth' },
            { label => 'ZivilklägerIn',                                             value => 'ptf' },
        ]
    });
}

q{ listening to: Fatima Spar & JOV: The Voice Within };

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ValueBuilder::RepeatableAutocomplete::RDA - Values for MARC21 based on RDA

=head1 VERSION

version 1.006

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

=item * L<https://koha-wiki.thulb.uni-jena.de/erschliessung/katalogisierung/handbuecher/100-haupteintragung-personenname/#Beziehungskennzeichnungen_fuer_Geistige_Schoepfer>

=item * L<https://koha-wiki.thulb.uni-jena.de/erschliessung/katalogisierung/handbuecher/700-nebeneintragung-personenname/#Beziehungskennzeichnungen_fuer_sonstige_Personen_Familien_und_Koerperschaften_die_mit_einer_Ressource_in_Verbindung_stehen>

=item * L<https://wiki.dnb.de/download/attachments/106042227/AH-017.pdf>

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
