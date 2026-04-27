package MARC::Field008::Print;

use strict;
use warnings;

use Check::Term::Color qw(check_term_color);
use Class::Utils qw(set_params);
use English;
use Error::Pure qw(err);
use MARC::Field008::L10N 0;
use Mo::utils 0.06 qw(check_bool);
use Mo::utils::Language 0.05 qw(check_language_639_1);

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Language.
	$self->{'lang'} = undef;

	# Use with ANSI sequences.
	$self->{'mode_ansi'} = undef;

	# Use description.
	$self->{'mode_desc'} = 1;

	# Output separator.
	$self->{'output_separator'} = "\n";

	# Process parameters.
	set_params($self, @params);

	# Check 'lang'.
	check_language_639_1($self, 'lang');

	# Check 'mode_ansi'.
	check_bool($self, 'mode_ansi');

	# Check 'mode_desc'.
	check_bool($self, 'mode_desc');

	# Set 'mode_ansi' from env variables.
	if (! defined $self->{'mode_ansi'}) {
		$self->{'mode_ansi'} = check_term_color();
	}

	# Check routine for ANSI colors output.
	if ($self->{'mode_ansi'}) {
		eval {
			require Term::ANSIColor;
		};
		if ($EVAL_ERROR) {
			err "Cannot load 'Term::ANSIColor' module.";
		}
	}

	$self->{'_l'} = MARC::Field008::L10N->get_handle(defined $self->{'lang'} ? $self->{'lang'} : ());

	return $self;
}

sub print {
	my ($self, $field008_obj) = @_;

	my @ret;
	# TODO Print some nice date.
	push @ret, $self->_key('Date entered on file').$field008_obj->date_entered_on_file;
	push @ret, $self->_key('Type of date/Publication status').
		$self->_print($field008_obj, 'type_of_date');
	push @ret, $self->_key('Date 1').$field008_obj->date1;
	push @ret, $self->_key('Date 2').$field008_obj->date2;
	# TODO Translate?
	push @ret, $self->_key('Place of publication, production, or execution').
		$field008_obj->place_of_publication;
	# TODO Translate?
	push @ret, $self->_key('Material').$field008_obj->material_type;
	my $material = $field008_obj->material;
	if ($field008_obj->material_type eq 'book') {
		push @ret, $self->_key('Illustrations').
			$self->_print_multi($material, 'illustrations', 'book');
		push @ret, $self->_key('Target audience').
			$self->_print($material, 'target_audience');
		push @ret, $self->_key('Form of item').
			$self->_print($material, 'form_of_item');
		push @ret, $self->_key('Nature of contents').
			$self->_print_multi($material, 'nature_of_content');
		push @ret, $self->_key('Government publication').
			$self->_print($material, 'government_publication');
		push @ret, $self->_key('Conference publication'). 
			$self->_print($material, 'conference_publication');
		push @ret, $self->_key('Festschrift').
			$self->_print($material, 'festschrift', 'book');
		push @ret, $self->_key('Index').
			$self->_print($material, 'index');
		push @ret, $self->_key('Literary form').
			$self->_print($material, 'literary_form', 'book');
		push @ret, $self->_key('Biography').
			$self->_print($material, 'biography', 'book');
	} elsif ($field008_obj->material_type eq 'computer_file') {
		push @ret, $self->_key('Target audience').
			$self->_print($material, 'target_audience');
		push @ret, $self->_key('Form of item').
			$self->_print($material, 'form_of_item', 'computer_file');
		push @ret, $self->_key('Type of computer file').
			$self->_print($material, 'type_of_computer_file', 'computer_file');
		push @ret, $self->_key('Government publication').
			$self->_print($material, 'government_publication');
	} elsif ($field008_obj->material_type eq 'continuing_resource') {
		push @ret, $self->_key('Frequency').
			$self->_print($material, 'frequency', 'continuing_resource');
		push @ret, $self->_key('Regularity').
			$self->_print($material, 'regularity', 'continuing_resource');
		push @ret, $self->_key('Type of continuing resource').
			$self->_print($material, 'type_of_continuing_resource',
			'continuing_resource');
		push @ret, $self->_key('Form of original item').
			$self->_print($material, 'form_of_original_item',
			'continuing_resource');
		push @ret, $self->_key('Form of item').
			$self->_print($material, 'form_of_item');
		push @ret, $self->_key('Nature of entire work').
			$self->_print($material, 'nature_of_entire_work',
			'continuing_resource');
		push @ret, $self->_key('Nature of contents').
			$self->_print_multi($material, 'nature_of_content');
		push @ret, $self->_key('Government publication').
			$self->_print($material, 'government_publication');
		push @ret, $self->_key('Conference publication').
			$self->_print($material, 'conference_publication');
		push @ret, $self->_key('Original alphabet or script of title').
			$self->_print($material, 'original_alphabet_or_script_of_title',
			'continuing_resource');
		push @ret, $self->_key('Entry convention').
			$self->_print($material, 'entry_convention',
			'continuing_resource');
	} elsif ($field008_obj->material_type eq 'map') {
		push @ret, $self->_key('Relief').
			$self->_print_multi($material, 'relief', 'map');
		push @ret, $self->_key('Projection').
			$self->_print($material, 'projection', 'map');
		push @ret, $self->_key('Type of cartographic material').
			$self->_print($material, 'type_of_cartographic_material', 'map');
		push @ret, $self->_key('Government publication').
			$self->_print($material, 'government_publication');
		push @ret, $self->_key('Form of item').
			$self->_print($material, 'form_of_item');
		push @ret, $self->_key('Index').
			$self->_print($material, 'index');
		push @ret, $self->_key('Special format characteristics').
			$self->_print_multi($material, 'special_format_characteristics', 'map');
	} elsif ($field008_obj->material_type eq 'mixed_material') {
		push @ret, $self->_key('Form of item').
			$self->_print($material, 'form_of_item');
	} elsif ($field008_obj->material_type eq 'music') {
		push @ret, $self->_key('Form of composition').
			$self->_print($material, 'form_of_composition', 'music');
		push @ret, $self->_key('Format of music').
			$self->_print($material, 'format_of_music', 'music');
		push @ret, $self->_key('Music parts').
			$self->_print($material, 'music_parts', 'music');
		push @ret, $self->_key('Target audience').
			$self->_print($material, 'target_audience');
		push @ret, $self->_key('Form of item').
			$self->_print($material, 'form_of_item');
		push @ret, $self->_key('Accompanying matter').
			$self->_print_multi($material, 'accompanying_matter', 'music');
		push @ret, $self->_key('Literary text for sound recordings').
			$self->_print_multi($material, 'literary_text_for_sound_recordings',
			'music');
		push @ret, $self->_key('Transposition and arrangement').
			$self->_print($material, 'transposition_and_arrangement',
			'music');

	# visual_material
	} else {
		# XXX For time from 001 to 999 is language key 001.
		my $lang_key;
		if ($material->running_time_for_motion_pictures_and_videorecordings ne '000'
			&& $material->running_time_for_motion_pictures_and_videorecordings =~ m/^\d+$/ms) {

			$lang_key = '001';
		}
		# TODO Value.
		push @ret, $self->_key('Running time for motion pictures and videorecordings').
			$self->_print($material, 'running_time_for_motion_pictures_and_videorecordings',
			'visual_material', $lang_key);
		push @ret, $self->_key('Target audience').
			$self->_print($material, 'target_audience');
		push @ret, $self->_key('Government publication').
			$self->_print($material, 'government_publication');
		push @ret, $self->_key('Form of item').
			$self->_print($material, 'form_of_item');
		push @ret, $self->_key('Type of visual material').
			$self->_print($material, 'type_of_visual_material', 'visual_material');
		push @ret, $self->_key('Technique').
			$self->_print($material, 'technique', 'visual_material');
	}
	# TODO Translate?
	push @ret, $self->_key('Language').$field008_obj->language;
	push @ret, $self->_key('Modified record').
		$self->_print($field008_obj, 'modified_record');
	push @ret, $self->_key('Cataloging source').
		$self->_print($field008_obj, 'cataloging_source');

	return wantarray ? @ret : (join $self->{'output_separator'}, @ret);
}

sub _key {
	my ($self, $key) = @_;

	my $ret;
	my $value = $self->{'_l'}->maketext($key);
	if ($self->{'mode_ansi'}) {
		$ret = Term::ANSIColor::color('cyan').$value.Term::ANSIColor::color('reset');
	} else {
		$ret = $value;
	}
	$ret .= ': ';

	return $ret;
}

sub _print {
	my ($self, $obj, $method_name, $prefix, $lang_key) = @_;

	my $ret_value = $obj->$method_name;
	my $ret;
	if ($self->{'mode_desc'}) {
		if (! defined $lang_key) {
			my $ret_value_fixed = $ret_value;
			$ret_value_fixed =~ s/\ /_/msg;
			$lang_key = $method_name.'.'.$ret_value_fixed;
			if (defined $prefix) {
				$lang_key = $prefix.'.'.$lang_key;
			}
		}
		$ret = $self->{'_l'}->maketext($lang_key);
	} else {
		$ret = $ret_value;
	}

	return $ret;
}

sub _print_multi {
	my ($self, $obj, $method_name, $prefix) = @_;

	my $ret_value = $obj->$method_name;
	my @ret_values = split m//ms, $ret_value;
	my @ret;
	my $not_coded = 0;
	foreach my $process_ret_value (@ret_values) {
		if ($process_ret_value eq ' ') {
			next;
		}
		if ($process_ret_value eq '|') {
			if (! $not_coded) {
				$not_coded = 1;
			} else {
				next;
			}
		}
		if ($self->{'mode_desc'}) {
			my $ret_value_fixed = $process_ret_value;
			$ret_value_fixed =~ s/\ /_/msg;
			my $lang_key = $method_name.'.'.$ret_value_fixed;
			if (defined $prefix) {
				$lang_key = $prefix.'.'.$lang_key;
			}
			push @ret, $self->{'_l'}->maketext($lang_key);
		} else {
			push @ret, $process_ret_value;
		}
	}

	return wantarray ? @ret : (join ', ', @ret);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Field008::Print - MARC 008 field class for print.

=head1 SYNOPSIS

 use MARC::Field008::Print;

 my $obj = MARC::Field008::Print->new(%params);
 my @ret = $obj->print($field008_obj);
 my $ret = $obj->print($field008_obj);

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Field008::Print->new(%params);

Constructor.

=over 8

=item * C<lang>

Language of texts in ISO 639-1 format.

Possible values are:

=over

=item * C<en>

=item * C<cs>

=back

Default value is undef, try to use language from locales.

=item * C<mode_ansi>

Mode for ANSI color support:

 1 - ANSI color support enabled.
 0 - ANSI color support disabled.

When is undefined, env variables C<COLOR> or C<NO_COLOR> could control ANSI
color support. See L<Check::Term::Color>.

Default value is undef.

=item * C<mode_desc>

Use description instead of raw leader values.

Default value is 1.

=item * C<output_separator>

Output separator used in scalar context of C<print()> method.

Default value is "\n".

=back

Returns instance of object.

=head2 C<print>

 my @ret = $obj->print($field008_obj);
 my $ret = $obj->print($field008_obj);

Process L<Data::MARC::Field008> instance to output print.
In scalar context compose printing output as one string.
In array context compose list of printing lines.

Color (ANSI colors) output is controlled by 'mode_ansi' parameter
or env variables C<COLOR> and C<NO_COLOR>.

Returns string in scalar context.
Returns array of string in array context.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Mo::utils::check_bool():
                 Parameter 'mode_ansi' must be a bool (0/1).
                         Value: %s
                 Parameter 'mode_desc' must be a bool (0/1).
                         Value: %s
         From Mo::utils::Language::check_language_639_1():
                 Parameter 'lang' doesn't contain valid ISO 639-1 code.
                         Codeset: %s
                         Value: %s
         Cannot load 'Term::ANSIColor' module.

=head1 EXAMPLE1

=for comment filename=print_data_marc_field008.pl

 use strict;
 use warnings;

 use Data::MARC::Field008;
 use Data::MARC::Field008::Book;
 use MARC::Field008::Print;

 # Print object.
 my $print = MARC::Field008::Print->new(
         'lang' => 'en',
 );

 # Data object.
 my $data_marc_field008 = Data::MARC::Field008->new(
         'cataloging_source' => ' ',
         'date_entered_on_file' => '830304',
         'date1' => '1982',
         'date2' => '    ',
         'language' => 'cze',
         'material' => Data::MARC::Field008::Book->new(
                 'biography' => ' ',
                 'conference_publication' => '0',
                 'festschrift' => '|',
                 'form_of_item' => ' ',
                 'government_publication' => 'u',
                 'illustrations' => 'a   ',
                 'index' => '0',
                 'literary_form' => '|',
                 'nature_of_content' => '    ',
                 #         89012345678901234
                 'raw' => 'a         u0|0 | ',
                 'target_audience' => ' ',
         ),
         'material_type' => 'book',
         'modified_record' => ' ',
         'place_of_publication' => 'xr ',
         #         0123456789012345678901234567890123456789
         'raw' => '830304s1982    xr a         u0|0 | cze  ',
         'type_of_date' => 's',
 );

 # Print to output.
 print scalar $print->print($data_marc_field008), "\n";

 # Output:
 # Date entered on file: 830304
 # Type of date/Publication status: Single known date/probable date
 # Date 1: 1982
 # Date 2:     
 # Place of publication, production, or execution: xr 
 # Material: book
 # Illustrations: Illustrations
 # Target audience: Unknown or not specified
 # Form of item: None of the following
 # Nature of contents: 
 # Government publication: Unknown if item is government publication
 # Conference publication: Not a conference publication
 # Festschrift: No attempt to code
 # Index: No index
 # Literary form: No attempt to code
 # Biography: No biographical material
 # Language: cze
 # Modified record: Not modified
 # Cataloging source: National bibliographic agency

=head1 EXAMPLE2

=for comment filename=print_data_marc_field008_raw.pl

 use strict;
 use warnings;

 use Data::MARC::Field008;
 use Data::MARC::Field008::Book;
 use MARC::Field008::Print;
 use Unicode::UTF8 qw(encode_utf8);

 # Print object.
 my $print = MARC::Field008::Print->new(
         'lang' => 'cs',
         'mode_desc' => 0,
 );

 # Data object.
 my $data_marc_field008 = Data::MARC::Field008->new(
         'cataloging_source' => ' ',
         'date_entered_on_file' => '830304',
         'date1' => '1982',
         'date2' => '    ',
         'language' => 'cze',
         'material' => Data::MARC::Field008::Book->new(
                 'biography' => ' ',
                 'conference_publication' => '0',
                 'festschrift' => '|',
                 'form_of_item' => ' ',
                 'government_publication' => 'u',
                 'illustrations' => 'a   ',
                 'index' => '0',
                 'literary_form' => '|',
                 'nature_of_content' => '    ',
                 #         89012345678901234
                 'raw' => 'a         u0|0 | ',
                 'target_audience' => ' ',
         ),
         'material_type' => 'book',
         'modified_record' => ' ',
         'place_of_publication' => 'xr ',
         #         0123456789012345678901234567890123456789
         'raw' => '830304s1982    xr a         u0|0 | cze  ',
         'type_of_date' => 's',
 );

 # Print to output.
 print encode_utf8(scalar $print->print($data_marc_field008)), "\n";

 # Output:
 # Datum uložení do souboru: 830304
 # Typ data/publikační status: s
 # Datum 1: 1982
 # Datum 2:     
 # Místo vydání, produkce nebo realizace: xr 
 # Materiál: book
 # Ilustrace: a
 # Uživatelské určení:  
 # Forma popisné jednotky:  
 # Povaha obsahu: 
 # Vládní publikace: u
 # Publikace z konference: 0
 # Jubilejní sborník: |
 # Rejstřík: 0
 # Literární forma: |
 # Biografie:  
 # Jazyk dokumentu: cze
 # Modifikace záznamu:  
 # Zdroj katalogizace:

=head1 DEPENDENCIES

L<Check::Term::Color>,
L<Class::Utils>,
L<English>,
L<Error::Pure>.
L<MARC::Field008::L10N>,
L<Mo::utils>,
L<Mo::utils::Language>.

And optional L<Term::ANSIColor> for ANSI color support.

=head1 SEE ALSO

=over

=item L<Data::MARC::Field008>

Data object for MARC field 008.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/MARC-Field008-Print>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025-2026 Michal Josef Špaček

BSD 2-Clause License

=head1 ACKNOWLEDGEMENTS

Development of this software has been made possible by institutional support
for the long-term strategic development of the National Library of the Czech
Republic as a research organization provided by the Ministry of Culture of
the Czech Republic (DKRVO 2024–2028), Area 11: Linked Open Data.

=head1 VERSION

0.01

=cut
