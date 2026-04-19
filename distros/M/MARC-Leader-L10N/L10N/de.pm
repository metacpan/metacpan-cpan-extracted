package MARC::Leader::L10N::de;

use base qw(MARC::Leader::L10N);
use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8);

our $VERSION = 0.05;

our %Lexicon = (
	'Bibliographic level' => 'Bibliografische Ebene',
	'bibliographic_level.a' => decode_utf8('unselbstständiger Teil einer Monografie'),
	'bibliographic_level.b' => decode_utf8('unselbstständiger Teil einer fortlaufenden Ressource'),
	'bibliographic_level.c' => 'Sammlung',
	'bibliographic_level.d' => 'Untereinheit',
	'bibliographic_level.i' => 'integrierende Ressource',
	'bibliographic_level.m' => 'Monografie',
	'bibliographic_level.s' => 'fortlaufende Ressource',

	'Character coding scheme' => 'Zeichenkodierungsschema',
	'char_coding_scheme._' => 'MARC-8',
	'char_coding_scheme.a' => 'Unicode (UCS)',

	'Base address of data' => 'Basisadresse der Daten',

	'Descriptive cataloging form' => 'Form der Katalogisierung',
	'descriptive_cataloging_form._' => 'nicht-ISBD',
	'descriptive_cataloging_form.a' => 'AACR 2',
	'descriptive_cataloging_form.c' => 'ISBD-Interpunktion weggelassen',
	'descriptive_cataloging_form.i' => 'ISBD-Interpunktion enthalten',
	'descriptive_cataloging_form.n' => 'keine ISBD-Interpunktion',
	'descriptive_cataloging_form.u' => 'unbekannt',

	'Encoding level' => 'Kodierungsniveau',
	'encoding_level._' => decode_utf8('vollständige Katalogisierung'),
	'encoding_level.1' => decode_utf8('vollständige Katalogisierung, Vorlage nicht eingesehen'),
	'encoding_level.2' => decode_utf8('verkürzte Katalogisierung, Vorlage nicht eingesehen'),
	'encoding_level.3' => 'Kurzaufnahme',
	'encoding_level.4' => 'Kernniveau',
	'encoding_level.5' => decode_utf8('Teilaufnahme (vorläufig)'),
	'encoding_level.7' => 'Minimalniveau',
	'encoding_level.8' => 'Vorabaufnahme',
	'encoding_level.u' => 'unbekannt',
	'encoding_level.z' => 'nicht zutreffend',

	'Length of the implementation-defined portion' => decode_utf8('Länge des implementationsspezifischen Anteils'),

	'Indicator count' => 'Indikatoranzahl',

	'Record length' => decode_utf8('Satzlänge'),

	'Length of the length-of-field portion' => decode_utf8('Länge des Längenanteils des Feldes'),

	'Multipart resource record level' => 'Ebene mehrteiliger Ressourcen',
	'multipart_resource_record_level._' => 'nicht spezifiziert oder nicht zutreffend',
	'multipart_resource_record_level.a' => 'mehrteilige Ressource (Gesamtaufnahme)',
	'multipart_resource_record_level.b' => decode_utf8('Teil mit eigenständigem Titel'),
	'multipart_resource_record_level.c' => decode_utf8('Teil mit unselbstständigem Titel'),

	'Length of the starting-character-position portion' => decode_utf8('Länge des Anfangspositionsanteils'),

	'Record status' => 'Satzstatus',
	'status.a' => decode_utf8('Erhöhung des Kodierungsniveaus'),
	'status.c' => decode_utf8('korrigiert oder überarbeitet'),
	'status.d' => decode_utf8('gelöscht'),
	'status.n' => 'neu',
	'status.p' => decode_utf8('Erhöhung des Kodierungsniveaus aus Vorabaufnahme'),

	'Subfield code count' => 'Unterfeldkennzeichen-Anzahl',

	'Type of record' => 'Satztyp',
	'type.a' => 'Sprachmaterial',
	'type.c' => 'Noten',
	'type.d' => 'Handschriftliche Noten',
	'type.e' => 'kartografisches Material',
	'type.f' => 'handschriftliches kartografisches Material',
	'type.g' => 'audiovisuelles Medium',
	'type.i' => 'nichtmusikalische Tonaufnahme',
	'type.j' => 'musikalische Tonaufnahme',
	'type.k' => 'zweidimensionale Grafik',
	'type.m' => 'Computerdatei',
	'type.o' => 'Medienkombination',
	'type.p' => 'gemischte Materialien',
	'type.r' => 'dreidimensionales Objekt',
	'type.t' => 'Handschrift (Sprachmaterial)',
	'type.z' => 'Normdaten',

	'Type of control' => 'Kontrolltyp',
	'type_of_control._' => 'kein spezifischer Typ',
	'type_of_control.a' => 'archivisch',

	'Undefined' => decode_utf8('Nicht definiert'),
	'undefined.0' => decode_utf8('nicht definiert'),
);

1;

__END__
