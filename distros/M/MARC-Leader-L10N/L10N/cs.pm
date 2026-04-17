package MARC::Leader::L10N::cs;

use base qw(MARC::Leader::L10N);
use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8);

our $VERSION = 0.04;

our %Lexicon = (
	'Bibliographic level' => decode_utf8('Bibliografická úroveň'),
	'bibliographic_level.a' => decode_utf8('analytická část (monografická)'),
	'bibliographic_level.b' => decode_utf8('analytická část (seriálová)'),
	'bibliographic_level.c' => decode_utf8('sbírka'),
	'bibliographic_level.d' => decode_utf8('podjednotka'),
	'bibliographic_level.i' => decode_utf8('integrační zdroj m monografie'),
	'bibliographic_level.m' => decode_utf8('monografie'),
	'bibliographic_level.s' => decode_utf8('seriál'),

	'Character coding scheme' => decode_utf8('Použitá znaková sada'),
	'char_coding_scheme._' => 'MARC-8',
	'char_coding_scheme.a' => 'UCS/Unicode',

	'Base address of data' => decode_utf8('Bázová adresa údajů'),

	'Descriptive cataloging form' => decode_utf8('Forma katalogizačního popisu'),
	'descriptive_cataloging_form._' => decode_utf8('jiná než ISBD'),
	'descriptive_cataloging_form.a' => 'AACR 2',
	'descriptive_cataloging_form.c' => decode_utf8('vynechána interpunkce ISBD'),
	'descriptive_cataloging_form.i' => decode_utf8('přítomna interpunkce ISBD'),
	'descriptive_cataloging_form.n' => decode_utf8('vynechána interpunkce jiná než ISBD'),
	'descriptive_cataloging_form.u' => decode_utf8('není znám'),

	'Encoding level' => decode_utf8('Úroveň úplnosti záznamu'),
	'encoding_level._' => decode_utf8('úplná úroveň'),
	'encoding_level.1' => decode_utf8('úplná úroveň, bez dokumentu v ruce'),
	'encoding_level.2' => decode_utf8('méně než úplná úroveň, bez dokumentu v ruce'),
	'encoding_level.3' => decode_utf8('zkrácený záznam'),
	'encoding_level.4' => decode_utf8('základní úroveň'),
	'encoding_level.5' => decode_utf8('částečně zpracovaný záznam'),
	'encoding_level.7' => decode_utf8('minimální úroveň'),
	'encoding_level.8' => decode_utf8('před vydáním dokumentu'),
	'encoding_level.u' => decode_utf8('není znám'),
	'encoding_level.z' => decode_utf8('nelze použít'),

	'Length of the implementation-defined portion' => decode_utf8('Délka implementačně definované části'),

	'Indicator count' => decode_utf8('Délka indikátorů'),

	'Record length' => decode_utf8('Délka záznamu'),

	'Length of the length-of-field portion' => decode_utf8('Počet znaků délky pole'),

	# TODO Check main title.
	'Multipart resource record level' => decode_utf8('Úroveň záznamu vícedílného zdroje'),
	'multipart_resource_record_level._' => decode_utf8('není specifikována, nelze použít'),
	'multipart_resource_record_level.a' => decode_utf8('soubor'),
	'multipart_resource_record_level.b' => decode_utf8('část/svazek s nezávislým názvem'),
	'multipart_resource_record_level.c' => decode_utf8('část/svazek se závislým názvem'),

	'Length of the starting-character-position portion' => decode_utf8('Délka počáteční znakové pozice'),

	'Record status' => decode_utf8('Status záznamu'),
	'status.a' => decode_utf8('doplněný záznam'),
	'status.c' => decode_utf8('opravený záznam'),
	'status.d' => decode_utf8('zrušený záznam'),
	'status.n' => decode_utf8('nový záznam'),
	'status.p' => decode_utf8('doplněný prozatímní záznam'),

	'Subfield code count' => decode_utf8('Délka označení podpole'),

	'Type of record' => decode_utf8('Typ záznamu'),
	'type.a' => decode_utf8('textový dokument'),
	'type.c' => decode_utf8('hudebnina'),
	'type.d' => decode_utf8('rukopisná hudebnina'),
	'type.e' => decode_utf8('kartografický dokument'),
	'type.f' => decode_utf8('rukopisný kartografický dokument'),
	'type.g' => decode_utf8('projekční médium'),
	'type.i' => decode_utf8('nehudební zvukový záznam'),
	'type.j' => decode_utf8('hudební zvukový záznam'),
	'type.k' => decode_utf8('dvojrozměrná neprojekční grafika'),
	'type.m' => decode_utf8('počítačový soubor/elektronický zdroj'),
	'type.o' => decode_utf8('souprava, soubor (kit)'),
	'type.p' => decode_utf8('smíšený dokument'),
	'type.r' => decode_utf8('trojrozměrný předmět, přírodní objekt'),
	'type.t' => decode_utf8('rukopisný textový dokument'),
	'type.z' => decode_utf8('záznam souboru autorit'),

	'Type of control' => decode_utf8('Typ kontroly'),
	'type_of_control._' => decode_utf8('není specifikován'),
	'type_of_control.a' => decode_utf8('archivní dokument'),

	'Undefined' => decode_utf8('Není definován'),
	'undefined.0' => decode_utf8('není definován'),
);

1;

__END__
