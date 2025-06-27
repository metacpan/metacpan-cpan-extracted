package MARC::Field008;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Data::MARC::Field008;
use Data::MARC::Field008::Book 0.03;
use Data::MARC::Field008::ComputerFile 0.03;
use Data::MARC::Field008::ContinuingResource 0.03;
use Data::MARC::Field008::Map 0.03;
use Data::MARC::Field008::MixedMaterial 0.03;
use Data::MARC::Field008::Music 0.03;
use Data::MARC::Field008::VisualMaterial 0.03;
use Error::Pure qw(err);
use List::Util 1.33 qw(any);
use Mo::utils 0.08 qw(check_bool check_isa check_required);
use Scalar::Util qw(blessed);

our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Ignore data errors.
	$self->{'ignore_data_errors'} = 0;

	# Leader.
	$self->{'leader'} = undef;

	# Verbose mode.
	$self->{'verbose'} = 0;

	# Process parameters.
	set_params($self, @params);

	# Check 'ignore_data_errors'.
	check_required($self, 'ignore_data_errors');
	check_bool($self, 'ignore_data_errors');

	# Check 'leader'.
	check_required($self, 'leader');
	check_isa($self, 'leader', 'Data::MARC::Leader');

	# Check 'verbose'.
	check_bool($self, 'verbose');

	return $self;
}

sub parse {
	my ($self, $field_008) = @_;

	# XXX Fix white space issue in MARC XML record.
	if (length($field_008) < 40) {
		$field_008 .= (' ' x (40 - length($field_008)));
	}

	# Check length.
	if (length($field_008) > 40) {
		err 'Bad length of MARC 008 field.',
			'Length', length($field_008),
		;
	}
	if ($self->{'verbose'}) {
		print "Field 008: |$field_008|\n";
	}

	my %params = (
		'raw' => $field_008,

		'date_entered_on_file' => (substr $field_008, 0, 6),
		'type_of_date' => (substr $field_008, 6, 1),
		'date1' => (substr $field_008, 7, 4),
		'date2' => (substr $field_008, 11, 4),
		'place_of_publication' => (substr $field_008, 15, 3),
		$self->_parse_different($field_008),
		'language' => (substr $field_008, 35, 3),
		'modified_record' => (substr $field_008, 38, 1),
		'cataloging_source' => (substr $field_008, 39, 1),
	);

	return Data::MARC::Field008->new(%params);
}

sub serialize {
	my ($self, $field_008_obj) = @_;

	# Check object.
	if (! blessed($field_008_obj) || ! $field_008_obj->isa('Data::MARC::Field008')) {
		err "Bad 'Data::MARC::Field008' instance to serialize.";
	}

	my $field_008 = $field_008_obj->date_entered_on_file.
		$field_008_obj->type_of_date.
		$field_008_obj->date1.
		$field_008_obj->date2.
		$field_008_obj->place_of_publication.
		$self->_serialize_different($field_008_obj->material).
		$field_008_obj->language.
		$field_008_obj->modified_record.
		$field_008_obj->cataloging_source;

	return $field_008;
}

sub _parse_different {
	my ($self, $field_008) = @_;

	my %params;

	# Book
	if ((any { $self->{'leader'}->type eq $_ } qw(a t))
		&& (any { $self->{'leader'}->bibliographic_level eq $_ } qw(a c d m))) {

		my %mat_params = (
			'illustrations' => substr($field_008, 18, 4),
			'target_audience' => substr($field_008, 22, 1),
			'form_of_item' => substr($field_008, 23, 1),
			'nature_of_content' => substr($field_008, 24, 4),
			'government_publication' => substr($field_008, 28, 1),
			'conference_publication' => substr($field_008, 29, 1),
			'festschrift' => substr($field_008, 30, 1),
			'index' => substr($field_008, 31, 1),
			'literary_form' => substr($field_008, 33, 1),
			'biography' => substr($field_008, 34, 1),

			'raw' => substr($field_008, 18, 17),
		);
		$Data::MARC::Field008::Book::STRICT = $self->{'ignore_data_errors'} ? 0 : 1;
		my $material = Data::MARC::Field008::Book->new(%mat_params);
		%params = (
			'material' => $material,
			'material_type' => 'book',
		);

	# Computer files.
	} elsif ($self->{'leader'}->type eq 'm') {
		my %mat_params = (
			'target_audience' => substr($field_008, 22, 1),
			'form_of_item' => substr($field_008, 23, 1),
			'type_of_computer_file' => substr($field_008, 26, 1),
			'government_publication' => substr($field_008, 28, 1),

			'raw' => substr($field_008, 18, 17),
		);
		$Data::MARC::Field008::ComputerFile::STRICT = $self->{'ignore_data_errors'} ? 0 : 1;
		my $material = Data::MARC::Field008::ComputerFile->new(%mat_params);
		%params = (
			'material' => $material,
			'material_type' => 'computer_file',
		);

	# Maps.
	} elsif (any { $self->{'leader'}->type eq $_ } qw(e f)) {
		my %mat_params = (
			'relief' => substr($field_008, 18, 4),
			'projection' => substr($field_008, 22, 2),
			'type_of_cartographic_material' => substr($field_008, 25, 1),
			'government_publication' => substr($field_008, 28, 1),
			'form_of_item' => substr($field_008, 29, 1),
			'index' => substr($field_008, 31, 1),
			'special_format_characteristics' => substr($field_008, 33, 2),

			'raw' => substr($field_008, 18, 17),
		);
		$Data::MARC::Field008::Map::STRICT = $self->{'ignore_data_errors'} ? 0 : 1;
		my $material = Data::MARC::Field008::Map->new(%mat_params);
		%params = (
			'material' => $material,
			'material_type' => 'map',
		);

	# Music.
	} elsif (any { $self->{'leader'}->type eq $_ } qw(c d i j)) {
		my %mat_params = (
			'form_of_composition' => substr($field_008, 18, 2),
			'format_of_music' => substr($field_008, 20, 1),
			'music_parts' => substr($field_008, 21, 1),
			'target_audience' => substr($field_008, 22, 1),
			'form_of_item' => substr($field_008, 23, 1),
			'accompanying_matter' => substr($field_008, 24, 6),
			'literary_text_for_sound_recordings' => substr($field_008, 30, 2),
			'transposition_and_arrangement' => substr($field_008, 33, 1),

			'raw' => substr($field_008, 18, 17),
		);
		$Data::MARC::Field008::Music::STRICT = $self->{'ignore_data_errors'} ? 0 : 1;
		my $material = Data::MARC::Field008::Music->new(%mat_params);
		%params = (
			'material' => $material,
			'material_type' => 'music',
		);

	# Continuing Resources
	} elsif ($self->{'leader'}->type eq 'a'
		&& (any { $self->{'leader'}->bibliographic_level eq $_ } qw(b i s))) {

		my %mat_params = (
			'frequency' => substr($field_008, 18, 1),
			'regularity' => substr($field_008, 19, 1),
			'type_of_continuing_resource' => substr($field_008, 21, 1),
			'form_of_original_item' => substr($field_008, 22, 1),
			'form_of_item' => substr($field_008, 23, 1),
			'nature_of_entire_work' => substr($field_008, 24, 1),
			'nature_of_content' => substr($field_008, 25, 3),
			'government_publication' => substr($field_008, 28, 1),
			'conference_publication' => substr($field_008, 29, 1),
			'original_alphabet_or_script_of_title' => substr($field_008, 33, 1),
			'entry_convention' => substr($field_008, 34, 1),

			'raw' => substr($field_008, 18, 17),
		);
		$Data::MARC::Field008::ContinuingResource::STRICT = $self->{'ignore_data_errors'} ? 0 : 1;
		my $material = Data::MARC::Field008::ContinuingResource->new(%mat_params);
		%params = (
			'material' => $material,
			'material_type' => 'continuing_resource',
		);

	# Visual Materials
	} elsif (any { $self->{'leader'}->type eq $_ } qw(g k o r)) {
		my %mat_params = (
			'running_time_for_motion_pictures_and_videorecordings' => substr($field_008, 18, 3),
			'target_audience' => substr($field_008, 22, 1),
			'government_publication' => substr($field_008, 28, 1),
			'form_of_item' => substr($field_008, 29, 1),
			'type_of_visual_material' => substr($field_008, 33, 1),
			'technique' => substr($field_008, 34, 1),

			'raw' => substr($field_008, 18, 17),
		);
		$Data::MARC::Field008::VisualMaterial::STRICT = $self->{'ignore_data_errors'} ? 0 : 1;
		my $material = Data::MARC::Field008::VisualMaterial->new(%mat_params);
		%params = (
			'material' => $material,
			'material_type' => 'visual_material',
		);

	# Mixed Materials
	} elsif ($self->{'leader'}->type eq 'p') {
		my %mat_params = (
			'form_of_item' => substr($field_008, 23, 1),

			'raw' => substr($field_008, 18, 17),
		);
		$Data::MARC::Field008::MixedMaterial::STRICT = $self->{'ignore_data_errors'} ? 0 : 1;
		my $material = Data::MARC::Field008::MixedMaterial->new(%mat_params);
		%params = (
			'material' => $material,
			'material_type' => 'mixed_material',
		);

	} else {
		err "Unsupported 008 type.";
	}

	return %params;
}

sub _serialize_different {
	my ($self, $material) = @_;

	my $ret;
	if ($material->isa('Data::MARC::Field008::Book')) {
		$ret = $material->illustrations.
			$material->target_audience.
			$material->form_of_item.
			$material->nature_of_content.
			$material->government_publication.
			$material->conference_publication.
			$material->festschrift.
			$material->index.
			' '.
			$material->literary_form.
			$material->biography;

	} elsif ($material->isa('Data::MARC::Field008::ComputerFile')) {
		$ret = (' ' x 4).
			$material->target_audience.
			$material->form_of_item.
			(' ' x 2).
			$material->type_of_computer_file.
			' '.
			$material->government_publication.
			(' ' x 6);
	} elsif ($material->isa('Data::MARC::Field008::ContinuingResource')) {
		$ret = $material->frequency.
			$material->regularity.
			' '.
			$material->type_of_continuing_resource.
			$material->form_of_original_item.
			$material->form_of_item.
			$material->nature_of_entire_work.
			$material->nature_of_content.
			$material->government_publication.
			$material->conference_publication.
			(' ' x 3).
			$material->original_alphabet_or_script_of_title.
			$material->entry_convention;
	} elsif ($material->isa('Data::MARC::Field008::Map')) {
		$ret = $material->relief.
			$material->projection.
			' '.
			$material->type_of_cartographic_material.
			(' ' x 2).
			$material->government_publication.
			$material->form_of_item.
			' '.
			$material->index.
			' '.
			$material->special_format_characteristics;
	} elsif ($material->isa('Data::MARC::Field008::MixedMaterial')) {
		$ret = (' ' x 5).
			$material->form_of_item.
			(' ' x 10);
	} elsif ($material->isa('Data::MARC::Field008::Music')) {
		$ret = $material->form_of_composition.
			$material->format_of_music.
			$material->music_parts.
			$material->target_audience.
			$material->form_of_item.
			$material->accompanying_matter.
			$material->literary_text_for_sound_recordings.
			' '.
			$material->transposition_and_arrangement.
			' ';
	} elsif ($material->isa('Data::MARC::Field008::VisualMaterial')) {
		$ret = $material->running_time_for_motion_pictures_and_videorecordings.
			' '.
			$material->target_audience.
			(' ' x 5).
			$material->government_publication.
			$material->form_of_item.
			(' ' x 3).
			$material->type_of_visual_material.
			$material->technique;
	}

	return $ret;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Field008 - Class for parsing and serialization of MARC field 008.

=head1 SYNOPSIS

 use MARC::Field008;

 my $obj = MARC::Field008->new(%params);
 my $data_obj = $cnf->parse($field_008);
 my $field_008 = $cnf->serialize($data_obj);

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Field008->new(%params);

Constructor.

=over 8

=item * C<ignore_data_errors>

Flag for ignoring material object errors.

It's required.

Default value is 0.

=item * C<leader>

MARC leader string.

It's required.

Default is undef.

=item * C<verbose>

Verbose mode.

Default is 0.

=back

Returns instance of object.

=head2 C<parse>

 my $data_obj = $cnf->parse($field_008);

Parse MARC field 008 string to data object.

Returns instance of L<Data::MARC::Field008>.

=head2 C<serialize>

 my $field_008 = $cnf->serialize($data_obj);

Serialize L<Data::MARC::Field008> object to string..

Returns string.

=head1 ERRORS

 new():
         From Mo::utils::check_bool():
                 Parameter 'ignore_data_errors' must be a bool (0/1).
                         Value: %s
                 Parameter 'verbose' must be a bool (0/1).
                         Value: %s
         From Mo::utils::check_isa():
                 Parameter 'leader' must be a 'Data::MARC::Leader' object.
                         Value: %s
                         Reference: %s
         From Mo::utils::check_required():
                 Parameter 'ignore_data_errors' is required.
                 Parameter 'leader' is required.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 parse():
         Bad length of MARC 008 field.
                 Length: %s

         Errors from L<Data::MARC::Field008>, see documentation.

 serialize():
         Bad 'Data::MARC::Field008' instance to serialize.

=head1 EXAMPLE1

=for comment filename=parse_example.pl

 use strict;
 use warnings;

 use MARC::Field008;
 use MARC::Leader;
 use Data::Printer;

 # Object.
 my $leader = MARC::Leader->new->parse('     nam a22        4500');
 my $obj = MARC::Field008->new(
         'leader' => $leader,
 );

 # Parse.
 my $data = $obj->parse('830304s1982    xr a         u0|0 | cze  ');

 # Dump.
 p $data;

 # Output:
 # Data::MARC::Field008  {
 #     parents: Mo::Object
 #     public methods (13):
 #         BUILD
 #         Data::MARC::Field008::Utils:
 #             check_cataloging_source, check_date, check_modified_record, check_type_of_date
 #         Error::Pure:
 #             err
 #         Error::Pure::Utils:
 #             err_get
 #         Mo::utils:
 #             check_isa, check_length_fix, check_number, check_required, check_strings
 #         Readonly:
 #             Readonly
 #     private methods (0)
 #     internals: {
 #         cataloging_source      " ",
 #         date_entered_on_file   830304,
 #         date1                  1982,
 #         date2                  "    ",
 #         language               "cze",
 #         material               Data::MARC::Field008::Book,
 #         material_type          "book",
 #         modified_record        " ",
 #         place_of_publication   "xr ",
 #         raw                    "830304s1982    xr a         u0|0 | cze  " (dualvar: 830304),
 #         type_of_date           "s"
 #     }
 # }

=head1 EXAMPLE2

=for comment filename=serialize_example.pl

 use strict;
 use warnings;

 use MARC::Field008;
 use MARC::Leader;
 use Data::MARC::Field008;
 use Data::MARC::Field008::Book;

 # Object.
 my $leader = MARC::Leader->new->parse('     nam a22        4500');
 my $obj = MARC::Field008->new(
         'leader' => $leader,
 );

 # Data.
 my $material = Data::MARC::Field008::Book->new(
         'biography' => ' ',
         'conference_publication' => '0',
         'festschrift' => '0',
         'form_of_item' => 'r',
         'government_publication' => ' ',
         'illustrations' => '    ',
         'index' => '0',
         'literary_form' => '0',
         'nature_of_content' => '    ',
         'target_audience' => ' ',
 );
 my $data = Data::MARC::Field008->new(
         'cataloging_source' => ' ',
         'date_entered_on_file' => '      ',
         'date1' => '    ',
         'date2' => '    ',
         'language' => 'cze',
         'material' => $material,
         'material_type' => 'book',
         'modified_record' => ' ',
         'place_of_publication' => '   ',
         'type_of_date' => 's',
 );

 # Serialize.
 print "'".$obj->serialize($data)."'\n";

 # Output:
 # '      s                r     000 0 cze  '

=head1 DEPENDENCIES

L<Class::Utils>,
L<Data::MARC::Field008>,
L<Data::MARC::Field008::Book>,
L<Data::MARC::Field008::ComputerFile>,
L<Data::MARC::Field008::ContinuingResource>,
L<Data::MARC::Field008::Map>,
L<Data::MARC::Field008::MixedMaterial>,
L<Data::MARC::Field008::Music>,
L<Data::MARC::Field008::VisualMaterial>,
L<Error::Pure>,
L<List::Util>,
L<Mo::utils>,
L<Scalar::Util>.

=head1 SEE ALSO

=over

=item L<Data::MARC::Field008>

Data object for MARC field 008.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/MARC-Field008>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
