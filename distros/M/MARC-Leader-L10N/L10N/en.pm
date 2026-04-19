package MARC::Leader::L10N::en;

use base qw(MARC::Leader::L10N);
use strict;
use warnings;

our $VERSION = 0.05;

our %Lexicon = (
	'_AUTO' => 1,

	'bibliographic_level.a' => 'Monographic component part',
	'bibliographic_level.b' => 'Serial component part',
	'bibliographic_level.c' => 'Collection',
	'bibliographic_level.d' => 'Subunit',
	'bibliographic_level.i' => 'Integrating resource',
	'bibliographic_level.m' => 'Monograph/Item',
	'bibliographic_level.s' => 'Serial',

	'char_coding_scheme._' => 'MARC-8',
	'char_coding_scheme.a' => 'UCS/Unicode',

	'descriptive_cataloging_form._' => 'Non-ISBD',
	'descriptive_cataloging_form.a' => 'AACR 2',
	'descriptive_cataloging_form.c' => 'ISBD punctuation omitted',
	'descriptive_cataloging_form.i' => 'ISBD punctuation included',
	'descriptive_cataloging_form.n' => 'Non-ISBD punctuation omitted',
	'descriptive_cataloging_form.u' => 'Unknown',

	'encoding_level._' => 'Full level',
	'encoding_level.1' => 'Full level, material not examined',
	'encoding_level.2' => 'Less-than-full level, material not examined',
	'encoding_level.3' => 'Abbreviated level',
	'encoding_level.4' => 'Core level',
	'encoding_level.5' => 'Partial (preliminary) level',
	'encoding_level.7' => 'Minimal level',
	'encoding_level.8' => 'Prepublication level',
	'encoding_level.u' => 'Unknown',
	'encoding_level.z' => 'Not applicable',

	'multipart_resource_record_level._' => 'Not specified or not applicable',
	'multipart_resource_record_level.a' => 'Set',
	'multipart_resource_record_level.b' => 'Part with independent title',
	'multipart_resource_record_level.c' => 'Part with dependent title',

	'status.a' => 'Increase in encoding level',
	'status.c' => 'Corrected or revised',
	'status.d' => 'Deleted',
	'status.n' => 'New',
	'status.p' => 'Increase in encoding level from prepublication',

	'type.a' => 'Language material',
	'type.c' => 'Notated music',
	'type.d' => 'Manuscript notated music',
	'type.e' => 'Cartographic material',
	'type.f' => 'Manuscript cartographic material',
	'type.g' => 'Projected medium',
	'type.i' => 'Nonmusical sound recording',
	'type.j' => 'Musical sound recording',
	'type.k' => 'Two-dimensional nonprojectable graphic',
	'type.m' => 'Computer file',
	'type.o' => 'Kit',
	'type.p' => 'Mixed materials',
	'type.r' => 'Three-dimensional artifact or naturally occurring object',
	'type.t' => 'Manuscript language material',

	'type_of_control._' => 'No specified type',
	'type_of_control.a' => 'Archival',

	'undefined.0' => 'Undefined',
);

1;

__END__
