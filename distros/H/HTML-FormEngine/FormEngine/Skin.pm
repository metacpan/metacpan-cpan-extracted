=head1 NAME

HTML::FormEngine::Skin - FormEngines basic skin package

=head1 THE TEMPLATE SYSTEM

The parsing of the templates is done from left to right and from top
to bottom!

=head2 Variables

Variables must have the following format:

<&[A-Z_]+&>

When the template is processed these directives are replaced by the
variables value. If no value was defined, the default value is used,
if even this is missing, they're just removed.

Variables, defined for a certain template, are valid for all
subtemplates too!

=head2 Handler calls

You can call a handler out of a template and so replace the call
directive with the handlers return value.

A handler name must match the follwing regular expression:
I<#?[a-z_]+[a-z_0-9]+>.

Optionally one can pass arguments to a handler.  E.g. C<<&error
ERROR_IN&>> calls the error handler and passes to it ERROR_IN as
argument. Mostly handlers are called without any arguments,
e.g. C<<&value&>>, which calls the value handler.

Handler calls can also be nested, e.g. like this: C<< <&<&arg 1&>
ERROR_IN&> >>.  In that example first C<< <&arg 1&> >> is called, the result
is expected to be the name of a handler which is then called with
I<ERROR_IN> as argument.

The handlers are normally defined in Handler.pm, but you can also
define them directly in the skin or wherever you think it fits
best. Important is that they're registered correctly by the skin. Read
L<HTML::FormEngine::Skin>, L<HTML::FormEngine::SkinComplex> and
L<HTML::FormEngine::SkinClassic> for more information.

The default handler is used for processing templates. So if you want
to nest templates, you might use the templates name as a handler name
and so call the default handler which will return the processed
template code.

To distinguish handler calls from template calls a I<#> is added
infront of the name if a existing handler and not the default handler
is to be called. This is only a convention and not necessary from the
technical point of view.

For more information about handlers, see the
L<HTML::FormEngine::Handler>.

=head2 Loops

If you want to repeat a certain template fragment several times, you
can use the following notation:

<~some lines of code~LOOPVARIABLES SEPERATED BY SPACE~>

If one or more loop variables are array references, the loop is
repeated until the last loop variable as no element left. If all loop
variables are scalars, the code is only printed once. If one ore more,
but not all loop variables are scalars, these scalar variables have in
every repetition the same value. If a loop variable is an array
reference, but has no elements left, it has the NULL value in the
following repetitions.

You can nest loops. For example the ClassicSkin uses this feature: If
you use one dimensional arrays, the text fields are printed each on a
single line, if you use two dimensional arrays, you can print several
text fields on the same line.

Since FormEngine 1.0 you can also define loops without specifying loop
variables. These loops are called global loops and they iterate over
all used variables. That means as long as one of the variables used in
the loops content has another element the loop is repeated. For
example the I<row> template of the ComplexSkin uses this feature.

=head2 <! !> Blocks

Code that is enclosed in '<! ... ! VARIABLENAMES !>', is only printed
when all variables which are mentioned in VARIABLENAMES are defined
(that means not empty). If you seperate the variable names by '|'
instead of ' ', only one of these variables must be defined.

=cut

######################################################################

package HTML::FormEngine::Skin;

use Locale::gettext;
use Digest::MD5 qw(md5_hex);
use Hash::Merge qw(merge);

######################################################################

=head1 HTML::FormEngine::Skin

This class is abstract and not a complete skin class but its the basis
of all skins. That means all methods defined here are available in all
skins.  In case you write your own skin you should also base it on
this class if it makes sense. if not you should at least support the
same methods.

=head2 Methods

=head3 new ([ $textdomain ])

This method is the constructor. It returns the skin object.
Optionally you can pass it the path to your locale directory.  By
default this is C</usr/share/locale>.  It is needed for C<gettext>
which translates the error messages and other stuff.

=cut

######################################################################

sub new {
  my ($class,$textdomain) = @_;
  my $self = bless({}, ref($class) || $class);
  $self->_textdomain($textdomain);
  $self->_init();
  return $self;
}

######################################################################

=head3 set_textdomain ( $textdomain )

Use this method to set the textdomain. Default is C</usr/share/locale>.

=cut

######################################################################

sub set_textdomain {
  my $self = shift;
  $self->_textdomain(shift);
}

######################################################################

=head3 get_templ ([ $name ])

Returns the definition of the template with the given name.

If no name is given a hash reference containing all templates is
returned.

=cut

######################################################################

sub get_templ {
  my($self, $name) = @_;
  return $self->{templ}->{$name} if($name);
  return $self->{templ};
}

######################################################################

=head3 set_templ ( HASHREF )

Overwrites all template definitions. Not recommended.

=cut

######################################################################

sub set_templ {
  my($self, $templ) = @_;
  $self->{templ} = $templ and return 1 if(ref($templ) eq 'HASH');
  return 0;
}

######################################################################

=head3 alter_templ ( HASHREF )

If you only want to add or overwrite some templates, call this method.
You have to pass a reference to the hash which stores these templates.

=cut

######################################################################

sub alter_templ {
  my ($self,$alter) = @_;
  $self->{templ} = merge($alter, $self->{templ}) and return 1 if(ref($alter) eq 'HASH');
  return 0;
}

######################################################################

=head3 get_default ( [$templ, $var] )

If no arguments specified it just returns all default settings in a
hash reference.

If $templ is given it returns the default settings for template $templ.

If $var is also given it returns the default setting of the variable
$var in template $templ.

=cut

######################################################################

sub get_default {
  my($self, $templ, $var) = @_;
  if(defined($templ)) {
    if(defined($var)) {
      return $self->{default}->{$templ}->{$var} if(defined($self->{default}->{$templ}->{$var}));
      return $self->{default}->{main}->{$var} if(defined($self->{default}->{main}->{$var}));
      return $self->{default}->{default}->{$var};
    }
    return $self->{default}->{$templ};
  }
  return $self->{default};
}

######################################################################

=head3 set_default ( HASHREF )

By using this method, you completly reset the default values of the
template variables. You have to pass a reference to the hash which
stores the new settings. In most cases you better call
L<alter_default ( HASHREF )>.

=cut

######################################################################

sub set_default {
  my($self, $default) = @_;
  $self->{default} = $default and return 1 if(ref($default) eq 'HASH');
  return 0;
}

######################################################################

=head3 alter_default ( HASHREF )

Pass a hash reference to this method for adding or overwriting default
values.

=cut

######################################################################

sub alter_default {
  my ($self,$alter) = @_;
  $self->{default} = merge($alter, $self->{default}) and return 1 if(ref($alter) eq 'HASH');
  return 0;
}

######################################################################

=head3 get_handler ([ $name ])

If $name is given it returns a reference to the handler having the
given name.

If not it returns a hash reference containing all handlers.

=cut

######################################################################

sub get_handler {
  my($self, $name) = @_;
  return $self->{handler}->{$name} if($name);
  return $self->{handler};
}

######################################################################

=head3 set_handler ( HASHREF )

This method resets the handler settings. If you just want to add or
overwrite a handler setting,  use L<alter_handler ( HASHREF )>.

=cut

######################################################################

sub set_handler {
  my($self, $handler) = @_;
  $self->{handler} = $handler and return 1 if(ref($handler) eq 'HASH');
  return 0;
}

######################################################################

=head3 alter_handler ( HASHREF )

This method adds or overwrites template handlers. Have a look at
Handler.pm for more information.

=cut

######################################################################

sub alter_handler {
  my ($self,$alter) = @_;
  $self->{handler} = merge($alter, $self->{handler}) and return 1 if(ref($alter) eq 'HASH');
  return 0;
}

######################################################################

=head3 get_check ([ $name ])

If $name is given it returns a reference to the check function
registered by the skin as $name.

If $name is not given it returns a hash reference containing all check
functions.

=cut

######################################################################

sub get_check {
  my($self, $name) = @_;
  return $self->{check}->{$name} if($name);
  return $self->{check};
}

######################################################################

=head3 set_check ( HASHREF )

This method resets the check settings. If you just want to add or
overwrite a check function,  use L<alter_check ( HASHREF )>.

=cut

######################################################################

sub set_check {
  my($self, $check) = @_;
  $self->{check} = $check and return 1 if(ref($check) eq 'HASH');
  return 0;
}

######################################################################

=head3 alter_check ( HASHREF )

This method adds or overwrites check routines. Have a look at
Checks.pm for more information.

=cut

######################################################################

sub alter_check {
  my ($self,$alter) = @_;
  $self->{check} = merge($alter, $self->{check}) and return 1 if(ref($alter) eq 'HASH');
  return 0;
}

######################################################################

=head3 is_hidden ( $templ ) 

Returns 1 (true) if the template with the given name is registered as
I<hidden>. Also see L<set_hidden ( ARRAY )>

=cut

######################################################################

sub is_hidden {
  my ($self,$templ) = @_;
  return $self->{hidden}->{$templ} if($templ);
  return 0;
}

######################################################################

=head3 get_hidden

Returns an array containing the names of all templates which are
registered as I<hidden>. Also see L<set_hidden ( ARRAY )>.

=cut

######################################################################

sub get_hidden {
  my $self = shift;
  return keys(%{$self->{hidden}});
}

######################################################################

=head3 set_hidden ( ARRAY )

With this method you can reset the list of templates which are handled
as hidden-templates, that means which shouldn't use any visible space
and for which it doesn't matter where they're placed in the form. By
default this list only contains I<hidden> as reference to the template
called I<hidden>.

Normally you'll prefer to only complete or redruce that list and
therefore you'll call L<alter_hidden ( ARRAY )> or L<rm_hidden ( ARRAY
)>.

=cut

######################################################################

sub set_hidden {
  my($self, @hidden) = @_;
  $self->{hidden} = {};
  return $self->alter_hidden(@hidden);
}

######################################################################

=head3 alter_hidden ( ARRAY )

See C<set_hidden>.

=cut

######################################################################

sub alter_hidden {
  my ($self,@hidden) = @_;
  local $_;
  foreach $_ (@hidden) {
    $self->{hidden}->{$_} = 1;
  }
  return 1;
}

######################################################################

=head3 rm_hidden ( ARRAY )

See L<set_hidden ( ARRAY )>.

=cut

######################################################################

sub rm_hidden {
  my($self,@hidden) = @_;
  local $_;
  foreach $_ (@hidden) {
    delete $self->{hidden}->{$_};
  }
  return 1;
}

######################################################################

=head3 get_confirm_skin

Returns the skin object which is used instead of this skin when the
confirm form is created.

See L<HTML::FormEngine>, function C<confirm ([ CONFIRMSG ])> for more
information.

=cut

######################################################################

sub get_confirm_skin {
  my $self = shift;
  return $self->{confirm_skin};
}

######################################################################

=head3 set_confirm_skin ( OBJECT )

Sets the confirm skin to the given skin object. 

See L<HTML::FormEngine>, function C<confirm ([ CONFIRMSG ])> for more
information.

=cut

######################################################################

sub set_confirm_skin {
  my($self, $skin) = @_;
  $self->{confirm_skin} = $skin and return 1 if(ref($skin));
  return 0;
}

######################################################################

######################################################################

#sub get_text_skin {
#  my $self = shift;
#  return $self->{text_skin};
#}

######################################################################

######################################################################

#sub set_text_skin {
#  my($self, $skin) = @_;
#  $self->{text_skin} = $skin and return 1 if(ref($skin));
#  return 0;
#}

######################################################################

=head3 get_not_null_string

Returns the string which is returned by the I<not_null> handler in
case a certain field must be filled out. By default that's the empty
string (no mark). A good value is e.g. I<*>. Use L<set_not_null_string
( $string )> to modify it.

=cut

######################################################################

sub get_not_null_string {
  my $self = shift;
  return $self->{not_null_string};
}

######################################################################

=head3 set_not_null_string ( $string )

See L<get_not_null_string>.

=cut

######################################################################

sub set_not_null_string {
  my ($self, $string) = @_;
  $self->{not_null_string} = $string;
}

######################################################################

=head2 SEE ALSO

L<HTML::FormEngine::SkinClassic>, L<HTML::FormEngine::SkinComplex>,
L<HTML::FormEngine::SkinClassicConfirm>,
L<HTML::FormEngine::SkinComplexConfirm>

And read the source code, especially the template definitions.

=cut

#--------- INTERNAL SUBROUTINES -------#

sub _init {
  my $self = shift;
  $self->{templ} = $self->_get_templ;
  $self->{handler} = $self->_get_handler;
  $self->{default} = $self->_get_default;

  #templates which represent hidden fields should be handled special so that they don't use any visible space
  #all templates referenced from $self->{hidden} are handled like that
  $self->{hidden} = $self->_get_hidden;

  $self->{check} = $self->_get_check;
  ##$self->{text_skin} = $self->_get_text_skin;
  $self->{confirm_skin} = $self->_get_confirm_skin;

  $self->{not_null_string} = $self->_get_not_null_string;
  $self->_init_child();
}

sub _init_child {
}

sub _textdomain {
  my($self, $textdomain) = @_;
  bindtextdomain("HTML-FormEngine", $textdomain||'/usr/share/locale');
  textdomain("HTML-FormEngine");
}

sub _get_templ {
  my %templ;
  $templ{_text} = '<input type="<&TYPE&>" value="<&#value&>" name="<&NAME&>" id="<&ID&>" maxlength="<&MAXLEN&>" size="<&SIZE&>" <&#readonly&> <&TEXT_XP&>/>';
  $templ{_button} = '<button type="<&TYPE&>" value="<&VALUE&>" name="<&NAME&>" id="<&ID&>" <&BUTTON_XP&>/>';
  $templ{_radio} = '<input type="radio" value="<&OPT_VAL&>" name="<&NAME&>" id="<&ID&>" <&#checked&> <&RADIO_XP&>/><&OPTION&>';
  $templ{_select} = '
     <select size="<&SIZE&>" name="<&NAME&>" id="<&ID&>" <&#multiple&> <&SELECT_XP&>><&_option&>
     </select>';
  $templ{_select_optgroup} = '
      <select size="<&SIZE&>" name="<&NAME&>" id="<&ID&>" <&#multiple&> <&SELECT_XP&>><&_optgroup&>
      </select>';
  $templ{_select_flexible} = '
      <select size="<&SIZE&>" name="<&NAME&>" id="<&ID&>" <&#multiple&> <&SELECT_XP&>><~ <&TEMPL&> ~TEMPL~>
      </select>';
  $templ{_optgroup} = '<~
        <optgroup label="<&OPTGROUP&>" <&OPTGROUP_XP&>><&_option&>
        </optgroup>~OPTGROUP OPTION OPT_VAL~>';
  $templ{optgroup} = '<&_optgroup&>';
  $templ{optgroup_flexible} = '
        <optgroup label="<&OPTGROUP&>" <&OPTGROUP_XP&>><~ <&TEMPL&> ~TEMPL~>
        </optgroup>';
  $templ{_option} = '<~
        <option value="<&OPT_VAL&>" label="<&OPTION&>" <&#checked selected&> <&OPTION_XP&>><&OPTION&></option> ~OPTION OPT_VAL~>';
  $templ{option} = '<&_option&>';
  $templ{_check} = '<input type="checkbox" value="<&OPT_VAL&>" name="<&NAME&>" id="<&ID&>" <&#checked&> <&CHECKBOX_XP&>/><&OPTION&>';
  $templ{_textarea} = '<textarea name="<&NAME&>" id="<&ID&>" cols="<&COLS&>" rows="<&ROWS&>" <&#readonly&> <&TEXTAREA_XP&>><&#value&></textarea>';
  $templ{_hidden} = '<input type="hidden" name="<&NAME&>" id="<&ID&>" value="<&#value&>" <&HIDDEN_XP&>/>';
  $templ{hidden} = '<&_hidden&>';
  $templ{_fieldset} = '
   <fieldset>
   <legend><&LEGEND&></legend>
   <table border=0><~
     <tr><&TEMPL&></tr>~TEMPL~>
   </table>
   </fieldset>';
  $templ{_templ} = '<~<&TEMPL&>~TEMPL~>';
  $templ{_print} = '<&#value -,1&><input type="hidden" name="<&NAME&>" value="<&#value&>" />';
  $templ{_print_option} = '<~
        <&OPTION&><!<input type="hidden" value="<&OPT_VAL&>" name="<&NAME&>" />!OPT_VAL NAME!> ~OPTION OPT_VAL~>';
  return \%templ;
}

sub _get_default {
  my %default;
  $default{_text} = {TYPE => 'text', SIZE => 20};
  $default{_radio} = {};
  $default{_select} = {};
  $default{_check} = {};
  $default{optgroup} = {};
  $default{option} = {};
  $default{_select_optgroup} = {};
  $default{_textarea} = {COLS => 27, ROWS => 10};
  $default{_button} = {TYPE => 'button'};
  $default{main} = {
		    ACTION => $ENV{REQUEST_URI},
		    METHOD => 'post',
		    ACCEPT => '*',
		    ENCTYPE => 'application/x-www-form-urlencoded',
		    TARGET => '_self',
		    CONFIRMSG => 'Are you really sure, that you want to submit the following data?',
		    CONFMSG_ALIGN => 'center',
		    CANCEL => 'Cancel',
		    CONFIRMED => 'confirmed',
		    CONFIRM_CANCEL => 'confirm_cancel',
		    SEPVAL => md5_hex('F02r23m234E345n42g6i46ne%$'),
		    FORM_ALIGN => 'center',
		    SUBMIT_ALIGN => 'right',
		    CANCEL_ALIGN => 'left',
		    FORM_TABLE_BORDER => 0,
		    FORM_TABLE_CELLSP => 1,
		    FORM_TABLE_CELLPAD => 1,
		   };
  $default{default} = {
		       templ => 'text',
		       TITLE => '<&NAME&>',
		       #NAME => '<&TITLE&>',
		       ID => '<&NAME&>',
		       NAME => '<&ID&>',
		       OPT_VAL => '<&OPTION&>',
		       OPTION => '<&OPT_VAL&>',
		       SUBMIT => 'Ok',
		       FORMNAME => 'FormEngine',
		       TITLE_ALIGN => 'left',
		       TITLE_VALIGN => 'top',
		       TABLE_BORDER => 0,
		       TABLE_CELLSP => 0,
		       TABLE_CELLPAD => 0,
		       TD_VALIGN => 'top',
		       TABLE_BORDER_IN => 0,
		       TABLE_CELLSP_IN => 0,
		       TABLE_CELLPAD_IN => 0,
		       TD_EXTRA_ERROR => 'style="color:#FF0000"',
		       TD_EXTRA_ERROR_IN => 'style="color:#FF0000"',
		       SPAN_EXTRA_ERROR => 'style="color:#FF0000"',
		       ERROR_VALIGN => 'bottom',
		       ERROR_ALIGN => 'left',
		       TABLE_WIDTH => '100%',
		       SP_NOTNULL => '',
		       SP_NOTNULL_IN => '',
		      };
  return \%default;
}

sub _get_handler {
  require HTML::FormEngine::Handler;
  my %handler;
  $handler{default} = \&HTML::FormEngine::Handler::_handle_default;
  $handler{'#checked'} = \&HTML::FormEngine::Handler::_handle_checked;
  $handler{'#value'} = \&HTML::FormEngine::Handler::_handle_value;
  $handler{'#error'} = \&HTML::FormEngine::Handler::_handle_error;
  $handler{'#error_check'} = \&HTML::FormEngine::Handler::_handle_error;
  $handler{'#error_in'} = \&HTML::FormEngine::Handler::_handle_error;
  $handler{'#gettext'} = \&HTML::FormEngine::Handler::_handle_gettext;
  $handler{'#gettext_var'} = \&HTML::FormEngine::Handler::_handle_gettext_var;
  $handler{'#label'} = \&HTML::FormEngine::Handler::_handle_label;
  $handler{'#decide'} = \&HTML::FormEngine::Handler::_handle_decide;
  $handler{'#readonly'} = \&HTML::FormEngine::Handler::_handle_readonly;
  $handler{'#multiple'} = \&HTML::FormEngine::Handler::_handle_multiple;
  $handler{'#confirm_check_prepare'} = \&HTML::FormEngine::Handler::_handle_confirm_check_prepare;
  $handler{'#seperate'} = \&HTML::FormEngine::Handler::_handle_seperate;
  $handler{'#seperate_conly'} = \&HTML::FormEngine::Handler::_handle_seperate;
  $handler{'#encentities'} = \&HTML::FormEngine::Handler::_handle_encentities;
  $handler{'#save_to_global'} = \&HTML::FormEngine::Handler::_handle_save_to_global;
  $handler{'#not_null'} = \&HTML::FormEngine::Handler::_handle_not_null;
  $handler{'#htmltotext'} = \&HTML::FormEngine::Handler::_handle_html2text;
  $handler{'#arg'} = \&HTML::FormEngine::Handler::_handle_arg;
  return \%handler;
}

sub _get_check {
  require HTML::FormEngine::Checks;
  my %check;
  $check{not_null} = \&HTML::FormEngine::Checks::_check_not_null;
  $check{email} = \&HTML::FormEngine::Checks::_check_email;
  $check{rfc822} = \&HTML::FormEngine::Checks::_check_rfc822;
  $check{date} = \&HTML::FormEngine::Checks::_check_date;
  $check{digitonly} = \&HTML::FormEngine::Checks::_check_digitonly;
  $check{fmatch} = \&HTML::FormEngine::Checks::_check_match;
  $check{match} = \&HTML::FormEngine::Checks::_check_match;
  $check{regex} = \&HTML::FormEngine::Checks::_check_regex;
  $check{unique} = \&HTML::FormEngine::Checks::_check_unique;
  return \%check;
}

sub _get_hidden {
  my %hidden=('hidden' => 1);
  return \%hidden;
}

sub _get_confirm_skin() {
  require HTML::FormEngine::SkinConfirm;
  return new HTML::FormEngine::SkinConfirm;
  #return undef;
}

#sub _get_text_skin() {
#  require HTML::FormEngine::SkinText;
#  return new HTML::FormEngine::SkinText;
#}

sub _get_not_null_string() {
  return ''; #*
}

1;

__END__
