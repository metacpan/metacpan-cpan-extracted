=head1 NAME 

HTML::FormEngine - create,validate and control html/xhtml forms

=cut

######################################################################

package HTML::FormEngine;
require 5.004;

# Copyright (c) 2003-2004, Moritz Sinn. This module is free software;
# you can redistribute it and/or modify it under the terms of the
# GNU GENERAL PUBLIC LICENSE, see COPYING for more information.

use strict;
use vars qw($VERSION);
$VERSION = '1.01';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	Carp

=head2 Nonstandard Modules

        Clone 0.13
        Hash::Merge 0.07
        Locale::gettext 1.01
        Date::Pcalc 1.2
        Digest::MD5 2.24
        HTML::Entities 1.27

=cut

######################################################################

use Clone qw(clone);
use Hash::Merge qw(merge);
use Carp;
use HTML::FormEngine::SkinClassic;

######################################################################

=head1 SYNOPSIS

=head2 Example Code

    #!/usr/bin/perl -w

    use strict;
    use CGI;
    use HTML::FormEngine;
    #use POSIX; # for setlocale
    #setlocale(LC_MESSAGES, 'german'); # for german error messages

    my $q = new CGI;
    print $q->header;

    my $Form = HTML::FormEngine->new(scalar $q->Vars);
    my @form = (
		{
		  templ => 'select',
		  NAME => 'Salutation',
		  OPTION => [[['mr.','mrs.']]],
		},
		{
		  templ => 'hidden_no_title',
		  NAME => 'test123',
		  VALUE => 'test',
		},
		{
		 SIZE => 10,
		 MAXLEN => 20,
		 PREFIX => [['&nbsp;', '&nbsp;/&nbsp;']],
		 NAME => 'name',
		 TITLE => 'For- / Surname ',
		 ERROR_IN => 'not_null'
		},
		{
		  MAXLEN => 30,
		  NAME => 'Email',
		  ERROR => ['not_null', ['rfc822'], ['match', 'matched net!']] # rfc822 defines the email address standard
		},
		{
		 templ => 'radio',
		 TITLE => 'Subscribe to newsletter?',
		 NAME => 'newsletter',
		 OPT_VAL => [[1, 2, 3]],
		 OPTION => [['Yes', 'No', 'Perhaps']],
		 VALUE => 1
		},
		{
		 templ => 'check',
		 OPTION => 'I agree to the terms of condition!',
		 NAME => "agree",
		 TITLE => '',
		 ERROR => sub{ return("you've to agree!") if(! shift); }
		}
    );

    $Form->set_seperate(1);
    $Form->conf(\@form);
    $Form->make();

    print $q->start_html('FormEngine example: Registration');
    if($Form->ok){
      $Form->clear();	
      print "<center>You've successfully subscribed!</center><br>";
    }
    print $Form->get,
	  $q->end_html;

=head2 Example Output

This output is produced by FormEngine when using the example code and
no data was submitted:

    <form action="/cgi-bin/formengine/registration.cgi" method="post" name="FormEngine" accept="*" enctype="application/x-www-form-urlencoded" target="_self" id="FormEngine" >
    <table border=0 cellspacing=1 cellpadding=1 align="center" >
    <tr >
       <td valign="top" align="left" ><label for="Salutation" accesskey="">Salutation</label><span ></span></td>
       <td >
	  <table border=0 cellspacing=0 cellpadding=0 >
	    <tr >

	      <td valign="top" >
		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" > &nbsp; </td>
		    <td >

	 <select size="" name="Salutation" id="Salutation"  >
	    <option value="mr." label="mr."  >mr.</option> 
	    <option value="mrs." label="mrs."  >mrs.</option> 
	 </select>

		    </td>
		    <td > &nbsp; </td>
		  </tr>
		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>

    </td>
       <td align="left" valign="bottom" style="color:#FF0000"></td><input type="hidden" name="Salutation" value="f29e202fda026b18561398f7879cdf37" />
    </tr>
    <tr ></tr>
    <tr >
       <td valign="top" align="left" ><label for="name" accesskey="">For- / Surname </label><span ></span></td>
       <td >
	  <table border=0 cellspacing=0 cellpadding=0 >
	    <tr >
	      <td valign="top" >

		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" >&nbsp;</td>
		    <td >
		      <input type="text" value="" name="name" id="name" maxlength="20" size="10"  />
		    </td>
		    <td > &nbsp; </td>
		  </tr>

		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	      <td valign="top" >
		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" >&nbsp;/&nbsp;</td>
		    <td >

		      <input type="text" value="" name="name" id="name" maxlength="20" size="10"  />
		    </td>
		    <td > &nbsp; </td>
		  </tr>
		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>

	  </table>
    </td>
       <td align="left" valign="bottom" style="color:#FF0000"></td><input type="hidden" name="name" value="f29e202fda026b18561398f7879cdf37" />
    </tr>
    <tr >
       <td valign="top" align="left" ><label for="Email" accesskey="">Email</label><span ></span></td>
       <td >
	  <table border=0 cellspacing=0 cellpadding=0 >
	    <tr >
	      <td valign="top" >

		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" > &nbsp; </td>
		    <td >
		      <input type="text" value="" name="Email" id="Email" maxlength="30" size="20"  />
		    </td>
		    <td > &nbsp; </td>

		  </tr>
		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>
    </td>
       <td align="left" valign="bottom" style="color:#FF0000"></td><input type="hidden" name="Email" value="f29e202fda026b18561398f7879cdf37" />
    </tr>
    <tr >

       <td valign="top" align="left" ><label for="newsletter" accesskey="">Subscribe to newsletter?</label><span ></span></td>
       <td >
	  <table border=0 cellspacing=0 cellpadding=0 >
	    <tr >
	      <td valign="top" >
		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" > &nbsp; </td>

		    <td >
		      <input type="radio" value="1" name="newsletter" id="newsletter" checked />Yes
		    </td>
		    <td > &nbsp; </td>
		  </tr>
		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>

	      <td valign="top" >
		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" > &nbsp; </td>
		    <td >
		      <input type="radio" value="2" name="newsletter" id="newsletter"  />No
		    </td>
		    <td > &nbsp; </td>

		  </tr>
		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	      <td valign="top" >
		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" > &nbsp; </td>

		    <td >
		      <input type="radio" value="3" name="newsletter" id="newsletter"  />Perhaps
		    </td>
		    <td > &nbsp; </td>
		  </tr>
		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>

	    </tr>
	  </table>
    </td>
       <td align="left" valign="bottom" style="color:#FF0000"></td><input type="hidden" name="newsletter" value="f29e202fda026b18561398f7879cdf37" />
    </tr>
    <tr >
       <td valign="top" align="left" ></td>
       <td >
	  <table border=0 cellspacing=0 cellpadding=0 >
	    <tr >

	      <td valign="top" >
		<table border=0 cellspacing=0 cellpadding=0 >
		  <tr >
		    <td align="" valign="" > &nbsp; </td>
		    <td >
		      <input type="checkbox" value="I agree to the terms of condition!" name="agree" id="agree"  />I agree to the terms of condition!
		    </td>
		    <td > &nbsp; </td>

		  </tr>
		  <tr ><td ></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>
    </td>
       <td align="left" valign="bottom" style="color:#FF0000"></td><input type="hidden" name="agree" value="f29e202fda026b18561398f7879cdf37" />
    </tr>
    <tr >

       <td align="right" colspan=3 >
	  <input type="submit" value="Ok" name="FormEngine" />
       </td>
    </tr>
    </table>

    </form>

=head1 DESCRIPTION

FormEngine.pm is a Perl 5 object class which provides an api for
managing html/xhtml forms. FormEngine has its own, very flexible
template system for defining form skins. A default skin and a more
flexible one is provided. This should be sufficent in most cases, but
extending the skins or making your own isn't difficult (please send
them to me!).

FormEngine also provides a set of functions for checking the form
input, it is very easy to define your own check methods or to adapt
the given.

I<gettext> is used for internationalization (e.g. error messages). So
use C<setlocale(LC_MESSAGES, 'german')> if you want to have german
error messages, butten lables and so on (there isn't support for any
other language yet, but it shouldn't be difficult to translate the .po
file, don't hesitate!).

Another usefull feature is the C<confirm> method which forces the user
to read through his input once again before submitting it.

FormEngine is designed to make extension writing an easy task!

=head1 OVERVIEW

Start with calling the C<new> method, it will return an FormEngine
object. As argument you should pass a reference to a hash of input
values (calling C<set_input> is also possible, environments like
mod_perl or CGI.pm offer already a hash of input values, see
C<set_input> for more). Now define an array which contains the form
configuration and pass a reference to C<conf>. Then call C<make>, this
will generate the html code. Next you can use C<ok> to check if the
form was submitted and all input values are correct. If this is the
case, you can e.g. display a success message and call
C<get_input(fieldname)> for getting the value of a certain field and
e.g. write it in a database. Else you should call C<get> (which will
return the html form code) or C<print> which will directly print the
form.

If you want the form to be always displayed, you can use C<clear> to
empty it (resp. display the defaults) when the transmission was
successfull.

=head1 USING FORMENGINE

The easiest way to define your form is to create an array of hash
references:

    my @form = (
		{
		  templ => 'select',
		  NAME => 'Salutation',
		  OPTION => [[['mr.','mrs.']]],
		},
		{
		  templ => 'hidden_no_title',
		  NAME => 'test123',
		  VALUE => 'test',
		},
		{
		 SIZE => 10,
		 MAXLEN => 20,
		 PREFIX => [['&nbsp;', '&nbsp;/&nbsp;']],
		 NAME => 'name',
		 TITLE => 'For- / Surname ',
		 ERROR_IN => 'not_null'
		},
		{
		  MAXLEN => 30,
		  NAME => 'Email',
		  ERROR => ['not_null', ['rfc822'], ['match', 'matched net!']] # rfc822 defines the email address standard
		},
		{
		 templ => 'radio',
		 TITLE => 'Subscribe to newsletter?',
		 NAME => 'newsletter',
		 OPT_VAL => [[1, 2, 3]],
		 OPTION => [['Yes', 'No', 'Perhaps']],
		 VALUE => 1
		},
		{
		 templ => 'check',
		 OPTION => 'I agree to the terms of condition!',
		 NAME => "agree",
		 TITLE => '',
		 ERROR => sub{ return("you've to agree!") if(! shift); }
		}
    );

This was taken out of the example above. The I<templ> key defines the
field type (resp. template), the capital written keys are explained
below. If I<templ> is not defined, it is expected to be C<text>.

Then pass a reference to that array to the C<conf> method like this:

       $Form->conf(\@form);

Another possibility is to define a hash of hash references and pass a
reference on that to C<conf>. This is seldom needed, but has the
advantage that you can define low level variables:

       my %form = (
            METHOD => 'get',
            FORMNAME => 'myform',
            SUBMIT => 'Yea! I want that!',
            'sub' => [ 
                        # Here you place your form definition (see above)
                     ] 
       );

       $Form->conf(\%form);

The meaning of the keys is explained below.  You can call
C<set_main_vars> for setting low level (main) variables as well, the
only difference is that the variables set through L<set_main_vars (
HASHREF )> are persistend, that means even if you call the L<conf (
FORMCONF )> method again they're still set if not overwritten.

=head2 The Default Skin (FormEngine)

If you want to use the same fieldname several times (e.g. for a group
of checkboxes or for two textfields like name and forename), you have
to call C<set_seperate> and pass 1 (for true). See C<set_seperate> for
more.

The following templates are known by the default skin:

=over

=item

B<text> - text input field(s), one row

=item

B<textarea> - text input field(s), several rows

=item

B<radio> - check box list (one can be selected)

=item

B<select> - pull down menu or a box with options (one or several can
be selected)

=item

B<check> - check box list (several can be selected)

=item

B<hidden> - invisible field(s), can be used for passing data

=item

B<button> - displays a standard, submit or a reset button

=item

B<print> - this template simply prints out the submitted value but
also saves it because it contains a hidden field

=back

The following templates are also known by the default skin but perhaps
a bit more difficult to understand and not so often used:

=over

=item

B<select_optgroup> - like select but lets you subdevide the options in
groups (see examples/namechooser.cgi)

=item

B<select_flexible> - lets you mix optgroup,optgroup_flexible and
option (see examples/namechooser.cgi)

=item

B<optgroup> - has to be placed in C<select_flexible>,
C<optgroup_flexible> or similar (see examples/namechooser.cgi)

=item

B<optgroup_flexible> - lets you nest option groups, cannot exist on
the first level (see examples/namechooser.cgi)

=item

B<option> - has to be placed in C<select_flexible>,
C<optgroup_flexible> or similar (see examples/namechooser.cgi)

=item

B<fieldset> - can be used for grouping fields (see
examples/feedback_fieldset.cgi)

=back

These fields are normally only used automatically for generating the
confirmation form but could be that they're also for some individual
usage:

=over

=item

B<print_option> - like C<print> but for printing out a list of
submitted options

=item

B<templ> - just used to print a list of other templates

=back

If you want to nest templates resp. place a template in another
template you have to call it with a leading '_' (underscore). So use
I<_text> instead of I<text> and so on.

Add I<_notitle> to the templates name if you don't want to have a
title, add I<_noerror> if you don't want to check for errors, add
I<_notitle_noerror> if you don't want both and simply add a I<2> if
you want the error messages to stand under the field and not next to
it. Read and run the I<examples> for more information.

B<NOTE>: All information given here about templates and variables is
only valid for the default skin and for SkinComplex. Other skins
should bring their own documentation.

=head2 Variables

Note that if you don't use the default skin, things might be
diffrent. But mostly only the layout changes.  A skin which doesn't
fit to the following conventiones should have its own documentation.

These Variables are B<always> available:

=over

=item

B<NAME> - the form fields name (this must be passed to L<get_input (
FIELDNAME )> for getting the complying value)

=item

B<TITLE> - the displayed title of the field, by default the value of
NAME

=item

B<VALUE> - the default (or initial) value of the field

=item

B<ERROR> - accepts name of an FormEngine check routine (see Config.pm
and Checks.pm), an anonymous function or an reference to a named
method. If an array reference is passed, a list of the above mentioned
values is expected. FormEngine will then call these routines one after
another until an error message is returned or the end of the list is
reached. If you want to alter the default error messages or you want
to pass arguments to it, you can do so by passing arrays like
I<[checkmethod, "error message", arg1, arg2]>, see C<namechooser.cgi>
for an example.

=back

These variables are available for the B<text template> only:

=over

=item

B<SIZE> - the physical length of the field (in characters) [default:
20]

=item

B<MAXLEN> - max. count of characters that can be put into the field
[default: no limit]

=item

B<TYPE> - if set to I<password> for each character a I<*> is printed
(instead of the character) [default: I<text>]

=back

These variables are available for B<selection templates> (C<radio>,
C<select>, C<check> and all similar ones) only:

=over

=item

B<OPTION> - accepts an reference to an array with options

=item

B<OPT_VAL> - accepts an reference to an array with values for the
options (by default the value of OPTION is used)

=back

These variables are available for the B<optgroup template> and all
similar ones:

=over

=item

B<OPTGROUP> - defines the titles of the option groups

=back

These variables are available for the B<textarea template> only:

=over

=item

B<COLS> - the width of the text input area [default: 27]

=item

B<ROWS> - the height of the text input area [default: 10]

=back

These variables are available for the B<button template> only:

=over

=item

B<TYPE> - can be 'button', 'submit' or 'reset' [default: 'button']

=back

These variables are so called B<main variables>, they can be set by
using the hash notation (see L<USING FORMENGINE>) or by calling
L<set_main_vars ( HASHREF )>:

=over

=item

B<ACTION> - the url of the page to which the form data should be
submitted [default: $ENV{REQUEST_URI}, that means: the script calls
itself]. Normally it doesn't make sense to change this value, but when
you use mod_perl, you should set it to I<$r->uri>.

=item

B<METHOD> - can be 'post' (transmit the data in HTTP header) or 'get'
(transmit the data by appeding it to the url) [default: post].

=item

B<SUBMIT> - the text that should be displayed on the submit button
[default: Ok]

=item

B<FORMNAME> - the string by which this form should be identified
[default: FormEngine]. You must change this if you have more than one
FormEngine-made form on a page. Else FormEngine won't be able to
distinguish which form was submitted.

=back

B<Note>: only NAME must be set, all other variables are optional.

Please also run the example scripts and read their code (they're very
short), it'll help you a lot understanding how to use FormEngine.

To really understand the skin system, how it works and what
possibilites there are you'll have to read the documentation of and
the code in the following files: Skin.pm, SkinComplex.pm,
SkinClassic.pm, SkinClassicConfirm.pm. These files are related to each
other in exactly this order, there's also SkinClassicConfirm.pm which
inherits everythings from SkinComplex but besides that it looks the
same like SkinClassicConfirm.pm.

B<There are many more variables and possibilites than documented
above, you have to read the template definitions in the skin packages
to know more!>

=head2 Methods For Creating Forms

=head3 new ([ HASHREF ])

This method is the constructor. It returns an FormEngine object.  You
should pass the form input in a hash reference to it, but you can use
L<set_input ( HASHREF )> as well.

=cut

######################################################################

sub new {
  my $class = shift;
  my $self = bless( {}, ref($class) || $class);
  $self->_initialize(shift);
  $self->_initialize_child(@_);
  return $self;
}

######################################################################

=head3 set_input ( HASHREF )

You have to pass a reference to a hash with input values.  You can
pass this hash reference to the constructor (C<new>) as well, then you
don't need this function.  If you use mod_perl you can get this
reference by calling 'scalar $m->request_args'.  If you use CGI.pm you
get it by calling 'scalar $q->Vars'.

=cut

######################################################################

sub set_input {
  my ($self, $input) = @_;

  if(ref($input) eq 'HASH') {
    foreach (keys(%{$input})) {
      #the following is needed if the input was forwarded from CGI.pm (arrays are represented by strings, the fields are seperated by \0)
      if(defined($input->{$_}) && !ref($input->{$_}) && $input->{$_} =~ m/\0/o) {
	$self->{input}->{$_} = [];
	@{$self->{input}->{$_}} = split("\0", $input->{$_});
      } else {
	$self->{input}->{$_} = $input->{$_};
      }
    }
    return 1
  }

  return 0
}

######################################################################

=head3 conf ( FORMCONF )

You have to pass the configuration of your form as array or hash
reference (see L<USING FORMENGINE>).

=cut

######################################################################

sub conf {
  my ($self, $conf) = @_;

  $self->{conf} = $self->_check_conf($conf) or return 0;

  local $_;
  foreach $_ (keys(%{$self->{conf_main}})) {
    $self->{conf}->{$_} = $self->{conf_main}->{$_} unless(defined($self->{conf}->{$_}));
  }
  return 1;
}

######################################################################

=head3 set_seperate ( BOOLEAN )

You've to pass true in case you want to use the same field name in
diffrent template calls. Its turned off by default because you won't
be able to set field values with java-script once it is enabled (which
doesn't matter in most cases).

=cut

######################################################################

sub set_seperate {
  my($self,$sep) = @_;
  $self->{seperate} = $sep and return 1 if(defined($sep));
  return 0;
}

######################################################################

=head3 set_main_vars ( HASHREF )

You can use this method for setting the values of the I<main> template
variables (e.g. I<SUBMIT>). Another possibility to do that is using
the hash notation when configuring the form (see L<USING FORMENGINE>).
The diffrence is that the object saves the settings made through this
method so that they're automatically reset when calling the L<conf (
FORMCONF )> method again. If you set the variables directly throught
the hash notation they're not persistent.

This method doesn't overwrite all settings which where probably
already made before, it only overwrites the variables which are
defined in the given HASH! So you can call this method several times
to complete your configuration or overwrite certain values.

To delete I<main> variable settings use L<del_main_vars ( ARRAY )>.

=cut

######################################################################

sub set_main_vars {
  # if the array notation is used for configuration, there is no
  # other possibility to set the values of the main-template variables
  # than using this function
  my ($self,$varval) = @_;
  if(defined($varval) && ref($varval) eq 'HASH') {
    foreach $_ (keys(%{$varval})) {
      $self->{conf_main}->{$_} = $varval->{$_};
      $self->{conf}->{$_} = $varval->{$_};
    }
  }
}

######################################################################

=head3 del_main_vars ( ARRAY )

Use this method to unset so called I<main> variables. They're not only
removed out of the form configuration but also out of the cache so
that you can get rid of settings that you once made with
L<set_main_vars ( HASHREF )> but which you don't want anymore, in fact
this is the real purpose of this method. Just pass the names of the
variables which should not be defined anymore.

=cut

######################################################################

sub del_main_vars {
  my ($self, @del) = @_;
  local $_;
  foreach $_ (@del) {
    delete $self->{conf_main}->{$_};
    delete $self->{conf}->{$_};
  }
}

######################################################################

=head3 clear ( )

If the form was submitted, this method simply calls L<set_use_input (
VALUE )> and L<set_error_chk ( VALUE )>. It sets both to false.  If
make was already called, it calls it again, so that no user input is
shown and no error checking is done.  Use it to reset the form.

=cut

######################################################################

sub clear {
  my $self = shift;
  if($self->is_submitted) {
    $self->set_use_input(0);
    $self->set_error_chk(0);
    $self->make() if($self->{cont} ne '');
  }
}

######################################################################

=head3 set_error_chk ( VALUE )

Sets whether the error handler should be called or not.
Default is true (1).

=cut

######################################################################

sub set_error_chk {
  my $self = shift;
  $self->{check_error} = (shift||0);
}

######################################################################

=head3 set_use_input ( VALUE )

Sets whether the given input should be displayed in the form fields or
not.  Default is true (1).

=cut

######################################################################

sub set_use_input {
  my $self = shift;
  $self->{use_input} = (shift||0);
}

######################################################################

=head3 make ( )

Creates the html/xhtml output, but doesn't return it (see L<get ( )> and
L<print ( )>).  Every method call which influences this output must be
called before calling make!

=cut

######################################################################

sub make {
  # this initialises the complex parsing process
  # all configuration must be done before calling make
  my $self = shift;
  foreach $_ (@{$self->{call_before_make}}) {
    &$_($self) if(ref($_) eq 'CODE');
  }
  my $pupo_defaults = $self->_push_varstack($self->{skin_obj}->get_default('default'), 'varstack_defaults');
  $self->{cont} = $self->_parse('<&main&>', 1);
  $self->_pop_varstack($pupo_defaults, 'varstack_defaults');
  return 1 if($self->{cont});
  return 0;
}

######################################################################

=head3 print ( )

Sends the html/xhtml output directly to STDOUT. L<make ( )> must be called
first!

=cut

######################################################################

sub print {
  my $self = shift;
  print $self->get(), "\n";
  return 1;
}

######################################################################

=head3 get ( )

Returns the html/xhtml form code in a string. L<make ( )> must be called
first!

=cut

######################################################################

sub get {
  my $self = shift;
  $self->make if($self->{call_make});
  $self->{call_make} = 0;
  return $self->{cont};
}

######################################################################

=head3 ok ( )

Returns true (1) if the form was submitted and no errors were found!
Else it returns false (0).

This method simply calls L<is_submitted ( )> and L<get_error_count ( )> but
also checks whether a confirmation was canceled
(L<confirmation_canceled ( )>). So normally you'll use this method instead
of calling all 3 functions, especially if you deal with the
confirmation feature of FormEngine (see L<confirm ( [CONFIRMMSG] )>).

L<make ( )> must be called before calling this method!

=cut

######################################################################

sub ok {
 my $self = shift;
 return $self->is_submitted && (! $self->get_error_count) && (! $self->confirmation_canceled);
}

######################################################################

=head3 get_error_count ( )

Returns the count of errors which where found by the error handler.
L<make ( )> must be called first!

=cut

######################################################################

sub get_error_count {
  my $self = shift;
  return $self->{errcount};
}

######################################################################

=head3 is_submitted ( )

Returns true (1) if the form was submitted, false (0) if not.

=cut

######################################################################

sub is_submitted {
  my $self = shift;
  return $self->{input}->{$self->get_formname()} ? 1 : 0;
}

######################################################################

=head3 errors ( )

Returns I<true> if the form was submitted and errors where found.

=cut

######################################################################

sub errors {
  my $self = shift;
  return $self->is_submitted && $self->get_error_count;
}

######################################################################

=head3 confirmation_canceled ( )

Returns I<true> if the user pressed I<Cancel> when he was asked to
confirm the given input.

=cut

######################################################################

sub confirmation_canceled {
  my $self = shift;
  return defined($self->{input}->{($self->{conf}->{CONFIRM_CANCEL} || $self->{skin_obj}->get_default('main','CONFIRM_CANCEL'))});
}

######################################################################

=head3 get_input ( FIELDNAME )

Returns the input value of the corresponding field.  If it has only
one value a scalar, if it has several values an array is returned.  If
C<set_seperate> was called with 1 (true) it packs the values which
belong together into subarrays.

=cut

######################################################################

#this method simply calls _get_input and turns arrays into scalars if they have only 1 element (that is more user friendly)
#for internal usage _get_input is better because it has a more integrative return value type
sub get_input {
  my($self,$fname) = @_;
  my $res = $self->_get_input($fname);
  for(0..$self->{seperate}) {
    $res = $res->[0] if(ref($res) eq 'ARRAY' and @$res == 1);
  }
  return $res;
}

#an alias for get_input (for being at least a bit backward compatible)
sub get_input_value {
  my $self = shift;
  return $self->get_input(shift);
}

######################################################################

=head3 confirm ( [CONFIRMMSG] )

Calling this method will print the users input data and ask him to
click 'Ok' or 'Cancel'. 'Ok' will submit the data once again and then
C<is_confirmed> will return true (1). 'Cancel' will display the form,
so that the user can change the data.

By default the message defined for I<CONFIRMSG> in I<Skin.pm> will be
displayed, but you can also pass your own text.

=cut

######################################################################

sub confirm {
  my($self,$confirmsg) = @_;

  #$self->{confirm} = 1;
  $self->{conf}->{CONFIRMSG} = $confirmsg if(defined($confirmsg));
  my $skin_orig = $self->{skin_obj};
  $self->set_skin_obj($self->{skin_obj}->get_confirm_skin());
  $self->make();
  $self->set_skin_obj($skin_orig);
  #$self->{confirm} = 0;
  delete $self->{conf}->{CONFIRMSG};
}

#sub text {
#  my $self = shift;
#
#  my $skin_orig = $self->{skin_obj};
#  $self->set_skin_obj($self->{skin_obj}->get_text_skin());
#  $self->make();
#  $self->set_skin_obj($skin_orig);
#}

######################################################################

=head3 is_confirmed ( )

This method returns true (1) when the form input was affirmed by the
user (see L<confirm ( [CONFIRMSG] )>).

=cut

######################################################################

sub is_confirmed {
  my($self) = @_;
  if(defined($self->{input}->{($self->{conf}->{CONFIRMED} || $self->{skin_obj}->get_default('main','CONFIRMED') || $self->{skin_obj}->get_default('default', 'CONFIRMED'))})) {
    return 1;
  }
  return 0;
}

######################################################################

=head2 Methods For Configuring FormEngine

=head3 set_skin_obj ( OBJECT )

If you want to use an alternative skin, call this method. You've to
pass a valid skin object.

An example: C<$form->set_skin_obj(new HTML::FormEngine::SkinComplex)>.

The default skin object is an instance of
C<HTML::FormEngine::SkinClassic>.

For more information please read L<HTML::FormEngine::Skin>.

Of course this method has to be called before calling L<make ( )>.

=cut

######################################################################

sub set_skin_obj {
  my($self, $skin) = @_;
  if(ref($skin)) {
    $self->{skin_obj} = $skin;
    return 1;
  }
  carp("the given data is not a valid skin object!");
  return 0;
}

######################################################################

=head3 get_skin_obj ( )

Returns the currently used skin object.

=cut

######################################################################

sub get_skin_obj {
  my $self = shift;
  return $self->{skin_obj};
}

######################################################################

=head2 Debug Methods

=head3 set_debug ( DEBUGLEVEL )

Sets the debug level. The higher the value the more output is printed
(to STDERR).

=cut

######################################################################

sub set_debug {
  my $self = shift;
  $self->{debug} = shift;
}

######################################################################

=head3 get_method ( )

Returns the value of I<main>s METHOD variable (should be I<get> or I<post>).

=cut

######################################################################

sub get_method {
  my $self = shift;
  return $self->{conf}->{METHOD} || $self->{skin_obj}->get_default('main','METHOD') || $self->{skin_obj}->get_default('default', 'METHOD');
}

######################################################################

=head3 get_formname ( )

Returns the value of I<main>s FORMNAME variable. If you have several
FormEngine forms on one page, these forms mustn't have the same
FORMNAME value!  You can set it with L<set_main_vars ( HASHREF )>.

=cut

######################################################################

sub get_formname {
  my $self = shift;
  return ($self->{conf}->{FORMNAME} || $self->{skin_obj}->get_default('main','FORMNAME') || $self->{skin_obj}->get_default('default','FORMNAME'));
}

######################################################################

=head3 get_conf ( )

Returns a reference to a hash with the current form configuration.
Changing this hash B<doesn't> influence the configuration, because it
is just a copy.

=cut

######################################################################

sub get_conf {
  my ($self, $field) = @_;
  if($field) {
    foreach $_ (keys(%{$self->{conf}->{sub}})) {
      foreach $_ (@{$self->{conf}->{sub}->{$_}}) {
	if($_->{'NAME'} eq $field) {
	  return clone($_);
	}
      }
    }
    return {};
  }
  return clone($self->{conf});
}

######################################################################

=head3 print_conf ( HASHREF )

Prints the given form configuration to STDERR.

=cut

######################################################################

sub print_conf {
  my $self = shift;
  my $conf = shift;
  my $i = shift || 0;
  my $y = 0;
  if(ref($conf) eq 'ARRAY') {
    for($y=0; $y<$i; $y++) { print STDERR " "; }
    print STDERR "ARRAY\n";
    foreach $_ (@{$conf}) {
      $self->print_conf($_, $i+1);
    }
  }
  elsif(ref($conf) eq 'HASH') {
    foreach $_ (keys(%{$conf})) {
      for($y=0; $y<$i; $y++) { print STDERR " "; }
      print STDERR $_, "\n";
      $self->print_conf($conf->{$_}, $i+1);
    }
  }
  else {
    for($y=0; $y<$i; $y++) { print STDERR " "; } 
    print STDERR $conf, "\n";
  }
}

######################################################################

=head2 Special Features

=head3 nesting templates

There are two ways how you can nest templates. The first one is to put
a handler call in the template definition. This is a less flexible
solution, but it might be very usefull. See L<HTML::FormEngine::Skin>
for more information.

The second and flexible way is, to assign a handler call to a template
variable (see L<HTML::FormEngine::Skin> for more information about
handler calls).  A good example for this way is hobbies.cgi. There you
have a option called I<other> and an input field to put in the name of
this alternative hobby. When you look at the form definition below,
you see that the value of the I<OPTION> variable of this option is
simply I<<&_text&>>, this is a handler call. So the handler is called
and its return value (in this case the processed C<_text> template) is
assigned to the variable.

The form definition of hobbies.cgi:

    my @form = (
	    {
	      templ => 'check',
	      NAME  => 'hobbie',
	      TITLE => 'Hobbies',
	      OPTION => [['Parachute Jumping', 'Playing Video Games'], ['Doing Nothing', 'Soak'], ['Head Banging', 'Cat Hunting'], "Don't Know", '<&_text&>'],
	      OPT_VAL => [[1,2], [3,4], [5,6], 7, 8],
	      VALUE => [1,2,7],
	     'sub' => {'_text' => {'NAME' => 'Other', 'VALUE' => '', ERROR => ''}},
	      ERROR_IN => sub{if(shift eq 4) { return "That's not a faithfull hobby!" }}
	    }
    );

If you have a closer look at the form definition above, you'll
recognize that there is a key called 'sub'. With help of this key you
can define the variables of the nested templates. If the nested
templates don't use the same variable names as their parents, you
don't need that, because then you can assign these variables on the
same level with the parents template variables.

=cut

######################################################################
# INTERNAL METHODS                                                   #
######################################################################

#this method is called by the constructor in initializes the object variables and settings
sub _initialize {
  my ($self,$input) = @_;

  #
  Hash::Merge::set_behavior('LEFT_PRECEDENT');

  # the form input
  $self->{input} = {};
  $self->set_input($input);
  # count of errors
  $self->{errcount} = 0;
  # whether to display the input again after the form was submitted
  $self->{use_input} = 1;
  # whether to check the input
  $self->{check_error} = 1;
  # the html/xhtml form code
  $self->{cont} = '';
  # the form configuration/layout
  $self->{conf} = {};
  # need for set_main_vars()
  $self->{conf_main} = {};
  # whether the make() method has to be called before returning the generated html/xhtml code (see get() method)
  $self->{call_make} = 0;
  # whenever the make() method is called the functions listed referenced in this array are being called too
  $self->{call_before_make} = [
			       sub {
				 my($self) = @_;
				 $self->{values} = {};
				 $self->{nconf} = {'main' => [clone($self->{conf})]};
				 $self->{varstack} = [];
				 $self->{varstack_defaults} = [];
			       }
			      ];

  # the level of nested templates that we currently are in (templates starting with "_" don't count)
  $self->{depth} = 0;
  # whether a special field-content should be submitted with the user made input to seperate fields with the same name from each other
  $self->{seperate} = 0;
  # object variables that have to be reseted to 0 when the "#seperate" handler is called and a field-seperation code is returned
  $self->{reset_on_seperate} = [];
  # saves the iteration count per global loop (loops that don't specify any variables) (see e.g. Skin.pm for more information on loops)
  $self->{loop} = [];
  # saves the iteration count foreach variable on all loop levels
  $self->{loop_var} = {};
  # if on a certain global loop level at least one variable has a next element, this is setted to 1 for that level which means
  # that the loop will be executed again
  $self->{loop_deep} = [];
  # this is the same as loop_deep but for none-global loops that means for loops which do specify special variables on which they iterate
  # then its saved per variable and its enough if only one variable has another element for the loop to be executed again
  $self->{loop_deep_var} = {};
  # this is for future release, there'll be a feature to say that if one variable has not a next element the loop should be finished.
  $self->{loop_deep2} = [];

  # see e.g. Skin.pm for possibilities on how to modify the skin
  $self->set_skin_obj(new HTML::FormEngine::SkinClassic);
}

# this function is for child classes of FormEngine.pm, instead of the constructor they should overwrite this function,
# so that the original constructor of this class is still called
sub _initialize_child {};

sub _check_conf {
  # the array notation is more user friendly
  # here we rewrite it into the internal hash notation.
  # users are allowed to use the more flexible but also more complicated
  # hash notation directly.

  my ($self,$conf) = @_;
  my ($templ, $tmp);

  #an array of field definitions is transformed into an internal useable hash
  if(ref($conf) eq 'ARRAY' && ref($conf->[0]) eq 'HASH') {
    my %cache = ();
    $cache{'sub'} = {};
    $cache{'TEMPL'} = [];
    foreach $_ (@{$conf}) {
      #default template is 'text'
      $templ = $_->{templ}||$self->{skin_obj}->get_default('default','templ');
      delete $_->{templ};
      #hidden templates must be handled special so that they don't use any visible space
      if($self->{skin_obj}->is_hidden($templ)) {
	$cache{'HIDDEN'} = [] unless(ref($cache{'HIDDEN'}) eq 'ARRAY');
	push @{$cache{'HIDDEN'}}, "<&$templ&>";
      }
      #TEMPL is a special variable which contains the list of subtemplates
      else {
	push @{$cache{'TEMPL'}}, "<&$templ&>";
      }
      if(ref($cache{sub}->{$templ}) ne 'ARRAY') {
	$cache{sub}->{$templ} = [];
      }
      push @{$cache{sub}->{$templ}}, $self->_check_conf($_);
    }
    $conf = \%cache;
  }
  #hash notation is already used
  elsif(ref($conf) eq 'HASH' && ref($conf->{sub}) eq 'HASH') {
    $conf->{TEMPL} = [] unless(ref($conf->{TEMPL}) eq 'ARRAY');
    foreach $_ (keys(%{$conf->{sub}})) {
      if(ref($conf->{sub}->{$_}) eq 'HASH') {
	$conf->{sub}->{$_} = [$self->_check_conf($conf->{sub}->{$_})];
      }
      elsif(ref($conf->{sub}->{$_}) eq 'ARRAY') {
	foreach $_ (@{$conf->{sub}->{$_}}) {
	  $_ = $self->_check_conf($_) if(ref($_) eq 'HASH');
	}
      }
    }
  }
  #transform to hash notation and fillup TEMPL resp HIDDEN
  elsif(ref($conf) eq 'HASH' && ref($conf->{sub}) eq 'ARRAY') {
    $tmp = $self->_check_conf($conf->{sub});
    if(ref($tmp) eq 'HASH') {
      $conf->{sub} = $tmp->{sub};
      $conf->{TEMPL} = $tmp->{TEMPL};
      $conf->{HIDDEN} = $tmp->{HIDDEN};
    }
  }

  #NEW --- TESTING ----

  #if(ref($conf->{OPTION}) eq 'HASH') {
  #  if(!defined($conf->{OPT_VAL})) {
  #    my @option;
  #    foreach $_ (keys(%{$conf->{OPTION}})) {
  # 	#...
  #    }
  #  } else {
  #    carp "want to rewrite OPTION-Hash to OPTION-Array and OPT_VAL-Array, but OPT_VAL is already being used!";
  #  }
  #}

  return $conf;
}

sub _get_var {
  # here we go through the variable stack (from highest to lowest level)
  # we break out of the loop if a value was found.
  # "varstack_defaults" contains the defaults and is searched when we don't find a certain value on the normal varstack
  # we return undef if there is no value defined for a certain variable

  my ($self,$var,@history) = @_;
  my $res = undef;

  return $res unless($var ne '');

  #TEMPL and HIDDEN must be handled special since they're only valid on the level where they're defined
  if($var eq 'TEMPL' || $var eq 'HIDDEN') {
    $res = defined($self->{varstack}->[-1]->{$var}) ? $self->_get_var_elem($var, $self->{varstack}->[-1]->{$var}) : undef;
  } else {
    
    my $value = undef;
    for(my $i=@{$self->{varstack}} - 1; $i>=0; $i--) {
      if(defined($self->{varstack}->[$i]->{$var})) {
	$res = $self->_get_var_elem($var, $self->{varstack}->[$i]->{$var});
	last;
      }
    }
    
    if(!defined($res)) {
      #nothing found on normal varstack, lets search in the defaults
      for (my $i=@{$self->{varstack_defaults}} -1; $i>=0; $i--) {
	if(defined($self->{varstack_defaults}->[$i]->{$var})) {
	  $res = $self->_get_var_elem($var, $self->{varstack_defaults}->[$i]->{$var});
	  last;
	}
      }
    }
  }

  #recognizing endless recursions
  if(defined($res) && ref($res) eq '') {
    return undef if(@history && grep {$res =~ m/<&$_&>/} @history);
    $res = $self->_parse($res, @history, $var);
  }

  #if nothing is found at all $res is undef
  return $res;
}

# sometimes variables contain arrays. this method returns the right array element due to the loop level and status.
# it is called by _get_var()
sub _get_var_elem {
  my($self, $var, $res) = @_;
  if(ref($res) eq 'ARRAY' and defined($self->{loop_var}->{$var}) || @{$self->{loop}} > 0) {
    my $loop;
    my $flag = 0;
    if(defined($self->{loop_var}->{$var})) {
      $loop = $self->{loop_var}->{$var};
    }
    elsif($var ne 'TEMPL') {
      $loop = $self->{loop};
      $flag = 1;
    }

    if(ref($loop) eq 'ARRAY') {
      for(my $i = 0; $i<@{$loop}; $i++) {
	if(defined($res->[$loop->[$i] +1])) {
	  $flag ? $self->{loop_deep}->[$i] = 1 : $self->{loop_deep_var}->{$var}->[$i] = 1;
	}
	elsif($flag) {
	  $self->{loop_deep2}->[$i] = 0;
	}
	$res = $res->[$loop->[$i]];
	return '' unless(defined($res));
	if(ref($res) ne 'ARRAY') {
	  return $res;
	}
      }
    }
  }
  return $res;
}

# this function sets an (variable,value) pair on the current stack level
# it can be usefull for certain handlers (see Handler.pm)
sub _set_var {
  my ($self,$var,$value) = @_;
  print "$var => $value\n" if($self->{debug});
  $self->{varstack}->[@{$self->{varstack}} -1]->{$var} = $value;
}

sub _parse {
  # here the templates are parsed into one resulting form, following the given configuration
  # this job is realized by calling _parse recursive

  # $cont contains the string which is to be parsed/interpreted
  # @history is passed when replacing <&[A-Z]&> variables, it is used to avoid endless recursions
  my ($self,$cont, @history) = @_;
  
  # the current char
  my $p = '';
  # the old char
  my $old = '';
  # contents of a certain area (like <& ..content.. &>)
  my $match = '';
  # position where the area started
  my $c = 0;
  # areas (sections) can be nested, %f just saves the level of nesting foreach area type (&, ~ and !)
  my %f;

  $cont = '' unless(defined($cont));
  for(my $i=0; $i<length($cont); $i++) {
    $old = $p;
    $p = substr($cont,$i,1);
    $match .= $p if($c);
    #here we find a starting tag like <& or <~ or <!
    ($c == 0 ? ($c=$i) : 1) && ++$f{$p} && next if($old eq '<' and grep {$p eq $_} ('&','~','!'));
    #here it is closed: &> or ~> or !>
    if($c > 0 and grep {$old eq $_} ('&','~','!') and $p eq '>') {
      my $res = undef;
      $f{$old}--; 
      #none of the < .. > sections must be opened! for every <(&|~|!) there must be a matching (&|~|!)>
      unless(grep {$_ > 0} values(%f)) {
	# replace variables with theire values
	if($match =~ m/^([A-Z_]+)&>$/) {
	  # @history, $1 is passed do recognize endless recursions
	  $res = $self->_get_var($1,@history,$1);
	  $res = '' unless(defined($res));
	}
	# handler calls
	elsif($match =~ m/^(.*)&>$/) {
	  local $_ = $self->_parse($1);
	  if(m/^(#?[a-z_]+[a-z_0-9]+)(?: (.*?))?$/) {
	    my $templ = $1;
	    my $args = $2;
	    my @args;
	    if(defined($args)) {
	      #we must prevent escaped commas from being interpreted
	      $args =~ s/\\,/#"\!§\$/g;
	      #get list of arguments
	      @args = split(/,/,$args);
	      push @args, '' if($args =~ m/^,$/);
	      #replace escaped commas with normal commas
	      local $_;
	      foreach $_ (@args) { s/#"\!§\$/,/g; }
	    }
	    
	    my $pupo = 0;
	    my $pupo_defaults = $self->_push_varstack($self->{skin_obj}->get_default($templ), 'varstack_defaults');
	    my $nconf_back = $self->{nconf};

	    if(ref($self->{nconf}->{$templ}) eq 'ARRAY' && ref($self->{nconf}->{$templ}->[0]) eq 'HASH') {
	      
	      # define new nconf
	      if(ref($self->{nconf}->{$templ}->[0]->{sub}) eq 'HASH') {
		
		# in case that we go on a deeper level we have to get the definitions for that level (_parse() works recursive)
		$self->{nconf} = $self->{nconf}->{$templ}->[0]->{sub};

	      } else {
		#not sure if that's a good idea. its a bugfix.
		$self->{nconf} = {};
	      }
	      
	      # soon we will store the definitions for the found subtemplate on the variable stack.
	      # sub isn't a variable, behind this key the subsubtemplate definitions are stored, those
	      # we allready extracted above.
	      # so we now delete this key to prevent it from being pushed on the variable stack.
	      if(defined($nconf_back->{$templ}->[0]->{sub})) {
		delete $nconf_back->{$templ}->[0]->{sub};
	      }
	      # shift is important! so next time the definition underneath will be the first one and thus be grabbed
	      my $cache = shift @{$nconf_back->{$templ}};
	      
	      # push the (completed) definitions
	      $pupo = $self->_push_varstack($cache);
	    }

	    my $handler;
	    # set handler
	    if(! ($handler = $self->{skin_obj}->get_handler($templ))) {
	      $handler = $self->{skin_obj}->get_handler('default');
	    }

	    #TEMPL and HIDDEN are only valid on one level so we also have to set the loop-level and status back to default
	    my $loop_templ_back = [$self->{loop_var}->{TEMPL}, $self->{loop_var}->{HIDDEN}];
	    my $loop_deep_templ_back = [$self->{loop_deep_var}->{TEMPL}, $self->{loop_deep_var}->{HIDDEN}];
	    $self->{loop_var}->{TEMPL} = [];
	    $self->{loop_var}->{HIDDEN} = [];
	    $self->{loop_deep_var}->{TEMPL} = [];
	    $self->{loop_deep_var}->{HIDDEN} = [];

	    #templates that begin with _ do not count
	    unless($templ =~ m/^_/) {
	      $self->{depth} ++; 
		$res = &$handler($self,$templ,@args);
	      $self->{depth} --;

	    } else {
	      $res = &$handler($self,$templ,@args);
	    }

	    #above we setted these settings to default because we were changing levels, now that we're back we have to set the original settings again
	    $self->{loop_var}->{TEMPL} = $loop_templ_back->[0];
	    $self->{loop_var}->{HIDDEN} = $loop_templ_back->[1];
	    $self->{loop_deep_var}->{TEMPL} = $loop_deep_templ_back->[0];
	    $self->{loop_deep_var}->{HIDDEN} = $loop_deep_templ_back->[1];

	    $res = '' unless(defined($res));

	    #we're back
	    $self->{nconf} = $nconf_back;

	    # pop as many as there were pushed before (can only be 0 or 1)
	    $self->_pop_varstack($pupo);
	    $self->_pop_varstack($pupo_defaults, 'varstack_defaults');
	  } else {
	    #the <&&> is empty... i'm not sur if its a good idea ... but we replace it by nothing:
	    $res = '';
	  }
	}
	# parse loops
	elsif($match =~ m/^(.*)~([A-Z_ ]*)~>$/s) {
	  my $body = $1;
	  my @itvars = split(' ', $2);
	  # a global loop, no loop variables defined so we loop over all variables
	  if(!@itvars) {
	    push @{$self->{loop}}, 0;
	    $self->{loop_deep}->[@{$self->{loop}}-1] = 0;
	    $self->{loop_deep2}->[@{$self->{loop}}-1] = 1;
	    foreach $_ (keys(%{$self->{loop_var}})) {
	      push @{$self->{loop_var}->{$_}}, 0;
	      $self->{loop_deep_var}->{$_}->[@{$self->{loop_var}->{$_}}-1] = 0;
	    }
	  }
	  else {
	    foreach $_ (@itvars) {
	      unless(defined($self->{loop_var}->{$_})) {
		$self->{loop_var}->{$_} = [];
		$self->{loop_deep_var}->{$_} = [] unless(defined($self->{loop_deep_var}->{$_}));
		# we copy the global status into the new variable statuses, its easier to handle like that
		#TEMPL and HIDDEN are only valid on one level and should not be affected by global loops
		if($_ ne 'TEMPL' && $_ ne 'HIDDEN') {
		  for(my $i=0; $i<@{$self->{loop}}; $i++) {
		    $self->{loop_var}->{$_}->[$i] = $self->{loop}->[$i];
		    $self->{loop_deep_var}->{$_}->[$i] = $self->{loop_deep}->[$i];
		  }
		}
	      }
	      push @{$self->{loop_var}->{$_}}, 0;
	      $self->{loop_deep_var}->{$_}->[@{$self->{loop_var}->{$_}}-1] = 0;
	    }
	  }

	  $res = '';
	  while(1) {
	    # parse and append
	    $res .= $self->_parse($body);
	    if(!@itvars) {
	      unless($self->{loop_deep}->[@{$self->{loop}}-1]) {
		my $flag = 0;
		foreach $_ (keys(%{$self->{loop_var}})) {
		  do {$flag=1; last;} if($self->{loop_deep_var}->{$_}->[@{$self->{loop_var}->{$_}}-1]);
		}
		do {last;} unless($flag);
	      }
	      $self->{loop}->[-1] ++;
	      foreach $_ (keys(%{$self->{loop_var}})) {
		$self->{loop_deep_var}->{$_}->[@{$self->{loop_var}->{$_}}-1] = 0;
		$self->{loop_var}->{$_}->[@{$self->{loop_var}->{$_}}-1] ++;
	      }
	      $self->{loop_deep}->[@{$self->{loop}}-1] = 0;
	    }
	    else {
	      my $flag = 0;
	      foreach $_ (@itvars) {
		  do {$flag=1; last;} if($self->{loop_deep_var}->{$_}->[@{$self->{loop_var}->{$_}}-1]);
	      }
	      do {last;} if(!$flag);
	      foreach $_ (@itvars) {
		$self->{loop_deep_var}->{$_}->[@{$self->{loop_var}->{$_}}-1] = 0;
		$self->{loop_var}->{$_}->[-1] ++;
	      }
	    }
	  }

	  if(!@itvars) {
	    pop @{$self->{loop}};
	    foreach $_ (keys(%{$self->{loop_var}})) {
	      pop @{$self->{loop_var}->{$_}};
	    }
	  }
	  else {
	    foreach $_ (@itvars) {
	      pop @{$self->{loop_var}->{$_}};
	      delete $self->{loop_var}->{$_} unless(@{$self->{loop_var}->{$_}});
	    }
	  }
	}
	# parse <! ... ! !> sections
	elsif($match =~ m/^(.*)\!(?:([A-Z_ ]+)|([A-Z_\|]+))\!>$/s) {
	  my $code = $1;
	  my $tmp = 0;
	  $res = '';
	  if(defined($2) and $2 ne '') {
	    local $_ = $2;
	    #check all variables, all must have a scalar value (ARRAYS are not allowed)
	    foreach $_ (split(' ',$_)) {
	      $_ = $self->_get_var($_);
	      ++$tmp && last unless(defined($_) and $_ ne '' and !ref($_));
	    }
	    $res = $code unless($tmp);
	  }
	  elsif(defined($3) and $3 ne '') {
	    $_ = $3;
	    #check all variables, one of them must have a scalar value (ARRAYS are not allowed)
	    foreach $_ (split('\|',$_)) {
	      $_ = $self->_get_var($_);
	      ++$tmp && last if(defined($_) and $_ ne '' and !ref($_));
	    }
	    $res = $code if($tmp);
	  }
	  $res = $self->_parse($res) if($res ne '');
	}

	#a variable-value found? a handler called? a section interpreted?
	if(defined($res)) {

	  #a little bit dirty: if $res is an array and everything is replaced by it we return it as array and not as string
          #this is necessary to support default settings like "OPT_VAL => <&OPTION&>"... if we wouldn't do it a string like 'ARRAY0xff45' would be returned if OPTION is an ARRAY
	  if(ref($res) eq 'ARRAY' && $c==1 && $i == length($cont)-1) {
	    return $res;
	  }

	  #we have to replace the <(&|~|!) ... (&|~|!)> stuff with the result
	  #$c contains the position of the first (&|~|!) $i the position of the last
	  $cont = substr($cont,0,$c-1) . $res . substr($cont,$i+1);
	  #we've to add the length diffrence between the code and the result
	  $i += length($res)-length($match)-2;
	}
	#reset variables
	$match = '';
	$c = 0;
      }
    }
  }
  return $cont;
}

#create a new level on the variable stack and fill it with the given values
sub _push_varstack {
  my ($self,$add, $name) = @_;
  if(ref($add) eq 'HASH') {
    #DEBUGGING
    if($self->{debug}) {
      local $_;
      foreach $_(keys(%{$add})) {
	for(my $i=0; $i<@{$self->{$name||'varstack'}}; $i++) {
	  print STDERR " ";
	}
	print STDERR "$_:", $add->{$_}, "\n";
      }
    }

    # the following code is a little hack to make writing form configurations a bit easier and more logic
    # the sub-sections seem to be independ because recursion-layers are automatically added
    local $_;
    foreach $_ (keys(%{$add})) {
      #TEMPL and HIDDEN are valid only for one level anyway so we must not care about them
      if($_ ne 'TEMPL' and $_ ne 'HIDDEN') {
	if(ref($add->{$_}) eq 'ARRAY') {
	  my $max;
	  if(defined($self->{loop_var}->{$_})) {
	    $max = @{$self->{loop_var}->{$_}};
	  } else {
	    $max = @{$self->{loop}};
	  }
	  for(my $i=0; $i<$max; $i++) {
	    $add->{$_} = [$add->{$_}];
	  }
	}
      }
    }

    push @{$self->{$name||'varstack'}}, $add;
    return 1;
  }
  return 0;
}

#remove level(s) from the variable stack (starting from the highest)
sub _pop_varstack {
  my ($self,$howmany,$name) = @_;
  my $i;
  for($i=0; $i<$howmany; $i++) {
    #DEBUGGING
    if($self->{debug}) {
      print STDERR "rm\n";
    }
    pop @{$self->{$name||'varstack'}};
  }
  return $i;
}

# returns the value for the currently parsed field
sub _get_value {
  my ($self,$namevar,$valuevar,$force) = @_;
  my $res;

  $valuevar = 'VALUE' unless(defined($valuevar));
  $namevar = 'NAME' unless(defined($namevar));

  #force_value forces to not return the submitted, but to return the configured value
  #$force forces to return the submitted in any case
  if(($self->is_submitted && $self->{use_input} && !$self->_get_var('force_value')) || $force) {
    local $_ = $self->_get_var($namevar);
    $res = $self->_get_input($_);
    #$self->{values} is increased with by the seperate handler
    $res = $res->[$self->{values}->{$_}||0] if(ref($res) eq 'ARRAY');
  }
  else {
    #return the configured (default) value
    $res = $self->_get_var($valuevar);
  }

  return defined($res) ? $res : ''
}

#adds a new field to the end of the form
sub _add_to_output {
  my($self,$templ,$def) = @_;
  if($templ && ref($def) eq 'HASH') {
    #add the template
    push @{$self->{conf}->{TEMPL}}, '<&' . $templ . '&>';
    $self->{conf}->{sub}->{$templ} = [] unless (ref($self->{conf}->{sub}->{$templ}) eq 'ARRAY');
    #add the definition
    push @{$self->{conf}->{sub}->{$templ}}, $def;
    $self->{call_make} = 1 if($self->{cont});
  }
}

#this methods turns an n-dimensional array into an 1 dimensional
sub _flatten_array {
  my($self,@array) = @_;
  my @res;
  foreach $_ (@array) {
    (ref($_) ne 'ARRAY') ? (push @res, $_) : (push @res, $self->_flatten_array(@$_));
  }
  return @res;
}

#this function is called by get_input
sub _get_input {
  my ($self,$fname) = @_;
  if(defined($fname) and $fname ne '') {
    if(ref($self->{input}->{$fname}) eq 'ARRAY') {
      my $res = [];
      my @tmp = ();
      for(my $i = 0; $i<@{$self->{input}->{$fname}}; $i++) {
	local $_ = $self->{input}->{$fname}->[$i];
	#SEPVAL seperates the value groups which belong together
	push @tmp, $_ if((!$self->{seperate}) or ($_ ne ($self->{conf}->{SEPVAL} || $self->{skin_obj}->get_default('main','SEPVAL'))));
	if($_ eq ($self->{conf}->{SEPVAL} || $self->{skin_obj}->get_default('main','SEPVAL')) or $i+1 == @{$self->{input}->{$fname}}) {
	  push @$res, @tmp > 1 ? [@tmp] : @tmp;
	  @tmp = ();
	}
      }
      return $res;
    }
    else {
      return (defined($self->{input}->{$fname}) and (!$self->{seperate} or $self->{input}->{$fname} ne ($self->{conf}->{SEPVAl} || $self->{skin_obj}->get_default('main', 'SEPVAL')))) ? $self->{input}->{$fname} : undef;
    }
  }
  return undef;
}

######################################################################

=head1 EXTENDING FORMENGINE

=head2 Modify A Skin

To set the current skin, use the method L<set_skin_obj ( OBJECT )>. To
Modify it you should have a look at L<HTML::FormEngine::Skin>.

=head2 Extending Or Writing A Skin

Have a look at L<HTML::FormEngine::Skin> for this task and especially
read its source code and the code and documentation of the other skin
packages.  You can easily change the layout by copying the skin hash,
fitting the html code to your needs and then using L<set_skin_obj (
OBJECT )> to overwrite the default.  Please send me your skins.

=head2 Write A Handler

Read L<HTML::FormEngine::Handler>. Also read L<HTML::FormEngine::Skin>
on how to make the handler available. To make it persistent see
L<Extending Or Writing A Skin>.

=head2 Write A Check Routine

The design of a check routine is explained in
L<HTML::FormEngine::Checks>.  You can easily refer to it by reference
or even define it in line as an anonymous function (see the ERROR
template variable).  If your new written routine is of general usage,
you should make it part of FormEngine by placing it in Checks.pm and
refering to it from Skin.pm. For more read L<HTML::FormEngine::Skin>.
Please send me your check methods!

=head1 MORE INFORMATION

Have a look at ...

=over

=item

L<HTML::FormEngine::Skin>, L<HTML::FormEngine::SkinComplex>,
L<HTML::FormEngine::SkinClassic>,
L<HTML::FormEngine::SkinComplexConfirm>,
L<HTML::FormEngine::SkinClassicConfirm> and the modules source code
for information about FormEngines template and skin system.

=item

L<HTML::FormEngine::Handler> and the modules source code for
information about FormEngines handler architecture.

=item

L<HTML::FormEngine::Checks> and the modules source code for
information about FormEngines check methods.

=back

=head1 BUGS

Please use L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-FormEngine>
to inform you about reported bugs and to report bugs.

If it doesn't work feel free to email directly to
moritz@freesources.org.

Thanks!

=head1 AUTHOR

(c) 2003-2004, Moritz Sinn. This module is free software; you can
redistribute it and/or modify it under the terms of the GNU General
Public License (see http://www.gnu.org/licenses/gpl.txt) as published
by the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

    This module is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

I am always interested in knowing how my work helps others, so if you
put this module to use in any of your own code please send me the
URL. If you make modifications to the module because it doesn't work
the way you need, please send me a copy so that I can roll desirable
changes into the main release.

Please use L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-FormEngine>
for comments, suggestions and bug reports. If it doesn't work feel
free to mail to moritz@freesources.org.

=head1 CREDITS

Special thanks go to Darren Duncan. His HTML::FormTemplate module gave
me a good example how to write a documentation. There are several
similarities between HTML::FormEngine and HTML::FormTemplate, we both
came to an related API design, the internal processes are completly
diffrent. It wasn't my purpose to have these api design decisions in
common with HTML::FormTemplate. When i wrote the php version of
HTML::FormEngine, i didn't know anything about
HTML::FormTemplate. Later i just ported this php class to perl. I
think we both came to an likewise API because its just the most
obvious solution.

Features which FormEngine has and FormTemplate hasn't:

=over

=item

Skinsystem

=item

More flexible validation and error message report

=item

Common checking methods are predefined, others can be added on the fly

=item

Internationalization with help of gettext

=item

Due to the handler system and the modular design FormEngine can easily
be extended

=item

A flexible set of methods to let the user confirm his input

=back

Features which FormTemplate has and FormEngine hasn't:

I<This list will be filled in later.>

(I asked the author to send me some notes, he told me he'll do so at
opportunity.)

=head1 SEE ALSO

HTML::FormTemplate by Darren Duncan

=cut

1;

__END__
