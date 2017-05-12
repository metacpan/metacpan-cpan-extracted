package HTTP::Request::Form;

use strict;
use vars qw($VERSION);
use URI::URL;
use HTTP::Request::Common;

$VERSION = "0.952";

sub new {
   my ($class, $form, $base, $debug) = @_;
   my @allfields;
   my @fields;
   my %fieldvals;
   my %fieldtypes;
   my %checkboxstate;
   my @buttons;
   my %buttonvals;
   my %buttontypes;
   my %selections;
   my $upload = 0;

   my $self = {};

   ($form->tag eq 'isindex')
   ? do {
       $self->{'isindex'} = 1;
       push @allfields, 'keywords'; # fake name. Same as CGI.pm uses.
       push @fields, 'keywords';
       $fieldvals{'keywords'} = ''; # fake value
       $fieldtypes{'keywords'} = 'input/text'; # fake type
     }
   : $form->traverse(
      sub {
      my ($self, $start, $depth) = @_;
      if (ref $self) {
         my $tag = $self->tag;
         if (($tag eq 'input') || 
	     (($tag eq 'button') && $start)) {
            my $type = lc($self->attr('type'));
	    $type = "text" if (!defined($type));
            if ($type eq 'hidden') {
               my $name = $self->attr('name');
               my $value = $self->attr('value');
               push @allfields, $name;
               $fieldvals{$name} = $value;
	       $fieldtypes{$name} = "$tag/$type";
            } elsif (($type eq 'submit') || 
	              ($type eq 'reset') || 
		      ($type eq 'image')) {
               my $name = $self->attr('name') || $type;
               my $value = $self->attr('value') || $type;
               if (defined($name)) {
                  if (!defined($buttonvals{$name})) {
                      push @buttons, $name;
                      $buttonvals{$name} = [$value];
		      $buttontypes{$name} = [$type];
                  } else {
                      push @{$buttonvals{$name}}, $value;
		      push @{$buttontypes{$name}}, $type;
                  }
               }
            } else {
               my $name = $self->attr('name');
               my $value = $self->attr('value');
	       if ($type eq 'radio') {
	          if (!defined($fieldtypes{$name})) {
		     push @allfields, $name;
		     push @fields, $name;
	             $fieldtypes{$name} = "$tag/$type";
		  }
                  if (!defined($selections{$name})) {
                     $selections{$name} = [$value];
                  } else {
                     push @{$selections{$name}}, $value;
                  }
                  $fieldvals{$name} = $value if ($self->attr('checked'));
	       } elsif ($type eq 'checkbox') {
	          push @allfields, $name;
		  push @fields, $name;
		  $fieldvals{$name} = $value;
		  $fieldtypes{$name} = "$tag/$type";
		  if ($self->attr('checked')) {
		     $checkboxstate{$name} = 1;
		  } else {
		     $checkboxstate{$name} = 0;
		  }
	       } else {
                  push @allfields, $name;
                  push @fields, $name;
                  $fieldvals{$name} = $value;
	          $fieldtypes{$name} = "$tag/$type";
	       }
	       if ($type eq 'file') {
	          $upload = 1;
	       }
            }
	 } elsif (($tag eq 'textarea') && $start) {
	    my $name = $self->attr('name');
	    push @allfields, $name;
	    push @fields, $name;
	    $fieldvals{$name} = "";
	    if ($self->content) {
	       foreach my $o (@{$self->content}) {
	          $fieldvals{$name} .= ref($o) ? $o->as_HTML : $o;
	       }
	    }
	    $fieldtypes{$name} = $tag;
         } elsif (($tag eq 'select') && $start) {
            my $name = $self->attr('name');
            push @allfields, $name;
            push @fields, $name;
            foreach my $o (@{$self->content || []}) {
               if (ref $o) {
                  my $tag = $o->tag;
                  if ($tag eq 'option') {
                     if ($o->attr('selected')) {
                        $fieldvals{$name} = $o->attr('value');
                     }
                     if (!defined($selections{$name})) {
                        $selections{$name} = [$o->attr('value')];
                     } else {
                        push @{$selections{$name}}, $o->attr('value');
                     }
                  }
               }
            }
	    $fieldtypes{$name} = $tag;
         }
      }
      1;
      }, 0
   );

   $self->{'debug'} = $debug;
   if (defined($form->attr('method'))) {
      $self->{'method'} = $form->attr('method');
   } else {
      $self->{'method'} = 'GET';
   }
   $self->{'name'} = $form->attr('name');
   $self->{'link'} = $form->attr('action');
   $self->{'base'} = $base;
   $self->{'allfields'} = \@allfields;
   $self->{'fields'} = \@fields;
   $self->{'fieldvals'} = \%fieldvals;
   $self->{'fieldtypes'} = \%fieldtypes;
   $self->{'buttons'} = \@buttons;
   $self->{'buttonvals'} = \%buttonvals;
   $self->{'buttontypes'} = \%buttontypes;
   $self->{'selections'} = \%selections;
   $self->{'upload'} = $upload;
   $self->{'checkboxstate'} = \%checkboxstate;
   bless $self, $class;
}

sub new_many {
   my ($class, $tree, $base, $debug) = @_;

   my (@to_return, @form_stack);

   # start off with throwaway pointers
   my $F = {};
   my $allfields = [];
   my $fields = [];
   my $fieldvals = {};
   my $fieldtypes = {};
   my $buttons = [];
   my $buttonvals = {};
   my $buttontypes = {};
   my $selections = {};
   my $checkboxstate = {};

   $tree->traverse(
      sub { # pre-order callback:
         my ($self, $start, $depth) = @_;
         if (ref $self) {
            my $tag = $self->tag;
            if ($tag eq 'form' or $tag eq 'isindex') {
               if($start) {
                 my $new = {};
                 $new->{'debug'} = $debug;
                 if (defined($self->attr('method'))) {
                    $new->{'method'} = $self->attr('method');
                 } else {
                    $new->{'method'} = 'GET';
                 }
                 $new->{'link'} = $self->attr('action');
                 $new->{'name'} = $self->attr('name');
                 $new->{'base'} = $base;
                 $new->{'allfields'}     = $allfields     = [];
                 $new->{'fields'}        = $fields        = [];
                 $new->{'fieldvals'}     = $fieldvals     = {};
                 $new->{'fieldtypes'}    = $fieldtypes    = {};
                 $new->{'buttons'}       = $buttons       = [];
                 $new->{'buttonvals'}    = $buttonvals    = {};
                 $new->{'buttontypes'}   = $buttontypes   = {};
                 $new->{'selections'}    = $selections    = {};
                 $new->{'checkboxstate'} = $checkboxstate = {};
                 $new->{'upload'} = 0;
                 bless $new, $class;
   
                 $F = $new;
                 push @to_return, $new;
                 push @form_stack, $new;
   
                 if($tag eq 'isindex') {
                   $new->{'isindex'} = 1;
                   push @$allfields, 'keywords'; # fake name. Same as CGI.pm uses.
                   push @$fields,    'keywords'; # fake name
                   $$fieldvals{'keywords'}  = '';   # fake value
                   $$fieldtypes{'keywords'} = "input/text"; # fake type
                   $start = 0; # so we'll pop it in the next block.
                               # (since ISINDEX is an empty element, we'd never
                               #  visit it in post-order for real)
   
                   #  In theory, this could mean that subsequent stranded form
                   #  elements would end up being put into this fake-o
                   #  Form object we made from the ISINDEX.  But hey, ISINDEX
                   #  is rare (and deprecated) these days, and is very unlikely
                   #  to co-occur with stranded form elements.  Moreover, the
                   #  added form elements would be basically ignored, unless
                   #  they actually had the field name "keywords".
                 }
               }
   
               unless($start) {
                 # We're leaving a FORM or ISINDEX element.
                 pop @form_stack;
                 $F = $form_stack[-1] if @form_stack;
                 # otherwise, the old one lingers.
   
                 # reset pointers:
                 $allfields     = $F->{'allfields'};
                 $fields        = $F->{'fields'};
                 $fieldvals     = $F->{'fieldvals'};
                 $fieldtypes    = $F->{'fieldtypes'};
                 $buttons       = $F->{'buttons'};
                 $buttonvals    = $F->{'buttonvals'};
                 $buttontypes   = $F->{'buttontypes'};
                 $selections    = $F->{'selections'};
                 $checkboxstate = $F->{'checkboxstate'};
               }
   
            } elsif (($tag eq 'input') ||
                (($tag eq 'button') && $start)) {
               my $type = lc($self->attr('type'));
               $type = "text" if (!defined($type));
               if ($type eq 'hidden') {
                  my $name = $self->attr('name');
                  my $value = $self->attr('value');
                  push @$allfields, $name;
                  $$fieldvals{$name} = $value;
                  $$fieldtypes{$name} = "$tag/$type";
               } elsif (($type eq 'submit') ||
                         ($type eq 'reset') ||
                         ($type eq 'image')) {
                  my $name = $self->attr('name') || $type;
                  my $value = $self->attr('value') || $type;
                  if (defined($name)) {
                     if (!defined($$buttonvals{$name})) {
                         push @$buttons, $name;
                         $$buttonvals{$name} = [$value];
                         $$buttontypes{$name} = [$type];
                     } else {
                         push @{$$buttonvals{$name}}, $value;
                         push @{$$buttontypes{$name}}, $type;
                     }
                  }
               } else {
                  my $name = $self->attr('name');
                  my $value = $self->attr('value');
                  if ($type eq 'radio') {
                     if (!defined($$fieldtypes{$name})) {
                        push @$allfields, $name;
                        push @$fields, $name;
                        $$fieldtypes{$name} = "$tag/$type";
                     }
                     if (!defined($$selections{$name})) {
                        $$selections{$name} = [$value];
                     } else {
                        push @{$$selections{$name}}, $value;
                     }
                     $$fieldvals{$name} = $value if ($self->attr('checked'));
                  } elsif ($type eq 'checkbox') {
                     push @$allfields, $name;
                     push @$fields, $name;
                     $$fieldvals{$name} = $value;
                     $$fieldtypes{$name} = "$tag/$type";
                     if ($self->attr('checked')) {
                        $$checkboxstate{$name} = 1;
                     } else {
                        $$checkboxstate{$name} = 0;
                     }
                  } else {
                     push @$allfields, $name;
                     push @$fields, $name;
                     $$fieldvals{$name} = $value;
                     $$fieldtypes{$name} = "$tag/$type";
                  }
                  if ($type eq 'file') {
                     $F->{'upload'} = 1;
                  }
               }
            } elsif (($tag eq 'textarea') && $start) {
               my $name = $self->attr('name');
               push @$allfields, $name;
               push @$fields, $name;
               $$fieldvals{$name} = "";
               foreach my $o (@{$self->content}) {
                  if ($o->can('as_HTML')) {
                     $$fieldvals{$name} .= $o->as_HTML;
                  } else {
                     $$fieldvals{$name} .= $o;
                  }
               }
               $$fieldtypes{$name} = $tag;
            } elsif (($tag eq 'select') && $start) {
               my $name = $self->attr('name');
               push @$allfields, $name;
               push @$fields, $name;
               foreach my $o (@{$self->content}) {
                  if (ref $o) {
                     my $tag = $o->tag;
                     if ($tag eq 'option') {
                        if ($o->attr('selected')) {
                           $$fieldvals{$name} = $o->attr('value');
                        }
                        if (!defined($$selections{$name})) {
                           $$selections{$name} = [$o->attr('value')];
                        } else {
                           push @{$$selections{$name}}, $o->attr('value');
                        }
                     }
                  }
               }
               $$fieldtypes{$name} = $tag;
            }
         }
         1;
     }, 0
   );
   
   return @to_return;

}

sub fields {
   my $self = shift;
   return @{$self->{'fields'}};
}

sub name {
   my $self = shift;
   return $self->{'name'};
}

sub isindex {
   my $self = shift;
   return $self->{'isindex'};
}

sub allfields {
   my $self = shift;
   return @{$self->{'allfields'}};
}

sub base {
   my $self = shift;
   return $self->{'base'};
}

sub method {
   my $self = shift;
   return $self->{'method'};
}

sub link {
   my $self = shift;
   return $self->{'link'};
}

sub field {
   my ($self, $name, $value) = @_;
   if (defined($value)) {
      $self->{'fieldvals'}->{$name} = $value;
   } else {
      return $self->{'fieldvals'}->{$name};
   }
}

sub field_selection {
   my ($self, $name) = @_;
   return $self->{'selections'}->{$name};
}

sub field_type {
   my ($self, $name) = @_;
   return $self->{'fieldtypes'}->{$name};
}

sub is_selection {
   my ($self, $name) = @_;
   if (defined($self->field_selection($name))) {
      return 1;
   } else {
      return undef;
   }
}

sub checkbox_check {
   my ($self, $name) = @_;
   return if (!defined($self->{'checkboxstate'}->{$name}));
   $self->{'checkboxstate'}->{$name} = 1;
}

sub checkbox_uncheck {
   my ($self, $name) = @_;
   return if (!defined($self->{'checkboxstate'}->{$name}));
   $self->{'checkboxstate'}->{$name} = 0;
}

sub checkbox_toggle {
   my ($self, $name) = @_;
   return if (!defined($self->{'checkboxstate'}->{$name}));
   if ($self->{'checkboxstate'}->{$name}) {
      $self->{'checkboxstate'}->{$name} = 0;
   } else {
      $self->{'checkboxstate'}->{$name} = 1;
   }
}

sub checkbox_ischecked {
   my ($self, $name) = @_;
   return $self->{'checkboxstate'}->{$name};
}

sub is_checkbox {
   my ($self, $name) = @_;
   if (defined($self->{'checkboxstate'}->($name))) {
      return 1;
   } else {
      return undef;
   }
}

sub checkboxes {
   my $self = shift;
   return keys %{$self->{'checkboxstate'}}
}

sub buttons {
   my $self = shift;
   return @{$self->{'buttons'}};
}

sub button {
   my ($self, $button, $value) = @_;
   if (defined($value)) {
      $self->{'buttonvals'}->{$button} = $value;
   } else {
      return $self->{'buttonvals'}->{$button};
   }
}

sub button_type {
   my ($self, $button) = @_;
   return $self->{'buttontypes'}->{$button};
}

sub button_exists {
   my ($self, $button) = @_;
   if (defined($self->button($button))) {
      return 1;
   } else {
      return undef;
   }
}

sub referer {
   my ($self, $value) = @_;
   if (defined($value)) {
      $self->{'referer'} = $value;
   } else {
      return $self->{'referer'};
   }
}

sub press {
   my ($self, $button, $bnum, $bnum2) = @_;
   my $x = 2;
   my $y = 2;
   if (ref $bnum) {
      $x = $bnum->[0];
      $y = $bnum->[1];
      $bnum = $bnum2;
   }
   my @array = ();
   foreach my $i ($self->allfields) {
      if ($self->field_type($i) eq "input/checkbox") {
         if ($self->checkbox_ischecked($i)) {
            push @array, $i;
            push @array, $self->field($i);
	 }
      } elsif ($self->field_type($i) eq "select") {
         if (defined($self->field($i))) {
	    push @array, $i;
	    push @array, $self->field($i);
	 }
      } elsif ($self->field_type($i) eq "input/file") {
         push @array, $i;
	 push @array, [ $self->field($i) ];
      } else {
         push @array, $i;
         push @array, $self->field($i);
      }
   }
   if (defined($button)) {
      die "Button $button not included in form"
          if (!defined($self->button($button)));
      if (defined($bnum)) {
         if (@{$self->button_type($button)}[$bnum] eq "image") {
            push @array, $button . '.x', $x;
            push @array, $button . '.y', $y;
	 } else {
            push @array, $button, @{$self->button($button)}[$bnum];
	 }
      } else {
         if (@{$self->button_type($button)}[0] eq "image") {
            push @array, $button . '.x', $x;
            push @array, $button . '.y', $y;
	 } else {
            push @array, $button, @{$self->button($button)}[0];
	 }
      }
   }
   my $url = url $self->link;
   if (defined($self->base)) {
      $url = $url->abs($self->base);
   }
   if ($self->{'debug'}) {
      print $self->method, " $url ", join(' - ', @array), "\n";
   }
   if ($self->{'isindex'}) {
      $url->query_keywords( $self->{'fieldvals'}->{'keywords'} );
      return GET $url;
   } elsif (uc($self->method) eq "POST") {
      my $referer = $self->referer;
      if ($self->{'upload'}) {
         if (defined($referer)) {
            return POST $url, Content_Type => 'form-data',
	                      'referer' => $referer,
	                      Content => \@array;
	 } else {
            return POST $url, Content_Type => 'form-data',
	                      Content => \@array;
	 }
      } else {
         if (defined($referer)) {
            return POST $url, 'referer' => $referer,
	                      Content => \@array;
	 } else {
            return POST $url, \@array;
	 }
      }
   } elsif (uc($self->method) eq "GET") {
      $url->query_form(@array);
      return GET $url;
   }
}

sub dump {
   my $self = shift;
   print "FORM METHOD=", $self->method, "\n     ACTION=", $self->link, "\n     BASE=", $self->base, "\n";
   foreach my $i ($self->allfields) {
      if (defined($self->field($i))) {
         print "FIELD{", $self->field_type($i), "} $i=", $self->field($i), "\n";
      } else {
         print "FIELD{", $self->field_type($i), "} $i\n";
      }
      if ($self->is_selection($i)) {
         print "      [", join(", ", @{$self->field_selection($i)}), "]\n";
      }
   }
   foreach my $i ($self->buttons) {
      if (defined($self->button($i))) {
         print "BUTTON $i=[", join(", ", map {$_ ? $_ : "<undef>"} @{$self->button($i)}), "]\n";
      } else {
         print "BUTTON $i\n";
      }
      if (defined($self->button_type($i))) {
         print "       $i={", join(", ", @{$self->button_type($i)}), "}\n";
      }
   }
   print "\n";
}

1;

__END__

=head1 NAME

HTTP::Request::Form - Construct HTTP::Request objects for form processing

=head1 SYNOPSIS

use the following as a tool to query Altavista for "perl" from the commandline:

  use URI::URL;
  use LWP::UserAgent;
  use HTTP::Request;
  use HTTP::Request::Common;
  use HTTP::Request::Form;
  use HTML::TreeBuilder 3.0;

  my $ua = LWP::UserAgent->new;
  my $url = url 'http://www.altavista.digital.com/';
  my $res = $ua->request(GET $url);
  my $tree = HTML::TreeBuilder->new;
  $tree->parse($res->content);
  $tree->eof();

  my @forms = $tree->find_by_tag_name('FORM');
  die "What, no forms in $url?" unless @forms;
  my $f = HTTP::Request::Form->new($forms[0], $url);
  $f->field("q", "perl");
  my $response = $ua->request($f->press("search"));
  print $response->content if $response->is_success;

=head1 DESCRIPTION

This is an extension of the HTTP::Request suite. It allows easy processing
of forms in a user agent by filling out fields, querying fields, selections
and buttons and pressing buttons. It uses HTML::TreeBuilder generated parse
trees of documents (especially the forms parts extracted with extract_links)
and generates it's own internal representation of forms from which it then
generates the request objects to process the form application.

=head1 CLASS METHODS

=over 4

=item new($form [, $base [, $debug]])

The C<new-method> constructs a new form processor. It get's an HTML::Element
object that contains a FORM element or ISINDEX element as the single parameter.
If an base-url is given as an additional parameter, this is used to make the
form-url absolute in regard to the given URL.

If debugging is true, the following functions will be a bit "talky" on stdio.

=item new_many($tree_part [, $base [, $debug]])

The C<new_many> method returns a list of newly constructed form processors.
It's just like the C<new> method except that it can apply to any part of an
HTML::Element tree, including the root; it constructs a new form processor
for each FORM element at or under C<$tree_part>.

Note that the return list might have zero, one or many new objects in it,
depending on how many FORM (or ISINDEX) elements were found.

Form elements (like INPUT, etc.) found outside of FORM elements are counted
as being part of the preceding FORM element. (And if there is no preceding
FORM element, they are ignored.) This feature is useful with the odd parse
trees that can result from basd HTML in or around FORM elements. If you need
to override that feature, then instead call:

  map HTTP::Request::Form->new($_), $tree->find_by_tag_name('FORM');

=back

=head1 INSTANCE METHODS

=over 4

=item base()

This returns the parameter $base to the "new" constructor.

=item link()

This returns the action attribute of the original form structure. This value
is cached within the form processor, so you can safely delete the form
structure after you created the form processor.

=item method()

This returns the method attribute of the original form structure. This value
is cached within the form processor, so you can safely delete the form
structure as soon as you created the form processor.

=item isindex()

This returns true if this came from an original form structure that was
actually an ISINDEX element. In that case, the form will hagve only
one field, an input/text field named "keywords".

=item name()

This returns the name attribute of the original form structure. This value
is cached within the form processor, so you can safely delete the form
structure after you created the form processor.

=item fields()

This method delivers a list of fieldnames that are of "open" type. This
excludes the "hidden" and "submit" elements, because they are already filled
with a value (and as such declared as "closed") or as in the case of "submit"
are buttons, of which only one must be used.

=item allfields()

This delivers a list of all fieldnames in the order as they occured in the
form-source excluding the submit fields.

=item field($name [, $value])

This method retrieves or sets a field-value. The field is identified by
its name. You have to be sure that you only put a allowed value into the
field.

=item field_type($name)

This method gives you the type of the named field, so that you can
distinguish on this type. (this is the only way to distinguish
selections and radio buttons).

=item is_selection($name)

This tests if a field is a selection or an input. Radio-Buttons are
used in the same way as standard selection fields, so is_selection
returns a true value for radio buttons, too! (Of course, only one
value is submitted for a radio button)

=item field_selection($name)

This delivers the array of the options of a selection. The element that is
marked with selected in the source is given as the default value. This
works in the same way for radio buttons, as they are just handled
as a special case of selections!

=item is_checkbox($name)

This tells you if a field is a checkbox. If it is, there are several support
methods to make use of the special features of checkboxes, for example the
fact that it is only sent if it is checked.

=item checkboxes()

This method delivers a list of all checkbox fields much in the same way as
the buttons method.

=item checkbox_check($name)

=item checkbox_uncheck($name)

=item checkbox_toggle($name)

These methods set, unset or toggle the checkbox checked state. Checkbox
values are only added to the result if they are checked.

=item checkbox_ischecked($name)

This methods tells you wether a checkbox is checked or not. This is important
if you want to analyze the state of fields directly after the parse.

=item buttons()

This delivers a list of all defined and named buttons of a form.

=item button($button [, $value])

This gets or sets the value of a button. Normally only getting a button value
is needed. The value of a button is a reference to an array of values (because
a button can exist multiple times).

=item button_type($button)

This gives you the type of a button (submit/reset/image). The result
is an array of type names, as a button with one name can exist
multiple times.

=item button_exists($button)

This gives true if the named button exists, false (undef) otherwise.

=item referer([$value])

This returns or sets the referer header for an request. This is useful if
a CGI needs a set referer for authentication.

=item press([$name [, $coord ] [, $number]])

This method creates a HTTP::Request object (via HTTP::Request::Common) that
sends the formdata to the server with the requested method. If you give a
button-name, that button is used. If you give no button name, it assumes a
button without a name and just leaves out this last parameter. If the number
of the button is given, that button value is delivered. If the number is not
given, 0 (the first button of this name) is assumed.

The "coord" parameter comes in handy if you have an image button. If this
is the case, the button press will simulate a press at coordinates [2,2]
unless you provide an anonymous array with different coordinates.

=item dump()

This method dumps the form-data on stdio for debugging purpose.

=back

=head1 SEE ALSO

L<HTTP::Request>, L<HTTP::Request::Common>, L<LWP::UserAgent>,
L<HTML::Element>, L<URI::URL>

=head1 INSTALLATION

  perl Makefile.PL
  make install

or see L<perlmodinstall>

=head1 REQUIRES

  Perl version 5.004 or later

  HTTP::Request::Common
  HTML::TreeBuilder
  LWP::UserAgent

=head1 VERSION

HTTP::Request::Form version 0.9, February 8th, 2001

=head1 RESTRICTIONS

Only a subset of all possible form elements are currently supported. The list
of supported tags as of this version includes:

  INPUT/CHECKBOX
  INPUT/HIDDEN
  INPUT/IMAGE
  INPUT/RADIO
  INPUT/RESET
  INPUT/SUBMIT
  INPUT/FILE
  INPUT/* (are all handled as simple text entry)
  OPTION
  SELECT
  TEXTAREA
  ISINDEX

=head1 BUGS

There is currently no support for multiple selections (you can do
them yourself by setting a selection to a comma-delimited list of
values).

Multiple fields are not properly handled, only the last value is
available. Exception are buttons, they are handled in the right way.

If there are several fields with the same name, you can only set
the value of the first of this fields (this is especially problematic
with checkboxes). This does work with buttons that have the same
name, though (you can press each instance identified by number).

Error-Checking is currently very limited (not to say nonexistant).

Support for HTML 4.0 optgroup tags is missing (as is with allmost
all current browsers, so that is not a great loss).

The button tag (HTML 4.0) is just handled as an alias for the input
tag - this is of course incorrect, but sufficient for support of
the usual button types.

=head1 COPYRIGHT

Copyright 1998, 1999, 2000 Georg Bauer E<lt>Georg_Bauer@muensterland.orgE<gt>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 MAJOR CONTRIBUTORS

Sean M. Burke (ISINDEX, new_many)

=cut

