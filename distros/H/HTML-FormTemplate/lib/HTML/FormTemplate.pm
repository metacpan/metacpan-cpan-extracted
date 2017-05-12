=head1 NAME

HTML::FormTemplate - Make data-defined persistant forms, reports

=cut

######################################################################

package HTML::FormTemplate;
require 5.004;

# Copyright (c) 1999-2004, Darren R. Duncan.  All rights reserved.  This module
# is free software; you can redistribute it and/or modify it under the same terms
# as Perl itself.  However, I do request that this copyright information and
# credits remain attached to the file.  If you modify this module and
# redistribute a changed version then please attach a note listing the
# modifications.  This module is available "as-is" and the author can not be held
# accountable for any problems resulting from its use.

use strict;
use warnings;
use vars qw($VERSION @ISA);
$VERSION = '2.03';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	Class::ParamParser 1.041
	HTML::EasyTags 1.071
	Data::MultiValuedHash 1.081
	CGI::MultiValuedHash 1.09

=cut

######################################################################

use Class::ParamParser 1.041;
@ISA = qw( Class::ParamParser );
use HTML::EasyTags 1.071;
use Data::MultiValuedHash 1.081;
use CGI::MultiValuedHash 1.09;

######################################################################

=head1 SYNOPSIS

	#!/usr/bin/perl
	use strict;
	use warnings;

	use HTML::FormTemplate;
	use HTML::EasyTags;

	my @definitions = (
		{
			visible_title => "What's your name?",
			type => 'textfield',
			name => 'name',
			is_required => 1,
		}, {
			visible_title => "What's the combination?",
			type => 'checkbox_group',
			name => 'words',
			'values' => ['eenie', 'meenie', 'minie', 'moe'],
			default => ['eenie', 'minie'],
		}, {
			visible_title => "What's your favorite colour?",
			type => 'popup_menu',
			name => 'color',
			'values' => ['red', 'green', 'blue', 'chartreuse'],
		}, {
			type => 'submit', 
		},
	);

	my $query_string = '';
	read( STDIN, $query_string, $ENV{'CONTENT_LENGTH'} );
	chomp( $query_string );

	my $form = HTML::FormTemplate->new();
	$form->form_submit_url( 
		'http://'.($ENV{'HTTP_HOST'} || '127.0.0.1').$ENV{'SCRIPT_NAME'} );
	$form->field_definitions( \@definitions );
	$form->user_input( $query_string );

	my ($mail_worked, $mail_failed);
	unless( $form->new_form() ) {
		if( open( MAIL, "|/usr/lib/sendmail -t") ) {
			print MAIL "To: perl\@DarrenDuncan.net\n";
			print MAIL "From: perl\@DarrenDuncan.net\n";
			print MAIL "Subject: A Simple Example HTML::FormTemplate Submission\n";
			print MAIL "\n";
			print MAIL $form->make_text_input_echo()."\n";
			close ( MAIL );
			$mail_worked = 1;
		} else {
			$mail_failed = 1;
		}
	}

	my $tagmaker = HTML::EasyTags->new();

	print
		"Status: 200 OK\n",
		"Content-type: text/html\n\n",
		$tagmaker->start_html( 'A Simple Example' ),
		$tagmaker->h1( 'A Simple Example' ),
		$form->make_html_input_form( 1 ),
		$tagmaker->hr,
		$form->new_form() ? '' : $form->make_html_input_echo( 1 ),
		$mail_worked ? "<p>Your favorites were emailed.</p>\n" : '',
		$mail_failed ? "<p>Error emailing your favorites.</p>\n" : '',
		$tagmaker->end_html;

=head1 DESCRIPTION

This Perl 5 object class can create web fill-out forms as well as parse,
error-check, and report their contents.  Forms can start out blank or with
initial values, or by repeating the user's last input values.  Facilities for
interactive user-input-correction are also provided.

The class is designed so that a form can be completely defined, using
field_definitions(), before any html is generated or any error-checking is done. 
For that reason, a form can be generated multiple times, each with a single
function call, while the form only has to be defined once.  Form descriptions can
optionally be read from a file by the calling code, making that code a lot more
generic and robust than code which had to define the field manually.

=head1 OVERVIEW

If the calling code provides a MultiValuedHash object or HASH ref containing the
parsed user input from the last time the form was submitted, via user_input(),
then the newly generated form will incorporate that, making the entered values
persistant. Since the calling code has control over the provided "user input",
they can either get it live or read it from a file, which is transparent to us. 
This makes it easy to make programs that allow the user to "come back later" and
continue editing where they left off, or to seed a form with initial values.
(Field definitions can also contain initial values.)

Based on the provided field definitions, this module can do some limited user
input checking, and automatically generate error messages and help text beside
the appropriate form fields when html is generated, so to show the user exactly
what they have to fix.  The "error state" for each field is stored in a hash,
which the calling code can obtain and edit using invalid_input(), so that results
of its own input checking routines are reflected in the new form.

This class also provides utility methods that you can use to create form field 
definitions that, when fed back to this class, generates field html that can be 
used by CGI scripts to allow users with their web browsers to define other form 
definitions for use with this class.

Note that this class is a subclass of Class::ParamParser, and inherits
all of its methods, "params_to_hash()" and "params_to_array()".

=head1 RECOGNIZED FORM FIELD TYPES

This class recognizes 10 form field types, and a complete field of that type can
be made either by providing a "field definition" with the same "type" attribute
value, or by calling a method with the same name as the field type.  Likewise,
groups of related form fields can be made with either a single field definition
or method call, for all of those field types.

Standalone fields of the following types are recognized:

=over 4

=item 0

B<reset> - makes a reset button

=item 0

B<submit> - makes a submit button

=item 0

B<hidden> - makes a hidden field, which the user won't see

=item 0

B<textfield> - makes a text entry field, one row high

=item 0

B<password_field> - same as textfield except contents are bulleted out

=item 0

B<textarea> - makes a big text entry field, several rows high

=item 0

B<checkbox> - makes a standalone check box

=item 0

B<radio> - makes a standalone radio button

=item 0

B<popup_menu> - makes a popup menu, one item can be selected at once

=item 0

B<scrolling_list> - makes a scrolling list, multiple selections possible

=back

Groups of related fields of the following types are recognized:

=over 4

=item 0

B<reset_group> - makes a group of related reset buttons

=item 0

B<submit_group> - makes a group of related submit buttons

=item 0

B<hidden_group> - makes a group of related hidden fields

=item 0

B<textfield_group> - makes a group of related text entry fields

=item 0

B<password_field_group> - makes a group of related password fields

=item 0

B<textarea_group> - makes a group of related big text entry fields

=item 0

B<checkbox_group> - makes a group of related checkboxes

=item 0

B<radio_group> - makes a group of related radio buttons

=item 0

B<popup_menu_group> - makes a group of related popup menus

=item 0

B<scrolling_list_group> - makes a group of related scrolling lists

=back

Other field types aren't intrinsically recognized, but can still be generated as
ordinary html tags by using methods of the HTML::EasyTags class.  A list of all
the valid field types is returned by the valid_field_type_list() method.

=head1 BUGS

There is a known issue where the W3C html validator has problems with the 
generated form code, such as saying hidden fields aren't allowed where they 
are put, as well as saying that "input" tags should be in a pair.  Hopefully a 
solution for these issues will present itself soon and be in the next release.  
However, web browsers like Netscape 4.08 still display the HTML properly.

=head1 OUTPUT FROM SYNOPSIS PROGRAM

=head2 This HTML code is from the first time the program runs:

	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN">
	<html>
	<head>
	<title>A Simple Example</title>
	</head>
	<body>
	<h1>A Simple Example</h1>
	<form method="post" action="http://nyxmydomain/dir/script.pl">
	<table>
	<input type="hidden" name=".is_submit" value="1" />
	<tr>
	<td>
	*</td> 
	<td>
	<strong>What's your name?:</strong></td> 
	<td>
	<input type="text" name="name" /></td></tr>

	<tr>
	<td></td> 
	<td>
	<strong>What's the combination?:</strong></td> 
	<td>
	<input type="checkbox" name="words" checked="1" value="eenie" />eenie
	<input type="checkbox" name="words" value="meenie" />meenie
	<input type="checkbox" name="words" checked="1" value="minie" />minie
	<input type="checkbox" name="words" value="moe" />moe</td></tr>

	<tr>
	<td></td> 
	<td>
	<strong>What's your favorite colour?:</strong></td> 
	<td>
	<select name="color" size="1">
	<option value="red" />red
	<option value="green" />green
	<option value="blue" />blue
	<option value="chartreuse" />chartreuse
	</select></td></tr>

	<tr>
	<td></td> 
	<td></td> 
	<td>
	<input type="submit" name="nonamefield001" /></td></tr>

	</table>
	</form>
	<hr />
	</body>
	</html>

=head2 This HTML code is the result page of clicking the submit button:

	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN">
	<html>
	<head>
	<title>A Simple Example</title>
	</head>
	<body>
	<h1>A Simple Example</h1>
	<form method="post" action="http://nyxmydomain/dir/script.pl">
	<table>
	<input type="hidden" name=".is_submit" value="1" />
	<tr>
	<td>
	*</td> 
	<td>
	<strong>What's your name?:</strong></td> 
	<td>
	<input type="text" name="name" value="This Is My Name" /></td></tr>

	<tr>
	<td></td> 
	<td>
	<strong>What's the combination?:</strong></td> 
	<td>
	<input type="checkbox" name="words" checked="1" value="eenie" />eenie
	<input type="checkbox" name="words" value="meenie" />meenie
	<input type="checkbox" name="words" checked="1" value="minie" />minie
	<input type="checkbox" name="words" value="moe" />moe</td></tr>

	<tr>
	<td></td> 
	<td>
	<strong>What's your favorite colour?:</strong></td> 
	<td>
	<select name="color" size="1">
	<option selected="1" value="red" />red
	<option value="green" />green
	<option value="blue" />blue
	<option value="chartreuse" />chartreuse
	</select></td></tr>

	<tr>
	<td></td> 
	<td></td> 
	<td>
	<input type="submit" name="nonamefield001" value="Submit Query" /></td></tr>

	</table>
	</form>
	<hr />
	<table>
	<tr><td>
	<strong>What's your name?:</strong></td> <td>This Is My Name</td></tr>
	<tr><td>
	<strong>What's the combination?:</strong></td> <td>eenie<br />minie</td></tr>
	<tr><td>
	<strong>What's your favorite colour?:</strong></td> <td>red</td></tr>
	</table><p>Your favorites were emailed.</p>

	</body>
	</html>

=head2 This text is the content of the email message that the program sent:

	Date: Mon, 3 Sep 2001 13:28:19 -0700
	To: perl@DarrenDuncan.net
	From: perl@DarrenDuncan.net
	Subject: A Simple Example HTML::FormTemplate Submission


	Q: What's your name?

	This Is My Name

	******************************

	Q: What's the combination?

	eenie
	minie

	******************************

	Q: What's your favorite colour?

	red

=cut

######################################################################

# Names of properties for objects of this class are declared here:
my $KEY_TAG_MAKER = 'tag_maker';  # store HTML::EasyTags object
my $KEY_AUTO_POSIT = 'auto_posit';  # with methods whose parameters 
	# could be either named or positional, when we aren't sure what we 
	# are given, do we guess positional?  Default is named.
my $KEY_FIELD_INPUT = 'field_input';  # an mvh w user input
my $KEY_NEW_FORM   = 'new_form';  # true when form used first time
my $KEY_IS_SUBMIT  = 'is_submit';  # ffn we check ui for to see if form submitted
my $KEY_DEF_FF_TYPE = 'def_ff_type';  # default field type when not specified
my $KEY_DEF_FF_NAME = 'def_ff_name';  # default field name (prefix) when not spec
my $KEY_SUBMIT_URL = 'submit_url';  # where form goes when submitted
my $KEY_SUBMIT_MET = 'submit_method';  # ususlly POST or GET
my $KEY_FIELD_DEFNA = 'field_defna';  # an array of field descriptions
my $KEY_NORMALIZED = 'normalized';  # are stored field defn in proper form?
my $KEY_FIELD_RENDE = 'field_rende';  # a hash w rendered field html
my $KEY_FIELD_INVAL = 'field_inval';  # a hash w shows invalid user input
my $KEY_INVAL_MARK = 'inval_mark';  # appears by fields with invalid input
my $KEY_ISREQ_MARK = 'isreq_mark';  # appears by fields that must be filled in
my $KEY_PRIVA_MARK = 'priva_mark';  # appears by fields marked as private
my $KEY_EMP_ECH_STR = 'emp_ech_str';  # string to show in place of empty field

# Keys for items in form property $KEY_FIELD_DEFNA:
my $FKEY_TYPE = 'type';  # actual type of input field
my $FKEY_NAME = 'name';  # actual name of input field
my $FKEY_VALUES = 'values';  # actual list selection options
my $FKEY_DEFAULTS = 'defaults';  # default user selections/input
my $FKEY_OVERRIDE = 'override';  # force coded default values to be used
my $FKEY_LABELS = 'labels';  # visible labels of list selection options
my $FKEY_NOLABELS = 'nolabels';  # selection options always have no labels
my $FKEY_TAG_ATTR = 'tag_attr';  # hash of miscellaneous html tag attributes
my $FKEY_MIN_GRP_COUNT = 'min_grp_count';  # num to set count of group members
my $FKEY_LIST = 'list';  # force field groups to ret as list inst of scalar
my $FKEY_LINEBREAK = 'linebreak';  # make field groups join with linebreaks
my $FKEY_TABLE_COLS = 'table_cols';  # put field groups in table with n columns
my $FKEY_TABLE_ROWS = 'table_rows';  # use table with n rows; ign if tcols defin
my $FKEY_TABLE_ACRF = 'table_acrf';  # order fields across first (down if false)
my $FKEY_IS_REQUIRED = 'is_required';  # field must be filled in (any mem)
my $FKEY_REQ_MIN_COUNT = 'req_min_count';  # need min this many grp mem filled in
my $FKEY_REQ_MAX_COUNT = 'req_max_count';  # need max this many grp mem filled in
my $FKEY_REQ_OPT_MATCH = 'req_opt_match';  # bool; check if input valid select opt
my $FKEY_VALIDATION_RULE = 'validation_rule';  # a regular expression for all mem
my $FKEY_VISIBLE_TITLE = 'visible_title';  # main title/prompt for field
my $FKEY_HELP_MESSAGE = 'help_message';   # suggestions for field use
my $FKEY_ERROR_MESSAGE = 'error_message';  # appears when input invalid
my $FKEY_STR_ABOVE_INPUT = 'str_above_input';  # str adjacent before input field
my $FKEY_STR_BELOW_INPUT = 'str_below_input';  # str adjacent after input field
my $FKEY_IS_PRIVATE = 'is_private';   # field not shared with public
my $FKEY_EXCLUDE_IN_ECHO = 'exclude_in_echo';  # always exclude from reports

# List of "special" attributes of a form field definition; these all have formal 
# keys in their names; any attributes not in this list are misc html tag attribs
my @SPECIAL_ATTRIB = ($FKEY_TYPE, $FKEY_NAME, $FKEY_VALUES, $FKEY_DEFAULTS, 
	$FKEY_OVERRIDE, $FKEY_LABELS, $FKEY_NOLABELS, $FKEY_TAG_ATTR, 
	$FKEY_MIN_GRP_COUNT, $FKEY_LIST, $FKEY_LINEBREAK, $FKEY_TABLE_COLS, 
	$FKEY_TABLE_ROWS, $FKEY_TABLE_ACRF, $FKEY_IS_REQUIRED, $FKEY_REQ_MIN_COUNT, 
	$FKEY_REQ_MAX_COUNT, $FKEY_REQ_OPT_MATCH, $FKEY_VALIDATION_RULE,
	$FKEY_VISIBLE_TITLE, $FKEY_HELP_MESSAGE, $FKEY_ERROR_MESSAGE, 
	$FKEY_STR_ABOVE_INPUT, $FKEY_STR_BELOW_INPUT, $FKEY_IS_PRIVATE, 
	$FKEY_EXCLUDE_IN_ECHO);

# Declare handlers for different form field types
my %FIELD_TYPES = ();
my $TKEY_VISIBL = 'visibl';  # a boolean - is this field user-visible or not
my $TKEY_EDITAB = 'editab';  # a boolean - can user set value by typing or select
my $TKEY_SELECT = 'select';  # a boolean - does the user select from list
my $TKEY_FLDGRP = 'fldgrp';  # a boolean - is this a field group or not
my $TKEY_MULTIV = 'multiv';  # a boolean - can field use >1 member of VALUES arg
my $TKEY_METHOD = 'method';  # a scalar - what method to use for html rendering
my $TKEY_PARSER = 'parser';  # always a 3-element array - for parsing definitions
my $TKEY_ATTRIB = 'attrib';  # an array - valid defin attribs for this type

# First set the 6 simpler %FIELD_TYPES atributes: 
# visible, editable, selectable, field group, multivalued, rendering method
{
	foreach my $type (qw( reset submit hidden textfield password_field textarea
			checkbox radio popup_menu scrolling_list )) {
		$FIELD_TYPES{$type} = {
			$TKEY_VISIBL => 1,  # true with 9/10, not hidden
			$TKEY_EDITAB => 1,  # true with 7/10, not reset submit hidden
			$TKEY_SELECT => 0,  # true with 6/10, not check radio popup scroll
			$TKEY_FLDGRP => 0,  # true with 10/10
			$TKEY_MULTIV => 0,  # true with 8/10, not popup scroll
			$TKEY_METHOD => '_make_input_html',  # true with 7/10, n txa pop scr
		};
		$FIELD_TYPES{$type."_group"} = {
			$TKEY_VISIBL => 1,  # true with 9/10, not hidden
			$TKEY_EDITAB => 1,  # true with 7/10, not reset, submit, hidden
			$TKEY_SELECT => 0,  # true with 6/10, not check radio popup scroll
			$TKEY_FLDGRP => 1,  # true with 10/10
			$TKEY_MULTIV => 1,  # true with 10/10
			$TKEY_METHOD => '_make_input_group_html',  # true with 7/10, n ...
		};
	}
	foreach my $type (qw( hidden )) {
		$FIELD_TYPES{$type}->{$TKEY_VISIBL} = 0;
		$FIELD_TYPES{$type."_group"}->{$TKEY_VISIBL} = 0;
	}
	foreach my $type (qw( reset submit hidden )) {
		$FIELD_TYPES{$type}->{$TKEY_EDITAB} = 0;
		$FIELD_TYPES{$type."_group"}->{$TKEY_EDITAB} = 0;
	}
	foreach my $type (qw( checkbox radio popup_menu scrolling_list )) {
		$FIELD_TYPES{$type}->{$TKEY_SELECT} = 1;
		$FIELD_TYPES{$type."_group"}->{$TKEY_SELECT} = 1;
	}
	foreach my $type (qw( popup_menu scrolling_list )) {
		$FIELD_TYPES{$type}->{$TKEY_MULTIV} = 1;
	}
	foreach my $type (qw( textarea )) {
		$FIELD_TYPES{$type}->{$TKEY_METHOD} = '_make_textarea_html';
		$FIELD_TYPES{$type."_group"}->{$TKEY_METHOD} = '_make_textarea_group_html';
	}
	foreach my $type (qw( popup_menu scrolling_list )) {
		$FIELD_TYPES{$type}->{$TKEY_METHOD} = '_make_select_html';
		$FIELD_TYPES{$type."_group"}->{$TKEY_METHOD} = '_make_select_group_html';
	}
}

# Next set the input parser attribute of %FIELD_TYPES: 
{
	foreach my $type (qw( reset submit )) {
		my $names = [ $FKEY_NAME, $FKEY_DEFAULTS ];
		my $rename = {
			'values' => $FKEY_DEFAULTS, value => $FKEY_DEFAULTS,
			labels => $FKEY_DEFAULTS, label => $FKEY_DEFAULTS,
		};
		my $rem = '';
		$FIELD_TYPES{$type}->{$TKEY_PARSER} = [$names, $rename, $rem];
		$FIELD_TYPES{$type."_group"}->{$TKEY_PARSER} = [$names, $rename, $rem];
	}
	foreach my $type (qw( hidden )) {
		my $names = [ $FKEY_NAME, $FKEY_DEFAULTS ];
		my $rename = {
			'values' => $FKEY_DEFAULTS, value => $FKEY_DEFAULTS,
		};
		my $rem = '';
		$FIELD_TYPES{$type}->{$TKEY_PARSER} = [$names, $rename, $rem];
		$FIELD_TYPES{$type."_group"}->{$TKEY_PARSER} = [$names, $rename, $rem];
	}
	foreach my $type (qw( textfield password_field )) {
		my $names = [ $FKEY_NAME, $FKEY_DEFAULTS, 'size', 'maxlength' ];
		my $names_group = [ $FKEY_NAME, $FKEY_DEFAULTS, 
			$FKEY_LINEBREAK, 'size', 'maxlength' ];
		my $rename = {
			'values' => $FKEY_DEFAULTS, value => $FKEY_DEFAULTS,
		};
		my $rem = '';
		$FIELD_TYPES{$type}->{$TKEY_PARSER} = [$names, $rename, $rem];
		$FIELD_TYPES{$type."_group"}->{$TKEY_PARSER} = 
			[$names_group, $rename, $rem];
	}
	foreach my $type (qw( textarea )) {
		my $names = [ $FKEY_NAME, $FKEY_DEFAULTS, 'rows', 'cols' ];
		my $names_group = [ $FKEY_NAME, $FKEY_DEFAULTS, 
			$FKEY_LINEBREAK, 'rows', 'cols' ];
		my $rename = {
			'values' => $FKEY_DEFAULTS, value => $FKEY_DEFAULTS, 
			text => $FKEY_DEFAULTS, columns => 'cols',
		};
		my $rem = $FKEY_DEFAULTS;
		$FIELD_TYPES{$type}->{$TKEY_PARSER} = [$names, $rename, $rem];
		$FIELD_TYPES{$type."_group"}->{$TKEY_PARSER} = 
			[$names_group, $rename, $rem];
	}
	foreach my $type (qw( checkbox radio popup_menu scrolling_list )) {
		my $names = [ $FKEY_NAME, $FKEY_DEFAULTS, $FKEY_VALUES, $FKEY_LABELS ];
		my $names_group = [ $FKEY_NAME, $FKEY_VALUES, $FKEY_DEFAULTS, 
			$FKEY_LINEBREAK, $FKEY_LABELS ];
		my $rename = {
			value => $FKEY_VALUES, checked => $FKEY_DEFAULTS,
			selected => $FKEY_DEFAULTS, on => $FKEY_DEFAULTS,
			label => $FKEY_LABELS, text => $FKEY_LABELS,
		};
		my $rem = $FKEY_LABELS;
		$FIELD_TYPES{$type}->{$TKEY_PARSER} = [$names, $rename, $rem];
		$FIELD_TYPES{$type."_group"}->{$TKEY_PARSER} = 
			[$names_group, $rename, $rem];
	}
	foreach my $type (keys %FIELD_TYPES) {
		my $rename = $FIELD_TYPES{$type}->{$TKEY_PARSER}->[1];
		$rename->{default} = $FKEY_DEFAULTS;
		$rename->{nolabel} = $FKEY_NOLABELS;
		$rename->{force} = $FKEY_OVERRIDE;
	}
	foreach my $type (qw( checkbox_group radio_group )) {
		my $rename = $FIELD_TYPES{$type}->{$TKEY_PARSER}->[1];
		$rename->{cols} = $FKEY_TABLE_COLS;
		$rename->{columns} = $FKEY_TABLE_COLS;
		$rename->{rows} = $FKEY_TABLE_ROWS;
	}
}

# Next set the valid-attributes attribute of %FIELD_TYPES: 
{
	foreach my $type (keys %FIELD_TYPES) {
		my $typerec = $FIELD_TYPES{$type};
		my @attrib = ($FKEY_TYPE, $FKEY_NAME, $FKEY_DEFAULTS, $FKEY_OVERRIDE, 
			$FKEY_TAG_ATTR, $FKEY_IS_REQUIRED, $FKEY_REQ_OPT_MATCH, 
			$FKEY_VALIDATION_RULE, $FKEY_VISIBLE_TITLE, $FKEY_HELP_MESSAGE, 
			$FKEY_ERROR_MESSAGE, $FKEY_STR_ABOVE_INPUT, $FKEY_STR_BELOW_INPUT, 
			$FKEY_IS_PRIVATE, $FKEY_EXCLUDE_IN_ECHO);
		if( $typerec->{$TKEY_FLDGRP} ) {
			push( @attrib, $FKEY_MIN_GRP_COUNT, $FKEY_LIST, $FKEY_LINEBREAK, 
				$FKEY_TABLE_COLS, $FKEY_TABLE_ROWS, $FKEY_TABLE_ACRF, 
				$FKEY_REQ_MIN_COUNT, $FKEY_REQ_MAX_COUNT );
		}
		$typerec->{$TKEY_ATTRIB} = \@attrib;
	}
	foreach my $type (qw( checkbox radio popup_menu scrolling_list )) {
		my @attrib = ($FKEY_VALUES, $FKEY_LABELS);
		push( @{$FIELD_TYPES{$type}->{$TKEY_ATTRIB}}, @attrib );
		push( @{$FIELD_TYPES{$type."_group"}->{$TKEY_ATTRIB}}, @attrib );
	}
	foreach my $type (qw( checkbox radio )) {
		my @attrib = ($FKEY_NOLABELS);
		push( @{$FIELD_TYPES{$type}->{$TKEY_ATTRIB}}, @attrib );
		push( @{$FIELD_TYPES{$type."_group"}->{$TKEY_ATTRIB}}, @attrib );
	}
	foreach my $type (qw( textfield password_field )) {
		my @attrib = ('size', 'maxlength');
		push( @{$FIELD_TYPES{$type}->{$TKEY_ATTRIB}}, @attrib );
		push( @{$FIELD_TYPES{$type."_group"}->{$TKEY_ATTRIB}}, @attrib );
	}
	foreach my $type (qw( textarea )) {
		my @attrib = ('rows', 'cols');
		push( @{$FIELD_TYPES{$type}->{$TKEY_ATTRIB}}, @attrib );
		push( @{$FIELD_TYPES{$type."_group"}->{$TKEY_ATTRIB}}, @attrib );
	}
	foreach my $type (qw( scrolling_list )) {
		my @attrib = ('size', 'multiple');
		push( @{$FIELD_TYPES{$type}->{$TKEY_ATTRIB}}, @attrib );
		push( @{$FIELD_TYPES{$type."_group"}->{$TKEY_ATTRIB}}, @attrib );
	}
}

# Used by _make_input_html() to convert our field types to actual
# <INPUT> tag TYPE arguments.
my %INPUT_TAG_IMPL_TYPE = (
	'reset' => 'reset',
	submit => 'submit',
	hidden => 'hidden',
	textfield => 'text',
	password_field => 'password',
	checkbox => 'checkbox',
	radio => 'radio',
	reset_group => 'reset',
	submit_group => 'submit',
	hidden_group => 'hidden',
	textfield_group => 'text',
	password_field_group => 'password',
	checkbox_group => 'checkbox',
	radio_group => 'radio',
);

######################################################################

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

Methods of this class always "return" their results, rather than printing them
out to a file or the screen.  Not only is this simpler, but it gives the calling
code the maximum amount of control over what happens in the program.  They may
wish to do post-processing with the generated HTML, or want to output it in a
different order than it is generated.

=head1 CONSTRUCTOR FUNCTIONS AND METHODS

=head2 new()

This function creates a new HTML::FormTemplate object and returns it.

=cut

######################################################################

sub new {
	my $class = shift( @_ );
	my $self = bless( {}, ref($class) || $class );
	$self->initialize( @_ );
	return( $self );
}

######################################################################

=head2 initialize()

This method is used by B<new()> to set the initial properties of an object,
that it creates.

=cut

######################################################################

sub initialize {
	my ($self) = @_;
	$self->{$KEY_TAG_MAKER} = HTML::EasyTags->new();
	$self->{$KEY_AUTO_POSIT} = 0;
	$self->{$KEY_FIELD_INPUT} = CGI::MultiValuedHash->new();
	$self->{$KEY_NEW_FORM} = 1;
	$self->{$KEY_IS_SUBMIT} = '.is_submit';
	$self->{$KEY_DEF_FF_TYPE} = 'textfield';
	$self->{$KEY_DEF_FF_NAME} = 'nonamefield';
	$self->{$KEY_SUBMIT_URL} = 'http://127.0.0.1';
	$self->{$KEY_SUBMIT_MET} = 'post';
	$self->{$KEY_FIELD_DEFNA} = [];
	$self->{$KEY_NORMALIZED} = 0;
	$self->{$KEY_FIELD_RENDE} = undef;
	$self->{$KEY_FIELD_INVAL} = undef;
	$self->{$KEY_INVAL_MARK} = '?';
	$self->{$KEY_ISREQ_MARK} = '*';
	$self->{$KEY_PRIVA_MARK} = '~';
	$self->{$KEY_EMP_ECH_STR} = '';
}

######################################################################

=head2 clone([ CLONE ])

This method initializes a new object to have all of the same properties of the
current object and returns it.  This new object can be provided in the optional
argument CLONE (if CLONE is an object of the same class as the current object);
otherwise, a brand new object of the current class is used.  Only object 
properties recognized by HTML::FormTemplate are set in the clone; other properties 
are not changed.

=cut

######################################################################

sub clone {
	my ($self, $clone) = @_;
	ref($clone) eq ref($self) or $clone = bless( {}, ref($self) );

	$clone->{$KEY_TAG_MAKER} = $self->{$KEY_TAG_MAKER}->clone();

	$clone->{$KEY_AUTO_POSIT} = $self->{$KEY_AUTO_POSIT};

	$clone->{$KEY_FIELD_INPUT} = $self->{$KEY_FIELD_INPUT}->clone();

	$clone->{$KEY_NEW_FORM} = $self->{$KEY_NEW_FORM};
	$clone->{$KEY_IS_SUBMIT} = $self->{$KEY_IS_SUBMIT};
	$clone->{$KEY_DEF_FF_TYPE} = $self->{$KEY_DEF_FF_TYPE};
	$clone->{$KEY_DEF_FF_NAME} = $self->{$KEY_DEF_FF_NAME};
	$clone->{$KEY_SUBMIT_URL} = $self->{$KEY_SUBMIT_URL};
	$clone->{$KEY_SUBMIT_MET} = $self->{$KEY_SUBMIT_MET};

	$clone->{$KEY_FIELD_DEFNA} = 
		[map { $_->clone() } @{$self->{$KEY_FIELD_DEFNA}}];

	$clone->{$KEY_NORMALIZED} = $self->{$KEY_NORMALIZED};

	defined( $self->{$KEY_FIELD_RENDE} ) and 
		$clone->{$KEY_FIELD_RENDE} = {%{$self->{$KEY_FIELD_RENDE}}};

	defined( $self->{$KEY_FIELD_INVAL} ) and 
		$clone->{$KEY_FIELD_INVAL} = {%{$self->{$KEY_FIELD_INVAL}}};

	$clone->{$KEY_INVAL_MARK} = $self->{$KEY_INVAL_MARK};
	$clone->{$KEY_ISREQ_MARK} = $self->{$KEY_ISREQ_MARK};
	$clone->{$KEY_PRIVA_MARK} = $self->{$KEY_PRIVA_MARK};
	$clone->{$KEY_EMP_ECH_STR} = $self->{$KEY_EMP_ECH_STR};

	return( $clone );
}

######################################################################

=head2 positional_by_default([ VALUE ])

This method is an accessor for the boolean "positional arguments" property of
this object, which it returns.  If VALUE is defined, this property is set to it. 
With methods whose parameters could be either named or positional, when we aren't
sure what we are given, do we guess positional?  Default is named.

=cut

######################################################################

sub positional_by_default {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$KEY_AUTO_POSIT} = $new_value;
	}
	return( $self->{$KEY_AUTO_POSIT} );
}

######################################################################

=head1 METHODS FOR SETTING USER INPUT AND NEW FORM STATUS

=head2 reset_to_new_form()

This method sets the boolean property "new form" to true, wipes out any user
input (putting form to factory defaults), and clears all error conditions.  You
can use this method to implement your own "defaults" button if you wish.

=cut

######################################################################

sub reset_to_new_form {
	my ($self) = @_;
	$self->{$KEY_FIELD_INPUT} = CGI::MultiValuedHash->new();
	$self->{$KEY_NEW_FORM} = 1;
	$self->{$KEY_FIELD_RENDE} = undef;
	$self->{$KEY_FIELD_INVAL} = undef;
}

######################################################################

=head2 user_input([ INPUT ])

This method is an accessor for the "user input" property of this object, which it
returns.  If INPUT is defined, this property is set to it.  This property is a
single MultiValuedHash object or HASH ref whose keys are the form fields that the
user filled in and whose values are what they entered.  These values are used
when creating form field html to preserve what the user previously entered, and
they are used when doing our own input checking, and they are used when
generating input echo reports.  This property is also examined when it is set and
automatically changes the "new form" property accordingly.  The property is
undefined by default.  The method also clears any error conditions.

=cut

######################################################################

sub user_input {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$new_value = CGI::MultiValuedHash->new( 0, $new_value );
		$self->{$KEY_FIELD_INPUT} = $new_value;
		$self->{$KEY_NEW_FORM} = 
			!$new_value->fetch_value( $self->{$KEY_IS_SUBMIT} );
		$self->{$KEY_FIELD_RENDE} = undef;
		$self->{$KEY_FIELD_INVAL} = undef;
	}
	return( $self->{$KEY_FIELD_INPUT} );
}

######################################################################

=head2 new_form([ VALUE ])

This method is an accessor for the boolean "new form" property of this object,
which it returns.  If VALUE is defined, this property is set to it.  If this
property is true, then we act like this is the first time we were called.  That
means that the form is blank except for factory defaults, and there are no error
conditions.  If this property is false then we are being called again after the
user submitted the form at least once, and we do perform input checking.  This
property is true by default.  No other properties are changed.

=cut

######################################################################

sub new_form {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$KEY_NEW_FORM} = $new_value;
		$self->{$KEY_FIELD_RENDE} = undef;
		$self->{$KEY_FIELD_INVAL} = undef;
	}
	return( $self->{$KEY_NEW_FORM} );
}

######################################################################

=head1 METHODS FOR DEFAULT FIELD PROPERTIES

=head2 new_form_determinant([ VALUE ])

This method is an accessor for the boolean "new form determinant" property of 
this object, which it returns.  If VALUE is defined, this property is set to it.  
This property is the name of a field that we will scan provided user input for 
to see if this form was submitted.  The default property value is ".is_submit".  
If this field has a true value in the user input, then the form is not new.

=cut

######################################################################

sub new_form_determinant {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$KEY_IS_SUBMIT} = $new_value;
	}
	return( $self->{$KEY_IS_SUBMIT} );
}

######################################################################

=head2 default_field_type([ VALUE ])

This method is an accessor for the boolean "default field type" property of 
this object, which it returns.  If VALUE is a valid field type, this property is 
set to it.  If someone tries to make a form field without providing a valid 
field type, then this is used as the default.  The default value is 'textfield'.

=cut

######################################################################

sub default_field_type {
	my ($self, $new_value) = @_;
	if( $FIELD_TYPES{$new_value} ) {
		$self->{$KEY_DEF_FF_TYPE} = $new_value;
	}
	return( $self->{$KEY_DEF_FF_TYPE} );
}

######################################################################

=head2 default_field_name([ VALUE ])

This method is an accessor for the boolean "default field name" property of 
this object, which it returns.  If VALUE is not an empty string, this property is 
set to it.  If someone tries to make a form field without providing a field name, 
then this is used as the default name, or as the prefix for a numbered name 
sequence with stored fields.  The default value is 'nonamefield'.

=cut

######################################################################

sub default_field_name {
	my ($self, $new_value) = @_;
	if( $new_value ne '' ) {
		$self->{$KEY_DEF_FF_NAME} = $new_value;
	}
	return( $self->{$KEY_DEF_FF_NAME} );
}

######################################################################

=head1 METHODS NAMED AFTER FIELD-TYPES

These methods have the same names as field types and each one will make HTML for 
either a single field or group of related fields of that type.  Arguments can be 
in either named or positional format, or specifically any argument format that 
Class::ParamParser knows how to handle.  If the parser is in doubt, it will guess 
the format based on the value you set with the positional_by_default() method.
The one exception to this is with TYPE; please see its description further below.

The method listings show the positional arguments in the parenthesis beside each
method name, and for those any use of brackets means that the enclosed arguments
are optional.  Below the method name is a vertical list of named arguments; for
those, any group of arguments that is enclosed by a bracket-pair are all aliases
for each other, and only one should be used at a time.  For any of [value,
default, label, nolabel] the singular and plural versions are always aliases for
each other, and so both are not explicitely shown below.

There are several extra named arguments that apply to each field type which are 
not shown here; see the EXTRA FIELD-TYPE METHOD ARGUMENTS section for details.
While the named argument "linebreak" is shown here for completeness, please see 
the other section for its explanation also.

=head2 reset( NAME[, DEFAULT] )

	NAME
	[DEFAULT or VALUE or LABEL]

This method makes a single reset button that has NAME for its name and 
optionally DEFAULT as its value.  Web browsers may or may not use this value as 
a button label and they may or may not include the value with form submissions.

=head2 submit( NAME[, DEFAULT] )

	NAME
	[DEFAULT or VALUE or LABEL]

This method makes a single submit button that has NAME for its name and 
optionally DEFAULT as its value.  Web browsers may or may not use this value as 
a button label and they may or may not include the value with form submissions.

=head2 hidden( NAME, DEFAULT )

	NAME
	[DEFAULT or VALUE]

This method makes a single hidden field that has NAME for its name and 
DEFAULT as its value.  Nothing is displayed visually by web browsers.

=head2 textfield( NAME[, DEFAULT[, SIZE[, MAXLENGTH]]] )

	NAME
	[DEFAULT or VALUE]
	SIZE
	MAXLENGTH

This method makes a single text entry field that has NAME for its name and 
DEFAULT as its value.  The field is one line high and is wide enough to display 
SIZE characters at once.  The user can enter a maximum of MAXLENGTH characters 
if that argument is set, or is not limited otherwise.

=head2 password_field( NAME[, DEFAULT[, SIZE[, MAXLENGTH]]] )

	NAME
	[DEFAULT or VALUE]
	SIZE
	MAXLENGTH

This method makes a single password entry field that has NAME for its name and 
DEFAULT as its value.  The arguments are the same as a textfield but the 
displayed value is visually bulleted out by the browser.

=head2 textarea( NAME[, DEFAULT[, ROWS[, COLS]]] )

	NAME
	[DEFAULT or VALUE or TEXT]
	ROWS
	[COLS or COLUMNS]

This method makes a single big text field that has NAME for its name and 
DEFAULT as its value.  The field is ROWS lines high and is wide enough to 
display COLS characters at once.

=head2 checkbox( NAME[, DEFAULT[, VALUE[, LABEL]]] )

	NAME
	VALUE
	[DEFAULT or CHECKED or SELECTED or ON]
	[LABEL or TEXT]
	NOLABEL

This method makes a single checkbox that has NAME for its name and 
VALUE as its value.  VALUE defaults to 'on' if it is not defined.
If DEFAULT is true then the box is checked; otherwise it is not.  
Unless NOLABEL is true, there is always a user-visible text label 
that appears beside the checkbox.  If LABEL is defined then that is used as 
the label text; otherwise NAME is used by default.

=head2 radio( NAME[, DEFAULT[, VALUE[, LABEL]]] )

	NAME
	VALUE
	[DEFAULT or CHECKED or SELECTED or ON]
	[LABEL or TEXT]
	NOLABEL

This method makes a single radio option that has NAME for its name and 
VALUE as its value.  The arguments are the same as for a checkbox.

=head2 popup_menu( NAME, [DEFAULTS], VALUES[, LABELS] )

	NAME
	VALUES
	[DEFAULTS or CHECKED or SELECTED or ON]
	[LABELS or TEXT]

This method makes a single popup menu that has NAME for its name and option 
values populated from the VALUES array ref argument.  VALUES defaults to a 
one-element list containing 'on' if not defined.  If DEFAULTS is a hash ref 
then its keys are matched with elements of VALUES and wherever its values are 
true then the corresponding menu option is selected; otherwise, DEFAULTS is 
taken as a list of option VALUES that are to be selected; by default, no 
options are selected.  Similarly, if LABELS is a hash ref then its keys are 
matched with elements of VALUES and its values provide labels for them; 
otherwise, LABELS is taken as a list of labels which are matched to VALUES 
by their corresponding array indices.  Since options must always have 
user-visible labels, any one for which LABELS is undefined will default to 
using its value as a label.  Note that a popup menu is a simplified case of 
a scrolling list where only one option can be selected and the selected option 
is the only one visible while the field doesn't have the user's focus (the menu 
visually opens up when the field has focus).

=head2 scrolling_list( NAME, [DEFAULTS], VALUES[, LABELS] )

	NAME
	VALUES
	[DEFAULTS or CHECKED or SELECTED or ON]
	[LABELS or TEXT]
	SIZE
	MULTIPLE

This method makes a single scrolling list that has NAME for its name and option 
values populated from the VALUES array ref argument.  The arguments are the same 
as for a popup menu, except that scrolling lists also support SIZE and MULTIPLE.
If MULTIPLE is true then the user can select multiple options; otherwise they 
can select only one.  If SIZE is a number greater than one then that number of 
options is visually displayed at once; this argument defaults to the count of 
elements in VALUES if false.  Note that setting SIZE to 1 will cause this 
field to be a popup menu instead.

=head2 reset_group( NAME[, DEFAULTS] )

	NAME
	[DEFAULTS or VALUES or LABELS]

This method makes a group of related reset buttons, which have NAME in common.
There is one group member for each element in the array ref DEFAULTS.

=head2 submit_group( NAME[, DEFAULTS] )

	NAME
	[DEFAULTS or VALUES or LABELS]

This method makes a group of related submit buttons, which have NAME in common.
There is one group member for each element in the array ref DEFAULTS.

=head2 hidden_group( NAME, DEFAULTS )

	NAME
	[DEFAULTS or VALUES]

This method makes a group of related hidden fields, which have NAME in common.
There is one group member for each element in the array ref DEFAULTS.

=head2 textfield_group( NAME[, DEFAULTS[, LINEBREAK[, SIZE[, MAXLENGTH]]]] )

	NAME
	[DEFAULTS or VALUES]
	SIZE
	MAXLENGTH

This method makes a group of related text entry fields, which have NAME in common.
There is one group member for each element in the array ref DEFAULTS.

=head2 password_field_group( NAME[, DEFAULTS[, LINEBREAK[, SIZE[, MAXLENGTH]]]] )

	NAME
	[DEFAULTS or VALUES]
	SIZE
	MAXLENGTH

This method makes a group of related password entry fields, which have NAME in common.
There is one group member for each element in the array ref DEFAULTS.

=head2 textarea_group( NAME[, DEFAULTS[, LINEBREAK[, ROWS[, COLS]]]] )

	NAME
	[DEFAULTS or VALUES or TEXT]
	ROWS
	[COLS or COLUMNS]

This method makes a group of related big text fields, which have NAME in common.
There is one group member for each element in the array ref DEFAULTS.

=head2 checkbox_group( NAME, VALUES[, DEFAULTS[, LINEBREAK[, LABELS]]] )

	NAME
	VALUES
	[DEFAULTS or CHECKED or SELECTED or ON]
	[LABELS or TEXT]
	NOLABELS

This method makes a group of related checkboxes, which have NAME in common. There
is one group member for each element in the array ref VALUES.  VALUES defaults to
a one-element list containing 'on' if not defined.  If DEFAULTS is a hash ref
then its keys are matched with elements of VALUES and wherever its values are
true then the corresponding box is checked; otherwise, DEFAULTS is taken as a
list of box VALUES that are to be checked; by default, no boxes are checked. 
Similarly, if LABELS is a hash ref then its keys are matched with elements of
VALUES and its values provide labels for them; otherwise, LABELS is taken as a
list of labels which are matched to VALUES by their corresponding array indices.
Unless NOLABELS is true, there is always a user-visible text label that appears
beside each checkbox.  Any checkbox for which LABELS is undefined will default to
using its value for a label.

=head2 radio_group( NAME, VALUES[, DEFAULTS[, LINEBREAK[, LABELS]]] )

	NAME
	VALUES
	[DEFAULTS or CHECKED or SELECTED or ON]
	[LABELS or TEXT]
	NOLABELS

This method makes a group of related radio options, which have NAME in common.
There is one group member for each element in the array ref VALUES.
The arguments are the same as for a checkbox_group.

=head2 popup_menu_group( NAME, VALUES[, DEFAULTS[, LINEBREAK[, LABELS]]] )

	NAME
	VALUES
	[DEFAULTS or CHECKED or SELECTED or ON]
	[LABELS or TEXT]

This method makes a group of related popup menus, which have NAME in common.
There is one group member for each element in the array ref DEFAULTS.

=head2 scrolling_list_group( NAME, VALUES[, DEFAULTS[, LINEBREAK[, LABELS]]] )

	NAME
	VALUES
	[DEFAULTS or CHECKED or SELECTED or ON]
	[LABELS or TEXT]
	SIZE
	MULTIPLE

This method makes a group of related scrolling lists, which have NAME in common.
There is one group member for each element in the array ref DEFAULTS.

=cut

######################################################################

sub reset          { $_[0]->_proxy( 'reset',          \@_ ) }
sub submit         { $_[0]->_proxy( 'submit',         \@_ ) }
sub hidden         { $_[0]->_proxy( 'hidden',         \@_ ) }
sub textfield      { $_[0]->_proxy( 'textfield',      \@_ ) }
sub password_field { $_[0]->_proxy( 'password_field', \@_ ) }
sub textarea       { $_[0]->_proxy( 'textarea',       \@_ ) }
sub checkbox       { $_[0]->_proxy( 'checkbox',       \@_ ) }
sub radio          { $_[0]->_proxy( 'radio',          \@_ ) }
sub popup_menu     { $_[0]->_proxy( 'popup_menu',     \@_ ) }
sub scrolling_list { $_[0]->_proxy( 'scrolling_list', \@_ ) }

sub reset_group          { $_[0]->_proxy( 'reset_group',          \@_ ) }
sub submit_group         { $_[0]->_proxy( 'submit_group',         \@_ ) }
sub hidden_group         { $_[0]->_proxy( 'hidden_group',         \@_ ) }
sub textfield_group      { $_[0]->_proxy( 'textfield_group',      \@_ ) }
sub password_field_group { $_[0]->_proxy( 'password_field_group', \@_ ) }
sub textarea_group       { $_[0]->_proxy( 'textarea_group',       \@_ ) }
sub checkbox_group       { $_[0]->_proxy( 'checkbox_group',       \@_ ) }
sub radio_group          { $_[0]->_proxy( 'radio_group',          \@_ ) }
sub popup_menu_group     { $_[0]->_proxy( 'popup_menu_group',     \@_ ) }
sub scrolling_list_group { $_[0]->_proxy( 'scrolling_list_group', \@_ ) }

######################################################################

=head1 METHODS FOR MAKING TOPS AND BOTTOMS OF HTML FORMS

Besides the field-type methods above, these can be used to make pieces of forms 
at a time giving you more control of the whole form layout.

=head2 start_form([ METHOD[, ACTION] ])

This method returns the top of an HTML form.  It consists of the opening 'form'
tag.  This method can take its optional two arguments in either named or
positional format; in the first case, the names look the same as the positional
placeholders above, except they must be in lower case.  The two arguments, METHOD
and ACTION, are scalars which respectively define the method that the form are
submitted with and the URL it is submitted to.  If either argument is undefined,
then the appropriate scalar properties of this object are used instead, and their
defaults are "POST" for METHOD and "127.0.0.1" for ACTION.  See the
form_submit_url() and form_submit_method() methods to access these properties.

=cut

######################################################################

sub start_form {
	my $self = shift( @_ );
	my $rh_params = $self->params_to_hash( \@_, $self->{$KEY_AUTO_POSIT}, 
		['method', 'action'], undef, undef, 1 );
	$rh_params->{'method'} ||= $self->{$KEY_SUBMIT_MET};
	$rh_params->{'action'} ||= $self->{$KEY_SUBMIT_URL};
	my $tagmaker = $self->{$KEY_TAG_MAKER};
	return( $tagmaker->make_html_tag( 'form', $rh_params, undef, 'start' ) );
}

######################################################################

=head2 end_form()

This method returns the bottom of an HTML form.  It consists of the closing
'form' tag.

=cut

######################################################################

sub end_form {
	my $self = shift( @_ );
	my $tagmaker = $self->{$KEY_TAG_MAKER};
	return( $tagmaker->make_html_tag( 'form', {}, undef, 'end' ) );
}

######################################################################

=head2 form_submit_url([ VALUE ])

This method is an accessor for the scalar "submit url" property of this object,
which it returns.  If VALUE is defined, this property is set to it.  This
property defines the URL of a processing script that the web browser would use to
process the generated form.  The default value is "127.0.0.1".

=cut

######################################################################

sub form_submit_url {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$KEY_SUBMIT_URL} = $new_value;
	}
	return( $self->{$KEY_SUBMIT_URL} );
}

######################################################################

=head2 form_submit_method([ VALUE ])

This method is an accessor for the scalar "submit method" property of this
object, which it returns.  If VALUE is defined, this property is set to it.  This
property defines the method that the web browser would use to submit form data to
a processor script.  The default value is "post", and "get" is the other option.

=cut

######################################################################

sub form_submit_method {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$KEY_SUBMIT_MET} = $new_value;
	}
	return( $self->{$KEY_SUBMIT_MET} );
}

######################################################################

=head1 METHODS FOR SETTING AND USING STORED FIELD DEFINITIONS

=head2 field_definitions([ DEFIN ])

This method is an accessor for the "field definitions" list property of this
object, which it returns.  If DEFIN is defined, this property is set to it.  This
property is a list of either MultiValuedHash objects or HASH refs, each of which
contains a description for one field or field group that is to be made.  Fields
will be processed in the same order they appear in this list.  The list is empty
by default.  The method also clears any error conditions.

=cut

######################################################################

sub field_definitions {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		my @fields = ref($new_value) eq 'ARRAY' ? @{$new_value} : $new_value;

		my @field_defn = ();

		foreach my $defin (@fields) {
			if( UNIVERSAL::isa( $defin, 'Data::MultiValuedHash' ) ) {
				$defin = $defin->fetch_all();
			}
			ref( $defin ) eq 'HASH' or next;  # improper input so we skip
			$defin = $self->_rename_defin_props( $defin );
			$defin = Data::MultiValuedHash->new( 1, $defin );  # copy input
			push( @field_defn, $defin );
		}

		$self->{$KEY_FIELD_DEFNA} = \@field_defn;
		$self->{$KEY_NORMALIZED} = 0;
		$self->{$KEY_FIELD_RENDE} = undef;
		$self->{$KEY_FIELD_INVAL} = undef;
	}
	return( [@{$self->{$KEY_FIELD_DEFNA}}] );  # refs to indiv defins returned
}

######################################################################

=head2 fields_normalized()

This method returns true if the field definitions have been "normalized".  The
boolean property that tracks this condition is false by default and only becomes
true when normalize_field_definitions() is called.  It becomes false when
field_definitions() is called.

=cut

######################################################################

sub fields_normalized {
	my $self = shift( @_ );
	return( $self->{$KEY_NORMALIZED} )
}

######################################################################

=head2 normalize_field_definitions()

This method edits the "field definitions" such that any fields without names are
given one (called "nonamefieldNNN"), any unknown field types become textfields,
and any special fields we use internally are created.  It returns true when
finished.  This method is called by any input checking or html making routines if
"normalized" is false because it is a precondition for them to work properly.

=cut

######################################################################

sub normalize_field_definitions {
	my $self = shift( @_ );
	my $ra_field_defn = $self->{$KEY_FIELD_DEFNA};

	my $nfn_field_count = 0;
	my $has_is_submit = 0;
	my $has_submit_button = 0;

	foreach my $defin (@{$ra_field_defn}) {

		# Make sure the field definition has a valid field type.

		my $type = $defin->fetch_value( $FKEY_TYPE );
		unless( $FIELD_TYPES{$type} ) {
			$type = $self->{$KEY_DEF_FF_TYPE};
			$defin->store( $FKEY_TYPE, $type );
		}

		# Make sure the field definition has field name.

		my $name = $defin->fetch_value( $FKEY_NAME );
		if( !$name or $name =~ /^$self->{$KEY_DEF_FF_NAME}/ ) {
			$name = $self->{$KEY_DEF_FF_NAME}.
				sprintf( "%3.3d", ++$nfn_field_count );
			$defin->store( $FKEY_NAME, $name );
		}

		$name eq $self->{$KEY_IS_SUBMIT} and $has_is_submit = 1;
		$type eq 'submit' and $has_submit_button = 1;
	}

	unless( $has_is_submit ) {
		unshift( @{$ra_field_defn}, Data::MultiValuedHash->new( 1, {
			$FKEY_TYPE => 'hidden',
			$FKEY_NAME => $self->{$KEY_IS_SUBMIT},
			$FKEY_DEFAULTS => 1,
		} ) );
	}

	unless( $has_submit_button ) {
		push( @{$ra_field_defn}, Data::MultiValuedHash->new( 1, {
			$FKEY_TYPE => 'submit',
			$FKEY_NAME => $self->{$KEY_DEF_FF_NAME}.
				sprintf( "%3.3d", ++$nfn_field_count ),
		} ) );
	}

	$self->{$KEY_FIELD_RENDE} = undef;
	$self->{$KEY_FIELD_INVAL} = undef;
	return( $self->{$KEY_NORMALIZED} = 1 );
}

######################################################################

=head1 METHODS FOR MAKING FIELD HTML USING STORED DEFINITIONS

=head2 field_html([ NAME ])

This method returns generated html code for form fields that were defined using
field_definitions().  If NAME is defined it only returnes code for the field (or
group) with that name; otherwise it returns a list of html for all fields.  This
is useful if you want to define your form fields ahead of time, but still want to
roll your own complete form.

=cut

######################################################################

sub field_html {
	my ($self, $name) = @_;
	unless( defined( $self->{$KEY_FIELD_RENDE} ) ) {
		$self->make_field_html();
	}
	if( defined( $name ) ) {
		return( $self->{$KEY_FIELD_RENDE}->{$name} );
	} else {
		return( {%{$self->{$KEY_FIELD_RENDE}}} );
	}
}

######################################################################

=head2 make_field_html()

This method goes through all the fields and has html made for them, then puts it
away for those that need it, namely make_html_input_form() and field_html().  It
returns a count of the number of fields generated, which includes all hidden
fields and buttons.

=cut

######################################################################

sub make_field_html {
	my $self = shift( @_ );
	$self->{$KEY_NORMALIZED} or $self->normalize_field_definitions();
	my %field_html = ();
	foreach my $defin (@{$self->{$KEY_FIELD_DEFNA}}) {
		my $name = $defin->fetch_value( $FKEY_NAME );
		$field_html{$name} = $self->_make_field_html( $defin );
	}
	$self->{$KEY_FIELD_RENDE} = \%field_html;
	return( scalar( keys %field_html ) );
}

######################################################################

=head1 METHODS FOR USER INPUT VALIDATION USING STORED DEFINITIONS

=head2 invalid_input([ NAMES ])

This method is an accessor for the "invalid input" property of this object, which
it returns.  If NAMES is a valid hash ref, this property is set to it.  This
property is a hash that indicates which fields have invalid input.  The property
is undefined by default, and is set when validate_form_input() is called.  The
optional NAMES argument lets you override the internal input checking to apply
your own input checking.  If you want both to happen, then call it once with no
arguments (internal is automatically done), then edit the results, then call this
again providing your new hash as an argument.

=cut

######################################################################

sub invalid_input {
	my ($self, $new_value) = @_;
	if( ref( $new_value ) eq 'HASH' ) {
		$self->{$KEY_FIELD_INVAL} = {%{$new_value}};
	}
	unless( defined( $self->{$KEY_FIELD_INVAL} ) ) {
		$self->validate_form_input();
	}
	return( $self->{$KEY_FIELD_INVAL} );  # returns ref; caller may change
}

######################################################################

=head2 validate_form_input()

This method sets the "invalid input" property by applying the various input 
checking properties of the fields to the user input for those fields.  If "new
form" is true then all fields are declared to be error free.  It returns a count
of the number of erroneous fields, and 0 if there are no errors.  This method is
called by make_html_input_form() and invalid_input() if "invalid input" is false
because it is a precondition for them to work properly.  If the "validation rule" 
regular expression does not compile, then Perl automatically throws an exception.

=cut

######################################################################

sub validate_form_input {
	my $self = shift( @_ );
	$self->{$KEY_NORMALIZED} or $self->normalize_field_definitions();

	if( $self->{$KEY_NEW_FORM} ) {
		$self->{$KEY_FIELD_INVAL} = {};
		return( 0 );
	}

	my $user_input = $self->{$KEY_FIELD_INPUT};
	my %input_invalid = ();

	foreach my $defin (@{$self->{$KEY_FIELD_DEFNA}}) {
		my $type = $defin->fetch_value( $FKEY_TYPE );

		# Don't check hidden fields or buttons since user can't change them.

		next unless( $FIELD_TYPES{$type}->{$TKEY_EDITAB} );

		my $name = $defin->fetch_value( $FKEY_NAME );
		my $is_required = $defin->fetch_value( $FKEY_IS_REQUIRED );
		my $min_count = $defin->fetch_value( $FKEY_REQ_MIN_COUNT );
		my $max_count = $defin->fetch_value( $FKEY_REQ_MAX_COUNT );
		my $req_options = $defin->fetch_value( $FKEY_REQ_OPT_MATCH );
		my $pattern = $defin->fetch_value( $FKEY_VALIDATION_RULE );

		# Fetch any input that exists; filter out empty strings.

		my @input = grep { $_ ne '' } $user_input->fetch( $name );
		my $input_count = @input;

		# If input is required then empty fields are an error.

		if( $is_required ) {
			unless( $input_count ) {
				$input_invalid{$name} = $FKEY_IS_REQUIRED;
				next;
			}
		}

		# If at least MIN values must be entered/selected, less is an error.

		if( defined( $min_count ) ) {
			unless( $input_count >= $min_count ) {
				$input_invalid{$name} = $FKEY_REQ_MIN_COUNT;
				next;
			}
		}

		# If at most MAX values must be entered/selected, more is an error.

		if( defined( $max_count ) ) {
			unless( $input_count <= $max_count ) {
				$input_invalid{$name} = $FKEY_REQ_MAX_COUNT;
				next;
			}
		}

		# If this is a selection field, then verify that the user input matches 
		# available selections for that field.  The @matched array below is the 
		# intersection of VALUES and INPUT sets.

		if( $req_options and $FIELD_TYPES{$type}->{$TKEY_SELECT} ) {
			my %values = map { ( $_ => 1 ) } $defin->fetch( $FKEY_VALUES );
			my @matched = grep { $values{$_} } @input;
			unless( $input_count == scalar( @matched ) ) {
				$input_invalid{$name} = $FKEY_REQ_OPT_MATCH;
				next;
			}
		}

		# Optionally do a simple pattern-match for valid input.

		if( defined( $pattern ) ) {
			my @matched = grep { $_ =~ /$pattern/ } @input;
			unless( $input_count == scalar( @matched ) ) {
				$input_invalid{$name} = $FKEY_VALIDATION_RULE;
				next;
			}
		}
	}

	$self->{$KEY_FIELD_INVAL} = \%input_invalid;
	return( scalar( keys %input_invalid ) );
}

######################################################################

=head1 METHODS FOR MAKING WHOLE FORMS AT ONCE

=head2 make_html_input_form([ TABLE[, LIST] ])

This method returns a complete html input form, including all form field tags,
reflected user input values, various text headings and labels, and any visual
cues indicating special status for various fields.  The first optional boolean
argument, TABLE, says to return the form within an HTML table, with one field or
field group per row.  Field headings and help text appear on the left and the
field or group itself appears on the right.  All table cells are
top-left-aligned, and no widths or heights are specified.  If TABLE is false then
each field or group is returned in a paragraph that starts with its title.  The
second optional boolean argument, LIST, causes the resulting form body to be
returned as an array ref whose elements are pieces of the page.  If this is false
then everything is returned in a single scalar.

=cut

######################################################################

sub make_html_input_form {
	my ($self, $in_table_format, $force_list ) = @_;
	$self->{$KEY_FIELD_RENDE} or $self->make_field_html();
	$self->{$KEY_FIELD_INVAL} or $self->validate_form_input();

	my $rh_field_html = $self->{$KEY_FIELD_RENDE};
	my $rh_invalid = $self->{$KEY_FIELD_INVAL};
	my @input_form = ();
	my $tagmaker = $self->{$KEY_TAG_MAKER};

	push( @input_form, $self->start_form() );
	if( $in_table_format ) {
		push( @input_form, "\n<table>" );
	}

	foreach my $defin (@{$self->{$KEY_FIELD_DEFNA}}) {
		my $type = $defin->fetch_value( $FKEY_TYPE );
		my $name = $defin->fetch_value( $FKEY_NAME );

		unless( $FIELD_TYPES{$type}->{$TKEY_VISIBL} ) {
			push( @input_form, $rh_field_html->{$name} );
			next;
		}

		my $flags_html = '';
		my $label_html = '';
		my $error_html = '';

		if( $FIELD_TYPES{$type}->{$TKEY_EDITAB} ) {
			if( $rh_invalid->{$name} ) {
				$flags_html .= "\n$self->{$KEY_INVAL_MARK}";
			}
			if( $defin->fetch_value( $FKEY_IS_REQUIRED ) ) {
				$flags_html .= "\n$self->{$KEY_ISREQ_MARK}";
			}
			if( $defin->fetch_value( $FKEY_IS_PRIVATE ) ) {
				$flags_html .= "\n$self->{$KEY_PRIVA_MARK}";
			}

			$label_html .= "\n<strong>" .
				$defin->fetch_value( $FKEY_VISIBLE_TITLE ) . ":</strong>";
			if( my $hm = $defin->fetch_value( $FKEY_HELP_MESSAGE ) ) {
				if( $in_table_format ) {
					$label_html .= "<br />";
				}
				$label_html .= "\n<small>($hm)</small>";
			}

			if( $rh_invalid->{$name} ) {
				$error_html .= "\n<small>" .
					$defin->fetch_value( $FKEY_ERROR_MESSAGE ) . 
					"</small>";
				if( $in_table_format ) {
					$error_html .= "<br />";
				}
			}
		}

		my $field_html = $rh_field_html->{$name};
		ref( $field_html ) eq 'ARRAY' and 
			$field_html = join( '', @{$field_html} );  # compensate "list" attr
		my $str_above = $defin->fetch_value( $FKEY_STR_ABOVE_INPUT );
		my $str_below = $defin->fetch_value( $FKEY_STR_BELOW_INPUT );

		if( $in_table_format ) {
			push( @input_form, <<__endquote );
\n<tr>
<td>$flags_html</td> 
<td>$label_html</td> 
<td>$error_html$str_above$field_html$str_below</td></tr>
__endquote
		} else {
			push( @input_form, <<__endquote );
\n<p>
$flags_html 
$label_html 
$error_html$str_above$field_html$str_below</p>
__endquote
		}
	}

	if( $in_table_format ) {
		push( @input_form, "\n</table>" );
	}
	push( @input_form, $self->end_form() );

	return( $force_list ? \@input_form : join( '', @input_form ) );
}

######################################################################

=head2 bad_input_marker([ VALUE ])

This method is an accessor for the string "invalid input marker" property of
this object, which it returns.  If VALUE is defined, this property is set to it. 
This string is used to visually indicate in which form fields the user has 
entered invalid input.  It defaults to a question mark ("?").

=cut

######################################################################

sub bad_input_marker {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$KEY_INVAL_MARK} = $new_value;
	}
	return( $self->{$KEY_INVAL_MARK} );
}

######################################################################

=head2 required_field_marker([ VALUE ])

This method is an accessor for the string "required field marker" property of
this object, which it returns.  If VALUE is defined, this property is set to it. 
This string is used to visually indicate which form fields are required, and 
must be filled in by users for the form to be processed.  It defaults to 
an asterisk ("*").

=cut

######################################################################

sub required_field_marker {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$KEY_ISREQ_MARK} = $new_value;
	}
	return( $self->{$KEY_ISREQ_MARK} );
}

######################################################################

=head2 private_field_marker([ VALUE ])

This method is an accessor for the string "private field marker" property of
this object, which it returns.  If VALUE is defined, this property is set to it. 
This string is used to visually indicate which form fields are meant to be 
private, meaning their content won't be shown to the public.  It defaults to 
a tilde ("~").

=cut

######################################################################

sub private_field_marker {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$KEY_PRIVA_MARK} = $new_value;
	}
	return( $self->{$KEY_PRIVA_MARK} );
}

######################################################################

=head1 METHODS FOR MAKING WHOLE REPORTS AT ONCE

=head2 make_html_input_echo([ TABLE[, EXCLUDE[, EMPTY[, LIST]]] ])

This method returns a complete html-formatted input "echo" report that includes
all the field titles and reflected user input values.  Any buttons or hidden
fields are excluded.  There is nothing that indicates whether the user input has
errors or not.  There is one heading per field group, and the values from each
member of the group are displayed together in a list.  The first optional boolean
argument, TABLE, says to return the report within an HTML table, with one field
or field group per row.  All table cells are top-left-aligned, and no widths or
heights are specified.  If TABLE is false then each field or group input is
returned in a paragraph that starts with its title.  The second optional boolean
argument, EXCLUDE, ensures that any fields that were defined to be "private" are
excluded from this report; by default they are included.  The third optional
string argument, EMPTY, specifies the string to use in place of the user's input
where the user left the field empty; by default nothing is shown.  The fourth
optional boolean argument, LIST, causes the resulting form body to be returned
as an array ref whose elements are pieces of the page.  If this is false then
everything is returned in a single scalar.

=cut

######################################################################

sub make_html_input_echo {
	my ($self, $in_table_format, $exclude_private, $empty_field_str, 
		$force_list) = @_;
	defined( $empty_field_str ) or $empty_field_str = $self->{$KEY_EMP_ECH_STR};
	$self->{$KEY_NORMALIZED} or $self->normalize_field_definitions();

	my $user_input = $self->{$KEY_FIELD_INPUT};
	my @input_echo = ();
	my $tagmaker = $self->{$KEY_TAG_MAKER};

	if( $in_table_format ) {
		push( @input_echo, "\n<table>" );
	}

	foreach my $defin (@{$self->{$KEY_FIELD_DEFNA}}) {
		my $type = $defin->fetch_value( $FKEY_TYPE );
		my $name = $defin->fetch_value( $FKEY_NAME );

		unless( $FIELD_TYPES{$type}->{$TKEY_EDITAB} ) {
			next;
		}
		if( $defin->fetch_value( $FKEY_EXCLUDE_IN_ECHO ) ) {
			next;
		}
		if( $exclude_private and $defin->fetch_value( $FKEY_IS_PRIVATE ) ) {
			next;
		}

		my $field_title = "\n<strong>" .
			$defin->fetch_value( $FKEY_VISIBLE_TITLE ) . ":</strong>";

		my @input = grep { $_ ne '' } $user_input->fetch( $name );
		scalar( @input ) or @input = $empty_field_str;
		foreach (@input) { 
			s/&/&amp;/g;
			s/\"/&quot;/g;
			s/>/&gt;/g;
			s/</&lt;/g;
		}
		my $user_input_str = join( $in_table_format ? '<br />' : ', ', @input );

		if( $in_table_format ) {
			push( @input_echo, 
				"\n<tr><td>$field_title</td> <td>$user_input_str</td></tr>" );
		} else {
			push( @input_echo, "\n<p>$field_title $user_input_str</p>" );
		}
	}

	if( $in_table_format ) {
		push( @input_echo, "\n</table>" );
	}

	return( $force_list ? \@input_echo : join( '', @input_echo ) );
}

######################################################################

=head2 make_text_input_echo([ EXCLUDE[, EMPTY[, LIST]] ])

This method returns a complete plain-text-formatted input "echo" report that
includes all the field titles and reflected user input values.  This report is
designed not for web display but for text reports or for inclusion in e-mail
messages.  Any buttons or hidden fields are excluded.  There is nothing that
indicates whether the user input has errors or not.  There is one heading per
field group, and the values from each member of the group are displayed together
in a list.  For each field, the title is displayed on one line, then followed by
a blank line, then followed by the user inputs.  The title is preceeded by the
text "Q: ", indicating it is the "question".  The first optional boolean
argument, EXCLUDE, ensures that any fields that were defined to be "private" are
excluded from this report; by default they are included.  The second optional
string argument, EMPTY, specifies the string to use in place of the user's input
where the user left the field empty; by default nothing is shown.  The third
optional boolean argument, LIST, causes the resulting form body to be returned
as an array ref whose elements are pieces of the page.  If this is false then
everything is returned in a single scalar, and there is a delimiter placed
between each field or group that consists of a line of asterisks ("*").

=cut

######################################################################

sub make_text_input_echo {
	my ($self, $exclude_private, $empty_field_str, $force_list) = @_;
	defined( $empty_field_str ) or $empty_field_str = $self->{$KEY_EMP_ECH_STR};
	$self->{$KEY_NORMALIZED} or $self->normalize_field_definitions();

	my $user_input = $self->{$KEY_FIELD_INPUT};
	my @input_echo = ();
	my $tagmaker = $self->{$KEY_TAG_MAKER};

	foreach my $defin (@{$self->{$KEY_FIELD_DEFNA}}) {
		my $type = $defin->fetch_value( $FKEY_TYPE );
		my $name = $defin->fetch_value( $FKEY_NAME );

		unless( $FIELD_TYPES{$type}->{$TKEY_EDITAB} ) {
			next;
		}
		if( $defin->fetch_value( $FKEY_EXCLUDE_IN_ECHO ) ) {
			next;
		}
		if( $exclude_private and $defin->fetch_value( $FKEY_IS_PRIVATE ) ) {
			next;
		}

		my @input = grep { $_ ne '' } $user_input->fetch( $name );
		scalar( @input ) or @input = $empty_field_str;

		push( @input_echo, 
			"\nQ: ".$defin->fetch_value( $FKEY_VISIBLE_TITLE )."\n".
			"\n".join( "\n", @input )."\n" );
	}

	return( $force_list ? \@input_echo : join( 
		"\n******************************\n", @input_echo ) );
}

######################################################################

=head2 empty_field_echo_string([ VALUE ])

This method is an accessor for the string "empty field echo string" property of
this object, which it returns.  If VALUE is defined, this property is set to it. 
While making input echo reports, this string is used in place of the user's 
input where the user left the field empty; this property is "" by default.

=cut

######################################################################

sub empty_field_echo_string {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$KEY_EMP_ECH_STR} = $new_value;
	}
	return( $self->{$KEY_EMP_ECH_STR} );
}

######################################################################

=head1 METHODS FOR MAKING FORM HTML USING MANUAL FIELD DEFINITIONS

=head2 field_html_from_defin( DEFIN )

This method creates form field html based on a field template DEFIN, and
optionally populates it with user input from a previous form invocation. The
field can be any type, including a group.  DEFIN must be either a hash ref or an
MVH object; if neither is provided then this method aborts and returns undef.
This method normally returns a scalar, unless the field template specifies
'list' as an option, in which case an array ref is returned (field groups only).

=cut

######################################################################

sub field_html_from_defin {
	my ($self, $defin) = @_;
	if( UNIVERSAL::isa( $defin, 'Data::MultiValuedHash' ) ) {
		$defin = $defin->fetch_all();
	}
	ref( $defin ) eq 'HASH' or return( undef );  # improper input so fail
	$defin = $self->_rename_defin_props( $defin );
	return( $self->_make_field_html( $defin ) );
}

######################################################################

=head1 METHODS FOR MAKING FORM-MAKING FORM DEFINITIONS

=head2 valid_types([ TYPE ])

This method returns a list of all the form field types that this class can
recognize when they are used either in the 'type' attribute of a field
definition, or as the name of an html-field-generating method.  This list
contains the same types listed in the "Recognized Form Field Types" of this
documentation.  If the optional scalar argument, TYPE, is defined, then this
method will instead return true if TYPE is a valid field type or false if not.

=cut

######################################################################

sub valid_types {
	my ($self, $type) = @_;
	$type and return( exists( $FIELD_TYPES{$type} ) );
	my @list = keys %FIELD_TYPES;
	return( wantarray ? @list : \@list );
}

######################################################################

=head2 valid_multivalue_types([ TYPE ])

This method returns true if a form field of the type defined by the optional
scalar argument, TYPE, makes use of a list for its VALUES attribute; otherwise, 
only a single VALUE can be used.  Note that multiple VALUES also means multiple 
LABELS and DEFAULTS where appropriate.  If called without any arguments, this 
method returns a list of all field types that make use of multiple VALUES.
The list that this method works with is a subset of valid_types().

=cut

######################################################################

sub valid_multivalue_types {
	my ($self, $type) = @_;
	$type and return( exists( $FIELD_TYPES{$type} ) and 
		$FIELD_TYPES{$type}->{$TKEY_MULTIV} );
	my @list = grep { $FIELD_TYPES{$_}->{$TKEY_MULTIV} } keys %FIELD_TYPES;
	return( wantarray ? @list : \@list );
}

######################################################################

=head2 valid_attributes( TYPE[, ATTRIB] )

This method returns a list of all the form field definition attributes that this
class can recognize when they are used in defining a field whose type is defined
by the scalar argument, TYPE.  If the optional scalar argument, ATTRIB, is
defined, then this method will instead return true if ATTRIB is a valid field
definition attribute or false if not.

=cut

######################################################################

sub valid_attributes {
	my ($self, $type, $attrib) = @_;
	if( $attrib ) {
		$FIELD_TYPES{$type} or return( 0 );
		my %valid = map { ( $_ => 1 ) } @{$FIELD_TYPES{$type}->{$TKEY_ATTRIB}};
		return( exists( $valid{$type} ) );
	} else {
		my @list = @{$FIELD_TYPES{$type}->{$TKEY_ATTRIB}};
		return( wantarray ? @list : \@list );
	}
}

######################################################################

=head1 HTML-MAKING UTILITY METHODS

=head2 make_table_from_list( SOURCE[, COLS[, ROWS[, ACROSS]]] )

This method takes a list of HTML or text elements and arranges them into an 
HTML table structure, returning the whole thing as a scalar.  The first argument, 
SOURCE, is an array ref containing the text we will arrange.  The arguments 
COLS and ROWS respectively indicate the maximum number of columns and rows that 
SOURCE elements are arranged into; the default for each is 1.  Because all source 
elements must be used, only one of ROWS or COLS is respected; the other is 
automatically recalcuated from the first; therefore you only need to provide one.  
COLS takes precedence when both are provided.  If the fourth argument ACROSS is 
true, then source elements are arranged from left-to-right first and then top to 
bottom; otherwise, the default has elements arranged from top to bottom first and 
left-to-right second.

=cut

######################################################################

sub make_table_from_list {
	my ($self, $ra_list, $max_cols, $max_rows, $acr_first) = @_;
	my @source = ref( $ra_list ) eq 'ARRAY' ? @{$ra_list} : $ra_list;
	my @table_lines = ();

	# Determine the ROWS x COLS dimensions of our table using the count of 
	# elements in SOURCE and any pre-defined COLS and ROWS values.  Then top 
	# up the SOURCE array with blanks so that it fills the table evenly; this 
	# makes sure that rows and columns line up visually, even without aligning.

	my $length = scalar( @source );
	if( $max_cols or !$max_rows ) {
		$max_cols < 1 and $max_cols = 1;
		$max_rows = int( $length / $max_cols ) + ($length % $max_cols ? 1 : 0);
	} else {
		$max_rows < 1 and $max_rows = 1;
		$max_cols = int( $length / $max_rows ) + ($length % $max_rows ? 1 : 0);
	}
	push( @source, map { '&nbsp;' } (1..($max_cols * $max_rows - $length)) );

	# Option one is to arrange the source elements across first and then down.

	if( $acr_first ) {
		push( @table_lines, "<table>\n" );
		foreach my $row_num (1..$max_rows) {
			my @row_source = splice( @source, 0, $max_cols ) or last;
			my @row_lines = map { "<td>$_</td>" } @row_source;
			push( @table_lines, "<tr>\n".join( "\n", @row_lines )."\n</tr>\n" );
		}
		push( @table_lines, "</table>\n" );

	# Option two is to arrange the source elements down first and then across.

	} else {
		push( @table_lines, "<table>\n<tr>\n" );
		foreach my $col_num (1..$max_cols) {
			my @cell_source = splice( @source, 0, $max_rows ) or last;
			push( @table_lines, 
				"<td>\n".join( "<br />\n", @cell_source )."\n</td>\n" );
		}
		push( @table_lines, "</tr>\n</table>\n" );
	}

	return( join( '', @table_lines ) );
}

######################################################################
# _proxy( TYPE, ARGS )
# This private method is a proxy for the 20 public methods whose names are the 
# same as form field types that this class can make.  Rather than having 20 
# methods with almost identical code, we put all the code here instead.
# The argument TYPE says which method we are proxying at the moment, and 
# the argument ARGS is an array ref having the complete argument list that the 
# original method got, including a reference to $self in its first element.
# Note that using these methods is the only opportunity to use positional 
# arguments in one's "form field definition"; named still works of course, 
# although an MVH object can not be used here.

sub _proxy {
	my ($self, $type, $ra_args) = @_;
	shift( @{$ra_args} );  # first element is an extra ref to $self
	my $defin = $self->params_to_hash( $ra_args, $self->{$KEY_AUTO_POSIT}, 
		@{$FIELD_TYPES{$type}->{$TKEY_PARSER}}, 1 );
	$defin->{$FKEY_TYPE} = $type;
	return( $self->_make_field_html( $defin ) );
}

######################################################################
# _rename_defin_groups( DEFIN )
# This private method takes a form field definition and resolves its property 
# aliases, returning a new form field definition.  DEFIN must be a hash ref and 
# this method returns a hash ref.

sub _rename_defin_props {
	my ($self, $defin) = @_;

	# Determine our field type.  Note that we have to do a bit of parsing ourself 
	# to get the type because we need the type to know how to parse definition.

	my %lc_defin = map { ( lc($_) => $defin->{$_} ) } sort keys %{$defin};
	my $type = $defin->{lc($FKEY_TYPE)} || $defin->{"-".lc($FKEY_TYPE)};
	ref( $type ) eq 'ARRAY' and $type = $type->[0];
	$FIELD_TYPES{$type} or $type = $self->{$KEY_DEF_FF_TYPE};

	# Make sure that field definition has appropriately named properties.

	$defin = $self->params_to_hash( [$defin], 0, 
		@{$FIELD_TYPES{$type}->{$TKEY_PARSER}}, 1 );
	$defin->{$FKEY_TYPE} = $type;

	return( $defin );
}

######################################################################
# _make_field_html( DEFIN )
# This private method takes a form field definition, which has had its property 
# aliases resolved, and creates form field html based on it.  DEFIN must be a 
# hash ref or MVH object.  This method serves as a dispatch for more specialized 
# HTML-making private methods, and it takes care of issues common to all field 
# types so the specialized methods don't each have to do them.  This method 
# copies its input DEFIN and proceeds to change the copy in the following ways 
# before dispatch: 1. 'type' is made valid; 2. 'name' is made defined; 
# 3. previous user-input is incorporated into 'default'; 4. miscellaneous DEFIN 
# properties are grouped into 'tag_attr'.  After dispatch, group fields are 
# in array refs, and so this method handles joining them together as needed.

sub _make_field_html {
	my ($self, $defin) = @_;
	$defin = Data::MultiValuedHash->new( 1, $defin );  # copy input

	# Make sure the field definition has a valid field type.

	my $type = $defin->fetch_value( $FKEY_TYPE );
	unless( $FIELD_TYPES{$type} ) {
		$type = $self->{$KEY_DEF_FF_TYPE};
		$defin->store( $FKEY_TYPE, $type );
	}

	# Make sure the field definition has field name.

	unless( $defin->exists( $FKEY_NAME ) ) {
		$defin->store( $FKEY_NAME, $self->{$KEY_DEF_FF_NAME} );
	}

	# Restore field values that user entered during previous form invocation, 
	# unless this is a new form or the coded value has priority on repeat.
	# Filter out any empty strings while we're at it, and HTML encode to prevent 
	# disrupting the new HTML page.

	unless( $self->{$KEY_NEW_FORM} or $defin->fetch_value( $FKEY_OVERRIDE ) ) {
		my $name = $defin->fetch_value( $FKEY_NAME );
		my @input = grep { $_ ne '' } $self->{$KEY_FIELD_INPUT}->fetch( $name );
		foreach (@input) { 
			s/&/&amp;/g;
			s/\"/&quot;/g;
			s/>/&gt;/g;
			s/</&lt;/g;
		}
		$defin->store( $FKEY_DEFAULTS, \@input );
	}

	# Make sure the field definition's misc tag attrib are properly formatted.

	my $tag_attr = $defin->fetch_value( $FKEY_TAG_ATTR );
	ref( $tag_attr ) eq 'HASH' or $tag_attr = {};
	%{$tag_attr} = (
		$FIELD_TYPES{$type}->{$TKEY_FLDGRP} ?
			$defin->fetch_all( \@SPECIAL_ATTRIB, 1 ) : 
			$defin->fetch_first( \@SPECIAL_ATTRIB, 1 ),
		%{$tag_attr},
	);
	$defin->store( $FKEY_TAG_ATTR, $tag_attr );

	# Make sure the field group definitions have a valid member count.
	# This setting does not affect checkbox_group or radio_group fields.

	if( $FIELD_TYPES{$type}->{$TKEY_FLDGRP} ) {
		my $wanted = $defin->fetch_value( $FKEY_MIN_GRP_COUNT );
		unless( defined( $wanted ) ) {
			my $first_default = $defin->fetch_value( $FKEY_DEFAULTS );
			if( ref( $first_default ) eq 'HASH' ) {
				$wanted = grep { $first_default->{$_} } keys %{$first_default};
			} else {
				$wanted = $defin->count( $FKEY_DEFAULTS );
			}
		}
		$wanted < 1 and $wanted = 1;
		$defin->store( $FKEY_MIN_GRP_COUNT, $wanted );
	}

	# Determine which of our private methods will make HTML for this field type.

	my $method = $FIELD_TYPES{$type}->{$TKEY_METHOD};

	# Make the field HTML.

	my $html = $self->$method( $defin );

	# If the field type is a group, then $html is an array ref with a 
	# group member in each array element.  So, unless the list property is true, 
	# join the group into a scalar, delim by linebreaks or grouped in a table.

	if( ref( $html ) eq 'ARRAY' ) {
		$html = $self->_join_field_group_html( $defin, $html );
	}

	# Return the new field HTML.

	return( $html );
}

######################################################################
# _make_textarea_html( DEFIN )
# This private method assists _make_field_html() by specializing in making 
# single "<TEXTAREA></TEXTAREA>" form tags.

sub _make_textarea_html {
	my ($self, $defin) = @_;

	# Set up default attributes common to textarea tags.

	my %params = (
		%{$defin->fetch_value( $FKEY_TAG_ATTR )},
		name => $defin->fetch_value( $FKEY_NAME ),
	);
	my $default = $defin->fetch_value( $FKEY_DEFAULTS );

	# Make the field HTML and return it.

	my $tagmaker = $self->{$KEY_TAG_MAKER};
	return( $tagmaker->make_html_tag( 'textarea', \%params, $default ) );
}

######################################################################
# _make_textarea_group_html( DEFIN )
# This private method assists _make_field_html() by specializing in making 
# a group of "<TEXTAREA></TEXTAREA>" form tags.

sub _make_textarea_group_html {
	my ($self, $defin) = @_;

	# Set up default attributes common to textarea tags.

	my %params = (
		%{$defin->fetch_value( $FKEY_TAG_ATTR )},
		name => $defin->fetch_value( $FKEY_NAME ),
	);
	my @defaults = $defin->fetch( $FKEY_DEFAULTS );

	# Make sure we have enough group members.

	my $wanted = $defin->fetch_value( $FKEY_MIN_GRP_COUNT );
	my $have = @defaults;
	if( $have < $wanted ) {
		push( @defaults, [map { '' } (1..($wanted - $have))] );
	}

	# Make the field HTML and return it.

	my $tagmaker = $self->{$KEY_TAG_MAKER};
	return( $tagmaker->make_html_tag_group( 
		'textarea', \%params, \@defaults, 1 ) );
}

######################################################################
# _make_input_html( DEFIN )
# This private method assists _make_field_html() by specializing in making 
# single "<INPUT>" form tags.

sub _make_input_html {
	my ($self, $defin) = @_;
	my $type = $defin->fetch_value( $FKEY_TYPE );

	# Set up default attributes common to all input tags.

	my %params = (
		%{$defin->fetch_value( $FKEY_TAG_ATTR )},
		type => $INPUT_TAG_IMPL_TYPE{$type},
		name => $defin->fetch_value( $FKEY_NAME ),
		value => $defin->fetch_value( $FKEY_DEFAULTS ),
	);
	my $label = '';

	# Set up attributes that are unique to check boxes and radio buttons.
	# One difference is that user input affects the "checked" attribute 
	# instead of "value".

	if( $type eq 'checkbox' or $type eq 'radio' ) {
		$params{value} = $defin->fetch_value( $FKEY_VALUES );
		defined( $params{value} ) or $params{value} = 'on';
		$params{checked} = $defin->fetch_value( $FKEY_DEFAULTS );
		$label = $defin->fetch_value( $FKEY_LABELS );
		defined( $label ) or $label = $params{name};
		$defin->fetch_value( $FKEY_NOLABELS ) and $label = '';

	# For most input tag types, an empty "value" attribute is useless so 
	# get rid of it.  For buttons an empty value leads to no button label.

	} else {
		$params{value} eq '' and delete( $params{value} );
	}

	# Make the field HTML and return it.

	my $tagmaker = $self->{$KEY_TAG_MAKER};
	return( $tagmaker->make_html_tag( 'input', \%params, $label ) );
}

######################################################################
# _make_input_group_html( DEFIN )
# This private method assists _make_field_html() by specializing in making 
# a group of "<INPUT>" form tags.

sub _make_input_group_html {
	my ($self, $defin) = @_;
	my $type = $defin->fetch_value( $FKEY_TYPE );

	# Set up default attributes common to all input tags.

	my %params = (
		%{$defin->fetch_value( $FKEY_TAG_ATTR )},
		type => $INPUT_TAG_IMPL_TYPE{$type},
		name => $defin->fetch_value( $FKEY_NAME ),
		value => scalar( $defin->fetch( $FKEY_DEFAULTS ) ) || [],
	);
	my @labels = ();

	# Set up attributes that are unique to checkboxes and radio buttons.
	# One difference is that user input affects the "checked" attribute 
	# instead of "value".

	if( $type eq 'checkbox_group' or $type eq 'radio_group' ) {
		my $ra_values = $defin->fetch( $FKEY_VALUES ) || ['on'];
		$params{value} = $ra_values;

		# The definition property "defaults" may be either an array ref 
		# or a hash ref.  If it is a hash ref then the hash keys would 
		# correspond to field values and the hash values would be either 
		# true or false to indicate if it is selected.  If it is an array 
		# ref then the array elements would be a list of field values, 
		# all of which are selected.  This code block takes either 
		# variable type and coerces the data into an array ref that has 
		# the same number of elements as there are field values, and each 
		# corresponding element is either true or false; this format is 
		# what HTML::EasyTags needs as input.

		my $ra_defaults = $defin->fetch( $FKEY_DEFAULTS ) || [];  # array
		if( ref( $ra_defaults->[0] ) eq 'HASH' ) {
			$ra_defaults = $ra_defaults->[0];  # hash
		}
		if( ref( $ra_defaults ) eq 'ARRAY' ) {
			$ra_defaults = {map { ( $_ => 1 ) } @{$ra_defaults}};  # hash
		}
		$ra_defaults = [map { $ra_defaults->{$_} } @{$ra_values}];  # ary
		$params{checked} = $ra_defaults;

		# The definition property "labels" may be either an array ref 
		# or a hash ref.  If it is a hash ref then the hash keys would 
		# correspond to field values and the hash values would be the 
		# labels associated with them; this is coerced into an array.
		# If it is an array ref then the elements already are 
		# counterparts to the field value list.  If any labels are 
		# undefined then the appropriate field value is used as a label.

		my $ra_labels = $defin->fetch( $FKEY_LABELS ) || [];  # array
		if( ref( $ra_labels->[0] ) eq 'HASH' ) {
			$ra_labels = $ra_labels->[0];  # hash
			$ra_labels = [map { $ra_labels->{$_} } @{$ra_values}];  # ary
		}
		foreach my $index (0..$#{$ra_values}) {
			unless( defined( $ra_labels->[$index] ) ) {
				$ra_labels->[$index] = $ra_values->[$index];
			}
		}
		$defin->fetch_value( $FKEY_NOLABELS ) and $ra_labels = [];
		@labels = @{$ra_labels};

	# Make sure we have enough group members.

	} else {
		my $wanted = $defin->fetch_value( $FKEY_MIN_GRP_COUNT );
		my $have = @{$params{value}};
		if( $have < $wanted ) {
			push( @{$params{value}}, [map { '' } (1..($wanted - $have))] );
		}
	}

	# Make the field HTML and return it.

	my $tagmaker = $self->{$KEY_TAG_MAKER};
	return( $tagmaker->make_html_tag_group( 'input', \%params, \@labels, 1 ) );
}

######################################################################
# _make_select_html( DEFIN )
# This private method assists _make_field_html() by specializing in making 
# single "<SELECT></SELECT>" form tags, which include a group of <OPTION> tags.

sub _make_select_html {
	my ($self, $defin) = @_;

	# Set up default attributes for the option tags.

	my $ra_values = $defin->fetch( $FKEY_VALUES ) || ['on'];

	# The definition property "defaults" is handled the same way as the 
	# same property for checkbox groups, so refer to the documentation there.

	my $ra_defaults = $defin->fetch( $FKEY_DEFAULTS ) || [];  # array
	if( ref( $ra_defaults->[0] ) eq 'HASH' ) {
		$ra_defaults = $ra_defaults->[0];  # hash
	}
	if( ref( $ra_defaults ) eq 'ARRAY' ) {
		$ra_defaults = {map { ( $_ => 1 ) } @{$ra_defaults}};  # hash
	}
	$ra_defaults = [map { $ra_defaults->{$_} } @{$ra_values}];  # ary

	# The definition property "labels" is handled the same way as the 
	# same property for checkbox groups, so refer to the documentation there.

	my $ra_labels = $defin->fetch( $FKEY_LABELS ) || [];  # array
	if( ref( $ra_labels->[0] ) eq 'HASH' ) {
		$ra_labels = $ra_labels->[0];  # hash
		$ra_labels = [map { $ra_labels->{$_} } @{$ra_values}];  # ary
	}
	foreach my $index (0..$#{$ra_values}) {
		unless( defined( $ra_labels->[$index] ) ) {
			$ra_labels->[$index] = $ra_values->[$index];
		}
	}

	# Set up default attributes common to all select tags.

	my %params = (
		%{$defin->fetch_value( $FKEY_TAG_ATTR )},
		name => $defin->fetch_value( $FKEY_NAME ),
	);
	$params{size} ||= scalar( @{$ra_values} );

	# Set up attributes that are unique to popup menus.  They are 
	# different in that only one item can be displayed at a time, and 
	# correspondingly the user can only choose one item at a time.

	if( $defin->fetch_value( $FKEY_TYPE ) eq 'popup_menu' ) {
		$params{size} = 1;
		$params{multiple} = 0;
	}

	# Make the field HTML and return it.

	my $tagmaker = $self->{$KEY_TAG_MAKER};
	return( join( '', 
		$tagmaker->make_html_tag( 'select', \%params, undef, 'start' ),
		@{$tagmaker->make_html_tag_group( 'option', { value => $ra_values, 
			selected => $ra_defaults },	$ra_labels, 1 )},
		$tagmaker->make_html_tag( 'select', {}, undef, 'end' ),
	) );
}

######################################################################
# _make_select_group_html( DEFIN )
# This private method assists _make_field_html() by specializing in making 
# a group of "<SELECT></SELECT>" form tags.

sub _make_select_group_html {
	my ($self, $defin) = @_;

	# Set up default attributes for the option tags.

	my $ra_values = $defin->fetch( $FKEY_VALUES ) || ['on'];

	# The definition property "labels" is handled the same way as the 
	# same property for checkbox groups, so refer to the documentation there.

	my $ra_labels = $defin->fetch( $FKEY_LABELS ) || [];  # array
	if( ref( $ra_labels->[0] ) eq 'HASH' ) {
		$ra_labels = $ra_labels->[0];  # hash
		$ra_labels = [map { $ra_labels->{$_} } @{$ra_values}];  # ary
	}
	foreach my $index (0..$#{$ra_values}) {
		unless( defined( $ra_labels->[$index] ) ) {
			$ra_labels->[$index] = $ra_values->[$index];
		}
	}

	# Set up default attributes common to all select tags.

	my %params = (
		%{$defin->fetch_value( $FKEY_TAG_ATTR )},
		name => $defin->fetch_value( $FKEY_NAME ),
	);
	$params{size} ||= scalar( @{$ra_values} );

	# Set up attributes that are unique to popup menus.  They are 
	# different in that only one item can be displayed at a time, and 
	# correspondingly the user can only choose one item at a time.

	if( $defin->fetch_value( $FKEY_TYPE ) eq 'popup_menu_group' ) {
		$params{size} = 1;
		$params{multiple} = 0;
	}

	# Make sure we have a list of valid default values, and hash of said also.
	# The valid list is an intersection of current defaults and field values.

	my @defaults = $defin->fetch( $FKEY_DEFAULTS );
	my $rh_defaults = $defaults[0];
	unless( ref( $rh_defaults ) eq 'HASH' ) {
		$rh_defaults = {map { ( $_ => 1 ) } @defaults};
	}
	@defaults = grep { $rh_defaults->{$_} } @defaults;

	# Make sure we have enough group members.

	my $wanted = $defin->fetch_value( $FKEY_MIN_GRP_COUNT );
	my $have = @defaults;
	if( $have < $wanted ) {
		push( @defaults, [map { '' } (1..($wanted - $have))] );
	}

	# Make the field HTML and return it.

	my $tagmaker = $self->{$KEY_TAG_MAKER};
	my @field_list = ();
	foreach my $default (@defaults) {
		my $ra_defaults = [map { $_ eq $default } @{$ra_values}];
		push( @field_list, join( '', 
			$tagmaker->make_html_tag( 'select', \%params, undef, 'start' ),
			@{$tagmaker->make_html_tag_group( 'option', { value => $ra_values, 
				selected => $ra_defaults },	$ra_labels, 1 )},
			$tagmaker->make_html_tag( 'select', {}, undef, 'end' ),
		) );
	}
	return( \@field_list );
}

######################################################################
# _join_field_group_html( DEFIN, LIST )
# This private method assists _make_field_html() by joining together a list of 
# field group html, LIST, according to the field preferences in DEFIN.  This 
# method will check a series of field definition properties in order until it 
# finds one that is true; it then joins the fields in accordance with that one.
# These are the properties in order of precedence: 1. 'list' causes the LIST 
# elements to be returned as is (in an array ref), one field per element; 
# 2. 'linebreak' creates a scalar with group members delimited by <br /> tags; 
# 3. 'table_cols' or 'table_rows' causes the group members to be formatted into 
# an HTML table, returned as a scalar; 4. otherwise, we join on ''.

sub _join_field_group_html {
	my ($self, $defin, $ra_tag_html) = @_;

	# First, see if definition wants a list returned.

	$defin->fetch_value( $FKEY_LIST ) and return( $ra_tag_html );

	# Second, see if definition wants linebreak-delimited fields.

	$defin->fetch_value( $FKEY_LINEBREAK ) and 
		return( join( '<br />', @{$ra_tag_html} ) );

	# Third, see if definition wants fields returned in an HTML table.

	my $cols = $defin->fetch_value( $FKEY_TABLE_COLS );  # 3 lines chg 2.01
	my $rows = $defin->fetch_value( $FKEY_TABLE_ROWS );
	my $acr_first = $defin->fetch_value( $FKEY_TABLE_ACRF );
	if( $cols or $rows ) {
		return( $self->make_table_from_list( $ra_tag_html, 
			$cols, $rows, $acr_first ) );
	}

	# If none of the above, then return fields concatenated as is.

	return( join( '', @{$ra_tag_html} ) );
}

######################################################################

1;
__END__

=head1 PROPERTIES OF FORM FIELD DEFINITIONS

The following sections detail all of the properties of form field definitions 
that are used by this class.  That is, if a field definition were a hash, then 
these properties are the keys and values.  The term "argument" may be used here 
to refer to properties, since they are arguments to the field-type methods.

=head1 PROPERTIES FOR BASIC FIELD HTML

These properties are the standard ones for making form field html regardless of 
the method you use to request that HTML; they are used with the field-type 
methods and with field_definitions() and with field_html_from_defin().
Please see the METHODS NAMED AFTER FIELD-TYPES section above for more detail on 
usage of these basic properties as well as the circumstances where certain 
aliases are or are not valid.  The singular and plural versions of [value, 
default, label, nolabel] are always aliases for each other.

=head2 type

This string argument specifies which kind of field we are going to make, and it 
must be in the list given in RECOGNIZED FORM FIELD TYPES.  This property 
defaults to default_field_type() if not valid.  This property is used to 
determine how to handle all of the other properties, so it is important to have.  
The only time that you don't use this property is with the field-type methods, 
because the field type is explicitely provided as the method name itself.

=head2 name

This string argument is the name of the field we will make.  This is needed for 
matching up user input with the fields it came from on a form submission, so we 
can do validation, error correction, and reporting.  This property defaults to 
default_field_name() if not provided.  Users do not see this name, but the web 
browsers care about it.

=head2 values

This list argument is used with selection-type fields to set the list of options 
that the user can select from, and can be used with checkbox, radio, popup menu, 
scrolling list, and groups of each.  This property defaults to 'on' if not set 
for most field types, and to NAME for single checkboxes and radio buttons.

=head2 defaults

This list/hash argument provides default user input for the field, which could 
be from actual live or stored user input, or could be coded default values for 
the field.  Aliases include [values, labels, text, checked, selected, on] 
depending on the field type.

=head2 override

When this boolean argument is true, it ensures that coded DEFAULT values are 
always used instead of persistant user input for subsequent form invocations.
You can use FORCE as an alias for OVERRIDE with all field types.

=head2 labels

This list/hash argument provides user-visible text that appears in 
selection-type fields; these list elements correspond to VALUES elements.
If this argument is not provided, the actual VALUES are used as labels.

=head2 nolabels

This boolean argument suppresses any field value labels from showing with single 
or groups of checkboxes or radio buttons.

=head2 tag_attr

This optional argument is a hash ref containing miscellaneous html attributes 
which will be inserted into new form field tags as-is; for field groups these 
are replicated across all of the group members just as NAME is.  Similarly, 
any named arguments which are not explicitely recognized by this class are 
treated as html tag attributes as well; note that in the case of a name 
conflict, the attributes that are pre-existing in TAG_ATTR have lower precedence.
Use TAG_ATTR if you want to pass tag attributes which begin with a "-", as such 
prefixes are removed from normal named method arguments.  Under most 
circumstances, any [size, maxlength, rows, cols/columns, multiple] arguments 
are moved into here.

=head2 min_grp_count

When this numerical argument is defined, methods that make form group fields will
make sure that there are at least this many group members; otherwise, there are
as many group members made as the greater of 1 and the count of DEFAULTS.  This
argument can not be used with checkbox_group and radio_group since they always
have as many group members as VALUES elements.

=head2 list

When this boolean argument is true, methods that make form field groups will 
return their results in an array ref rather than a string, with the html for 
each group member in a separate array element.  Using this lets you delimit the 
fields in any way you choose, rather than only the ways this class understands.

=head2 linebreak

When this boolean argument is true, methods that make form field groups will 
join the html for all group members into a string with the members being 
delimited by linebreaks, that is, '<br />' tags.

=head2 table_cols, table_rows, table_acrf

When either TABLE_COLS or TABLE_ROWS is set, methods that make form field groups 
will arrange the html for all group members into a table using the 
make_table_from_list() method.  The above three arguments correspond to [COLS, 
ROWS, ACROSS] arguments respectively of that method.  For checkbox_group and 
radio_group only, you can use COLS/COLUMNS and ROWS as aliases for the first two.

=head1 PROPERTIES FOR USER-INPUT VALIDATION

In cases where user input has been evaluated to be in error, a visual cue is
provided to the user in the form of a question mark ("?") that this is so. 
You need to make your own legend explaining this where appropriate.
See bad_input_marker().  Note that any empty strings are filtered from the 
user input prior to any validation checks are done.

=head2 is_required

This boolean property is an assertion that the field must be filled in by the 
user, or otherwise there is an error condition.  A visual cue is provided to 
the user in the form of an asterisk ("*") that this is so.  You need to make
your own legend explaining this where appropriate.  See required_field_marker().

=head2 req_min_count, req_max_count

These numerical properties are assertions of how few or many members of field 
groups must be filled in or options selected by the user, or otherwise there is 
an error condition.  Each property can be used independently or together.

=head2 req_opt_match

This boolean property is an assertion that the user input returned from 
selection fields or groups must match the list of VALUES provided for that 
field; if there is any user input that doesn't match, there is an error 
condition.  You can use this to check if users are trying to "cheat" by manually 
providing selection values, or otherwise check for different error conditions.

=head2 validation_rule

This string property is a Perl 5 regular expression that is applied to the 
user input, one group member at a time.  If it evaluates to false on any of 
them then an error condition is present.  If the regular expression fails to 
compile then Perl will throw an exception automatically during runtime of the 
input validation routines.  You should error-check your regular expressions 
before passing them to field_definitions().

=head1 PROPERTIES FOR NON-FIELD HTML IN FORMS AND REPORTS

These properties are only used by make_html_input_form(), make_html_input_echo(), 
and make_text_input_echo().  Likewise, the "visual cues" mentioned in the 
previous section only appear in make_html_input_form().

=head2 visible_title

This string is the "main title" or "name" or "question" or "prompt"
that is visually associated with a form field or field group that lets the user
know what the field is for.  It is printed in bold type with a colon (":")
appended on the end.  This title is also used with the input echo reports, as a
label or heading for each piece of user input.

=head2 help_message

This string is an optional sentance or three that helps
the user further, such as explaining the reason for this' fields existence, or by
providing examples of valid input.  It is printed in smaller type and enclosed in
parenthesis.

=head2 error_message

This string is an optional sentance or three that only
appears when the user didn't enter invalid input.  It helps the user further,
such as explaining what they did wrong or giving examples of valid input.  It is
printed in smaller type.

=head2 str_above_input

This optional string is HTML code that gets inserted directly before input field 
HTML while generating a complete form.  One possible use of this could be to 
store a <DIV> tag above the field.

=head2 str_below_input

This optional string is HTML code that gets inserted directly after input field 
HTML while generating a complete form.  One possible use of this could be to 
store a </DIV> tag below the field.

=head2 is_private

This boolean property results in a visual cue provided to the user in the form
of a tilde ("~"), that you don't intend to make the contents of that field
public.  You need to make your own legend explaining this where appropriate.
See private_field_marker().

=head2 exclude_in_echo

This boolean property is an assertion that this field's value will
never be shown when reports are generated.  This provides an alternative to the
more messy redefining of the form field definitions that would otherwise be
required to exclude fields that aren't private or hidden or buttons.  Normally
the calling code is manually displaying the information from fields excluded this
way in a location outside the report html.

=head1 COMPARISONS WITH CGI.PM

The methods of this class and their parameters are designed to be compatible with
any same-named methods in the popular CGI.pm class. This class will produce
browser-compatible (and often identical) HTML from such methods, and this class
can accept all the same argument formats.  Exceptions to this include:

=over 4

=item 0

None of our methods are exported and must be called using object
notation, whereas CGI.pm can export any of it's methods.

=item 0

We save in module complexity by not talking to any global variables or
files or users directly, expecting rather that the calling code will do this. 
Methods that generate HTML will return their results so the caller can print them
on their own terms, allowing greater control.  The calling code must obtain and
provide the user's submitted input from previous form incarnations, usually with
the user_input() accessor method.  If that method is used prior to generating
html, then the html methods will behave like those in CGI.pm do when instantiated
with a query string, or automatically, or when the "params" were otherwise
manipulated.  The caller must provide the url that the form submits to, usually
with the form_submit_url() accessor method, or the default for this value is 
"127.0.0.1".  That method must be used prior to methods that generate entire
forms, in order for them to work as desired.  By contrast, CGI.pm uses the
current script's url as the default.  Of course, if you build forms
piece-by-piece and call start_form() yourself, you can give it the "action"
argument, which overrides the corresponding property.

=item 0

start_form() doesn't provide a default value for the "encoding" argument,
so if the calling code doesn't provide one then it isn't used.  By contrast,
CGI.pm provides a default encoding of "application/x-www-form-urlencoded".

=item 0

We generally provide a B<lot> more aliases for named arguments to the form field
making methods, and these are detailed in the METHODS NAMED AFTER FIELD-TYPES
part of this documentation.  This is partly to maintain backwards compatability
with the aliases that CGI.pm uses, and partly to provide a more consistant
argument names between the various methods, something that CGI.pm doesn't always
do.  For example, "value" is an alias for "default" in every method where they
don't mean different things.  Another example is that the singular and plural
versions of the [default, value, label, nolabel] arguments are always aliases for
each other. Another reasoning for this aliasing is to provide a consistant
interface for those who are used to giving all the literal HTML names for various
arguments, which is exactly what HTML::EasyTags uses.  In the cases where our
field argument isn't a true HTML argument, and rather is the text that goes
outside the tag (such as textarea values or checkbox labels), we accept "text" as
aliases, which is the exact convention that HTML::EasyTags uses when you want to
specify such text when using named parameters; this makes literalists happy.

=item 0

The arguments "default" and "labels" in our field making methods can be
either an ARRAY ref or a HASH ref (or a scalar) and we can handle them
appropriately; this choice translates to greater ease of use.  By contrast,
CGI.pm only takes Hashes for labels.

=item 0

Our checkbox_group and radio_group methods do not recognize some of the special
parameters that CGI.pm uses to organize new fields into tables, namely 
[colheaders, rowheaders].  However, we do support [cols/columns, rows] for those 
field types only; these parameters are aliases for the [table_cols, table_rows] 
parameters that work with all field group types.  While we don't support 
[colheaders, rowheaders], we do provide a new "list" argument so field groups 
aren't joined at all and the caller can organize them however they like.

=item 0

We don't give special treatment to any of the special JavaScript related
parameters to field making methods that CGI.pm does, and so we use them as
ordinary and miscellaneous html attributes.

=item 0

We save on complexity and don't have a special field type called "defaults"
like CGI.pm does.  Rather, calling code can just ask for a "submit" button with
an appropriate name, and then call our reset_to_new_form() method if they
discover it was clicked on during a previous form invocation.  This method has
the same effect, wiping out anything the user entered, but the caller has more
control over when the wipeout occurs.  For that matter, simply not setting the
user_input() property would have the same effect.

=item 0

We don't currently make "File Upload" fields or a "Clickable Image" buttons
or "Javascript Action" buttons that CGI.pm does, although we make all the other
field types.  You can still use HTML::EasyTags to make HTML for these, however.
We do make standalone radio buttons, which CGI.pm does not (as a special case 
like checkbox anyway), and we do make groups of all field types that we can make 
singles of, whereas CGI.pm only supports groups of checkboxes and radio buttons.

=item 0

We can both predefine all fields before generating them, which CGI.pm does
not, and we can also define fields as-needed in the same manner that CGI.pm does.

=back

=head1 AUTHOR

Copyright (c) 1999-2003, Darren R. Duncan.  All rights reserved.  This module
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.  However, I do request that this copyright information and
credits remain attached to the file.  If you modify this module and
redistribute a changed version then please attach a note listing the
modifications.  This module is available "as-is" and the author can not be held
accountable for any problems resulting from its use.

I am always interested in knowing how my work helps others, so if you put this
module to use in any of your own products or services then I would appreciate
(but not require) it if you send me the website url for said product or
service, so I know who you are.  Also, if you make non-proprietary changes to
the module because it doesn't work the way you need, and you are willing to
make these freely available, then please send me a copy so that I can roll
desirable changes into the main release.

Address comments, suggestions, and bug reports to B<perl@DarrenDuncan.net>.

=head1 CREDITS

Thanks to B<Lincoln D. Stein> for setting a good interface standard in the
HTML-related methods of his CGI.pm module.  I was heavily influenced by his
interfaces when designing my own.  Thanks also because I borrowed ideas for my
Synopsis program from his aforementioned module.

Thanks to Geir Johannessen <geir.johannessen@nextra.com> for alerting me to 
several obscure bugs in my POD; these only showed up when manifying, whereas 
MacPerl's Shuck and CPAN's HTMLizer rendered it properly.

=head1 SEE ALSO

perl(1), Class::ParamParser, HTML::EasyTags, Data::MultiValuedHash, 
CGI::MultiValuedHash, CGI::Portable, CGI, CGI::FormMagick, CGI::QuickForm, 
CGI::Validate.

=cut
