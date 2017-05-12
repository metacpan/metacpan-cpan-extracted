
package HTML::StickyForms;
BEGIN {
  $HTML::StickyForms::VERSION = '0.08';
}
use strict;
use warnings;


################################################################################
# Class method: new($request)
# Description: Return a new HTML::StickyForms object
#	$request may be an instance of CGI (new or old) or Apache::Request
# Author: Peter Haworth
sub new{
  my($class,$req)=@_;

  my $type;
  if(!$req){
    $type='empty';
  }elsif(UNIVERSAL::isa($req,'Apache::Request')){
    $type='apreq';
  }elsif(UNIVERSAL::isa($req,'CGI') || UNIVERSAL::isa($req,'CGI::State')){
    $type='CGI';
  }else{
    # XXX Maybe this should die?
    return undef;
  }

  my $self=bless {
    req => $req,
    type => $type,
    values_as_labels => 0,
    well_formed => '',
  },$class;

  # Count submitted fields
  $self->set_sticky;

  $self;
}

################################################################################
# Method: set_sticky([BOOL])
# Description: Count the number of parameters set in the request
# Author: Peter Haworth
sub set_sticky{
  my $self=shift;
  return $self->{params}=!!$_[0] if @_;

  $self->{params}=()=$self->{type} eq 'empty' ? () : $self->{req}->param;
}

################################################################################
# Method: values_as_labels([BOOL])
# Description: Set/Get the values_as_labels attribute
# Author: Peter Haworth. Idea from Thomas Klausner (domm@zsi.at)
sub values_as_labels{
  my $self=shift;
  return $self->{values_as_labels}=$_[0] if @_;
  $self->{values_as_labels};
}

################################################################################
# Method: well_formed([BOOL])
# Description: Set/Get the well_formed attribute
# Author: Peter Haworth
sub well_formed{
  my $self=shift;
  return !!($self->{well_formed}=$_[0] ? '/' : '') if @_;
  !!$self->{well_formed};
}

################################################################################
# Method: trim_params()
# Description: Trim leading and trailing whitespace from all submitted values
# Author: Peter Haworth
sub trim_params{
  my($self)=@_;
  my $req=$self->{req};
  my $type=$self->{type};
  return if $type eq 'empty';

  foreach my $k($req->param){
    my @v=$req->param($k);
    my $changed;
    foreach(@v){
      $changed+= s/^\s+//s + s/\s+$//s;
    }
    if($changed){
      if($type eq 'apreq'){
	# XXX This should work, but doesn't
	# $req->param($k,\@v);

	# This does work, though
	if(@v==1){
	  $req->param($k,$v[0]);
	}else{
	  my $tab=$req->parms;
	  $tab->unset($k);
	  foreach(@v){
	    $tab->add($k,$_);
	  }
	}
      }else{
	$req->param($k,@v)
      }
    }
  }
}

################################################################################
# Subroutine: _escape($string)
# Description: Escape HTML-special characters in $string
# Author: Peter Haworth
sub _escape($){
  $_[0]=~s/([<>&"\177-\377])/sprintf "&#%d;",ord $1/ge;
}

################################################################################
# Method: text(%args)
# Description: Return an HTML <input type="text"> field
# Special %args elements:
#	type => type attribute value, defaults to "text"
#	default => value attribute value, if sticky values not present
# Author: Peter Haworth
sub text{
  my($self,%args)=@_;
  my $type=delete $args{type} || 'text';
  my $name=delete $args{name};
  my $value=delete $args{default};
  $value=$self->{req}->param($name) if $self->{params};

  _escape($name);
  _escape($value);

  my $field=qq(<input type="$type" name="$name" value="$value");
  while(my($key,$val)=each %args){
    $field.=qq( $key="$val"); # XXX Escape?
  }

  return "$field$self->{well_formed}>";
}

################################################################################
# Method: password(%args)
# Description: Return an HTML <input type="password"> field
#	As text()
# Author: Peter Haworth
sub password{
  my $self=shift;
  $self->text(@_,type => 'password');
}

################################################################################
# Method: textarea(%args)
# Description: Return an HTML <textarea> tag
# Special %args elements:
#	default => field contents, if sticky values not present
# Author: Peter Haworth
sub textarea{
  my($self,%args)=@_;
  my $name=delete $args{name};
  my $value=delete $args{default};
  $value=$self->{req}->param($name) if $self->{params};

  _escape($name);
  _escape($value);

  my $field=qq(<textarea name="$name");
  while(my($key,$val)=each %args){
    $field.=qq( $key="$val"); # XXX Escape?
  }

  return "$field>$value</textarea>";
}

################################################################################
# Method: checkbox(%args)
# Description: Return a single HTML <input type="checkbox"> tag
# Special %args elements:
#	checked => whether the box is checked, if sticky values not present
# Author: Peter Haworth
sub checkbox{
  my($self,%args)=@_;
  my $name=delete $args{name};
  my $value=delete $args{value};
  my $checked=delete $args{checked};
  $checked=$self->{req}->param($name) eq $value if $self->{params};

  _escape($name);
  _escape($value);

  my $field=qq(<input type="checkbox" name="$name" value="$value");
  $field.=' checked="checked"' if $checked;
  while(my($key,$val)=each %args){
    $field.=qq( $key="$val"); # XXX Escape?
  }

  return "$field$self->{well_formed}>";
}

################################################################################
# Method: checkbox_group(%args)
# Description: Return a group of HTML <input type="checkbox"> tags
# Special %args elements:
#	type => defaults to "checkbox"
#	value/values => arrayref of field values, defaults to label keys
#	label/labels => hashref of field names, no default
#	escape => whether to escape HTML characters in labels
#	default/defaults => arrayref of selected values, if no sticky values
#	linebreak => whether to add <br>s after each checkbox
#	values_as_labels => override the values_as_labels attribute
# Author: Peter Haworth
sub checkbox_group{
  my($self,%args)=@_;
  my $type=delete $args{type} || 'checkbox';
  my $name=delete $args{name};
  my $labels=delete $args{labels} || delete $args{label} || {};
  my $escape=delete $args{escape};
  my $values=delete $args{values} || delete $args{value} || [keys %$labels];
  my $defaults=delete $args{exists $args{defaults} ? 'defaults' : 'default'};
  $defaults=[] unless defined $defaults;
  $defaults=[$defaults] if ref($defaults) ne 'ARRAY';
  my $br=delete $args{linebreak} ? "<br$self->{well_formed}>" : '';
  my $v_as_l=$self->{values_as_labels};
  if(exists $args{values_as_labels}){
    $v_as_l=delete $args{values_as_labels};
  }
  my %checked=map { ; $_ => 1 }
    $self->{params} ? $self->{req}->param($name) : @$defaults;

  _escape($name);

  my $field=qq(<input type="$type" name="$name");
  while(my($key,$val)=each %args){
    $field.=qq( $key="$val"); # XXX Escape?
  }

  my @checkboxes;
  for my $value(@$values){
    _escape(my $evalue=$value);
    my $field=qq($field value="$evalue");
    $field.=' checked="checked"' if $checked{$value};
    $field.="$self->{well_formed}>";
    if((my $label=$v_as_l && !exists $labels->{$value}
      ? $value : $labels->{$value})=~/\S/
    ){
      _escape($label) if $escape;
      $field.=$label;
    }
    $field.=$br;
    push @checkboxes,$field;
  }

  return @checkboxes if wantarray;
  return join '',@checkboxes;
}

################################################################################
# Method: radio_group(%args)
# Description: Return a group of HTML <input type="radio"> tags
# Special %args elements:
#	value/values => arrayref of field values, defaults to label keys
#	label/labels => hashref of field labels, no default
#	escape => whether to escape HTML characters in labels
#	defaults/default => selected value, if no sticky values
#	linebreak => whether to add <br>s after each checkbox
# Author: Peter Haworth
sub radio_group{
  my($self,%args)=@_;

  $self->checkbox_group(%args,type => 'radio');
}

################################################################################
# Method: select(%args)
# Description: Return an HTML <select> tag
# Special %args elements:
#	value/values => arrayref of field values, defaults to label keys
#	label/labels => hashref of field labels, no default
#	default/defaults => selected value(s), if no sticky values
#	size => if positive, sets multiple
#	values_as_labels => override the values_as_labels attribute
#		Of little value, since this is HTML's default, anyway
# Author: Peter Haworth
sub select{
  my($self,%args)=@_;
  my $name=delete $args{name};
  my $multiple=delete $args{multiple};
  my $labels=delete $args{labels} || delete $args{label} || {};
  my $values=delete $args{values} || delete $args{value} || [keys %$labels];
  my $defaults=delete $args{exists $args{defaults} ? 'defaults' : 'default'};
  $defaults=[] unless defined $defaults;
  $defaults=[$defaults] if ref($defaults) ne 'ARRAY';
  my $v_as_l=$self->{values_as_labels};
  if(exists $args{values_as_labels}){
    $v_as_l=delete $args{values_as_labels};
  }
  my %selected=map { ; $_ => 1 }
    $self->{params} ? $self->{req}->param($name) : @$defaults;

  _escape($name);
  my $field=qq(<select name="$name");
  while(my($key,$val)=each %args){
    $field.=qq( $key="$val"); # XXX Escape?
  }
  $field.=' multiple="multiple"' if $multiple;
  $field.=">\n";
  for my $value(@$values){
    _escape(my $evalue=$value);
    $field.=qq(<option value="$evalue");
    $field.=' selected="selected"' if $selected{$value};
    $field.=">";
    if((my $label=$v_as_l && !exists $labels->{$value}
      ? $value : $labels->{$value})=~/\S/
    ){
      _escape($label);
      $field.=$label;
    }
    $field.="</option>\n";
  }
  $field.="</select>";

  $field;
}

################################################################################
# Return true to require
1;


__END__

=head1 NAME

HTML::StickyForms - HTML form generation for CGI or mod_perl

=head1 SYNOPSIS

 # mod_perl example

 use HTML::StickyForms;
 use Apache::Request;

 sub handler{
   my($r)=@_;
   $r=Apache::Request->new($r);
   my $f=HTML::StickyForms->new($r);

   $r->send_http_header;
   print
     "<HTML><BODY><FORM>",
     "Text field:",
     $f->text(name => 'field1', size => 40, default => 'default value'),
     "<BR>Text area:",
     $f->textarea(name => 'field2', cols => 60, rows => 5, default => 'stuff'),
     "<BR>Radio buttons:",
     $f->radio_group(name => 'field3', values => [1,2,3],
       labels => { 1=>'one', 2=>'two', 3=>'three' }, default => 2),
     "<BR>Single checkbox:",
     $f->checkbox(name => 'field4', value => 'xyz', checked => 1),
     "<BR>Checkbox group:",
     $f->checkbox_group(name => 'field5', values => [4,5,6],
       labels => { 4=>'four', 5=>'five', 6=>'six' }, defaults => [5,6]),
     "<BR>Password field:",
     $f->password(name => 'field6', size => 20),
     '<BR><INPUT type="submit" value=" Hit me! ">',
     '</FORM></BODY></HTML>',
    ;
    return OK;
  }

=head1 THIS MODULE IS DEPRECATED

This version has exactly the same functionality as version 0.06, and
exists only to provide more visibility to its successor, L<HTML::StickyForm>.
The new module tidies up a few interface inconsistencies which couldn't be
done without breaking backwards compatibility with the existing module, hence
the name change.

The new module provides a more consistent API, which allows stickiness to be
varied on a per-method basis in an obvious manner. It also diverges slightly
from the previous dogma of only supplying methods which strictly benefit from
stickiness, as it now provides convenience methods for generating password,
hidden and submit elements, as well as the form element itself. This allows
cleaner code to be written, since the whole form can now be generated using
a single API. Objects created by the new module have the C<well_formed>
attribute enabled by default, since most widely-used browsers can handle this
now. Finally, the trim_params() method has been removed from the new module,
since this would be better located in a module geared towards parameter
validation.

=head1 DESCRIPTION

This module provides a simple interface for generating HTML E<lt>FORME<gt>
fields, with default values chosen from the previous form submission. This
module was written with mod_perl in mind, but works equally well with CGI.pm,
including the new 3.x version.

The module does not provide methods for generating all possible form fields,
only those which benefit from having default values overridden by the previous
form submission. This means that, unlike CGI.pm, there are no routines for
generating E<lt>FORME<gt> tags, hidden fields or submit fields. Also this
module's interface is much less flexible than CGI.pm's. This was done mainly
to keep the size and complexity down.

=head2 METHODS

=over 4

=item HTML::StickyForms-E<gt>new($req)

Creates a new form generation object. The single argument can be an
Apache::Request object, a CGI object (v2.x), a CGI::State object (v3.x),
or an object of a subclass of any of the above. As a special case, if the
argument is C<undef> or C<''>, the object created will behave as if a request
object with no submitted fields was given.

=item $f-E<gt>set_sticky([BOOL])

If a true argument is passed, the form object will be sticky, using the request
object's parameters to fill the form. If a false argument is passed, the form
object will not be sticky, using the user-supplied default values to fill the
form. If no argument is passed, the request object's parameters are counted,
and the form object is made sticky if one or more parameters are present,
non-sticky otherwise.

This method is called by the constructor when a form object is created, so it
is not usually necessary to call it explicitly. However, it may be necessary to
call this method if parameters are set with the C<param()> method after the
form object is created.

=item $f-E<gt>trim_params()

Removes leading and trailing whitespace from all submitted values.

=item $f-E<gt>values_as_labels([BOOL])

With no arguments, this method returns the C<values_as_labels> attribute. This
attribute determines what to do when a value has no label in the
C<checkbox_group()>, C<radio_group()> and C<select()> methods. If this attribute
is false (the default), no labels will be automatically generated. If it is
true, labels will default to the corresponding value if they are not supplied
by the user.

If an argument is passed, it is used to set the C<values_as_labels> attribute.

=item $f-E<gt>well_formed([BOOL])

With no arguments, this method return the C<well_formed> attribute. This
attribute determines whether to generate well-formed XML, by including the
trailing slash in non-container elements. If this attribute is false, no
slashes are added - this is the default, since some older browsers don't
behave sensibly in the face of such elements. If true, all elements will
be well-formed.

If an argument is passed, it is used to set the C<well_formed> attribute.

=item $f-E<gt>text(%args)

Generates an E<lt>INPUTE<gt> tag, with a type of C<"text">. All arguments
are used directly to generate attributes for the tag, with the following
exceptions:

=over 8

=item type,

Defaults to C<"text">

=item name,

The value passed will have all HTML-special characters escaped.

=item default,

Specifies the default value of the field if no fields were submitted in the
request object passed to C<new()>. The value used will have all HTML-special
characters escaped.

=back

=item $f-E<gt>password(%args)

As C<text()>, but generates a C<"password"> type field.

=item $f-E<gt>textarea(%args)

Generates a E<lt>TEXTAREAE<gt> container. All arguments are used directly
to generate attributes for the start tag, except for:

=over 8

=item name.

This value will be HTML-escaped.

=item default.

Specifies the default contents of the container if no fields were submitted.
The value used will be HTML-escaped.

=back

=item $f-E<gt>checkbox(%args)

Generates a single C<"checkbox"> type E<lt>INPUTE<gt> tag. All arguments are
used directly to generate attributes for the tag, except for:

=over 8

=item name, value

The values passed will be HTML-escaped.

=item checked

Specifies the default state of the field if no fields were submitted.

=back

=item $f-E<gt>checkbox_group(%args)

Generates a group of C<"checkbox"> type E<lt>INPUTE<gt> tags. If called in
list context, returns a list of tags, otherwise a single string containing
all tags. All arguments are used directly to generate attributes in each tag,
except for the following:

=over 8

=item type

Defaults to C<"checkbox">.

=item name

This value will be HTML-escaped.

=item values, or value

An arrayref of values. One tag will be generated for each element. The values
will be HTML-escaped. Defaults to label keys.

=item labels, or label

A hashref of labels. Each tag generated will be followed by the label keyed
by the value. If no label is present for a given value, no label will be
generated. Defaults to an empty hashref.

=item escape

If this value is true, the labels will be HTML-escaped.

=item defaults, or default

A single value or arrayref of values to be checked if no fields were submitted.
Defaults to an empty arrayref.

=item linebreak

If true, each tag/label will be followed by a E<lt>BRE<gt> tag.

=item values_as_labels

Overrides the form object's C<values_as_labels> attribute.

=back

=item $f-E<gt>radio_group(%args)

As C<checkbox_group()>, but generates C<"radio"> type tags.

=item $f-E<gt>select(%args)

Generates a E<lt>SELECTE<gt> tags. All arguments are used directly to generate
attributes in the E<lt>SELECTE<gt> tag, except for the following:

=over 8

=item name:

This value will be HTML-escaped.

=item values or value

An arrayref of values. One E<lt>OPTIONE<gt> tag will be created inside the
E<lt>SELECTE<gt> tag for each element. The values will be HTML-escaped.
Defaults to label keys.

=item labels or label

A hashref of labels. Each E<lt>OPTIONE<gt> tag generated will contain the
label keyed by its value. If no label is present for a given value, no label
will be generated. Defaults to an empty hashref.

=item defaults or default

A single value or arrayref of values to be selected if no fields were
submitted. Defaults to an empty arrayref.

=item multiple

If a true value is passed, the C<MULTIPLE> attribute is set.

=item values_as_labels,

Overrides the form object's C<values_as_labels> attribute.

=back

=back

=head1 AUTHOR

Copyright (C) IOP Publishing Ltd 2000-2011

	Peter Haworth <pmh@edison.ioppublishing.com>

You may use and distribute this module according to the same terms
that Perl is distributed under.

