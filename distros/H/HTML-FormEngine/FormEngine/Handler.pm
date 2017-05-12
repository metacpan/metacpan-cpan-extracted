=head1 NAME

HTML::FormEngine::Handler - FormEngine template handler

=head1 HANDLERS

=cut

######################################################################

package HTML::FormEngine::Handler;

use Locale::gettext;

######################################################################

=head2 default

The default handler is called if the named handler doesn't exist.

With help of the default handler one can nest templates. It expects
the name, with which it was called, to be the name of an template.  It
then reads in this template and processes it. The resulting code is
returned.

=cut

######################################################################

sub _handle_default {
  my ($self,$templ,@args) = @_;
  if(defined($templ) && defined($self->{skin_obj}->get_templ($templ))) {
    my $back = $self->{_handle_default};
    $self->{_handle_default} = (@args ? \@args : undef);
    my $res = $self->_parse($self->{skin_obj}->get_templ($templ));
    $self->{_handle_default} = $back;
    return $res;
  }
  return '';
}

######################################################################

=head2 checked

This handler is used in the I<select>, I<radio>, I<check> and similar
templates.

The first argument defines the value, which should be returned if a
certain option was submitted. By default this is 'checked'.

The second argument defines the name of the variable in which the
option values are stored (default: OPT_VAL).

The third argument defines the name of the variable which defines the
field name (default: NAME).

..or if you want to know it more exactly:

The first argument is returned if the field was selected. If this
argument is not defined, I<checked> is returned. If the field wasn't
selected, an empty string is returned.

The second argument is the name of the variable in which the value of
the field is defined which is submitted if the field was selected.  By
default the value of this argument is I<OPT_VAL>.

The third argument contains the name of the variable in which the name
of the field is stored. With the help of this variable the submitted
value of the field is read in to be compared with the value which the
field should have if it was selected. So the handler can determine
whether the field was selected or not. By default this argument is
I<NAME>.

Normally the only important argument is the first one. The others can
be important if you want to change variable names.

=cut

######################################################################

sub _handle_checked {
  my($self, $caller, $res, $namevar, $valuevar) = @_;
  $res = 'checked' if(! defined($res));

  #we use a little dirty hack to get the whole VALUE contents and not the element corresponding to the loop-level
  #we want the whole because the user of this module just specifies e.g. VALUE = [1,2,7] to say that he wants the checkboxes
  #representing the values 1,2,7 to be checked. If we would consider the loop level he'd have to say e.g. VALUE = [1,2,,,,7]
  #if the form was submitted this hack doesn't have any effect.
  my $loop;
  #...choosing the loop-status that matters...
  if(defined($self->{loop_var}->{'VALUE'})) {
    $loop = \$self->{loop_var}->{'VALUE'};
  } else {
    $loop = \$self->{loop};
  }

  #temporaly reseting the loop-level (we pretend not to be in any loop)
  local $_ = $$loop;
  $$loop = [];
  my $checked = $self->_get_value($namevar);
  $$loop = $_;

  #i don't know if that is a good idea...
  return '' unless($checked ne '');

  my $value = $self->_get_var($valuevar||'OPT_VAL');
  my $input = '';
  #we just have to check if one of the submitted values matches $value
  if(ref($checked) eq 'ARRAY') {
    if(grep {$_ eq $value} @{$checked}) {
      return $res;
    }
  }
  #..even easier
  elsif($checked eq $value) {
    return $res;
  }
  return '';
}

######################################################################

=head2 value

This handler returns the value of the field.

The first argument defines the value which should be returned if the
value is empty. By default this is undef.

If the second argument is true (1), the returned value will be
returned again next time the handler is called for this field name.

The third argument is used to tell the handler the name of the
variable in which the field name is stored. By default this is
I<NAME>.

The fourth argument should be set to the name of the variable which
contains the fields value. By default this is I<VALUE>.

If the form wasn't submitted, the fields default value is returned.

=cut

######################################################################

sub _handle_value {
  my ($self,$caller,$none,$same,$namevar,$valuevar) = @_;
  $res = $self->_get_value($namevar,$valuevar);
  if(ref($res) eq 'ARRAY') {
    $_ = $self->_get_var($namevar||'NAME');
    if(ref($self->{_handle_value}) ne 'HASH') {
      $self->{_handle_value} = {};
      # this hash must be cleaned before calling make again!!
      push @{$self->{call_before_make}}, sub { my ($self) = @_; $self->{_handle_value} = {}; };
      # seperate handler should reset _handle_value so that the count starts again from 0
      push @{$self->{reset_on_seperate}}, '_handle_value';
    }
    if(!$same) {
      $res = $res->[$self->{_handle_value}->{$_}++ || 0];
    }
    #next call the same value should be returned for this field name
    elsif($same > 0) {
      $res = $res->[$self->{_handle_value}->{$_} || 0];
    }
    elsif($same < 0) {
      $res = $res->[(defined($self->{_handle_value}->{$_}) and $self->{_handle_value}->{$_} > 0) ? $self->{_handle_value}->{$_} -1 : 0];
    }
  }
  return (defined($res) and $res ne '') ? $res : $none;
}

######################################################################

=head2 error, error_in, error_check

The first argument sets the name of the variable in which the error
checks are set. By default this is I<ERROR>.

The second argument sets the name of the variable in which the fields
name is stored. By default this is I<NAME>.

The third argument sets the name of the variable which contains the
fields value. By default this is I<VALUE> but if error_check was used
as handler name the default is I<OPT_VAL>.

If the last argument is set to true (1) no checking will be done, that
means that also no error can be returned. This can only be usefull for
debugging.

The handler calls the defined error checks until an error message is
returned or all checks were called. If it retrieves an error message
it returns this message or the message given by the [checkmethod,
errormessage, arg1, ... argn] notation, else NULL is returned.

=cut

######################################################################

sub _handle_error {
  my ($self,$caller,$keyvar,$namevar,$valuevar,$nocheck) = @_;
  if($self->is_submitted && $self->{check_error}) {
    my $check = $self->_get_var($keyvar||'ERROR');
    $check = [ $check ] if(defined($check) and ref($check) ne 'ARRAY' and $check ne '');
    if(ref($check) eq 'ARRAY' and @{$check}) {
      my $name = $self->_get_var($namevar||'NAME');
      my $value = $self->_get_value($namevar,$valuevar,1);

      # #error_in calls should only check exactly one value
      if($caller eq '#error_in' && ref($value) eq 'ARRAY') {
	if (ref($self->{_handle_error}) ne 'HASH') {
	  $self->{_handle_error} = {};
	  push @{$self->{call_before_make}}, sub { my($self) = @_; $self->{_handle_error} = {}; };
	  # seperate handler should reset _handle_error so that the count starts again from 0
	  push @{$self->{reset_on_seperate}}, '_handle_error';
	}
	$value = $value->[$self->{_handle_error}->{$name}++ || 0];
      }

      # error_check is designed to be used in templates like radio, checkbox and select
      elsif($caller eq '#error_check') {
	$value = [$value] if(ref($value) ne 'ARRAY');
	my $optval = $self->_get_var($valuevar || 'OPT_VAL');
	if(grep {$optval eq $_} @$value) {
	  $value = $optval;
	}
	else {
	  $value = '';
	}
      }

      unless($nocheck) {
	foreach my $chk (@{$check}) {
	  my $errmsg = '';
	  my @args = ();
	  if(ref($chk) ne 'CODE') {
	    #this implements the [checkmethod, errmsg, arg1, arg2, ... argn] notation
	    if(ref($chk) eq 'ARRAY') {
	      #add the name of the call alias infront of the argument list
	      push @args, $chk->[0];
	      $errmsg = $chk->[1];
	      push @args, @$chk[2..@{$chk}-1] if(@{$chk} >= 3);
	      $chk = $chk->[0];
	    }
	    else {
	      #add the name of the call alias infront of the argument list
	      push @args, $chk;
	    }
	    $chk = $self->{skin_obj}->get_check($chk);
	  }
	  if(ref($chk) eq 'CODE') {
	    local $_ = undef;
	    if($_ = &$chk($value, $self, @args)) {
	      $self->{errcount} ++;
	      return $self->_get_var('errmsg') || $errmsg || $_;
	    }
	  }
	}
      }
    }
  }
  return '';
}  

######################################################################

=head2 gettext

The arguments given to this handler, are passed through gettext and
then joined together with a spacing blank inbetween. The resulting
string is returned.

=cut

######################################################################

sub _handle_gettext {
  my ($self,$caller) =  (shift,shift);
  my @res;
  foreach $_ (@_) {
    push @res, gettext($_);
  }
  return join(' ', @res);
}

######################################################################

=head2 gettext_var

You can pass variable names to this handler. The values of those
variables are then pushed through gettext and the resulting strings
are glued together with a blank inbetween.

=cut

######################################################################

sub _handle_gettext_var {
  my ($self,$caller) =  (shift,shift);
  my @res;
  foreach $_ (@_) {
    #get content of variable
    $_ = $self->_get_var($_);
    push @res, gettext($_) if($_ ne '');
  }
  return join(' ', @res);
}

######################################################################

=head2 label

This handler gets the id, title and accesskey value and uses this
informations to create a (X)HTML C<< <label> >> tag which is then returned.

The first argument should be set to the name of the variable which
provides the fields title, by default this is I<TITLE>.

The seconds argument default is I<ID>. It should be always set to the
variable which contains the fields id.

The third argument is used to try to get an accesskey for the
field. Normally the variable ACCESSKEY is expected to provide such, if
you prefer to use another variable please give its name here.

=cut

######################################################################

sub _handle_label {
  my($self,$caller,$labelvar,$idvar,$accesskeyvar) = @_;
  my $label = $self->_get_var($labelvar||'TITLE');
  my $id = $self->_get_var($idvar||'ID');
  #the label tag doesn't make sense without a label
  return '' if(!$label);
  #the label tag doesn't make sense without an id, we also should parse it if things like <& are contained
  #its not necessary anymore because this is done by _get_var anyway
  #return $self->_parse($label) if(ref($id) || !defined($id) || $label =~ /<(&|~|!).*(!|~|&)>/);
  my $accesskey = $self->_get_var($accesskeyvar||'ACCESSKEY');
  $accesskey='' unless(defined($accesskey));
  return "<label for=\"$id\" accesskey=\"$accesskey\">$label</label>";
}

######################################################################

=head2 decide

Expects a list of variable names, it then returns the content of the
first variable in the list which is not empty.

=cut

######################################################################

sub _handle_decide {
  my($self,$caller,@vars) = @_;
  foreach $_ (@vars) {
    my $value = $self->_get_var($_,1);
    return $self->_parse($value) if(defined($value));
  }
  return '';
}

######################################################################

=head2 readonly

Expects the name of the variable which says whether the field should
be set readonly or not. By default this is I<READONLY>.
C<readonly="readonly"> is returned if that variable is set to 1 (true).

=cut

######################################################################

sub _handle_readonly {
  my($self,$caller,$readonlyvar) = @_;
  $readonlyvar = 'READONLY' unless($readonlyvar);
  return 'readonly="readonly"' if($self->_get_var($readonlyvar,1));
  return '';
}

######################################################################

=head2 multiple

Works like C<readonly> but C<multiple="multiple"> is returned if
I<MULTIPLE> is true.

=cut

######################################################################

sub _handle_multiple {
  my($self,$caller,$multiplevar) = @_;
  $multiplevar = 'MULTIPLE' unless($multiplevar);
  return 'multiple="multiple"' if($self->_get_var($multiplevar,1));
  return '';
}

######################################################################

=head2 confirm_check_prepare

This handler is a confirm handler. It sets the variables I<OPTION> and
I<OPT_VAL> to the list of submitted values resp. their visible
names. This is usefull because like that only the really submitted
values and options are printed when the template iterates over OPTION
and/or OPT_VAL.

With the first argument you can set how many options/values you want to
have per line when iterating. By default this is 2. Internally it just
configurs how many elements every array should have.

The second argument is by default I<OPTION> and should always be set
to the name of the variable which provides the option list.

The third argument configures which variable should be read in to get
the list of submitted values. By default this is I<OPT_VAL>.

The fourth argument should be set to the right variable name if the
variable which contains the fields name is not I<NAME> (normally it is
I<NAME>).

=cut

######################################################################

sub _handle_confirm_check_prepare {
  my($self,$caller,$perline,$optionvar,$optvalvar,$namevar) = @_;
  $perline = 2 unless($perline);
  #get list of submitted values
  my $value = $self->_get_value($namevar);
  $value = [$value] unless(ref($value) eq 'ARRAY');
  #get list of all options
  my $option = $self->_get_var($optionvar||'OPTION');
  $option = [$self->_flatten_array(ref($option) eq 'ARRAY' ? @$option : $option)];
  #get list of all values
  my $optval = $self->_get_var($optvalvar||'OPT_VAL');
  $optval = [$self->_flatten_array(ref($optval) eq 'ARRAY' ? @$optval : $optval)];
  my %option;
  #create a optval => option map
  for(my $i=0; $i<@$option; $i++) {
    $option{$optval->[$i]} = $option->[$i];
  }
  my @optcache = (), my @valcache = ();
  my @option = ();
  my @value = ();
  $i = 0;
  #now create the new option and value list which then only contains the submitted values/options
  foreach $_ (@$value) {
    if(defined($option{$_})) {
      push @optcache, $option{$_};
      push @valcache, $_;
      $i++;
      #when iterating the first array dimension creates the rows, the second fills up the columns
      if(!($i % $perline)) {
	push @option, [@optcache];
	push @value, [@valcache];
	@optcache = ();
	@valcache = ();
      }
    }
  }
  #we probably have to fill up the last row
  #while($i % $perline and $i > 0) {
    #i don't know why, but when i enable this namechooser.cgi ends up in an endless loop when the confirm-form is being generated
    #push @optcache, '';
   #$i++;
  #}
  push @option, [@optcache] if(@optcache);
  push @value, [@valcache] if(@valcache);
  $self->_set_var('OPTION', \@option);
  $self->_set_var('OPT_VAL', \@value);
  return '';
}


######################################################################

=head2 seperate

First of all: The handler doesn't do anything if the C<set_seperate>
method was not called with a true value!

If set_seperate was called with a true value, this handler returns a
seperation-field if the fieldname changes while iterating or if a
template came to its end. Of course that only works when used in the
right way in the templates.

The seperation-field is important because it controlls which values of
a certain fieldname belong together and are thus packed into one
subarray of the C<get_input> result for that fieldname.

E.g.: you've a field called I<name> which consists of two text-inputs,
one for the first- and one for the lastname. If you now call
C<get_input('name')> it'll return: [firstname,lastname]. So far no
problem. The problem comes if you use this I<name> field twice
e.g. because you want to get the data of 2 persons in one form. Now
FormEngine normally would think that all four belong together:
[firstname,lastname,firstname,lastname] but with the help of the
seperation field which will automatically be inserted inbetween, it
knows that the following is to be expected:
[[firstname,lastname],[firstname,lastname]]. So far that isn't so
important, but it really gets important for the radio,select and
checkbox fields, because here FormEngine must know which values belong
to which group and so on.

One might think: why do people not just use diffrent names? Well, i
would say it is much more easier to define and also much more easy
to evaluate the return value if fields who semanticlly belong
together have the same name. If you would give the fields for each
person its own name like name1, name2 ... it'll be not so nice to call
get_value() for each person especially if the count of persons is
flexible. So its much nicer to just call get_value(name) and then to
know that each subarray represents one person.

The first argument is attached to the seperation-field-code. If the
second argument is set to true (1) the sepeartion-field-code will be
returned in any case (if set_seperate was called with a true
value). The third argument is by default I<NAME> and should always be
set to the variable which contains the fields name.

=cut

######################################################################

  sub _handle_seperate {
    my($self,$caller,$attach,$clear,$namevar) = @_;
    #only if set_seperate() was called and set to true this handler shall do something
    return '' unless($self->{seperate});
    my $res = '';
    my $name = $self->_get_var($namevar||'NAME',1);
    if (ref($self->{_handle_seperate}) ne 'ARRAY') {
      $self->{_handle_seperate} = [];
      push @{$self->{call_before_make}}, sub { my($self) = @_; $self->{_handle_seperate} = []; };
    }
    #seperation works per level, that means that when the fieldname changes from one to another level that has no effect, only changes on the same level matter
    my $old = $self->{_handle_seperate}->[$self->{depth}];
    #if clear is true or the fieldname changed...
    if($clear || (defined($old) and $old ne $name)) {
      local $_ =  defined($old) ? $old : $name;
      #create the seperation field
      $res = $self->_parse('<input type="hidden" name="'.$_.'" value="<&SEPVAL&>" />' . (defined($attach) ? $attach : '')) unless($caller eq '#seperate_conly');
      #
      $self->{values}->{$_} ++;
      foreach my $key (@{$self->{reset_on_seperate}}) {
	$self->{$key}->{$_} = 0;
      }
    }
    $self->{_handle_seperate}->[$self->{depth}] = ($clear ? undef : $name);
    return $res;
  }

######################################################################

=head2 encentities

This handler expects a variable name. It then fetches the variables
contents and passes it through encode_entities so that all HTML
entities are encoded. The resulting string is returned.

=cut

######################################################################

sub _handle_encentities {
  my($self,$caller,$var) = @_;
  return '' unless(defined($var));
  require HTML::Entities;
  return encode_entities($self->_get_var($var));
}

######################################################################

=head2 save_to_global

The handlers first argument can be any template expression (like
<&NAME&> or <&value ,1&>), the second argument is by default I<saved>
and should always be set to a string which is not yet used as variable
name anywhere in the template (at least it normally will make most
sense if it is not used anywhere, in some cases might be usefull to
use an existing name).

The handler will then read in the value of the expression given as
first argument and will save it to the variable given as second
argument but as a global variable, that means that value will then be
available in every template if the variable is not overwritten by a
local variable.

This handler is especially usefull in association with the C<fmatch>
check method.

=cut

######################################################################

sub _handle_save_to_global {
  my($self,$caller,$expr,$savetovar) = @_;
  my $val = $self->_parse($expr);
  if(defined($val)) {
    $self->{varstack}->[0]->{$savetovar||'saved'} = $val;
  }
  return '';
}

######################################################################

=head2 not_null

The first argument is by default I<ERROR> and should always be set to
the name of the variable which defines the error checks.

The second argument is returned if the list of error checks contains
the I<not_null> check, which means that the field mustn't be
empty. What is to be returned by default is setted by the skin,
normally it is the empty string (no mark). A good value would be
e.g. I<*>. See L<HTML::FormEngine::Skin> on how to modify the default
(C<set_not_null_string>).

This handler is used to automatically mark fields which have to be
filled out.

=cut

######################################################################

sub _handle_not_null {
  my($self,$caller,$err_var,$res) = @_;
  my $err = $self->_get_var($err_var||'ERROR');
  return '' unless(defined($err));
  $err = [$err] unless(ref($err) eq 'ARRAY');
  return $res||$self->{skin_obj}->get_not_null_string() if(grep {defined($_) && $_ eq 'not_null'} @$err);
  return '';
}

######################################################################

=head2 html2text

This handler expects a variable name as argument, it then fetches the
value of the variable and passes it through
C<HTML::Entities::decode_entities> before returning
it. C<decode_entities> turns HTML entities like C<&lt;> in their
corresponding plain-text character.

=cut

######################################################################

sub _handle_html2text {
  my($self,$caller,$var) = @_;
  require HTML::Entities;
  return '' unless(defined($var));
  return HTML::Entities::decode_entities($self->_get_var($var));
}

######################################################################

=head2 arg

When calling a template you can pass arguments to it like this: C<<
<&template arg0,arg1...,argn&> >>

In the template you then use this handler to fetch the passed
arguments. An example: C<< <&#arg 1&> >>. This will return I<arg1>.

=cut

######################################################################

sub _handle_arg {
  my($self,$caller,@args) = @_;
  my @res;
  local $_;
  foreach $_ (@args) {
    if(ref($self->{_handle_default}->[$_]) eq 'ARRAY') {
      push @res, join(',',@{$self->{_handle_default}->[$_]});
    }
    else {
      push @res, $self->{_handle_default}->[$_]||'';
    }
  }
  my $res = join(',', @res);
  return $res if(defined($res));
  return '';
}

######################################################################

=head1 WRITING A HANDLER

=head2 Design

In general, a handler has the following structure:

   sub myhandler {
     my($self,$callname,@args) = @_;
     # ... some code ... #
     return $res;
   }

C<$self> contains a reference to the FormEngine object.

C<$callname> contains the name or synonym which was used to call the
handler.  So it is possible to use the same handler for several,
similar jobs.

C<@args> contains the arguments which were passed to the handler (see
Skin.pm).

=head2 Install

Read L<HTML::FormEngine::Skin> on how to make your handlers
available. To hardcode them into the skin edit its source code, also
read about the other skin packages.

=cut

1;

__END__
