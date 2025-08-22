package Koha::Contrib::ValueBuilder::RepeatableAutocomplete::RDA;
use strict;
use warnings;
use utf8;

# ABSTRACT: Values for MARC21 based on RDA

our $VERSION = '1.005'; # VERSION

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
        for my $data (@{$VALUES{$lang}}) {
            my $label = $data->{label};
            $label.= ' (Geistige*r Schöpfer*in)' if $data->{type} eq 'creator';
            my $item = { value => $data->{value}, clean_label => $data->{label}, label => $label };
            push(@list, $item);
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
        for my $data (@{$VALUES{$lang}}) {
            my $item = { value => $data->{value}, clean_label => $data->{label}, label => $data->{label} };
            push(@list, $item);
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
    de => [
        { label => '(gegenwärtigeR) EigentümerIn',                              value => 'own', type => 'other_agent' },
        { label => 'Abgebildet',                                                value => 'oth', type => 'other_agent' },
        { label => 'AbsenderIn',                                                value => 'oth', type => 'other_agent' },
        { label => 'AdressatIn',                                                value => 'rcp', type => 'other_agent' },
        { label => 'AkademischeR BetreuerIn',                                   value => 'dgs', type => 'other_agent' },
        { label => 'AktenbildnerIn',                                            value => 'oth', type => 'other_agent' },
        { label => 'AngeklagteR/Beklagte',                                      value => 'dfd', type => 'other_agent' },
        { label => 'AquarellistIn',                                             value => 'oth', type => 'creator' },
        { label => 'ArchitektIn',                                               value => 'arc', type => 'creator' },
        { label => 'Archiv',                                                    value => 'oth', type => 'creator' },
        { label => 'ArrangeurIn',                                               value => 'arr', type => 'other_agent' },
        { label => 'Art Director',                                              value => 'adi', type => 'other_agent' },
        { label => 'AssistentIn',                                               value => 'oth', type => 'other_agent' },
        { label => 'AuftraggeberIn',                                            value => 'pat', type => 'other_agent' },
        { label => 'AusführendeR',                                              value => 'prf', type => 'other_agent' },
        { label => 'BaumeisterIn',                                              value => 'oth', type => 'creator' },
        { label => 'BearbeiterIn',                                              value => 'oth', type => 'other_agent' },
        { label => 'BegründerIn eines Werks',                                   value => 'oth', type => 'other_agent' },
        { label => 'Behandelt',                                                 value => 'oth', type => 'other_agent' },
        { label => 'BeiträgerIn',                                               value => 'oth', type => 'other_agent' },
        { label => 'BeraterIn',                                                 value => 'csl', type => 'other_agent' },
        { label => 'BerichterstatterIn',                                        value => 'cre', type => 'creator' },
        { label => 'BerufungsbeklagteR/RevisionsbeklagteR',                     value => 'ape', type => 'other_agent' },
        { label => 'BerufungsklägerIn/RevisionsklägerIn',                       value => 'apl', type => 'other_agent' },
        { label => 'BestandsbildnerIn',                                         value => 'oth', type => 'creator' },
        { label => 'Beteiligt',                                                 value => 'oth', type => 'other_agent' },
        { label => 'Bildagentur',                                               value => 'oth', type => 'creator' },
        { label => 'BildhauerIn',                                               value => 'scl', type => 'creator' },
        { label => 'BildregisseurIn',                                           value => 'vdg', type => 'other_agent' },
        { label => 'BrailleschriftprägerIn',                                    value => 'brl', type => 'other_agent' },
        { label => 'BuchbinderIn',                                              value => 'bnd', type => 'other_agent' },
        { label => 'BuchgestalterIn',                                           value => 'bkd', type => 'other_agent' },
        { label => 'BuchhändlerIn',                                             value => 'oth', type => 'creator' },
        { label => 'BuchkünstlerIn',                                            value => 'art', type => 'creator' },
        { label => 'BühnenbildnerIn',                                           value => 'oth', type => 'creator' },
        { label => 'BühnenregisseurIn',                                         value => 'sgd', type => 'other_agent' },
        { label => 'Casting Director',                                          value => 'oth', type => 'other_agent' },
        { label => 'ChefredakteurIn',                                           value => 'pbd', type => 'other_agent' },
        { label => 'ChoreografIn',                                              value => 'chr', type => 'creator' },
        { label => 'ChorleiterIn',                                              value => 'cnd', type => 'other_agent' },
        { label => 'ColoristIn',                                                value => 'clr', type => 'other_agent' },
        { label => 'Corresponding author',                                      value => 'oth', type => 'creator' },
        { label => 'CutterIn',                                                  value => 'edm', type => 'other_agent' },
        { label => 'DJ/DJane',                                                  value => 'ctb', type => 'other_agent' },
        { label => 'DesignerIn',                                                value => 'dsr', type => 'creator' },
        { label => 'DirigentIn',                                                value => 'cnd', type => 'other_agent' },
        { label => 'DiskussionsteilnehmerIn',                                   value => 'pan', type => 'other_agent' },
        { label => 'Dokumentiert',                                              value => 'oth', type => 'other_agent' },
        { label => 'DonatorIn',                                                 value => 'oth', type => 'other_agent' },
        { label => 'DramaturgIn',                                               value => 'oth', type => 'other_agent' },
        { label => 'DrehbuchautorIn',                                           value => 'aus', type => 'creator' },
        { label => 'DruckerIn',                                                 value => 'prt', type => 'other_agent' },
        { label => 'DruckformherstellerIn',                                     value => 'plt', type => 'other_agent' },
        { label => 'DruckgrafikerIn',                                           value => 'prm', type => 'other_agent' },
        { label => 'Durch Verfahrensvorschriften geregeltes Gericht',           value => 'cou', type => 'other_agent' },
        { label => 'EmailmalerIn',                                              value => 'oth', type => 'creator' },
        { label => 'EntwerferIn',                                               value => 'oth', type => 'creator' },
        { label => 'ErfinderIn',                                                value => 'inv', type => 'creator' },
        { label => 'Erwähnt',                                                   value => 'oth', type => 'other_agent' },
        { label => 'ErzählerIn',                                                value => 'nrt', type => 'other_agent' },
        { label => 'FernsehproduzentIn',                                        value => 'tlp', type => 'other_agent' },
        { label => 'FernsehregisseurIn',                                        value => 'tld', type => 'other_agent' },
        { label => 'FestrednerIn',                                              value => 'oth', type => 'other_agent' },
        { label => 'FilmemacherIn',                                             value => 'fmk', type => 'creator' },
        { label => 'FilmproduzentIn',                                           value => 'fmp', type => 'other_agent' },
        { label => 'FilmregisseurIn',                                           value => 'fmd', type => 'other_agent' },
        { label => 'Filmvertrieb',                                              value => 'fds', type => 'other_agent' },
        { label => 'FormgießerIn',                                              value => 'cas', type => 'other_agent' },
        { label => 'FormschneiderIn',                                           value => 'oth', type => 'creator' },
        { label => 'ForscherIn',                                                value => 'res', type => 'other_agent' },
        { label => 'Fotoatelier',                                               value => 'oth', type => 'creator' },
        { label => 'FotografIn',                                                value => 'pht', type => 'creator' },
        { label => 'FotohändlerIn',                                             value => 'oth', type => 'creator' },
        { label => 'GalanteriewarenherstellerIn',                               value => 'oth', type => 'creator' },
        { label => 'GartenarchitektIn',                                         value => 'oth', type => 'creator' },
        { label => 'Gastgebende Institution',                                   value => 'his', type => 'other_agent' },
        { label => 'GastgeberIn',                                               value => 'hst', type => 'other_agent' },
        { label => 'Geehrt',                                                    value => 'oth', type => 'other_agent' },
        { label => 'GefeierteR',                                                value => 'hnr', type => 'other_agent' },
        { label => 'GeistigeR SchöpferIn',                                      value => 'cre', type => 'creator' },
        { label => 'GemmenschneiderIn',                                         value => 'oth', type => 'creator' },
        { label => 'Geregelte Gebietskörperschaft',                             value => 'jug', type => 'other_agent' },
        { label => 'GerichtsstenografIn',                                       value => 'crt', type => 'other_agent' },
        { label => 'Gesammelt',                                                 value => 'oth', type => 'other_agent' },
        { label => 'GeschichtenerzählerIn',                                     value => 'stl', type => 'other_agent' },
        { label => 'GesprächsteilnehmerIn',                                     value => 'oth', type => 'creator' },
        { label => 'GießerIn',                                                  value => 'oth', type => 'creator' },
        { label => 'GlasmalerIn',                                               value => 'oth', type => 'creator' },
        { label => 'GoldschmiedIn',                                             value => 'oth', type => 'creator' },
        { label => 'Grad-verleihende Institution',                              value => 'dgg', type => 'other_agent' },
        { label => 'GraduierteR',                                               value => 'oth', type => 'other_agent' },
        { label => 'GrafikerIn',                                                value => 'oth', type => 'creator' },
        { label => 'GraveurIn',                                                 value => 'oth', type => 'creator' },
        { label => 'Herausgebendes Organ',                                      value => 'isb', type => 'other_agent' },
        { label => 'HerausgeberIn',                                             value => 'edt', type => 'other_agent' },
        { label => 'HerstellerIn',                                              value => 'mfr', type => 'other_agent' },
        { label => 'HolzbildhauerIn',                                           value => 'oth', type => 'creator' },
        { label => 'HolzschneiderIn',                                           value => 'oth', type => 'creator' },
        { label => 'HörfunkproduzentIn',                                        value => 'rpc', type => 'other_agent' },
        { label => 'HörfunkregisseurIn',                                        value => 'rdd', type => 'other_agent' },
        { label => 'IlluminatorIn',                                             value => 'ilu', type => 'other_agent' },
        { label => 'IllustratorIn',                                             value => 'ill', type => 'other_agent' },
        { label => 'InhaberIn',                                                 value => 'oth', type => 'other_agent' },
        { label => 'InstrumentalmusikerIn',                                     value => 'itr', type => 'other_agent' },
        { label => 'InterviewerIn',                                             value => 'ivr', type => 'creator' },
        { label => 'InterviewteR',                                              value => 'ive', type => 'creator' },
        { label => 'KalligrafIn',                                               value => 'cll', type => 'creator' },
        { label => 'KalligrafIn',                                               value => 'cll', type => 'other_agent' },
        { label => 'KarikaturistIn',                                            value => 'oth', type => 'creator' },
        { label => 'KartografIn',                                               value => 'ctg', type => 'creator' },
        { label => 'KeramikerIn',                                               value => 'oth', type => 'creator' },
        { label => 'Klischeeanstalt',                                           value => 'oth', type => 'creator' },
        { label => 'KommentarverfasserIn',                                      value => 'wac', type => 'other_agent' },
        { label => 'KommentatorIn',                                             value => 'cmm', type => 'other_agent' },
        { label => 'KomponistIn',                                               value => 'cmp', type => 'creator' },
        { label => 'KorrektorIn',                                               value => 'oth', type => 'other_agent' },
        { label => 'KorrespondenzpartnerIn',                                    value => 'oth', type => 'creator' },
        { label => 'KostümbildnerIn',                                           value => 'cst', type => 'other_agent' },
        { label => 'KunsthandwerkerIn',                                         value => 'oth', type => 'creator' },
        { label => 'KunsthändlerIn',                                            value => 'oth', type => 'creator' },
        { label => 'KupferstecherIn',                                           value => 'oth', type => 'creator' },
        { label => 'KuratorIn',                                                 value => 'cur', type => 'other_agent' },
        { label => 'KünstlerIn',                                                value => 'art', type => 'creator' },
        { label => 'KünstlerischeR LeiterIn',                                   value => 'oth', type => 'creator' },
        { label => 'KürzendeR',                                                 value => 'abr', type => 'other_agent' },
        { label => 'LandschaftsarchitektIn',                                    value => 'lsa', type => 'creator' },
        { label => 'LandvermesserIn',                                           value => 'srv', type => 'other_agent' },
        { label => 'LaudatorIn',                                                value => 'oth', type => 'creator' },
        { label => 'LayouterIn',                                                value => 'oth', type => 'creator' },
        { label => 'LehrerIn',                                                  value => 'tch', type => 'other_agent' },
        { label => 'LeihgeberIn',                                               value => 'dpt', type => 'other_agent' },
        { label => 'LeihnehmerIn',                                              value => 'oth', type => 'other_agent' },
        { label => 'LektorIn',                                                  value => 'oth', type => 'other_agent' },
        { label => 'Letterer',                                                  value => 'ill', type => 'other_agent' },
        { label => 'LibrettistIn',                                              value => 'lbt', type => 'creator' },
        { label => 'LichtdruckerIn',                                            value => 'clt', type => 'other_agent' },
        { label => 'LichtgestalterIn',                                          value => 'lgd', type => 'other_agent' },
        { label => 'LinolschneiderIn',                                          value => 'oth', type => 'creator' },
        { label => 'LithografIn',                                               value => 'ltg', type => 'other_agent' },
        { label => 'Lithografische Anstalt',                                    value => 'oth', type => 'creator' },
        { label => 'MalerIn',                                                   value => 'oth', type => 'creator' },
        { label => 'MaskenbildnerIn',                                           value => 'ctb', type => 'other_agent' },
        { label => 'MedailleurIn',                                              value => 'oth', type => 'creator' },
        { label => 'Medium',                                                    value => 'med', type => 'other_agent' },
        { label => 'MiniaturmalerIn',                                           value => 'oth', type => 'creator' },
        { label => 'MischtontechnikerIn',                                       value => 'ctb', type => 'other_agent' },
        { label => 'MitarbeiterIn',                                             value => 'oth', type => 'other_agent' },
        { label => 'Mitglied eines Ausschusses, der akademische Grade vergibt', value => 'oth', type => 'other_agent' },
        { label => 'Mitglied eines Graduierungsausschusses',                    value => 'oth', type => 'other_agent' },
        { label => 'MitunterzeichnerIn',                                        value => 'oth', type => 'other_agent' },
        { label => 'MitwirkendeR',                                              value => 'ctb', type => 'other_agent' },
        { label => 'Modeatelier',                                               value => 'oth', type => 'creator' },
        { label => 'ModelleurIn',                                               value => 'oth', type => 'creator' },
        { label => 'ModeratorIn',                                               value => 'mod', type => 'other_agent' },
        { label => 'ModeschöpferIn',                                            value => 'ctb', type => 'creator' },
        { label => 'Musik-ProgrammiererIn',                                     value => 'ctb', type => 'other_agent' },
        { label => 'MusikalischeR LeiterIn',                                    value => 'msd', type => 'other_agent' },
        { label => 'Nachrichtenagentur',                                        value => 'oth', type => 'creator' },
        { label => 'Normerlassende Gebietskörperschaft',                        value => 'enj', type => 'creator' },
        { label => 'On-Screen-TeilnehmerIn',                                    value => 'ctb', type => 'other_agent' },
        { label => 'On-screen PräsentatorIn',                                   value => 'osp', type => 'other_agent' },
        { label => 'OrchesterleiterIn',                                         value => 'cnd', type => 'other_agent' },
        { label => 'OrganisatorIn',                                             value => 'oth', type => 'other_agent' },
        { label => 'PapiermacherIn',                                            value => 'ppm', type => 'other_agent' },
        { label => 'Produktionsfirma',                                          value => 'prn', type => 'other_agent' },
        { label => 'ProduzentIn einer Tonaufnahme',                             value => 'pro', type => 'other_agent' },
        { label => 'ProduzentIn',                                               value => 'pro', type => 'other_agent' },
        { label => 'ProgrammgestalterIn',                                       value => 'oth', type => 'other_agent' },
        { label => 'ProgrammiererIn',                                           value => 'prg', type => 'creator' },
        { label => 'ProtokollantIn',                                            value => 'mtk', type => 'other_agent' },
        { label => 'PräsentatorIn',                                             value => 'pre', type => 'other_agent' },
        { label => 'Präses',                                                    value => 'pra', type => 'creator' },
        { label => 'PuppenkünstlerIn',                                          value => 'oth', type => 'creator' },
        { label => 'PuppenspielerIn',                                           value => 'ppt', type => 'other_agent' },
        { label => 'RadiererIn',                                                value => 'etr', type => 'other_agent' },
        { label => 'RechnungslegerIn',                                          value => 'oth', type => 'other_agent' },
        { label => 'RedakteurIn',                                               value => 'oth', type => 'other_agent' },
        { label => 'RednerIn',                                                  value => 'spk', type => 'other_agent' },
        { label => 'RegieassistentIn',                                          value => 'oth', type => 'other_agent' },
        { label => 'RegisseurIn',                                               value => 'drt', type => 'other_agent' },
        { label => 'RegistrarIn',                                               value => 'cor', type => 'other_agent' },
        { label => 'Remix Artist',                                              value => 'cre', type => 'creator' },
        { label => 'RespondentIn',                                              value => 'rsp', type => 'creator' },
        { label => 'RezensentIn',                                               value => 'oth', type => 'creator' },
        { label => 'RichterIn',                                                 value => 'jud', type => 'other_agent' },
        { label => 'SammlerIn',                                                 value => 'col', type => 'other_agent' },
        { label => 'SchabkünstlerIn',                                           value => 'oth', type => 'creator' },
        { label => 'SchauspielerIn',                                            value => 'act', type => 'other_agent' },
        { label => 'SchneiderIn',                                               value => 'oth', type => 'creator' },
        { label => 'SchreiberIn',                                               value => 'oth', type => 'other_agent' },
        { label => 'SchriftkünstlerIn',                                         value => 'oth', type => 'creator' },
        { label => 'SchriftsetzerIn',                                           value => 'oth', type => 'creator' },
        { label => 'Sender',                                                    value => 'brd', type => 'other_agent' },
        { label => 'SilhouettenkünstlerIn',                                     value => 'oth', type => 'creator' },
        { label => 'SoftwareentwicklerIn',                                      value => 'ctb', type => 'other_agent' },
        { label => 'Sonstige Person, Familie und Körperschaft',                 value => 'oth', type => 'other_agent' },
        { label => 'Special-effects-ProviderIn',                                value => 'ctb', type => 'other_agent' },
        { label => 'SponsorIn',                                                 value => 'spn', type => 'other_agent' },
        { label => 'SprecherIn',                                                value => 'oth', type => 'other_agent' },
        { label => 'StahlstecherIn',                                            value => 'oth', type => 'creator' },
        { label => 'StecherIn',                                                 value => 'egr', type => 'other_agent' },
        { label => 'SteinmetzIn',                                               value => 'oth', type => 'creator' },
        { label => 'StickerIn',                                                 value => 'oth', type => 'creator' },
        { label => 'StifterIn',                                                 value => 'dnr', type => 'other_agent' },
        { label => 'SynchronregisseurIn',                                       value => 'ctb', type => 'other_agent' },
        { label => 'SynchronsprecherIn',                                        value => 'vac', type => 'other_agent' },
        { label => 'SzenenbildnerIn',                                           value => 'prs', type => 'other_agent' },
        { label => 'SängerIn',                                                  value => 'sng', type => 'other_agent' },
        { label => 'TechnikerIn',                                               value => 'oth', type => 'other_agent' },
        { label => 'TechnischeR ZeichnerIn',                                    value => 'drn', type => 'other_agent' },
        { label => 'TextdichterIn',                                             value => 'lyr', type => 'creator' },
        { label => 'TextilkünstlerIn',                                          value => 'oth', type => 'creator' },
        { label => 'TischlerIn',                                                value => 'oth', type => 'creator' },
        { label => 'TongestalterIn',                                            value => 'sds', type => 'other_agent' },
        { label => 'ToningenieurIn',                                            value => 'rce', type => 'other_agent' },
        { label => 'TonmeisterIn',                                              value => 'rcd', type => 'other_agent' },
        { label => 'TonregisseurIn',                                            value => 'oth', type => 'other_agent' },
        { label => 'TontechnikerIn',                                            value => 'ctb', type => 'other_agent' },
        { label => 'TranskribiererIn',                                          value => 'trc', type => 'other_agent' },
        { label => 'TrickfilmzeichnerIn',                                       value => 'anm', type => 'other_agent' },
        { label => 'TänzerIn',                                                  value => 'dnc', type => 'other_agent' },
        { label => 'UhrmacherIn',                                               value => 'oth', type => 'creator' },
        { label => 'UnterzeichnerIn',                                           value => 'ato', type => 'other_agent' },
        { label => 'UrheberIn',                                                 value => 'oth', type => 'creator' },
        { label => 'VeranstalterIn',                                            value => 'orm', type => 'other_agent' },
        { label => 'VerfasserIn einer Einleitung',                              value => 'win', type => 'other_agent' },
        { label => 'VerfasserIn eines Geleitwortes',                            value => 'aui', type => 'other_agent' },
        { label => 'VerfasserIn eines Nachworts',                               value => 'aft', type => 'other_agent' },
        { label => 'VerfasserIn eines Postscriptums',                           value => 'oth', type => 'other_agent' },
        { label => 'VerfasserIn eines Vorworts',                                value => 'wpr', type => 'other_agent' },
        { label => 'VerfasserIn von Zusatztexten',                              value => 'wat', type => 'other_agent' },
        { label => 'VerfasserIn von ergänzendem Text',                          value => 'est', type => 'other_agent' },
        { label => 'VerfasserIn von zusätzlichen Lyrics',                       value => 'wal', type => 'other_agent' },
        { label => 'VerfasserIn',                                               value => 'aut', type => 'creator' },
        { label => 'VerkäuferIn',                                               value => 'sll', type => 'other_agent' },
        { label => 'Verlag',                                                    value => 'pbl', type => 'other_agent' },
        { label => 'VerlegerIn',                                                value => 'oth', type => 'other_agent' },
        { label => 'VertragspartnerIn',                                         value => 'ctr', type => 'other_agent' },
        { label => 'Vertrieb',                                                  value => 'dst', type => 'other_agent' },
        { label => 'VerwahrerIn',                                               value => 'oth', type => 'other_agent' },
        { label => 'Visual-effects-Provider',                                   value => 'oth', type => 'other_agent' },
        { label => 'Visual-effects-ProviderIn',                                 value => 'ctb', type => 'other_agent' },
        { label => 'VorbesitzerIn',                                             value => 'oth', type => 'other_agent' },
        { label => 'VortragendeR',                                              value => 'oth', type => 'creator' },
        { label => 'WachsbossiererIn',                                          value => 'oth', type => 'creator' },
        { label => 'Werbeagentur',                                              value => 'oth', type => 'creator' },
        { label => 'Werkstatt',                                                 value => 'oth', type => 'creator' },
        { label => 'WidmendeR',                                                 value => 'dto', type => 'other_agent' },
        { label => 'WidmungsempfängerIn',                                       value => 'dte', type => 'other_agent' },
        { label => 'XylografIn',                                                value => 'oth', type => 'creator' },
        { label => 'Xylografische Anstalt',                                     value => 'oth', type => 'creator' },
        { label => 'ZeichnerIn',                                                value => 'oth', type => 'creator' },
        { label => 'ZensorIn',                                                  value => 'cns', type => 'other_agent' },
        { label => 'Zitiert',                                                   value => 'oth', type => 'other_agent' },
        { label => 'ZivilklägerIn',                                             value => 'ptf', type => 'other_agent' },
        { label => 'ZusammenstellendeR',                                        value => 'com', type => 'creator' },
        { label => 'annotierende Person',                                       value => 'ann', type => 'other_agent' },
        { label => 'ausfertigende Institution',                                 value => 'oth', type => 'other_agent' },
        { label => 'beschriftende Person',                                      value => 'ins', type => 'other_agent' },
        { label => 'frühereR EigentümerIn',                                     value => 'fmo', type => 'other_agent' },
        { label => 'verleihende Institution',                                   value => 'oth', type => 'other_agent' },
        { label => 'ÜbersetzerIn',                                              value => 'trl', type => 'other_agent' },
    ]
    );
}

q{ listening to: Fatima Spar & JOV: The Voice Within };

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ValueBuilder::RepeatableAutocomplete::RDA - Values for MARC21 based on RDA

=head1 VERSION

version 1.005

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
