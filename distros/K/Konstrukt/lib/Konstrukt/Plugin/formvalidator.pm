#TODO: let the javascript modify the form to enable validation.
#      no manual modification in the HTML source needed!
#      http://jquery.com/docs/ProgressiveEnhancement/
#TODO: include strings.js from script.js. don't load it explicitly in the HTML
#function include(file) {
#    document.write("<script type=\"text/javascript\" src=\"" + file + "\"></script>\n");
#}
#TODO: -Also ignore _fields in the JS-Part
#TODO: -validate(): Does the silent-Option make sense?
#FEATURE: shortcut?:
#	my $form = Konstrukt::Plugin::formvalidator->new();
#	$form->load('/path/to/form.form');
#	$form->retrieve_values('cgi');
#	my $ok = $form->validate();
#	if (!$ok) { $self->add_node($form->errors()); }
#=>
#	my $form = Konstrukt::Plugin::formvalidator->new('/path/to/form.form'[, 'cgi']);
#  if ($form->validate()) { ... }
#FEATURE: use Data::Domain? http://search.cpan.org/~dami/Data-Domain-0.01/lib/Data/Domain.pm

=head1 NAME

Konstrukt::Plugin::formvalidator - HTML form validator

=head1 SYNOPSIS
	
B<Usage:>

	<!-- add form validation code to your page -->
	<& formvalidator form="some_dialogue.form" / &>

or

	<!-- the same but explicitly define the JS files -->
	<& formvalidator
		form="/some/dialogue.form"
	   script="/formvalidator/formvalidator.js"
	   strings="/formvalidator/formvalidator_strings.js"
	/ &>

B<Result:>

	<!-- add form validation code to your page -->
	<script type="text/javascript" src="/formvalidator/formvalidator.js"></script>
	<script type="text/javascript" src="/formvalidator/formvalidator_strings.js"></script>
	<script type="text/javascript">
		<!-- JS definitions of your form ... -->
	</script>

=head1 DESCRIPTION

HTML form validator for the Konstrukt framework.
Allows for both client- and server-side form-validation.

First of all you have to define the structure and the constraints of the form
you want to validate. Therefor you have to create a file, which looks like this:

	$form_name = 'fooform';
	$form_specification = {
		a        => { name => 'Element A',      minlength => 1, maxlength => 64,  match => '' },
		b        => { name => 'Element B',      minlength => 4, maxlength => 4,   match => '' },
		email    => { name => 'E-Mail Address', minlength => 1, maxlength => 128, match => '^.+?\@.+\..+$' },
		homepage => { name => 'Homepage'      , minlength => 0, maxlength => 256, match => '^[hH][tT][tT][pP]\:\/\/\S+\.\S+$'},
		_ignored => {...}
		...
	};

The name is only needed by the JavaScript-Part to identify the the form within
the document.

The specification is an anonymous hash. Each element represents an input-field
in the HTML-form. Note that the HTML-element has to be named like the elements
in the hash:

	<input name="email" maxlength="128" />
	
For each element you have to specify a descriptive "name", which will be used
for error messages, when the form doesn't validate, the "minlength" and
"maxlength" constraints, and the regular expression "match", to which the
elements value has to match to get the form validated.

If you only want to check fields, that contain a value, you may use a regular
expression like C<"(match pattern if not empty|^$)">.

Note that fields, which names start with an underline ("_") will be ignored by
the validation progress.

Server-side validation is be done like this:

	#get the plugin object
	my $form = use_plugin 'formvalidator';
	
	#load the form specification
	$form->load('/path/to/form.form');
	
	#populate the form with the values, which have been passed via HTTP using
	#the CGI module ($Konstrukt::CGI->param(name))
	$form->retrieve_values('cgi');
	
	#validate the form
	my $ok = $form->validate();
	
	#throw out the errors
	if (!$ok) { $self->add_node($form->errors()); }
	
	#use the form data:
	print $form->get_value('fieldname');

Client-side validation is done with help of a JavaScript, which has to be
included into the HTML-file.

The Konstrukt-Plugin "formvalidator" will put the additional code into the
HTML-source, which is needed to validate the form using JavaScript.

	<& formvalidator form="/path/to/form.form" script="/path/to/formvalidator.js" strings="/path/to/formvalidator_strings.js" / &>

The form will be validated by the JavaScript upon submission (you must do this
in your template that contains the form):

	<form id="fooform" onsubmit="return validateForm(document.getElementById('fooform'))">...</form>

=head1 CONFIGURATION

You may want to set up the template file, which will be used to format the found
errors, and the default scripts in your konstrukt.settings. Defaults:

	formvalidator/error_template /formvalidator/error.template
	formvalidator/script         /formvalidator/formvalidator.js
	formvalidator/strings        /formvalidator/formvalidator_string.js

=cut

package Konstrukt::Plugin::formvalidator;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Plugin; #import use_plugin

use Konstrukt::Debug;

=head1 METHODS

=head2 init

Inititalization of this class

=cut
sub init {
	my ($self) = @_;
	
	#set default settings
	$Konstrukt::Settings->default("formvalidator/template_path",  '/templates/formvalidator/');
	$Konstrukt::Settings->default("formvalidator/error_template", 'error.template');
	$Konstrukt::Settings->default("formvalidator/script",         'formvalidator.js');
	$Konstrukt::Settings->default("formvalidator/strings",        'formvalidator_strings.js');
	
	$self->{template_path} = $Konstrukt::Settings->get('formvalidator/template_path');
	
	#reset state
	delete $self->{strings_printed};
	delete $self->{script_printed};
	
	return 1;
}
#= /init

=head2 install

Installs the templates.

B<Parameters:>

none

=cut
sub install {
	my ($self) = @_;
	return $Konstrukt::Lib->plugin_file_install_helper($self->{template_path});
}
# /install

=head2 load

Loads a form specification file.

B<Parameters>:

=over

=item * $file - The path to the form specification file

=back

=cut
sub load {
	my ($self, $file) = @_;

	#read the file and add cache condition. pop it from the stack as we're already done with it.
	my $formfile = $Konstrukt::File->read_and_track($file);
	$Konstrukt::File->pop();
	
	#process file
	if (defined($formfile)) {
		my $form_name;
		my $form_specification;
		eval($formfile);
		#Check for errors
		if ($@) {
			#Errors in eval
			chomp($@);
			$Konstrukt::Debug->error_message("Error while loading form specification file '$file'! $@") if Konstrukt::Debug::ERROR;
			$self->{form} = {};
			$self->{form_name} = undef;
			return undef;
		} else {
			$self->{form} = $form_specification;
			$self->{form_name} = $form_name;
		}
	} else {
		$self->{form} = undef;
		$Konstrukt::Debug->error_message("Couldn't read file '$file'!") if Konstrukt::Debug::ERROR;
	}
	
	return 1;
}
#= /load

=head2 retrieve_values

Populates the form with the values, which have been passed via HTTP.

B<Parameters>:

=over

=item * $method - The method how the values should be retrieved. Currently only
'CGI' is supported.

=back

=cut
sub retrieve_values {
	my ($self, $method) = @_;

	if (lc($method) eq 'cgi') {
		if (exists($self->{form}) and keys %{$self->{form}}) {
			#collect form data from HTTP-parameters
			foreach my $key (keys %{$self->{form}}) {
				$self->{form}->{$key}->{values} = [$Konstrukt::CGI->param($key)];
				if (!@{$self->{form}->{$key}->{values}}) {
					#no values received. add undef to the list, since validate won't work with empty lists
					push @{$self->{form}->{$key}->{values}}, undef;
				}
			}
		} else {
			$Konstrukt::Debug->debug_message("There is no form loaded or the form is empty!") if Konstrukt::Debug::INFO;
		}
	} else {
		$Konstrukt::Debug->error_message("Invalid method '$method' specified. Currently only 'CGI' is supported.") if Konstrukt::Debug::ERROR;
		return undef;
	}
	
	return 1;
}
#= /retrieve_values

=head2 validate

Validates the form data agains the given form specification.

If every check is passed true will be returned. Otherwise this functin will
throw out some error messages in template syntax an false will be returned.

Additionally all values will be freed of leading and trailing whitespaces.

Returns true, if the data is valid, false otherwise.

B<Parameters>:

=over

=item * $dont_trim_values - If true, leading and trainling whitespaces will not be removed from the values.

=item * $silent - Don't throw out an error message, when a field doesn't validate.
Just remove that field from the form-hash.

=back

=cut
sub validate {
	my ($self, $dont_trim_values, $silent) = @_;

	my $ok = 1;
	$self->{errors} = [];
	
	if (exists($self->{form}) and keys %{$self->{form}}) {
		foreach my $key (keys %{$self->{form}}) {
			if (substr($key,0,1) ne '_') {
				foreach my $item (@{$self->{form}->{$key}->{values}}) {
					#workaround to validate "undef"
					$item = '' unless defined($item);
					#trim
					$item =~ s/^\s*//; $item =~ s/\s*$//;
					#cut to maximum length
					$item = substr($item,0,$self->{form}->{$key}->{maxlength});
					#minumum length
					my $field_name;
					if (defined($self->{form}->{$key}->{name}) and $self->{form}->{$key}->{name}) {
						$field_name = $self->{form}->{$key}->{name};
					} else {
						$field_name = $key;
					}
					if (length($item) < $self->{form}->{$key}->{minlength}) {
						if ($silent) { #kill entry
							delete($self->{form}->{$key});
						} else {#croak
							push @{$self->{errors}}, $field_name;
						}
						$ok = 0;
					} elsif ($self->{form}->{$key}->{match}) {
						#check format
						if ($item !~ /$self->{form}->{$key}->{match}/) {
							if ($silent) { #kill entry
								delete($self->{form}->{$key});
							} else {#croak
								push @{$self->{errors}}, $field_name;
							}
							$ok = 0;
						}
					}
				}
			}
		}
	} else {
		$ok = 0;
		$Konstrukt::Debug->debug_message("There is no form loaded or the form is empty!") if Konstrukt::Debug::INFO;
	}
	
	return $ok;
}
#= /validate

=head2 get_value

Returns the value of a form field.
Should only be called after the form values have been retrieved with the method retrieve_values().

If called in a list context, returns the fields values as an array, if the field exists. () otherwise.

If called in a scalar context, returns the fields first (maybe only) value, if the field exists. undef otherwise.

B<Parameters>:

=over

=item * $fieldname - The name of the field, whose value is requested

=back

=cut
sub get_value {
	my ($self, $fieldname) = @_;
	
	if (wantarray) {
		return (exists($self->{form}->{$fieldname}->{values}) ? @{$self->{form}->{$fieldname}->{values}} : ());
	} else {
		return (exists($self->{form}->{$fieldname}->{values}) ? ${$self->{form}->{$fieldname}->{values}}[0] : undef);
	}
}
#= /get_value

=head2 errors

Returns an node with the errors that were found during form validation.

B<Parameters>:

=over

=item * $templatefile - The file which will be used to format the found
validation errors. Defaults to the formvalidator/error_template setting in
your konstrukt.settings or to 'error.template', if not specified.
This file should contain an template list named "list" with the template field
named "error" which will contain the error message.

=back

=cut
sub errors {
	my ($self, $templatefile) = @_;
	
	my $template = use_plugin 'template';
	$templatefile ||= $self->{template_path} . $Konstrukt::Settings->get('formvalidator/error_template');
	
	return $template->node($templatefile, { list => [ map { { error => $_ } } @{$self->{errors}} ] });
}
#= /errors

=head2 prepare

We can already return the form in the prepare step.

=cut
sub prepare {
	my ($self, $tag) = @_;
	
	my $result = '';
	if ($self->load($tag->{tag}->{attributes}->{form})) {
		if (not $self->{script_printed}) {
			$result .= "<script type=\"text/javascript\" src=\""
				. ($tag->{tag}->{attributes}->{script} || ($self->{template_path} . $Konstrukt::Settings->get('formvalidator/script')))
				. "\"></script>\n";
			$self->{script_printed} = 1; #only print this once
		}
		if (not $self->{strings_printed}) {
			$result .= "<script type=\"text/javascript\" src=\""
				. ($tag->{tag}->{attributes}->{strings} || ($self->{template_path} . $Konstrukt::Settings->get('formvalidator/strings')))
				. "\"></script>\n";
			$self->{strings_printed} = 1; #only print this once
		}
		#generate the JS for each form element
		$result .= "<script type=\"text/javascript\">\n<!--\n";
		my $match;
		foreach my $key (keys %{$self->{form}}) {
			$match = $self->{form}->{$key}->{match};
			$match =~ s/\\/\\\\/g; #escape \ with \\
			$result .= "addFormElement(\"".$self->{form_name}."\", \"$key\", \"$self->{form}->{$key}->{name}\", $self->{form}->{$key}->{minlength}, $self->{form}->{$key}->{maxlength}, \"$match\");\n";
		}
		$result .= "// -->\n</script>";
	}
	
	#reset the collected nodes
	$self->reset_nodes();
	
	#add output node
	$self->add_node($result);
	
	#return output
	return $self->get_nodes();
}
#= /prepare

=head2 execute

All the work is done in the prepare step.

=cut
sub execute {
	return undef;
}
#= /execute

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: error.template -- >8 --

<div class="formvalidator error">
	<h1>There have been mistakes in your form input!</h1>
	<p>These mistakes have been found:</p>
	<ul>
	<+@ list @+><li><+$ error $+>(none)<+$ / $+></li><+@ / @+>
	</ul>
</div>

-- 8< -- textfile: formvalidator.js -- >8 --

/* formvalidator.js
 *  A JavaScript to check forms for consitency with a common interface
 *
 * Usage:
 *  addFormElement("name or id of the form", "internal name of element", "element description", minimum_length, maximum_length, /regexp_to_check/);
 *  Example: addFormElement("someform", "input", "Some Input", 1, 10, /^\d*$/); // the element "input" must have at least 1 char, but not more than 10. All chars must be digits
 *  var form_ok = validateForm(document.someform);
 *  Note that the regexp may be "" to avoid value checking.
 *
 * Limitations:
 *  You cannot use a form field with the name "name". This will cause trouble.
 *  Also currently only text, textarea, password, radio and checkbox fields will be validated.
 *
 * Copyright:
 *  by Thomas Wittek, mail at gedankenkonstrukt dot de
 *  Published under the GPL.
 */

if (!form_data) {
	var form_data = new Array;
}

function addFormElement(form, name, descr, min, max, match) {
	if (!form_data[form]) {
		form_data[form] = new Array;
	}
	form_data[form][name] = new Array;
	form_data[form][name]["description"] = descr;
	form_data[form][name]["minlength"]   = min;
	form_data[form][name]["maxlength"]   = max;
	form_data[form][name]["match"]       = match;
}

function validateForm(form) {
	var retval = true;
	var formname = form.getAttribute("name");
	if (!formname) {
		formname = form.getAttribute("id");
	}
	//debug
	/*
	alert("form name: " + formname);
	for(i=0; i<=form.elements.length-1; i++) {
		alert("form element (nama/type/value): " + form.elements[i].name + " - " + form.elements[i].type + " - " + form.elements[i].value);
			if ((form.elements[i].type == "checkbox")) {
				alert("checked?: " + form.elements[i].checked);
			}
	}
	*/
	for(i=0; i<=form.elements.length-1; i++) {
		if ((retval == true) && (form.elements[i].name != "") && form_data[formname][form.elements[i].name] && ((form.elements[i].type == "text") || (form.elements[i].type == "textarea") || (form.elements[i].type == "password") || (form.elements[i].type == "checkbox"))) {
			// Remove leading and trailing whitespaces and cut to maximum length
			if ((form.elements[i].type == "text") || (form.elements[i].type == "textarea") || (form.elements[i].type == "password")) {
				// Trim
				form.elements[i].value = form.elements[i].value.replace(/^\s*/,"");
				form.elements[i].value = form.elements[i].value.replace(/\s*$/,"");
				// Cut
				form.elements[i].value = form.elements[i].value.substr(0,form_data[formname][form.elements[i].name]["maxlength"]);
			}
			if ((form.elements[i].type == "radio") && (form.elements[i].checked == false)) {
				continue;
			}
			// Checkbox element must be checked, when "match" is "true" or "1"
			if (form.elements[i].type == "checkbox") {
				if (form_data[formname][form.elements[i].name]["match"] == "1" || form_data[formname][form.elements[i].name]["match"] == "true") {
					if (!form.elements[i].checked) {
						var msg = formvalidator_not_checked;
						msg = msg.replace(/\$name\$/, form_data[formname][form.elements[i].name]["description"]);
						alert(msg);
						form.elements[i].focus();
						retval = false;
						break;
					}
				}
				continue;
			}
			// Check for minimum length
			if (form.elements[i].value.length < form_data[formname][form.elements[i].name]["minlength"]) {
				// Too short
				var msg = formvalidator_too_short;
				msg = msg.replace(/\$name\$/, form_data[formname][form.elements[i].name]["description"]);
				alert(msg);
				form.elements[i].focus();
				retval = false;
				break;
			} else {
				if (form.elements[i].value.length != 0 && form_data[formname][form.elements[i].name]["match"] && !form.elements[i].value.match(form_data[formname][form.elements[i].name]["match"])) {
					// Doesn't match!
					var msg = formvalidator_invalid;
					msg = msg.replace(/\$name\$/, form_data[formname][form.elements[i].name]["description"]);
					alert(msg);
					form.elements[i].focus();
					retval = false;
					break;
				}
			}
		}
	}
	return retval;
}//validateForm()

-- 8< -- textfile: formvalidator_strings.js -- >8 --

/* formvalidator_strings.js
 *  The message strings, which will be put out upon a validation error.
 *  See formvalidator.js for more details
 *
 * Copyright:
 *  by Thomas Wittek, mail at gedankenkonstrukt dot de
 *  Published under the GPL.
 */

var formvalidator_too_short   = "The form field '$name$' is incomplete! Please follow the mandatory format.";
var formvalidator_invalid     = "The form field '$name$' has an invalid format!";
var formvalidator_not_checked = "The form field '$name$' is not checked, but has to!";
