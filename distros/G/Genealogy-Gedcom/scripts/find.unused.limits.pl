#!/usr/bin/env perl

use strict;
use warnings;

use File::Slurper 'read_lines';

# ----------------
# Source of max: Ged551-5.pdf.
# See also Lexer.pm.

my(%max) =
(
 address_city => 60,
 address_country => 60,
 address_email => 120,
 address_fax => 60,
 address_line => 60,
 address_line1 => 60,
 address_line2 => 60,
 address_line3 => 60,
 address_postal_code => 10,
 address_state => 60,
 address_web_page => 120,
 adopted_by_which_parent => 4,
 age_at_event => 12,
 ancestral_file_number => 12,
 approved_system_id => 20,
 attribute_descriptor => 90,
 attribute_type => 4,
 automated_record_id => 12,
 caste_name => 90,
 cause_of_event => 90,
 certainty_assessment => 1,
 change_date => 11,
 character_set => 8,
 child_linkage_status => 15,
 copyright_gedcom_file => 90,
 copyright_source_data => 90,
 count_of_children => 3,
 count_of_marriages => 3,
 date => 35,
 date_approximated => 35,
 date_calendar => 35,
 date_calendar_escape => 15,
 date_exact => 11,
 date_fren => 35,
 date_greg => 35,
 date_hebr => 35,
 date_juln => 35,
 date_lds_ord => 35,
 date_period => 35,
 date_phrase => 35,
 date_range => 35,
 date_value => 35,
 day => 2,
 descriptive_title => 248,
 digit => 1,
 entry_recording_date => 90,
 event_attribute_type => 15,
 event_descriptor => 90,
 event_or_fact_classification => 90,
 event_type_family => 4,
 event_type_individual => 4,
 events_recorded => 90,
 file_name => 90,
 gedcom_content_description => 248,
 gedcom_form => 20,
 generations_of_ancestors => 4,
 generations_of_descendants => 4,
 language_id => 15,
 language_of_text => 15,
 language_preference => 90,
 lds_baptism_date_status => 10,
 lds_child_sealing_date_status => 10,
 lds_endowment_date_status => 10,
 lds_spouse_sealing_date_status => 10,
 multimedia_file_reference => 30,
 multimedia_format => 4,
 name_of_business => 90,
 name_of_family_file => 120,
 name_of_product => 90,
 name_of_repository => 90,
 name_of_source_data => 90,
 name_personal => 120,
 name_phonetic_variation => 120,
 name_piece => 90,
 name_piece_given => 120,
 name_piece_nickname => 30,
 name_piece_prefix => 30,
 name_piece_suffix => 30,
 name_piece_surname => 120,
 name_piece_surname_prefix => 30,
 name_romanized_variation => 120,
 name_text => 120,
 name_type => 30,
 national_id_number => 30,
 national_or_tribal_origin => 120,
 new_tag => 15,
 nobility_type_title => 120,
 null => 0,
 occupation => 90,
 ordinance_process_flag => 3,
 pedigree_linkage_type => 7,
 permanent_record_file_number => 90,
 phone_number => 25,
 phonetic_type => 30,
 physical_description => 248,
 place_hierarchy => 120,
 place_latitude => 8,
 place_living_ordinance => 120,
 place_longitude => 8,
 place_name => 120,
 place_phonetic_variation => 120,
 place_romanized_variation => 120,
 place_text => 120,
 possessions => 248,
 publication_date => 11,
 receiving_system_name => 20,
 record_identifier => 18,
 registered_resource_identifier => 25,
 relation_is_descriptor => 25,
 religious_affiliation => 90,
 responsible_agency => 120,
 restriction_notice => 7,
 role_descriptor => 25,
 role_in_event => 15,
 romanized_type => 30,
 scholastic_achievement => 248,
 sex_value => 7,
 social_security_number => 11,
 source_call_number => 120,
 source_description => 248,
 source_descriptive_title => 248,
 source_filed_by_entry => 60,
 source_jurisdiction_place => 120,
 source_media_type => 15,
 source_originator => 248,
 source_publication_facts => 248,
 submitter_name => 60,
 submitter_registered_rfn => 30,
 submitter_text => 248,
 temple_code => 5,
 text => 248,
 text_from_source => 248,
 time_value => 12,
 transmission_date => 11,
 user_reference_number => 20,
 user_reference_type => 40,
 version_number => 15,
 where_within_source => 248,
 year => 4,
 year_greg => 7,
);
$max{$_}             = 0 for keys %max;
my($input_file_name) = 'lib/Genealogy/Gedcom/Reader/Lexer.pm';
my(@line)            = read_lines($input_file_name);
my($last)            = $#line;

my($id);

for (my $i = 0; $i <= $last; $i++)
{
	if ($line[$i] =~ /^sub tag_(.+)/)
	{
		$id = $1;

		if ($line[$i + 3] =~ /'(.+)'/)
		{
			$max{$id} = 1;

		}
	}
}

print "Unused: \n";

for my $i (sort keys %max)
{
	print "$i\n" if ($max{$i} == 0);
}
