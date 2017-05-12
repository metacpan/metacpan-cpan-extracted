
=head1 NAME

HTML::StickyForm - Lightweight general-purpose HTML form generation, with sticky values

=head1 SYNOPSIS

 # mod_perl example

 use HTML::StickyForm;
 use Apache::Request;

 sub handler{
   my($r)=@_;
   $r=Apache::Request->new($r);
   my $f=HTML::StickyForm->new($r);

   $r->send_http_header;
   print
     '<html><body>',
     $form->form_start,

     "Text field:",
     $f->text(name => 'field1', size => 40, default => 'default value'),

     "<br />Text area:",
     $f->textarea(name => 'field2', cols => 60, rows => 5, default => 'stuff'),

     "<br />Single radio button:",
     $f->radio(name => 'field3', value => 'xyz', checked => 1),

     "<br />Radio buttons:",
     $f->radio_group(name => 'field4', values => [1,2,3],
       labels => { 1=>'one', 2=>'two', 3=>'three' }, default => 2),

     "<br />Single checkbox:",
     $f->checkbox(name => 'field5', value => 'xyz', checked => 1),

     "<br />Checkbox group:",
     $f->checkbox_group(name => 'field6', values => [4,5,6],
       labels => { 4=>'four', 5=>'five', 6=>'six' }, default => [5,6]),

     "<br />Password field:",
     $f->password(name => 'field7', size => 20),

     '<br />",
     $f->submit(value => ' Hit me! '),

     $f->form_end,
     '</body></html>',
    ;
    return OK;
  }

=head1 DESCRIPTION

This module provides a simple interface for generating HTML form
elements, with default values chosen from the previous form submission. This
module was written with mod_perl (L<Apache::Request>) in mind, but works
equally well with CGI.pm, including the new 3.x version, or any other module
which implements a param() method, or even completely standalone.

The module does not provide methods for generating all possible HTML elements,
only those which are used in form construction.
In addition, this module's interface is much less flexible than CGI.pm's; all
routines work only as methods, and there is only one way of passing parameters
to each method.  This was done for two reasons: to keep the API simple and
consistent, and to keep the code size down to a minimum.

=cut


package HTML::StickyForm;
BEGIN {
  $HTML::StickyForm::VERSION = '0.08';
}
use strict;
use warnings;

=head1 CLASS METHODS

=over

=item new([REQUEST])

Creates a new form generation object. The single argument can be:

=over

=item *

any object which responds to a C<param> method in the same way that L<CGI> and
L<Apache::Request> objects do. That is, with no arguments, the names of the
parameters are returned as a list. With a single argument, the value(s) of the
supplied parameter is/are returned; in scalar context the first value,
and in list context all values.

=item *

a plain arrayref. This will be used to construct an
L<HTML::StickyForm::RequestHash> object, which responds as described above.
The array will be passed directly to the RequestHash constructor, so both
methods for specifying multiple values are allowed.

=item *

a plain hashref. This will be used to construct an
L<HTML::StickyForm::RequestHash> object. Multiple values must be represented
as arrayref values.

=item *

a false value. This will be used to construct an
L<HTML::StickyForm::RequestHash> object with no parameters set.

=back

The constructor dies if passed an unrecognised request object.

If an appropriate object is supplied, parameters will be fetched from the
object on an as needed basis, which means that changes made to the request
object after the form object is constructed may affect the default values
used in generated form elements. However, once constructed, the form object's
sticky status does not get automatically updated, so if changes made to the
request object need to affect the form object's sticky status, set_sticky()
must be called between request object modification and form generation.

In contrast, L<HTML::StickyForm::RequestHash> objects created as part of form
object construction use copies of the parameters from the supplied hashref or
arrayref. This means that the changes made to the original data do not affect
the request object, so have absolutely no effect of the behaviour of the
form object.

=cut

sub new{
  my($class,$req)=@_;

  # Identify the type of request
  my $type;
  if(!$req){
    $type='hash';
    $req={};
  }elsif(eval{ local $SIG{__DIE__}; $req->can('param'); }){
    $type='object';
  }elsif(ref($req) eq 'HASH'){
    $type='hash';
  }elsif(ref($req) eq 'ARRAY'){
    $type='array';
  }else{
    require Carp;
    Carp::croak(
      "Unrecognised request passed to HTML::StickyForm constructor ($req)");
  }
  if($type eq 'hash' || $type eq 'array'){
    require HTML::StickyForm::RequestHash;
    $req=HTML::StickyForm::RequestHash->new($type eq 'hash' ? %$req : @$req);
  }

  my $self=bless {
    req => $req,
    values_as_labels => 0,
    well_formed => ' /',
  },$class;

  # Count submitted fields
  $self->set_sticky;

  $self;
}

=back

=head1 METHODS

=head2 Configuration methods

=over

=item set_sticky([BOOL])

With no arguments, the request object's parameters are counted, and the form
object is made sticky if one or more parameters are present, non-sticky
otherwise.  If an argument is given, its value as a boolean determines whether
the form object will be sticky or not. In both cases, the return value will be
the new value of the sticky flag.

A non-sticky form object always uses the values supplied to methods when
constructing HTML elements, whereas a sticky form object will use the values
from the request.

This method is called by the constructor when the form object is created, so it
is not usually necessary to call it explicitly. However, it may be necessary to
call this method if parameters are set with the C<param()> method after the
form object is created.

=cut

sub set_sticky{
  my $self=shift;
  return $self->{params}=!!$_[0] if @_;

  $self->{params}=!!(()=$self->{req}->param);
}

=item get_sticky()

Returns true if the form object is sticky.

=cut

sub get_sticky{
  my($self)=@_;

  !!$self->{params};
}

=item values_as_labels([BOOL])

With no arguments, this method returns the C<values_as_labels> attribute,
which determines what should happen when a value has no label in the
checkbox_group(), radio_group() and select() methods. If this attribute
is false (the default), no labels will be automatically generated. If it is
true, labels will default to the corresponding value if they are not supplied
by the user.

If an argument is passed, it is used to set the C<values_as_labels> attribute.

=cut

sub values_as_labels{
  my $self=shift;
  return $self->{values_as_labels}=!!$_[0] if @_;
  $self->{values_as_labels};
}

=item well_formed([BOOL])

With no arguments, this method return the C<well_formed> attribute, which
determines whether to generate well-formed XML, by including the trailing
slash in non-container elements.
If true, all generated elements will be well-formed.  If false, no slashes
are added - which is unfortunately required by some older browsers.

If an argument is passed, it is used to set the C<well_formed> attribute.

=cut

sub well_formed{
  my $self=shift;
  return !!($self->{well_formed}=$_[0] ? ' /' : '') if @_;
  !!$self->{well_formed};
}

=back

=head2 HTML generation methods

Most of these methods are specified as taking PAIRLIST arguments. This means
that arguments must be passed as a list of name/value pairs. For example:

  $form->text(name => 'fred',value => 'bloggs');

This represents two arguments; "name" with a value of "fred", and "value"
with a value of "bloggs".

In cases where sticky values are useful, there are two ways of specifying the
values, depending on whether stickiness is required for the element being
generated. To set sticky value defaults, use the C<default> argument.
Alternatively, to set values which are not affected by previous values entered
by the user, use the C<value> argument (or C<selected> or C<checked>, depending
on the type of element being generated).

=over

=item form_start(PAIRLIST)

Generates a C<E<lt>formE<gt>> start tag. All arguments are interpreted
as attributes for the element. All names and values are HTML escaped.
The following arguments are treated specially:

C<method>: Defaults to C<GET>

=cut

sub form_start{
  my($self,$args)=&_args;
  $args->{method}='GET' unless exists $args->{method};

  my $field='<form';
  while(my($name,$val)=each %$args){
    _escape($name);
    _escape($val);
    $field.=qq( $name="$val");
  }
  $field.='>';

  $field;
}

=item form_start_multipart(PAIRLIST)

As form_start(), but the C<enctype> argument defaults to C<multipart/form-data>.

=cut

sub form_start_multipart{
  my($self,$args)=&_args;
  $args->{enctype}||='mutipart/form-data';
  $self->form_start($args);
}

=item form_end()

Generates a C<E<lt>formE<gt>> end tag.

=cut

sub form_end{
  '</form>';
}

=item text(PAIRLIST)

Generates an C<E<lt>inputE<gt>> element.  In general, arguments are interpreted
as attributes for the element. All names and values are HTML escaped. The
following arguments are treated specially:

C<type>: Defaults to C<text>

C<value>: Unconditional value. If present, causes C<default> and any sticky
value to be ignored.

C<default>: Conditional value, ignored if C<value> is present. If the form is
sticky, the sticky value will be used for the C<value> attribute's value.
Otherwise, the supplied C<default> will be used.
A C<default> attribute is never created.

=cut

sub text{
  my($self,$args)=&_args;
  my $type=delete $args->{type} || 'text';
  my $name=delete $args->{name};
  my $value;
  if(exists $args->{value}){
    $value=delete $args->{value};
    delete $args->{default};
  }else{
    $value=delete $args->{default};
    $value=$self->{req}->param($name) if $self->{params};
  }

  _escape($type);
  _escape($name);
  _escape($value);

  my $field=qq(<input type="$type" name="$name" value="$value");
  while(my($key,$val)=each %$args){
    _escape($key);
    _escape($val);
    $field.=qq( $key="$val");
  }

  return "$field$self->{well_formed}>";
}

=item hidden(PAIRLIST)

As text(), but produces an input element of type C<hidden>.

=cut

sub hidden{
  my($self,$args)=&_args;
  $args->{type}||='hidden';
  $self->text($args);
}

=item password(PAIRLIST)

As text(), but produces an input element of type C<password>.

=cut

sub password{
  my($self,$args)=&_args;
  $args->{type}||='password';
  $self->text($args);
}

=item textarea(PAIRLIST)

Generates a E<lt>textareaE<gt> container. All arguments are used directly
to generate attributes for the start tag, except for those listed below.
All values are HTML-escaped.

C<value>: Unconditional value. If present, specifies the contents of the
container, and causes C<default> and any sticky value to be ignored. A
C<value> attribute is never created.

C<default>: Conditional value, ignored if C<value> is present. If the form is
stikcy, the sticky value wil be used for the container contents. Otherwise,
sticky, the supplied C<default> will be used.
A C<default> attribute is never created.

=cut

sub textarea{
  my($self,$args)=&_args;
  my $name=delete $args->{name};
  my $value;
  if(exists $args->{value}){
    $value=delete $args->{value};
    delete $args->{default};
  }else{
    $value=delete $args->{default};
    $value=$self->{req}->param($name) if $self->{params};
  }

  _escape($name);
  _escape($value);

  my $field=qq(<textarea name="$name");
  while(my($key,$val)=each %$args){
    _escape($key);
    _escape($val);
    $field.=qq( $key="$val");
  }

  return "$field>$value</textarea>";
}

=item checkbox(PAIRLIST)

Generates a single C<checkbox> type C<E<lt>inputE<gt>> element. All arguments
are used directly to generate attributes for the tag, except for those listed
below. All values are HTML-escaped.

C<checked>: Unconditional status. If present, used to decide whether to include
a checked attribute, and causes C<default> and any sticky value to be ignored.

C<default>: Conditional status, ignored if C<checked> is present. If the form
is sticky, the sticky value will be used to determine whether to include a
checked attribute. Otherwise, the supplied C<default> will be used.

If the decision to include the C<checked> attribute is based on the sticky
value, the sticky parameter must include at least one value which is the same
as the supplied C<value> argument. If the decision is based on the value of
the C<checked> or C<default> arguments, the supplied argument need only be
true for the C<checked> attribute to be created.

=cut

sub checkbox{
  my($self,$args)=&_args;
  my $type=delete $args->{type} || 'checkbox';
  my $name=delete $args->{name};
  my $value=delete $args->{value};
  my $checked;
  if(exists $args->{checked}){
    $checked=delete $args->{checked};
    delete $args->{default};
  }else{
    $checked=delete $args->{default};
    $value='' unless defined($value);
    $checked=grep $_ eq $value,$self->{req}->param($name) if $self->{params};
  }

  _escape($name);
  _escape($value);

  my $field=qq(<input type="$type" name="$name" value="$value");
  $field.=' checked="checked"' if $checked;
  while(my($key,$val)=each %$args){
    _escape($key);
    _escape($val);
    $field.=qq( $key="$val");
  }

  return "$field$self->{well_formed}>";
}

=item checkbox_group(PAIRLIST)

Generates a group of C<checkbox> type C<E<lt>inputE<gt>> elements. If called in
list context, returns a list of elements, otherwise a single string containing
all tags. All arguments are used directly to generate attributes in each tag,
except for those listed below. Arguments with scalar values result in that
value being used for each element, whereas hashref values result in the value
keyed by the element's C<value> attribute being used.
Unless otherwise stated, all names and values are HTML-escaped.

C<values>: An arrayref of values.
One element will be generated for each element, in the order supplied.
If not supplied, the label keys will be used instead.

C<labels>: A hashref of labels.
Each element generated will be followed by the label keyed
by the value. Values will be HTML-escaped unless a false C<escape> argument
is supplied.  If no label is present for a given value and C<values_as_labels>
is true, the value will also be used for the label.

C<escape_labels>: If present and false, labels will not be HTML-escaped.

C<checked>: Unconditional status. If present, used to decide whether each
checkbox is marked as checked, and causes C<default>, C<defaults> and any
sticky values to be ignored. May be a single value or arrayref of values.

C<default>: Conditional status, ignored if C<checked> is present.
If the form is sticky, individual checkboxes are marked as checked if the
sticky parameter includes at least one value which is the same as the individual
checkbox's value. Otherwise, the supplied C<default> values are
used in the same way. May be a single value or arrayref of values.

C<linebreak>: If true, each element/label will be followed by a C<E<lt>brE<gt>>
element.

C<values_as_labels>: If supplied, overrides the form object's
C<values_as_labels> attribute.

=cut

sub checkbox_group{
  my($self,$args)=&_args;
  my $type=delete $args->{type} || 'checkbox';
  my $name=delete $args->{name};
  my $labels=delete $args->{labels} || {};
  my $escape_labels=1;
  $escape_labels=delete $args->{escape_labels} if exists $args->{escape_labels};
  my $values=delete $args->{values};
  $values||=[keys %$labels];
  my $checked=[];
  if(exists $args->{checked}){
    $checked=delete $args->{checked};
    $checked=[$checked] if ref($checked) ne 'ARRAY';
    delete $args->{default};
  }else{
    if(exists $args->{default}){
      $checked=delete $args->{default};
      $checked=[$checked] if ref($checked) ne 'ARRAY';
    }
    $checked=[$self->{req}->param($name)] if $self->{params};
  }
  my %checked=map +($_,'checked'),@$checked;
  my $br=delete $args->{linebreak} ? "<br$self->{well_formed}>" : '';
  my $v_as_l=$self->{values_as_labels};
  if(exists $args->{values_as_labels}){
    $v_as_l=delete $args->{values_as_labels};
  }

  _escape($type);
  _escape($name);

  my $field=qq(<input type="$type" name="$name");
  my %per_value=(
    checked => \%checked,
    value => {map +($_,$_),@$values},
  );
  while(my($key,$val)=each %$args){
    if($val && ref($val) eq 'HASH'){
      $per_value{$key}=$val;
      next;
    }
    _escape($key);
    _escape($val);
    $field.=qq( $key="$val");
  }

  my @checkboxes;
  for my $value(@$values){
    my $field=$field;
    while(my($key,$hash)=each %per_value){
      exists $hash->{$value}
        or next;
      _escape($key);
      _escape(my $val=$hash->{$value});
      $field.=qq( $key="$val");
    }
    $field.="$self->{well_formed}>";

    if(exists $labels->{$value}){
      my $label=$labels->{$value};
      _escape($label) if $escape_labels;
      $field.=$label;
    }elsif($v_as_l){
      _escape(my $evalue=$value);
      $field.=$evalue;
    }
    $field.=$br;
    push @checkboxes,$field;
  }

  return @checkboxes if wantarray;
  return join '',@checkboxes;
}

=item radio(PAIRLIST)

As radio_group(), but setting C<type> to C<radio>.

=cut

sub radio{
  my($self,$args)=&_args;
  $args->{type}||='radio';
  $self->checkbox($args);
}

=item radio_group(PAIRLIST)

As checkbox_group(), but setting C<type> to C<radio>.

=cut

sub radio_group{
  my($self,$args)=&_args;
  $args->{type}||='radio';
  $self->checkbox_group($args);
}

=item select(PAIRLIST)

Generates a C<E<lt>selectE<gt>> element. Arguments starting with a dash
are used directly to generate attributes in the C<E<lt>optionE<gt>> elements.
All other arguments are used directly to
generate attributes in the C<E<lt>selectE<gt>> element, except for those listed below.
Unless otherwise stated, all names and values are HTML-escaped.

C<values>: An arrayref of values and/or option groups.
Scalar values are used directly to create C<E<lt>optionE<gt>> elements,
whereas arrayrefs represent option groups. The first element in an option
group is either the group's label or a hashref holding all of the group's
attributes, of which C<disabled> is special cased to produce the attribute
value C<disabled> if true, and no attribute if false.
Defaults to label keys.

C<labels>: A hashref of labels.
Each C<E<lt>optionE<gt>> tag generated will contain the
label keyed by its value. If no label is present for a given value, no label
will be generated. Defaults to an empty hashref.

C<selected>: Unconditional status. If present, the supplied values will be
used to decide which options to mark as selected, and C<default> and any
sticky values will be ignored. May be a single value or arrayref.

C<default>: Conditional status, ignored if C<selected> is
supplied. If the form is sticky, the sticky values will be used to decide which
options are selected. Otherwise, the supplied values will be used.
May be a single value or arrayref.

C<multiple>: If true, the C<multiple> attribute is set to C<multiple>.

C<values_as_labels>: Overrides the form object's C<values_as_labels> attribute.
This is of little value, since it's the default behaviour of HTML in any case.

=cut

sub select{
  my($self,$args)=_args(@_);
  my $name=delete $args->{name};
  my $multiple=delete $args->{multiple};
  my $labels=delete $args->{labels} || {};
  my $values=delete $args->{values} || [keys %$labels];
  my $selected;
  if(exists $args->{selected}){
    $selected=delete $args->{selected};
    delete $args->{default};
  }else{
    $selected=delete $args->{default};
    $selected=[$self->{req}->param($name)] if $self->{params};
  }
  if(!defined $selected){ $selected=[]; }
  elsif(ref($selected) ne 'ARRAY'){ $selected=[$selected]; }
  my %selected=map +($_,'selected'),@$selected;
  my $v_as_l=$self->{values_as_labels};
  if(exists $args->{values_as_labels}){
    $v_as_l=delete $args->{values_as_labels};
  }

  my %option_args;
  for my $key(keys %$args){
    (my $option_key=$key)=~s/\A-// or next;
    $option_args{$option_key}=delete $args->{$key};
  }
  $option_args{selected}=\%selected;

  _escape($name);
  my $field=qq(<select name="$name");
  while(my($key,$val)=each %$args){
    _escape($key);
    _escape($val);
    $field.=qq( $key="$val");
  }
  $field.=' multiple="multiple"' if $multiple;
  $field.=">";

  $field.=_select_options($values,\%option_args,$labels,$v_as_l);
  $field.="</select>";

  $field;
}



=item submit(PAIRLIST)

Generates an C<E<lt>inputE<gt>> of type C<submit>. All of the supplied
arguments are HTML-escaped, and used directly as attributes. C<submit>
fields are not sticky.

=cut

sub submit{
  my($self,$args)=_args(@_);
  $args->{type}='submit' unless exists $args->{type};

  my $field='<input';
  while(my($key,$val)=each %$args){
    _escape($key);
    _escape($val);
    $field.=qq( $key="$val");
  }
  $field.="$self->{well_formed}>";

  $field;
}


=back




=begin private

=head1 PRIVATE SUBROUTINES

These subs are only intended for internal use.

=over

=item _escape($string)

Escape HTML-special characters in $string, in place. If $string is not defined,
it will be updated to an empty string.

=cut

sub _escape($){
  if(defined $_[0]){
    $_[0]=~s/([<>&"]|[^\0-\177])/sprintf "&#%d;",ord $1/ge;
  }else{
    $_[0]='';
  }
}

=item _args(@_)

Work out which of the two argument passing conventions is being used, and
return ($self,\%args). This essentially converts the public unrolled
PAIRLIST arguments into a single hashref, as used by the internal
interfaces.

=cut

sub _args{
  my $self=shift;
  my $args=ref($_[0]) ? {%{$_[0]}} : {@_};
  ($self,$args);
}

=item _select_options(\@values,\%option_args,\%labels,$values_as_labels)

Returns an HTML fragment containing C<option> elements for the supplied
list of option values. Values which are arrayrefs are used to represent
option groups, wherein the zeroth element is either the group name, or
a hashref holding the group's attributes.

=cut

sub _select_options{
  my($values,$option_args,$labels,$v_as_l)=@_;
  my $field='';
  for my $value(@$values){
    if(ref $value){
      # Handle option group
      my($_group,@subvalues)=@$value;
      my %group=ref($_group) ? %$_group : (label => $_group);
      if(delete $group{disabled}){
        $group{disabled}='disabled';
      }
      $field.=qq(<optgroup);
      while(my($name,$value)=each %group){
        _escape($value);
	$field.=qq( $name="$value");
      }
      $field.='>';
      $field.=_select_options(\@subvalues,$option_args,$labels,$v_as_l);
      $field.='</optgroup>';
    }else{
      # Handle single option
      _escape(my $evalue=$value);
      $field.=qq(<option value="$evalue");
      while(my($key,$val)=each %$option_args){
        if(ref $val){
	  defined($val=$val->{$value})
	    or next;
	}
	_escape($val);
	$field.=qq( $key="$val");
      }
      $field.=">";
      if(exists $labels->{$value}){
	my $label=$labels->{$value};
	_escape($label);
	$field.=$label;
      }elsif($v_as_l){
	$field.=$evalue;
      }
      $field.="</option>";
    }
  }

  $field;
}

=back

=end private

=cut

# Return true to require
1;



=head1 AUTHOR

Copyright (C) Institute of Physics Publishing 2000-2011

	Peter Haworth <pmh@edison.ioppublishing.com>

You may use and distribute this module according to the same terms
that Perl is distributed under.


