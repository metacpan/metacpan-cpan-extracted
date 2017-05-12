package Genealogy::Gedcom::Reader::Lexer;

use strict;
use warnings;

use Genealogy::Gedcom::Date;

use Log::Handler;

use Moo;

use File::Slurper 'read_lines';

use Set::Array;

use Types::Standard qw/Any ArrayRef Int Str/;

has counter =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has gedcom_data =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has input_file =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has items =>
(
	default  => sub{return Set::Array -> new},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has logger =>
(
	default  => sub{return undef},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has maxlevel =>
(
	default  => sub{return 'notice'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has minlevel =>
(
	default  => sub{return 'error'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has parser =>
(
	default  => sub{return Genealogy::Gedcom::Date -> new},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has report_items =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has result =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has strict =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

our $VERSION = '0.88';

# --------------------------------------------------

sub BUILD
{
	my($self) = @_;

	if (! defined $self -> logger)
	{
		$self -> logger(Log::Handler -> new);
		$self -> logger -> add
		(
			screen =>
			{
				maxlevel       => $self -> maxlevel,
				message_layout => '%m',
				minlevel       => $self -> minlevel,
				utf8           => 1,
			}
		);
	}

} # End of BUILD.

# --------------------------------------------------

sub check_date
{
	my($self, $id, $line) = @_;

	if ($self -> check_length($id, $line) )
	{
		$self -> push_item($line, 'Invalid date');
	}
	else
	{
		my($date) = $self -> parser -> parse(date => $$line[4]);

		$self -> log(debug => "$id: $date");
		$self -> push_item($line, $self -> parser -> error ? 'Invalid date' : 'Date');
	}

} # End of check_date.

# --------------------------------------------------

sub check_date_period
{
	my($self, $id, $line) = @_;

	if ($self -> check_length($id, $line) )
	{
		$self -> push_item($line, 'Invalid date');
	}
	else
	{
		my($date) = $self -> parser -> parse(date => $$line[4]);

		$self -> log(debug => "$id: $date");
		$self -> push_item($line, $self -> parser -> error ? 'Invalid date' : 'Date');
	}

} # End of check_date_period.

# --------------------------------------------------

sub check_exact_date
{
	my($self, $id, $line) = @_;

	if ($self -> check_length($id, $line) )
	{
		$self -> push_item($line, 'Invalid date');
	}
	else
	{
		my($date) = $self -> parser -> parse(date => $$line[4]);

		# This is commented out because log has already been called by the caller.
		# See also the previous 2 methods.

		#$self -> log(debug => "$id: $date");
		$self -> push_item($line, $self -> parser -> error ? 'Invalid date' : 'Date');
	}

} # End of check_exact_date.

# --------------------------------------------------

sub check_length
{
	my($self, $id, $line) = @_;
	$id         =~ s/^tag_//;
	my($value)  = $$line[4];
	my($length) = length($value);
	my($min)    = $self -> get_min_length($id, $line);
	my($max)    = $self -> get_max_length($id, $line);
	my($result) = ( ($length < $min) || ($length > $max) ) ? 1 : 0;

	if ($result)
	{
		$self -> log(warning => "Line: $$line[0]. Field: $id. Value: $value. Length: $length. Valid length range $min .. $max");
	}

	# Return 0 for success and 1 for failure.

	return $result;

} # End of check_length.

# --------------------------------------------------

sub cross_check_xrefs
{
	my($self) = @_;

	my(@link);
	my(%target);

	for my $item (@{$self -> items})
	{
		if ($$item{type} =~ /^Link/)
		{
			push @link, [$$item{data}, $$item{line_count}];
		}

		if ( ($$item{level} == 0) && $$item{xref})
		{
			if ($target{$$item{xref} })
			{
				$self -> log(warning => "Line $$item{line_count}. Xref $$item{xref} was also used on line $target{$$item{xref} }");
			}

			$target{$$item{xref} } = $$item{line_count};
		}
	}

	my(%seen);

	for my $link (@link)
	{
		next if ($seen{$$link[0]});

		$self -> log(warning => "Line $$link[1]. Link $$link[0] does not point to an existing xref") if (! $target{$$link[0]});

		$seen{$$link[0]} = 1;
	}

} # End of cross_check_xrefs.

# --------------------------------------------------

sub get_gedcom_data_from_file
{
	my($self) = @_;

	$self -> gedcom_data([map{s/^\s+//; s/\s+$//; $_} read_lines($self -> input_file)]);

} # End of get_gedcom_data_from_file.

# --------------------------------------------------
# Source of max: Ged551-5.pdf.
# See also scripts/find.unused.limits.pl.

sub get_max_length
{
	my($self, $id, $line) = @_;
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

	# This dies rather than calls log(error...) because it's a coding error if $id is mis-spelt.

	return $max{$id} || die "Error: Line: $$line[0]. Invalid field name in get_max_length($id)";

} # End of get_max_length.

# --------------------------------------------------

sub get_min_length
{
	my($self, $id, $line) = @_;

	return $self -> strict;

} # End of get_min_length.

# --------------------------------------------------

sub get_sub_name
{
	my($self, @caller) = @_;

	# Remove package name prefix from sub name.

	$caller[3] =~ s/^.+:://;

	return $caller[3];

} # End of get_sub_name.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> $level($s) if ($self -> logger);

} # End of log.

# --------------------------------------------------

sub push_item
{
	my($self, $line, $type) = @_;

	$self -> items -> push
		(
		 {
			 count      => $self -> counter($self -> counter + 1),
			 data       => $$line[4],
			 level      => $$line[1],
			 line_count => $$line[0],
			 tag        => $$line[3],
			 type       => $type,
			 xref       => $$line[2],
		 }
		);

} # End of push_item.

# -----------------------------------------------

sub renumber_items
{
	my($self) = @_;
	my(@item) = @{$self -> items};

	my(@new);

	for my $i (0 .. $#item)
	{
		$item[$i]{count} = $i + 1;

		push @new, $item[$i];
	}

	$self -> items(Set::Array -> new(@new) );

} # End of renumber_items.

# -----------------------------------------------

sub report
{
	my($self)   = @_;
	my($format) = '%6s  %6s  %6s  %-6s  %-6s  %-12s  %-s';

	$self -> log(info => sprintf($format, 'Count', 'Line', 'Level', 'Tag', 'Xref', 'Type', 'Data') );

	my(%type);

	for my $item ($self -> items -> print)
	{
		$type{$$item{type} } = 1;

		$self -> log(info => sprintf($format, $$item{count}, $$item{line_count}, $$item{level}, $$item{tag}, $$item{xref}, $$item{type}, $$item{data}) );
	}

} # End of report.

# --------------------------------------------------

sub run
{
	my($self) = @_;

	if ($self -> input_file)
	{
		$self -> get_gedcom_data_from_file;
	}
	else
	{
		my($lines) = $self -> gedcom_data;

		die 'Error: You must provide a GEDCOM file with -input_file, or data with gedcom_data([...])' if ($#$lines < 0);
	}

	my($line)       = [];
	my($line_count) = 0;
	my($result)     = 0; # Default to success.

	for my $record (@{$self -> gedcom_data})
	{
		$line_count++;

		next if ($record =~ /^$/);

		# Arrayref elements:
		# 0: Input file line count.
		# 1: Level.
		# 2: Record id to be used as the target of a xref.
		# 3: Tag.
		# 4: Data belonging to tag.
		# 5: Type (Item/Child of item) of record.
		# 6: Input record.

		if ($record =~ /^(0)\s+\@(.+?)\@\s+(_?(?:[A-Z]{3,4}))\s*(.*)$/)
		{
			push @$line, [$line_count, $1, defined($2) ? $2 : '', $3, defined($4) ? $4 : '', $record];
		}
		elsif ($record =~ /^(0)\s+(HEAD|TRLR)$/)
		{
			push @$line, [$line_count, $1, '', $2, '', $record];
		}
		elsif ($record =~ /^(\d+)\s+(_?(?:ADR[123]|[A-Z]{3,5}))\s*\@?(.*?)\@?$/)
		{
			push @$line, [$line_count, $1, '', $2, defined($3) ? $3 : '', $record];
		}
		else
		{
			die "Error: Line: $line_count. Invalid GEDCOM syntax in '$record'";
		}
	}

	$self -> tag_lineage(0, $line);
	$self -> report if ($self -> report_items);
	$self -> cross_check_xrefs;

	# Return 0 for success and 1 for failure.

	return $result;

} # End of run.

# --------------------------------------------------

sub tag_address_city
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Address');

	return ++$index;

} # End of tag_address_city.

# --------------------------------------------------

sub tag_address_country
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Address');

	return ++$index;

} # End of tag_address_country.

# --------------------------------------------------

sub tag_address_email
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Address');

	return ++$index;

} # End of tag_address_email.

# --------------------------------------------------

sub tag_address_fax
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Address');

	return ++$index;

} # End of tag_address_fax.

# --------------------------------------------------

sub tag_address_line
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Address');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 ADR1 => sub{return $self -> tag_address_line1(shift, shift)},
			 ADR2 => sub{return $self -> tag_address_line2(shift, shift)},
			 ADR3 => sub{return $self -> tag_address_line3(shift, shift)},
			 CITY => sub{return $self -> tag_address_city(shift, shift)},
			 CONT => sub{return $self -> tag_continue(shift, shift)},
			 CTRY => sub{return $self -> tag_address_country(shift, shift)},
			 POST => sub{return $self -> tag_address_postal_code(shift, shift)},
			 STAE => sub{return $self -> tag_address_state(shift, shift)},
		 }
		);

} # End of tag_address_line.

# --------------------------------------------------

sub tag_address_line1
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Address');

	return ++$index;

} # End of tag_address_line1.

# --------------------------------------------------

sub tag_address_line2
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Address');

	return ++$index;

} # End of tag_address_line2.

# --------------------------------------------------

sub tag_address_line3
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Address');

	return ++$index;

} # End of tag_address_line3.

# --------------------------------------------------

sub tag_address_postal_code
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Address');

	return ++$index;

} # End of tag_address_postal_code.

# --------------------------------------------------

sub tag_address_state
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Address');

	return ++$index;

} # End of tag_address_state.

# --------------------------------------------------

sub tag_address_structure
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($index, 'address_line', $$line[$index][4]);
	$self -> push_item($$line[$index], 'Address structure');

	# Special case: $index, not ++$index. We're assumed to be already printing at the tag ADDR.

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 $self -> tag_address_structure_tags(),
		 }
		);

} # End of tag_address_structure.

# --------------------------------------------------

sub tag_address_structure_tags
{
	my($self) = @_;

	return
		(
		 ADDR  => sub{return $self -> tag_address_line(shift, shift)},
		 EMAIL => sub{return $self -> tag_address_email(shift, shift)},
		 FAX   => sub{return $self -> tag_address_fax(shift, shift)},
		 PHON  => sub{return $self -> tag_phone_number(shift, shift)},
		 WWW   => sub{return $self -> tag_address_web_page(shift, shift)},
		);

} # End of tag_address_structure_tags.

# --------------------------------------------------

sub tag_address_web_page
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Address');

	return ++$index;

} # End of tag_address_web_page.

# --------------------------------------------------

sub tag_advance
{
	my($self, $id, $index, $line, $jump) = @_;
	my($level) = $$line[$index][1];
	my($tag)   = $$line[$index][3];

	while ( ($index <= $#$line) && ($$line[$index][1] >= $level) && ($$jump{$$line[$index][3]} || ($$line[$index][3] =~ /^_/) ) )
	{
		if ($$jump{$$line[$index][3]})
		{
			$index = $$jump{$$line[$index][3]} -> ($index, $line);
		}
		else
		{
			$self -> push_item($$line[$index], 'User');

			$index++;
		}
	}

	return $index;

} # End of tag_advance.

# --------------------------------------------------

sub tag_age_at_event
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_age_at_event.

# --------------------------------------------------

sub tag_alias_xref
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Link to INDI');

	return ++$index;

} # End of tag_alias_xref.

# --------------------------------------------------

sub tag_ancestral_file_number
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_ancestral_file_number.

# --------------------------------------------------

sub tag_approved_system_id
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 CORP => sub{return $self -> tag_name_of_business(shift, shift)},
			 DATA => sub{return $self -> tag_name_of_source_data(shift, shift)},
			 NAME => sub{return $self -> tag_name_of_product(shift, shift)},
			 VERS => sub{return $self -> tag_version_number(shift, shift)},
		 }
		);

} # End of tag_approved_system_id.

# --------------------------------------------------

sub tag_association_structure
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Individual');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
			 RELA => sub{return $self -> tag_relation_is_descriptor(shift, shift)},
			 SOUR => sub{return $self -> tag_source_citation(shift, shift)},
		 }
		);

} # End of tag_association_structure.

# --------------------------------------------------

sub tag_automated_record_id
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_automated_record_id.

# --------------------------------------------------

sub tag_bapl_conl
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Individual');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 DATE => sub{return $self -> tag_date_lds_ord(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
			 PLAC => sub{return $self -> tag_place_living_ordinance(shift, shift)},
			 SOUR => sub{return $self -> tag_source_citation(shift, shift)},
			 STAT => sub{return $self -> tag_lds_baptism_date_status(shift, shift)},
			 TEMP => sub{return $self -> tag_temple_code(shift, shift)},
		 }
		);

} # End of tag_bapl_conl.

# --------------------------------------------------

sub tag_caste_name
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return $self -> tag_advance
		(
		 $id,
		 +$index,
		 $line,
		 {
			 DATE => sub{return $self -> tag_change_date1(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
		 }
		);

} # End of tag_caste_name.

# --------------------------------------------------

sub tag_cause_of_event
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Event');

	return ++$index;

} # End of tag_cause_of_event.

# --------------------------------------------------

sub tag_certainty_assessment
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Source');

	return ++$index;

} # End of tag_certainty_assessment.

# --------------------------------------------------

sub tag_change_date
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_exact_date($id, $$line[$index]);

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 TIME => sub{return $self -> tag_time_value(shift, shift)},
		 }
		);

} # End of tag_change_date.

# --------------------------------------------------

sub tag_change_date1
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], '');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 DATE => sub{return $self -> tag_change_date(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
		 }
		);

} # End of tag_change_date1.

# --------------------------------------------------

sub tag_character_set
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Header');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 VERS => sub{return $self -> tag_version_number(shift, shift)},
		 }
		);

} # End of tag_character_set.

# --------------------------------------------------

sub tag_child_xref
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Link to INDI');

	return ++$index;

} # End of tag_child_xref.

# --------------------------------------------------

sub tag_child_linkage_status
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_child_linkage_status.

# --------------------------------------------------

sub tag_child_to_family_link
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Link to FAM');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
			 PEDI => sub{return $self -> tag_pedigree_linkage_type(shift, shift)},
			 STAT => sub{return $self -> tag_child_linkage_status(shift, shift)},
		 }
		);

} # End of tag_child_to_family_link.

# --------------------------------------------------

sub tag_child_to_family_xref
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Link to FAM');

	return ++$index;

} # End of tag_child_to_family_xref.

# --------------------------------------------------

sub tag_concat
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Concat');

	return ++$index;

} # End of tag_concat.

# --------------------------------------------------

sub tag_continue
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Continue');

	return ++$index;

} # End of tag_continue.

# --------------------------------------------------

sub tag_copyright_gedcom_file
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Header');

	return ++$index;

} # End of tag_copyright_gedcom_file.

# --------------------------------------------------

sub tag_copyright_source_data
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Copyright');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 CONC => sub{return $self -> tag_concat(shift, shift)},
			 CONT => sub{return $self -> tag_continue(shift, shift)},
		 }
		);

} # End of tag_copyright_source_data.

# --------------------------------------------------

sub tag_count_of_children
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Family');

	return ++$index;

} # End of tag_child_count.

# --------------------------------------------------

sub tag_count_of_marriages
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Family');

	return ++$index;

} # End of tag_count_of_marriages.

# --------------------------------------------------

sub tag_date_lds_ord
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_date($id, $$line[$index]);

	return ++$index;

} # End of tag_date_lds_ord.

# --------------------------------------------------

sub tag_date_period
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_date_period($id, $$line[$index]);

	return ++$index;

} # End of tag_date_period.

# --------------------------------------------------

sub tag_date_value
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_date($id, $$line[$index]);

	return ++$index;

} # End of tag_date_value.

# --------------------------------------------------

sub tag_descriptive_title
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_descriptive_title.

# --------------------------------------------------

sub tag_endl
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Individual');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 DATE => sub{return $self -> tag_date_lds_ord(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
			 PLAC => sub{return $self -> tag_place_living_ordinance(shift, shift)},
			 SOUR => sub{return $self -> tag_source_citation(shift, shift)},
			 STAT => sub{return $self -> tag_lds_endowment_date_status(shift, shift)},
			 TEMP => sub{return $self -> tag_temple_code(shift, shift)},
		 }
		);

} # End of tag_endl.

# --------------------------------------------------

sub tag_entry_recording_date
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_date($id, $$line[$index]);

	return ++$index;

} # End of tag_entry_recording_date.

# --------------------------------------------------

sub tag_event_detail
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Event');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 $self -> tag_event_detail_tags,
		 }
		);

} # End of tag_event_detail.

# --------------------------------------------------

sub tag_event_detail_tags
{
	my($self) = @_;

	return
		(
		 AGNC => sub{return $self -> tag_responsible_agency(shift, shift)},
		 CAUS => sub{return $self -> tag_cause_of_event(shift, shift)},
		 DATE => sub{return $self -> tag_date_value(shift, shift)},
		 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
		 OBJE => sub{return $self -> tag_multimedia_link(shift, shift)},
		 PLAC => sub{return $self -> tag_place_name(shift, shift)},
		 RELI => sub{return $self -> tag_religious_affiliation(shift, shift)},
		 RESN => sub{return $self -> tag_restriction_notice(shift, shift)},
		 SOUR => sub{return $self -> tag_source_citation(shift, shift)},
		 TYPE => sub{return $self -> tag_event_or_fact_classification(shift, shift)},
		 $self -> tag_address_structure_tags,
		);

} # End of tag_event_detail_tags.

# --------------------------------------------------

sub tag_event_or_fact_classification
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_event_or_fact_classification.

# --------------------------------------------------

sub tag_event_type_cited_from
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Event');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 ROLE => sub{return $self -> tag_role_in_event(shift, shift)},
		 }
		);

} # End of tag_event_type_cited_from.

# --------------------------------------------------

sub tag_events_recorded
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Event');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 DATE => sub{return $self -> tag_date_period(shift, shift)},
			 PLAC => sub{return $self -> tag_source_jurisdiction_place(shift, shift)},
		 }
		);

} # End of tag_events_recorded.

# --------------------------------------------------

sub tag_family_event_detail
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Event');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 HUSB => sub{return $self -> tag_age_at_event(shift, shift)},
			 WIFE => sub{return $self -> tag_age_at_event(shift, shift)},
			 $self -> tag_event_detail_tags,
		 }
		);

} # End of tag_family_event_detail.

# --------------------------------------------------

sub tag_file_name
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'File name');

	return ++$index;

} # End of tag_file_name.

# --------------------------------------------------

sub tag_family_record
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Family');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 ANUL  => sub{return $self -> tag_family_event_detail(shift, shift)},
			 CENS  => sub{return $self -> tag_family_event_detail(shift, shift)},
			 CHAN  => sub{return $self -> tag_change_date1(shift, shift)},
			 CHIL  => sub{return $self -> tag_child_xref(shift, shift)},
			 DIV   => sub{return $self -> tag_family_event_detail(shift, shift)},
			 DIVF  => sub{return $self -> tag_family_event_detail(shift, shift)},
			 ENGA  => sub{return $self -> tag_family_event_detail(shift, shift)},
			 EVEN  => sub{return $self -> tag_family_event_detail(shift, shift)},
			 HUSB  => sub{return $self -> tag_husband_xref(shift, shift)},
			 MARB  => sub{return $self -> tag_family_event_detail(shift, shift)},
			 MARC  => sub{return $self -> tag_family_event_detail(shift, shift)},
			 MARL  => sub{return $self -> tag_family_event_detail(shift, shift)},
			 MARR  => sub{return $self -> tag_family_event_detail(shift, shift)},
			 MARS  => sub{return $self -> tag_family_event_detail(shift, shift)},
			 NCHIL => sub{return $self -> tag_count_of_children(shift, shift)},
			 NOTE  => sub{return $self -> tag_note_structure(shift, shift)},
			 OBJE  => sub{return $self -> tag_multimedia_link(shift, shift)},
			 REFN  => sub{return $self -> tag_user_reference_number(shift, shift)},
			 RESI  => sub{return $self -> tag_family_event_detail(shift, shift)},
			 RESN  => sub{return $self -> tag_restriction_notice(shift, shift)},
			 RIN   => sub{return $self -> tag_rin(shift, shift)},
			 SLGS  => sub{return $self -> tag_lds_spouse_sealing(shift, shift)},
			 SOUR  => sub{return $self -> tag_source_citation(shift, shift)},
			 SUBM  => sub{return $self -> tag_submitter_xref(shift, shift)},
			 WIFE  => sub{return $self -> tag_wife_xref(shift, shift)},
		 }
		);

} # End of tag_family_record.

# --------------------------------------------------

sub tag_gedcom
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Header');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 FORM => sub{return $self -> tag_gedcom_form(shift, shift)},
			 VERS => sub{return $self -> tag_version_number(shift, shift)},
		 }
		);

} # End of tag_gedcom.

# --------------------------------------------------

sub tag_gedcom_form
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_gedcom_form.

# --------------------------------------------------

sub tag_generations_of_ancestors
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Submission');

	return ++$index;

} # End of tag_generations_of_ancestors.

# --------------------------------------------------

sub tag_generations_of_descendants
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Submission');

	return ++$index;

} # End of tag_generations_of_descendants.

# --------------------------------------------------

sub tag_header
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Header');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
		 CHAR => sub{return $self -> tag_character_set(shift, shift)},
		 COPR => sub{return $self -> tag_copyright_gedcom_file(shift, shift)},
		 DATE => sub{return $self -> tag_transmission_date(shift, shift)},
		 DEST => sub{return $self -> tag_receiving_system_name(shift, shift)},
		 FILE => sub{return $self -> tag_file_name(shift, shift)},
		 GEDC => sub{return $self -> tag_gedcom(shift, shift)},
		 LANG => sub{return $self -> tag_language_of_text(shift, shift)},
		 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
		 PLAC => sub{return $self -> tag_place(shift, shift)},
		 SUBM => sub{return $self -> tag_submitter_xref(shift, shift)},
		 SUBN => sub{return $self -> tag_submission_xref(shift, shift)},
		 SOUR => sub{return $self -> tag_approved_system_id(shift, shift)},
		 }
		);

} # End of tag_header.

# --------------------------------------------------

sub tag_husband_xref
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Link to INDI');

	return ++$index;

} # End of tag_husband_xref.

# --------------------------------------------------

sub tag_individual_attribute_detail
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_individual_attribute_detail.

# --------------------------------------------------

sub tag_individual_attribute_structure_tags
{
	my($self) = @_;

	return
		(
		 CAST => sub{return $self -> tag_caste_name(shift, shift)},
		 DSCR => sub{return $self -> tag_physical_description(shift, shift)},
		 EDUC => sub{return $self -> tag_scholastic_achievement(shift, shift)},
		 FACT => sub{return $self -> tag_individual_attribute_detail(shift, shift)},
		 IDNO => sub{return $self -> tag_national_id_number(shift, shift)},
		 NATI => sub{return $self -> tag_national_or_tribal_origin(shift, shift)},
		 NCHI => sub{return $self -> tag_individual_attribute_detail(shift, shift)},
		 NMR  => sub{return $self -> tag_count_of_marriages(shift, shift)},
		 OCCU => sub{return $self -> tag_occupation(shift, shift)},
		 PROP => sub{return $self -> tag_possessions(shift, shift)},
		 RELI => sub{return $self -> tag_individual_attribute_detail(shift, shift)},
		 RESI => sub{return $self -> tag_individual_attribute_detail(shift, shift)},
		 SSN  => sub{return $self -> tag_social_security_number(shift, shift)},
		 TITL => sub{return $self -> tag_nobility_type_title(shift, shift)},
		);

} # End of tag_individual_attribute_structure_tags.

# --------------------------------------------------

sub tag_individual_event_detail
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Event');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 AGE => sub{return $self -> tag_age_at_event(shift, shift)},
			 $self -> tag_event_detail_tags,
		 }
		);

} # End of tag_individual_event_detail.

# --------------------------------------------------

sub tag_individual_event_structure_tags
{
	my($self) = @_;

	return
		(
		 ADOP => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 BAPM => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 BARM => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 BASM => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 BLES => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 BIRT => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 BURI => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 CENS => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 CHAN => sub{return $self -> tag_change_date1(shift, shift)},
		 CHR  => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 CHRA => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 CONF => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 CREM => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 DEAT => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 EMIG => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 EVEN => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 FCOM => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 GRAD => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 IMMI => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 NATU => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 ORDN => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 PROB => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 RETI => sub{return $self -> tag_individual_event_detail(shift, shift)},
		 WILL => sub{return $self -> tag_individual_event_detail(shift, shift)},
		);

} # End of tag_individual_event_structure_tags.

# --------------------------------------------------

sub tag_individual_record
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Individual');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 AFN  => sub{return $self -> tag_ancestral_file_number(shift, shift)},
			 ALIA => sub{return $self -> tag_alias_xref(shift, shift)},
			 ANCI => sub{return $self -> tag_submitter_xref(shift, shift)},
			 ASSO => sub{return $self -> tag_association_structure(shift, shift)},
			 BAPL => sub{return $self -> tag_bapl_conl(shift, shift)},
			 CONL => sub{return $self -> tag_bapl_conl(shift, shift)},
			 DESI => sub{return $self -> tag_submitter_xref(shift, shift)},
			 ENDL => sub{return $self -> tag_endl(shift, shift)},
			 FAMC => sub{return $self -> tag_child_to_family_link(shift, shift)},
			 FAMS => sub{return $self -> tag_spouse_to_family_link(shift, shift)},
			 NAME => sub{return $self -> tag_name_personal(shift, shift)},
			 REFN => sub{return $self -> tag_user_reference_number(shift, shift)},
			 RESN => sub{return $self -> tag_restriction_notice(shift, shift)},
			 RFN  => sub{return $self -> tag_permanent_record_file_number(shift, shift)},
			 RIN  => sub{return $self -> tag_automated_record_id(shift, shift)},
			 SEX  => sub{return $self -> tag_sex_value(shift, shift)},
			 SLGC => sub{return $self -> tag_slgc(shift, shift)},
			 SOUR => sub{return $self -> tag_source_citation(shift, shift)},
			 SUBM => sub{return $self -> tag_submitter_xref(shift, shift)},
			 $self -> tag_individual_attribute_structure_tags,
			 $self -> tag_individual_event_structure_tags,
		 }
		);

} # End of tag_individual_record.

# --------------------------------------------------

sub tag_language_of_text
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Header');

	return ++$index;

} # End of tag_language_of_text.

# --------------------------------------------------

sub tag_language_preference
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Submitter');

	return ++$index;

} # End of tag_language_preference.

# --------------------------------------------------

sub tag_lds_baptism_date_status
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 DATE => sub{return $self -> tag_change_date1(shift, shift)},
		 }
		);

} # End of tag_lds_baptism_date_status.

# --------------------------------------------------

sub tag_lds_child_sealing_date_status
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 DATE => sub{return $self -> tag_change_date1(shift, shift)},
		 }
		);

} # End of tag_lds_child_sealing_date_status.

# --------------------------------------------------

sub tag_lds_endowment_date_status
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 DATE => sub{return $self -> tag_change_date1(shift, shift)},
		 }
		);

} # End of tag_lds_endowment_date_status.

# --------------------------------------------------

sub tag_lds_spouse_sealing
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_date($id, $$line[$index]);

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 DATE => sub{return $self -> tag_date_lds_ord(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
			 PLAC => sub{return $self -> tag_place_living_ordinance(shift, shift)},
			 SOUR => sub{return $self -> tag_source_citation(shift, shift)},
			 STAT => sub{return $self -> tag_lds_spouse_sealing_date_status(shift, shift)},
			 TEMP => sub{return $self -> tag_temple_code(shift, shift)},
		 }
		);

} # End of tag_lds_spouse_sealing.

# --------------------------------------------------

sub tag_lds_spouse_sealing_date_status
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Family');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 DATE => sub{return $self -> tag_change_date1(shift, shift)},
		 }
		);

} # End of tag_lds_spouse_sealing_date_status.

# --------------------------------------------------

sub tag_lineage
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");

	$index = $self -> tag_header($index, $line);
	$index = $self -> tag_advance
		(
		 $id,
		 $index,
		 $line,
		 {
			 SUBN => sub{return $self -> tag_submission_record(shift, shift)},
		 }
		);
	$index = $self -> tag_advance
		(
		 $id,
		 $index,
		 $line,
		 {
			 FAM  => sub{return $self -> tag_family_record(shift, shift)},
			 INDI => sub{return $self -> tag_individual_record(shift, shift)},
			 NOTE => sub{return $self -> tag_note_record(shift, shift)},
			 OBJE => sub{return $self -> tag_multimedia_record(shift, shift)},
			 REPO => sub{return $self -> tag_repository_record(shift, shift)},
			 SOUR => sub{return $self -> tag_source_record(shift, shift)},
			 SUBM => sub{return $self -> tag_submitter_record(shift, shift)},
		 }
		);

	$self -> tag_trailer($index, $line);

} # End of tag_lineage.

# --------------------------------------------------

sub tag_map
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Place');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 LATI => sub{return $self -> tag_place_latitude(shift, shift)},
			 LONG => sub{return $self -> tag_place_longitude(shift, shift)},
		 }
		);

} # End of tag_map.

# --------------------------------------------------

sub tag_multimedia_link
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Link to OBJE');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 FILE => sub{return $self -> tag_multimedia_link_file_refn(shift, shift)},
			 TITL => sub{return $self -> tag_descriptive_title(shift, shift)},
		 }
		);

} # End of tag_multimedia_link.

# --------------------------------------------------

sub tag_multimedia_link_file_refn
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($index, 'multimedia_file_reference', $$line[$index][4]);
	$self -> push_item($$line[$index], 'Multimedia');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 FORM => sub{return $self -> tag_multimedia_link_format(shift, shift)},
		 }
		);

} # End of tag_multimedia_link_file_refn.

# --------------------------------------------------

sub tag_multimedia_link_format
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Multimedia');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 MEDI => sub{return $self -> tag_source_media_type(shift, shift)},
		 }
		);

} # End of tag_multimedia_link_format.

# --------------------------------------------------

sub tag_multimedia_record
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Multimedia');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 CHAN => sub{return $self -> tag_change_date1(shift, shift)},
			 FILE => sub{return $self -> tag_multimedia_record_file_refn(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
			 REFN => sub{return $self -> tag_user_reference_number(shift, shift)},
			 RIN  => sub{return $self -> tag_automated_record_id(shift, shift)},
			 SOUR => sub{return $self -> tag_source_citation(shift, shift)},
		 }
		);

} # End of tag_multimedia_record.

# --------------------------------------------------

sub tag_multimedia_record_file_refn
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($index, 'multimedia_file_reference', $$line[$index][4]);
	$self -> push_item($$line[$index], 'Multimedia');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 FORM => sub{return $self -> tag_multimedia_record_format(shift, shift)},
			 TITL => sub{return $self -> tag_descriptive_title(shift, shift)},
		 }
		);

} # End of tag_multimedia_record_file_refn.

# --------------------------------------------------

sub tag_multimedia_record_format
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Multimedia');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 TYPE => sub{return $self -> tag_source_media_type(shift, shift)},
		 }
		);

} # End of tag_multimedia_record_format.

# --------------------------------------------------

sub tag_name_of_business
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 $self -> tag_address_structure_tags,
		 }
		);

} # End of tag_name_of_business.

# --------------------------------------------------

sub tag_name_of_family_file
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'File name');

	return ++$index;

} # End of tag_name_of_family_file.

# --------------------------------------------------

sub tag_name_of_product
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_name_of_product.

# --------------------------------------------------

sub tag_name_of_repository
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Repository');

	return ++$index;

} # End of tag_name_of_repository.

# --------------------------------------------------

sub tag_name_of_source_data
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Source');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 DATE => sub{return $self -> tag_publication_date(shift, shift)},
			 COPR => sub{return $self -> tag_copyright_source_data(shift, shift)},
		 }
		);

} # End of tag_name_of_source_data.

# --------------------------------------------------

sub tag_name_personal
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 FONE => sub{return $self -> tag_name_phonetic_variation(shift, shift)},
			 ROMN => sub{return $self -> tag_name_romanized_variation(shift, shift)},
			 TYPE => sub{return $self -> tag_name_type(shift, shift)},
			 $self -> tag_personal_name_piece_tags,
		 }
		);

} # End of tag_name_personal.

# --------------------------------------------------

sub tag_name_phonetic_variation
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 TYPE => sub{return $self -> tag_phonetic_type(shift, shift)},
			 $self -> tag_personal_name_piece_tags,
		 }
		);

} # End of tag_name_phonetic_variation.

# --------------------------------------------------

sub tag_name_piece_given
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_name_piece_given.

# --------------------------------------------------

sub tag_name_piece_nickname
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_name_piece_nickname.

# --------------------------------------------------

sub tag_name_piece_prefix
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_name_piece_prefix.

# --------------------------------------------------

sub tag_name_piece_suffix
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_name_piece_suffix.

# --------------------------------------------------

sub tag_name_piece_surname
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_name_piece_surname.

# --------------------------------------------------

sub tag_name_piece_surname_prefix
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_name_piece_surname_prefix.

# --------------------------------------------------

sub tag_name_romanized_variation
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 TYPE => sub{return $self -> tag_romanized_type(shift, shift)},
			 $self -> tag_personal_name_piece_tags,
		 }
		);

} # End of tag_name_romanized_variation.

# --------------------------------------------------

sub tag_name_type
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_name_type.

# --------------------------------------------------

sub tag_national_or_tribal_origin
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_national_or_tribal_origin.

# --------------------------------------------------

sub tag_national_id_number
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_national_id_number.

# --------------------------------------------------

sub tag_nobility_type_title
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_nobility_type_title.

# --------------------------------------------------

sub tag_note_record
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Note');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 CHAN => sub{return $self -> tag_change_date1(shift, shift)},
			 CONC => sub{return $self -> tag_concat(shift, shift)},
			 CONT => sub{return $self -> tag_continue(shift, shift)},
			 REFN => sub{return $self -> tag_user_reference_number(shift, shift)},
			 RIN  => sub{return $self -> tag_automated_record_id(shift, shift)},
			 SOUR => sub{return $self -> tag_source_citation(shift, shift)},
		 }
		);

} # End of tag_note_record.

# --------------------------------------------------

sub tag_note_structure
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Note');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 CONC => sub{return $self -> tag_concat(shift, shift)},
			 CONT => sub{return $self -> tag_continue(shift, shift)},
		 }
		);

} # End of tag_note_structure.

# --------------------------------------------------

sub tag_occupation
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_occupation.

# --------------------------------------------------

sub tag_ordinance_process_flag
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Submission');

	return ++$index;

} # End of tag_ordinance_process_flag.

# --------------------------------------------------

sub tag_pedigree_linkage_type
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_pedigree_linkage_type.

# --------------------------------------------------

sub tag_permanent_record_file_number
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_permanent_record_file_number.

# --------------------------------------------------

sub tag_personal_name_piece_tags
{
	my($self) = @_;

	return
		(
		 GIVN => sub{return $self -> tag_name_piece_given(shift, shift)},
		 NICK => sub{return $self -> tag_name_piece_nickname(shift, shift)},
		 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
		 NPFX => sub{return $self -> tag_name_piece_prefix(shift, shift)},
		 NSFX => sub{return $self -> tag_name_piece_suffix(shift, shift)},
		 SOUR => sub{return $self -> tag_source_citation(shift, shift)},
		 SPFX => sub{return $self -> tag_name_piece_surname_prefix(shift, shift)},
		 SURN => sub{return $self -> tag_name_piece_surname(shift, shift)},
		);

} # End of tag_personal_name_piece_tags.

# --------------------------------------------------

sub tag_personal_name_pieces
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Individual');

	# Special case. $index not ++$index.

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 $self -> tag_personal_name_piece_tags
		 }
		);

} # End of tag_personal_name_pieces.

# --------------------------------------------------

sub tag_phone_number
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_phone_number.

# --------------------------------------------------

sub tag_phonetic_type
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_phonetic_type.

# --------------------------------------------------

sub tag_physical_description
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_physical_description.

# --------------------------------------------------

sub tag_place
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Place');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 FORM => sub{return $self -> tag_place_hierarchy(shift, shift)},
		 }
		);

} # End of tag_place.

# --------------------------------------------------

sub tag_place_hierarchy
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Place');

	return ++$index;

} # End of tag_place_hierarchy.

# --------------------------------------------------

sub tag_place_latitude
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Place');

	return ++$index;

} # End of tag_place_latitude.

# --------------------------------------------------

sub tag_place_living_ordinance
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Place');

	return ++$index;

} # End of tag_place_living_ordinance.

# --------------------------------------------------

sub tag_place_longitude
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Place');

	return ++$index;

} # End of tag_place_longitude.

# --------------------------------------------------

sub tag_place_name
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Place');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 FORM => sub{return $self -> tag_place_hierarchy(shift, shift)},
			 FONE => sub{return $self -> tag_place_phonetic_variation(shift, shift)},
			 MAP  => sub{return $self -> tag_map(shift, shift)},
			 ROMN => sub{return $self -> tag_place_romanized_variation(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
		 }
		);

} # End of tag_place_name.

# --------------------------------------------------

sub tag_place_phonetic_variation
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Place');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 TYPE => sub{return $self -> tag_phonetic_type(shift, shift)},
		 }
		);

} # End of tag_place_phonetic_variation.

# --------------------------------------------------

sub tag_place_romanized_variation
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Place');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 TYPE => sub{return $self -> tag_romanized_type(shift, shift)},
		 }
		);

} # End of tag_place_romanized_variation.

# --------------------------------------------------

sub tag_possessions
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_possessions.

# --------------------------------------------------

sub tag_publication_date
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_exact_date($id, $$line[$index]);

	return ++$index;

} # End of tag_publication_date.

# --------------------------------------------------

sub tag_receiving_system_name
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Header');

	return ++$index;

} # End of tag_receiving_system_name.

# --------------------------------------------------

sub tag_relation_is_descriptor
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_relation_is_descriptor.

# --------------------------------------------------

sub tag_religious_affiliation
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_religious_affiliation.

# --------------------------------------------------

sub tag_repository_record
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Repository');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 CHAN => sub{return $self -> tag_change_date1(shift, shift)},
			 NAME => sub{return $self -> tag_name_of_repository(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
			 REFN => sub{return $self -> tag_user_reference_number(shift, shift)},
			 RIN  => sub{return $self -> tag_automated_record_id(shift, shift)},
			 $self -> tag_address_structure_tags,
		 }
		);

} # End of tag_repository_record.

# --------------------------------------------------

sub tag_responsible_agency
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Source');

	return ++$index;

} # End of tag_responsible_agency.

# --------------------------------------------------

sub tag_restriction_notice
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_restriction_notice.

# --------------------------------------------------

sub tag_rin
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_rin.

# --------------------------------------------------

sub tag_role_in_event
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Source');

	return ++$index;

} # End of tag_role_in_event.

# --------------------------------------------------

sub tag_romanized_type
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_romanized_type.

# --------------------------------------------------

sub tag_scholastic_achievement
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_scholastic_achievement.

# --------------------------------------------------

sub tag_sex_value
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_sex_value.

# --------------------------------------------------

sub tag_slgc
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Individual');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 DATE => sub{return $self -> tag_date_lds_ord(shift, shift)},
			 FAMC => sub{return $self -> tag_child_to_family_xref(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
			 PLAC => sub{return $self -> tag_place_living_ordinance(shift, shift)},
			 SOUR => sub{return $self -> tag_source_citation(shift, shift)},
			 STAT => sub{return $self -> tag_lds_child_sealing_date_status(shift, shift)},
			 TEMP => sub{return $self -> tag_temple_code(shift, shift)},
		 }
		);

} # End of tag_slgc.

# --------------------------------------------------

sub tag_social_security_number
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Individual');

	return ++$index;

} # End of tag_social_security_number.

# --------------------------------------------------

sub tag_source_call_number
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Source');

	return ++$index;

} # End of tag_source_call_number.

# --------------------------------------------------

sub tag_source_citation
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Source');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 CONC => sub{return $self -> tag_concat(shift, shift)},
			 CONT => sub{return $self -> tag_continue(shift, shift)},
			 DATA => sub{return $self -> tag_source_citation_data(shift, shift)},
			 EVEN => sub{return $self -> tag_event_type_cited_from(shift, shift)},
			 OBJE => sub{return $self -> tag_multimedia_link(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
			 PAGE => sub{return $self -> tag_where_within_source(shift, shift)},
			 QUAY => sub{return $self -> tag_certainty_assessment(shift, shift)},
			 TEXT => sub{return $self -> tag_text_from_source(shift, shift)},
		 }
		);

} # End of tag_source_citation.

# --------------------------------------------------

sub tag_source_citation_data
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Source');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 DATE => sub{return $self -> tag_entry_recording_date(shift, shift)},
			 TEXT => sub{return $self -> tag_text_from_source(shift, shift)},
		 }
		);

} # End of tag_source_citation_data.

# --------------------------------------------------

sub tag_source_data
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Source');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 AGNC => sub{return $self -> tag_responsible_agency(shift, shift)},
			 EVEN => sub{return $self -> tag_events_recorded(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
		 }
		);

} # End of tag_source_data.

# --------------------------------------------------

sub tag_source_descriptive_title
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Source');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 CONC => sub{return $self -> tag_concat(shift, shift)},
			 CONT => sub{return $self -> tag_continue(shift, shift)},
		 }
		);

} # End of tag_source_descriptive_title.

# --------------------------------------------------

sub tag_source_filed_by_entry
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Source');

	return ++$index;

} # End of tag_source_filed_by_entry.

# --------------------------------------------------

sub tag_source_jurisdiction_place
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Source');

	return ++$index;

} # End of tag_source_jurisdiction_place.

# --------------------------------------------------

sub tag_source_media_type
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Source');

	return ++$index;

} # End of tag_source_media_type.

# --------------------------------------------------

sub tag_source_originator
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Source');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 CONC => sub{return $self -> tag_concat(shift, shift)},
			 CONT => sub{return $self -> tag_continue(shift, shift)},
		 }
		);

} # End of tag_source_originator.

# --------------------------------------------------

sub tag_source_publication_date
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Source');

	return ++$index;

} # End of tag_source_publication_date.

# --------------------------------------------------

sub tag_source_publication_facts
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Source');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 CONC => sub{return $self -> tag_concat(shift, shift)},
			 CONT => sub{return $self -> tag_continue(shift, shift)},
		 }
		);

} # End of tag_source_publication_facts.

# --------------------------------------------------

sub tag_source_record
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Source');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 ABBR => sub{return $self -> tag_source_filed_by_entry(shift, shift)},
			 AUTH => sub{return $self -> tag_source_originator(shift, shift)},
			 CHAN => sub{return $self -> tag_change_date1(shift, shift)},
			 DATA => sub{return $self -> tag_source_record_data(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
			 OBJE => sub{return $self -> tag_multimedia_link(shift, shift)},
			 PUBL => sub{return $self -> tag_source_publication_facts(shift, shift)},
			 REFN => sub{return $self -> tag_user_reference_number(shift, shift)},
			 RIN  => sub{return $self -> tag_automated_record_id(shift, shift)},
			 REPO => sub{return $self -> tag_source_repository_citation(shift, shift)},
			 TEXT => sub{return $self -> tag_text_from_source(shift, shift)},
			 TITL => sub{return $self -> tag_source_descriptive_title(shift, shift)},
		 }
		);

} # End of tag_source_record.

# --------------------------------------------------

sub tag_source_record_data
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Source');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 AGNC => sub{return $self -> tag_responsible_agency(shift, shift)},
			 EVEN => sub{return $self -> tag_events_recorded(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
		 }
		);

} # End of tag_source_record_data.

# --------------------------------------------------

sub tag_spouse_to_family_link
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Link to FAM');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
		 }
		);

} # End of tag_spouse_to_family_link.

# --------------------------------------------------

sub tag_submission_record
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Link to SUBM');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 ANCE => sub{return $self -> tag_generations_of_ancestors(shift, shift)},
			 DESC => sub{return $self -> tag_generations_of_descendants(shift, shift)},
			 FAMF => sub{return $self -> tag_name_of_family_file(shift, shift)},
			 ORDI => sub{return $self -> tag_ordinance_process_flag(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
			 RIN  => sub{return $self -> tag_rin(shift, shift)},
			 SUBM => sub{return $self -> tag_submitter_xref(shift, shift)},
			 TEMP => sub{return $self -> tag_temple_code(shift, shift)},
		 }
		);

} # End of tag_submission_record.

# --------------------------------------------------

sub tag_submission_repository_citation
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Submission');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 CALN => sub{return $self -> tag_source_call_number(shift, shift)},
			 MEDI => sub{return $self -> tag_source_media_type(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
		 }
		);

} # End of tag_submission_repository_citation.

# --------------------------------------------------

sub tag_submission_xref
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Submission');

	return ++$index;

} # End of tag_submission_xref.

# --------------------------------------------------

sub tag_submitter_record
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Submitter');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 CHAN => sub{return $self -> tag_change_date1(shift, shift)},
			 LANG => sub{return $self -> tag_language_preference(shift, shift)},
			 NAME => sub{return $self -> tag_submitter_name(shift, shift)},
			 NOTE => sub{return $self -> tag_note_structure(shift, shift)},
			 OBJE => sub{return $self -> tag_multimedia_link(shift, shift)},
			 RFN  => sub{return $self -> tag_submitter_registered_rfn(shift, shift)},
			 RIN  => sub{return $self -> tag_rin(shift, shift)},
			 $self -> tag_address_structure_tags,
		 }
		);

} # End of tag_submitter_record.

# --------------------------------------------------

sub tag_submitter_registered_rfn
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Submitter');

	return ++$index;

} # End of tag_rfn.

# --------------------------------------------------

sub tag_submitter_name
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Submission');

	return ++$index;

} # End of tag_submitter_name.

# --------------------------------------------------

sub tag_submitter_xref
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Submission');

	return ++$index;

} # End of tag_submitter_xref.

# --------------------------------------------------

sub tag_temple_code
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_temple_code.

# --------------------------------------------------

sub tag_text_from_source
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 CONC => sub{return $self -> tag_concat(shift, shift)},
			 CONT => sub{return $self -> tag_continue(shift, shift)},
		 }
		);

} # End of tag_text_from_source.

# --------------------------------------------------

sub tag_time_value
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_time_value.

# --------------------------------------------------

sub tag_trailer
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> log(warning => "Line: $$line[$index][0]. The unknown tag $$line[$index][3] was detected") if ($$line[$index][3] ne 'TRLR');
	$self -> push_item($$line[$index], 'Trailer');

	return ++$index;

} # End of tag_trailer.

# --------------------------------------------------

sub tag_transmission_date
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_exact_date($id, $$line[$index]);

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 TIME => sub{return $self -> tag_time_value(shift, shift)},
		 }
		);

} # End of tag_transmission_date.

# --------------------------------------------------

sub tag_user_reference_number
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return $self -> tag_advance
		(
		 $id,
		 ++$index,
		 $line,
		 {
			 TYPE => sub{return $self -> tag_user_reference_type(shift, shift)},
		 }
		);

} # End of tag_user_reference_number.

# --------------------------------------------------

sub tag_user_reference_type
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_user_reference_type.

# --------------------------------------------------

sub tag_version_number
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], '');

	return ++$index;

} # End of tag_version_number.

# --------------------------------------------------

sub tag_where_within_source
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> check_length($id, $$line[$index]);
	$self -> push_item($$line[$index], 'Source');

	return ++$index;

} # End of tag_page.

# --------------------------------------------------

sub tag_wife_xref
{
	my($self, $index, $line) = @_;
	my($id) = $self -> get_sub_name(caller 0);

	$self -> log(debug => "$id($$line[$index][0], '$$line[$index][5]')");
	$self -> push_item($$line[$index], 'Link to INDI');

	return ++$index;

} # End of tag_wife_xref.

# --------------------------------------------------

1;

=pod

=head1 NAME

L<Genealogy::Gedcom::Reader::Lexer> - An OS-independent lexer for GEDCOM data

=head1 Synopsis

Run scripts/lex.pl -help.

A typical run would be:

perl -Ilib scripts/lex.pl -i data/royal.ged -r 1 -s 1

Turn on debugging prints with:

perl -Ilib scripts/lex.pl -i data/royal.ged -r 1 -s 1 -max debug

royal.ged was downloaded from L<http://www.vjet.f2s.com/ftree/download.html>. It's more up-to-date than the one shipped with L<Gedcom>.

Various sample GEDCOM files may be found in the data/ directory in the distro.

=head1 Description

L<Genealogy::Gedcom::Reader::Lexer> provides a lexer for GEDCOM data.

See L<the GEDCOM Specification Ged551-5.pdf|http://wiki.webtrees.net/en/Main_Page>.

=head1 Installation

Install L<Genealogy::Gedcom> as you would for any C<Perl> module:

Run:

	cpanm Genealogy::Gedcom

or run:

	sudo cpan Genealogy::Gedcom

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($lexer) = Genealogy::Gedcom::Reader::Lexer -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Genealogy::Gedcom::Reader::Lexer>.

Key-value pairs accepted in the parameter list (see corresponding methods for details [e.g. input_file()]):

=over 4

=item o input_file => $gedcom_file_name

Read the GEDCOM data from this file.

Default: ''.

=item o logger => $logger_object

Specify a logger object.

To disable logging, just set logger to the empty string.

Default: An object of type L<Log::Handler>.

=item o maxlevel => $level

This option is only used if the lexer creates an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

Default: 'info'.

Log levels are, from highest (i.e. most output) to lowest: 'debug', 'info', 'warning', 'error'. No lower levels are used.

=item o minlevel => $level

This option is only used if the lexer creates an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

Default: 'error'.

=item o report_items => $Boolean

=over 4

=item o 0 => Report nothing

=item o 1 => Call L</report()> to report, via the log, the items recognized by the lexer

This output is at log level 'info'.

=back

Default: 0.

=item o strict => $Boolean

Specifies lax or strict string length checking during validation.

=over 4

=item o 0 => String lengths can be 0, allowing blank NOTE etc records

=item o 1 => String lengths must be > 0, as per the GEDCOM Specification

Note: A string of length 1 - e.g. '0' - might still be an error.

=back

Default: 0.

The upper lengths on strings are always as per the GEDCOM Specification.
See L</get_max_length($id, $line)> for details.

String lengths out of range (as with all validation failures) are reported as log messages at level 'warning'.

=back

=head1 Methods

=head2 check_date($id, $line)

Checks the date field in the input arrayref $line, $$line[4].

$id identifies what type of record the $line is expected to be.

=head2 check_length($id, $line)

Checks the length of the data component (after the tag) on the input arrayref $line, $$line[4].

$id identifies what type of record the $line is expected to be.

=head2 cross_check_xrefs

Ensure that all xrefs point to existing records.

See L<FAQ/What validation is performed?> for details.

=head2 get_gedcom_from_file()

If the caller has requested GEDCOM data be read from a file, with the input_file option to new(), this method reads that file.

Called as appropriate by L</run()>, if you do not suppy data with L</gedcom_data([$gedcom_data])>.

=head2 gedcom_data([$gedcom_data])

The [] indicate an optional parameter.

Get or set the arrayref of GEDCOM records to be processed.

This is normally only used internally, but can be used to bypass reading from a file.

Note: If supplying data this way rather than via the file, you must strip newlines etc on every line, as well as leading and trailing blanks.

=head2 get_max_length($id, $line)

Get the maximum string length of the data component (after the tag) on the given $line.

$id identifies what type of record the $line is expected to be.

=head2 get_min_length($id, $line)

Get the minimum string length of the data component (after the tag) on the given $line.

Currently, this value is actually the value of strict(), i.e. 0 or 1.

$id identifies what type of record the $line is expected to be.

=head2 input_file([$gedcom_file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file to read the GEDCOM data from.

=head2 items()

Returns a object of type L<Set::Array>, which is an arrayref of items output by the lexer.

See the L</FAQ> for details.

=head2 log($level, $s)

Calls $self -> logger -> $level($s).

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set logger to the empty string.

=head2 maxlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if the lexer creates an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

=head2 minlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if the lexer creates an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

=head2 push_item($line, $type)

Pushes a hashref of components of the $line, with type $type, onto the arrayref of items returned by L</items()>.

See the L</FAQ> for details.

=head2 renumber_items()

Scan the arrayref of hashrefs returned by items() and ensure the 'count' field is ok.

This is done in case array elements have been combined, e.g. when processing CONCs and CONTs for NOTEs.

=head2 report()

Report, via the log, the list of items recognized by the lexer.

=head2 report_items([0 or 1])

The [] indicate an optional parameter.

Get or set the value which determines whether or not to report the items recognised by the lexer.

=head2 run()

This is the only method the caller needs to call. All parameters are supplied to new(), or via previous calls to various methods.

Returns 0 for success and 1 for failure.

=head2 strict([0 or 1])

The [] indicate an optional parameter.

Get or set the value which determines whether or not to use 0 or 1 as the minimum string length.

=head1 FAQ

See L<Genealogy::Gedcom/FAQ>.

=head1 Repository

L<https://github.com/ronsavage/Genealogy-Gedcom>

=head1 See Also

L<Genealogy::Gedcom::Date>.

L<Gedcom::Date>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 References

=over 4

=item o The original Perl L<Gedcom>

=item o GEDCOM

=over 4

=item o L<GEDCOM Specification|http://wiki.webtrees.net/en/Main_Page>

=item o L<GEDCOM Validation|http://www.tamurajones.net/GEDCOMValidation.xhtml>

=item o L<GEDCOM Tags|http://www.tamurajones.net/GEDCOMTags.xhtml>

=back

=item o Usage of non-standard tags

=over 4

=item o L<http://www.tamurajones.net/FTWTEXT.xhtml>

This is apparently the worst offender he's seen. Search that page for 'tags'.

=item o L<http://www.tamurajones.net/GenoPro2011.xhtml>

=item o L<http://www.tamurajones.net/GenoPro2007.xhtml>

=item o L<http://www.tamurajones.net/TheFTWTEXTProblem.xhtml>

=back

=item o Other articles on Tamura's site

=over 4

=item o L<http://www.tamurajones.net/FiveFreakyFeaturesYourGenealogySoftwareShouldNotHave.xhtml>

=item o L<http://www.tamurajones.net/TwelveOrdinaryMustHaveGenealogySoftwareFeatures.xhtml>

=back

=item o Other projects

Many of these are discussed on Tamura's site.

=over 4

=item o L<http://bettergedcom.wikispaces.com/>

=item o L<http://www.ngsgenealogy.org/cs/GenTech_Projects>

=item o L<http://gdmxml.fugal.net/>

=item o L<http://www.cosoft.org/genxml/>

=item o L<http://www.sunflower.com/~billk/GEDC/>

=item o L<http://ancestorsnow.blogspot.com/2011/07/vged.html>

=item o L<http://www.tamurajones.net/GEDCOMValidation.xhtml>

=item o L<http://webtrees.net/>

=item o L<http://swoodbridge.com/Genealogy/lifelines/>

=item o L<http://deadendssoftware.blogspot.com/>

=item o L<http://www.legacyfamilytree.com/>

=item o L<https://devnet.familysearch.org/docs/api-overview>

=back

=back

=head1 The Gedcom Mailing List

Contact perl-gedcom-help@perl.org.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy::Gedcom>.

=head1 Author

L<Genealogy::Gedcom::Reader::Lexer> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
