package HTML::FormsDj;

use strict;
use warnings;

our $VERSION = '0.03';

use Data::FormValidator;
use Data::FormValidator::Constraints;
use Data::Dumper;
use Carp::Heavy;
use Digest::SHA;
use Carp;

our $_csrftoken;

sub new {
  my($this, %param) = @_;
  my $class = ref($this) || $this;
  my $self = \%param;
  bless $self, $class;


  if (exists $self->{meta}->{fields} && exists  $self->{meta}->{fieldsets}) {
    croak 'Either use meta->fields or meta->fieldsets, not both!';
  }

  if (! exists $self->{field}) {
    croak 'No FIELDS hash specified!';
  }

  if (! exists $self->{meta}) {
    $self->{meta} = {};
  }

  if (! exists $self->{meta}->{fields} && ! exists $self->{meta}->{fieldsets}) {
    # generate them if the user doesn't bother
    $self->{meta}->{fields} = [];
    foreach my $field (sort keys %{$self->{field}}) {
      my $n = $field;
      $n =~ s/^(.)/uc($1)/e;
      push @{$self->{meta}->{fields}}, { field => $field, label => $n };
    }
  }

  if (exists $self->{csrf}) {
    if ($self->{csrf} && ! $_csrftoken) {
      my $sha = Digest::SHA->new('SHA-256');
      $sha->reset();
      $self->{sha} = $sha;
      $_csrftoken = $self->_gen_csrf_token();
    }
  }
  else {
    $self->{csrf} = 0;
  }

  return $self;
}

sub cleandata {
  my($this, %data) = @_;

  # construct validator structs
  my(@required, @optional, %input, %attrs, %constraints);

  $this->{isclean} = 0;

  if ($this->{csrf}) {
    if(! $this->_check_csrf(%data)) {
      # CSRF check failed, so we don't tamper with input
      # further. die and done.
      return ();
    }
  }

  if (exists $this->{dfv}) {
    # override all
    %input = %{$this->{dfv}};
  }
  else {
    # generate dfv hash
    foreach my $field (keys %{$this->{field}}) {
      if($this->{field}->{$field}->{required}) {
	push @required, $field;
      }
      else {
	push @optional, $field;
      }
      $constraints{ $field } = $this->{field}->{$field}->{validate};
      $input{ $field } = $data{ $field } || qq();
    }
  }

  if (exists $this->{attributes}) {
    # there are dfv options, pass them as is
    %attrs = %{$this->{attributes}};
  }
  if(! exists $attrs{required}) {
    $attrs{required} = \@required;
  }
  if(! exists $attrs{optional}) {
    $attrs{optional} = \@optional;
  }
  if(! exists $attrs{constraint_methods}) {
    $attrs{constraint_methods} = \%constraints;
  }

  # validate the input
  my $results = Data::FormValidator->check(\%input, \%attrs);

  if ($results->has_invalid or $results->has_missing) {
    # store errors for later output
    $this->{isclean} = 0;
    if ( $results->has_missing ) {
      foreach my $field ( $results->missing ) {
	$this->{missing}->{$field} = 1;
      }
    }
    if ( $results->has_invalid ) {
      foreach my $field ( $results->invalid ) {
	my $failed = $results->invalid( $field );
	if (ref($failed) eq 'HASH') {
	  $this->{invalid}->{$field} = join ', ', @{$failed->{$field}};
	}
	else {
	  $this->{invalid}->{$field} = join ', ', @{$failed};
	}
      }
    }
  }
  else {
    if(exists $this->{clean}) {
      # call the custom clean() closure supplied by the user
      ($this->{isclean}, $this->{error}) = $this->{clean}(%{$results->valid});
    }
    else {
      $this->{isclean} = 1;
    }
  }


  # store cleaned and raw data
  $this->{cleaned} = $results->valid;
  $this->{raw}     = \%data;

  return %{$this->{cleaned}};
}

sub clean {
  my($this) = @_;
  return $this->{isclean};
}

sub error {
  my($this) = @_;
  if(exists $this->{error}) {
    return $this->{error};
  }
  else {
    return qq();
  }
}

sub _check_csrf {
  my ($this, %data) = @_;

  if (! exists $data{csrftoken}) {
    $this->{error}   = 'CSRF ERROR: CSRF token is not supplied with POST data!';
    return 0;
  }

  if (! exists $this->{'_csrf_cookie'}) {
    $this->{error}   = 'CSRF ERROR: CSRF cookie is not set correctly(notexist)!';
    return 0;
  }
  else {
    if(! $this->{'_csrf_cookie'} ) {
      $this->{error}   = 'CSRF ERROR: CSRF cookie is not set correctly(undef)!';
      return 0;
    }
  }

  my $posttoken   = $data{csrftoken};          # hidden post var
  my $cookietoken = $this->{'_csrf_cookie'};   # cookie

  if ($posttoken ne $cookietoken) {
    $this->{error}   = 'CSRF ERROR:  supplied COOKIE csrftoken doesnt match stored csrf token!';
    $this->{error}  .= sprintf "<br>post: %s<br>cookie: %s", $posttoken, $cookietoken;
    return 0;
  }

  return 1;
}

sub as_p {
  my($this) = @_;
  my $html;
  $this->_normalize();

  if ($this->{csrf}) {
    $html = $this->csrftoken();
  }

  if (exists $this->{meta}->{fields}) {
    # just an array of fields
    foreach my $field( @{$this->{meta}->{fields}}) {
      $html .= $this->_p_field($field);
    }
  }
  else {
    # it's a fieldset
    foreach my $fieldset (@{$this->{meta}->{fieldsets}}) {
      my $htmlfields;
      foreach my $field (@{$fieldset->{fields}}) {
	$htmlfields .= $this->_p_field($field);
      }
      $html .= $this->_fieldset(
				join(' ', @{$fieldset->{classes}}),
				$fieldset->{id},
				$fieldset->{legend},
				$htmlfields
				);
    }
  }

  return $html;
}

sub as_table {
  my($this) = @_;
  my $html;
  $this->_normalize();

  if ($this->{csrf}) {
    $html = $this->csrftoken();
  }

  if (exists $this->{meta}->{fields}) {
    # just an array of fields
    foreach my $field( @{$this->{meta}->{fields}}) {
      $html .= $this->_tr_field($field);
    }
    return $this->_table('formtable', $html);
  }
  else {
    # it's a fieldset
    foreach my $fieldset (@{$this->{meta}->{fieldsets}}) {
      my $htmlfields;
      foreach my $field (@{$fieldset->{fields}}) {
	$htmlfields .= $this->_tr_field($field);
      }
      $html .= $this->_table($fieldset->{id}, $htmlfields, $fieldset->{legend});
    }
  }

  return $html;
}

sub as_is {
  my($this) = @_;
  $this->_normalize();
  return $this->{meta};
}

sub fields {
  my($this) = @_;
  if (exists $this->{meta}->{fields}) {
    return @{$this->{meta}->{fields}};
  }
  else {
    return ();
  }
}

sub fieldsets {
  my($this) = @_;
  if (exists $this->{meta}->{fieldsets}) {
    return @{ $this->{meta}->{fieldsets} };
  }
  else {
    return ();
  }
}

sub dumpmeta {
  my($this) = @_;
  my $dump = Dumper($this->{meta});
  $dump =~ s/^\$VAR1 = /        /;
  return sprintf qq(<pre>%s</pre>), $dump;
}

sub csrftoken {
  my($this) = @_;
  if ($this->{csrf}) {
    return sprintf qq(<input type="hidden" name="csrftoken" value="%s"/>), $_csrftoken;
  }
  else {
    return qq();
  }
}

sub getcsrf {
  my($this) = @_;
  if ($this->{csrf}) {
    return $_csrftoken;
  }
  else {
    return qq();
  }
}

sub csrfcookie {
  my($this, $token) = @_;
  if ($this->{csrf}) {
    $this->{'_csrf_cookie'} = $token;
  }
  return 1;
}

#
# INTERNALS HERE
#

sub _message {
  my($this, $message, $id) = @_;
  return sprintf qq(<span class="fielderror" id="%s">%s</span>), $id, $message;
}

sub _tr_field {
  my($this, $field) = @_;
  return $this->_tr(
		   join(q( ), @{$field->{classes}}),
		   $field->{id},
		   $this->_label(
				 $field->{id} . '_input',
				 $field->{label}
				),
		   $this->_input(
				 $field->{id} . '_input',
				 $field->{type},
				 $field->{field},
				 $field->{value},
				 $field->{default} # hashref, arrayref or scalar
				) .
		    $this->_message($field->{message}, $field->{id} . '_message')
		  );
}

sub _tr {
  my($this, $class, $id, $label, $input) = @_;
  return sprintf qq(<tr id="%s"><td class="%s tdlabel">%s</td><td class="%s tdinput">%s</td></tr>\n),
    $id, $class, $label, $class, $input;
}

sub _table {
  my($this, $id, $cdata, $legend) = @_;
  my $html = sprintf qq(<table id="%s">), $id;
  if ($legend) {
    $html .= sprintf qq(<thead><tr><td colspan="2">%s</td></tr></thead>\n), $legend;
  }
  $html .= sprintf qq(<tbody>%s</tbody></table>\n), $cdata;
  return $html;
}

sub _normalize_field {
  my($this, $field) = @_;

  if (! exists $field->{label}) {
    $field->{label} = $field->{field};
    $field->{label} =~ s/^(.)/uc($1)/e;
  }

  if (exists $this->{markrequired} && $this->{field}->{$field->{field}}->{required}) {
    if ($this->{markrequired} eq 'asterisk') {
      $field->{label} = $field->{label} . ' *';
    }
    elsif ($this->{markrequired} eq 'bold') {
      $field->{label} = $this->_b($field->{label});
    }
    else {
      $field->{label} = $field->{label} . $this->{markrequired};
    }
  }

  if (! exists $field->{classes}) {
    $field->{classes} = [ qw(formfield) ];
  }

  if (! exists $field->{id}) {
    $field->{id} = 'id_formfield_' . $field->{field};
  }

  if (! exists  $field->{message}) {
    $field->{message} = qq();
  }
  if (exists $this->{invalid}->{$field->{field}}) {
    if (! exists $field->{message}) {
      $field->{message} = 'invalid input';
    }
    $field->{error} = $this->{invalid}->{$field->{field}};
  }

  if (exists $this->{missing}->{$field->{field}}) {
    if (! exists $field->{message}) {
      $field->{message} = 'missing input';
    }
    $field->{error} = 'missing input';
  }

  if (! exists $this->{raw}->{$field->{field}}) {
    $field->{value} = qq();
  }
  else {
    $field->{value} = $this->{raw}->{$field->{field}};
  }

  if (! exists $this->{field}->{$field->{field}}->{type}) {
    $field->{type} = 'text';
  }
  else {
    $field->{type} = $this->{field}->{$field->{field}}->{type};
  }

  if (! exists $field->{default}) {
    $field->{default} = qq();
  }

  return $field;
}

sub _normalize {
  my($this) = @_;

  if (exists $this->{meta}->{fields}) {
    my @normalized;
    foreach my $field( @{$this->{meta}->{fields}}) {
      if (! exists $field->{field}) {
	carp 'unnamed field, ignoring!';
	next;
      }

      push @normalized, $this->_normalize_field($field);
    }
    $this->{meta}->{fields} = \@normalized;
  }

  if (exists $this->{meta}->{fieldsets}) {

    my @fieldsets;
    foreach my $fieldset (@{$this->{meta}->{fieldsets}}) {
      if (! exists $fieldset->{id}) {
	if (! exists $fieldset->{name}) {
	  $fieldset->{id} = 'id_fieldset_' . $.;
	}
	else {
	  $fieldset->{id} = 'id_fieldset_' . $fieldset->{name};
	}
      }

      if (! exists $fieldset->{classes}) {
	$fieldset->{classes} = [ qw(formfieldset) ];
      }

      if (! exists $fieldset->{legend}) {
	$fieldset->{legend} = qq();
      }

      my @normalized;
      foreach my $field (@{$fieldset->{fields}}) {
	if (! exists $field->{field}) {
	  carp 'unnamed field, ignoring!';
	  next;
	}
	push @normalized, $this->_normalize_field($field);
      }

      $fieldset->{fields} = \@normalized;
      push @fieldsets, $fieldset;
    }
    $this->{meta}->{fieldsets} = \@fieldsets;
  }

  return;
}


sub _fieldset {
  my($this, $class, $id, $legend, $cdata) = @_;
  return sprintf qq(<fieldset class="%s" id="%s"><legend>%s</legend>\n%s\n</fieldset>\n),
    $class, $id, $legend, $cdata;
}

sub _p_field {
  my($this, $field) = @_;
  return $this->_p(
		   join(' ', @{$field->{classes}}),
		   $field->{id},
		   $this->_label(
				 $field->{id} . '_input',
				 $field->{label}
				) .
		   $this->_input(
				 $field->{id} . '_input',
				 $field->{type},
				 $field->{field},
				 $field->{value},
				 $field->{default} # hashref, arrayref or scalar
				) .
		   $this->_message($field->{message}, $field->{id} . '_message')
		  );
}

sub _p {
  my ($this, $class, $id, $cdata) = @_;
  return sprintf qq(<p class="%s" id="%s">%s</p>\n), $class, $id, $cdata;
}

sub _label {
  my ($this, $id, $name) = @_;
  return sprintf qq(\n  <label for="%s">%s</label>), $id, $name;
}

sub _input {
  my ($this, $id, $type, $name, $value, $default) = @_;

  my $html;

  if ($type eq 'text' || $type eq 'password') {
    if (! $value) {
      $value = $default;
    }
    $html = sprintf qq(\n  <input type="%s" id="%s" name="%s" value="%s"/>\n), $type, $id, $name, $value;
  }
  elsif ($type eq 'choice') {
    my $html = sprintf qq(\n  <select name="%s" id="%s">), $name, $id;
    if (ref($default) eq 'HASH') {
      foreach my $option (sort keys %{$default}) {
	$html .= sprintf qq(\n    <option value="%s">%s</option>), $option, $default->{$option};
      }
    }
    elsif (ref($default) eq 'ARRAY') {
      foreach my $option (@{$default}) {
	my $selected = qq();
	if ($value eq $option->{value}) {
	  $selected = ' selected';
	}
	$html .= sprintf qq(\n    <option value="%s"%s>%s</option>), $option->{value}, $selected, $option->{label};
      }
    }
    $html .= qq(\n  </select>\n);

  }
  elsif ($type eq 'option') {
    $html = qq(\n<ul>\n);
    if (ref($default) eq 'HASH') {
      foreach my $option (sort keys %{$default}) {
	my $checked = qq();
	if ($value eq $option->{value}) {
	  $checked = qq( checked="checked");
	}
	$html .= qq(<li>) . $this->_label(
					 $id . $option,
					 sprintf (qq(<input type="radio" value="%s" name="%s"%s/>), $option, $name, $checked)
					 . $default->{$option}
					 ) .
                 qq(\n</li>\n);
      }
    }
    elsif (ref($default) eq 'ARRAY') {
      foreach my $option (@{$default}) {
	my $checked = qq();
	if ($value eq $option->{value}) {
	  $checked = qq( checked="checked");
	}
	$html .= qq(<li>) . $this->_label(
					 $id . $option->{value},
					 sprintf (qq(<input type="radio" value="%s" name="%s"%s/>), $option->{value}, $name, $checked)
					 . $option->{label}
					 ) .
                 qq(\n</li>\n);
	;
      }
    }
    $html .= qq(\n</ul>);
  }
  elsif ($type eq 'textarea') {
    $html = sprintf qq(<textarea id="%s" name="%s">%s</textarea>\n), $id, $name, $value;
  }
  return $html;
}

sub _b {
  my($this, $cdata) = @_;
  return sprintf qq(<strong>%s</strong>), $cdata;
}

sub _gen_csrf_token {
  my($this) = @_;
  $this->{sha}->add(rand(10));
  $this->{sha}->add(time);
  my $csrftoken = $this->{sha}->hexdigest();
  $this->{sha}->reset();
  return $csrftoken;
}

1;

__END__

=head1 NAME

HTML::FormsDj - a web forms module the django way

=head1 SYNOPSIS

In your L<Dancer> app:

 use HTML::FormsDj;
 use Data::FormValidator;
 
 # a custom DFV constraint. You may also use one
 # of the supplied ones of Data::FormValidator
 sub valid_string { 
   return sub {
     my $dfv = shift;
     $dfv->name_this('valid_string');
     my $val = $dfv->get_current_constraint_value();
     return $val =~ /^[a-zA-Z0-9\-\._ ]{4,}$/;
   }
 }

 # our route, we act on GET and POST requests
 any '/addbook' => sub {
   my $form = new HTML::FormsDj(
      # the form, we maintain 2 form variables, title and author
      field => {
		title   => {
			    type     => 'text',
			    validate => valid_string(),
			    required => 1,
			},
		author  => {
			    type     => 'text',
			    validate => valid_string(),
			    required => 1,
			   },
	       },
      name         => 'registerform'
   );

  if ( request->method() eq "POST" ) {
    # a POST request, fetch the raw input and pass it to the form
    my %input = params;

    # "clean" the data, which means to validate it
    my %clean = $form->cleandata(%input);

    if ($form->clean() ) {
      # validation were successfull, so save the data
      # you'll have to put your own way of data saving
      # here of course
      &savebook($clean{title}, $clean{author});
      redirect '/booklist';
    }
    else {
      # nope, something were invalid, put the user
      # back to the form. his input will be preserved
      return template 'addbook', { form => $form };
    }
  }
  else {
    # a GET request, so just present the empty form
    template 'addbook', { form => $form };
  }
 };

In your template (views/addbook.tt):

 <form name="addbook" method="post" action="/addbook">
 <% form.as_p %>
 <input type="submit" name="submit" value="Add Book"/>
 </form>

That's it. Here's the output:

 <form name="addbook" method="post" action="/addbook">

 <p class="formfield" id="id_formfield_author">
  <label for="id_formfield_author_input">Author</label>
  <input type="text" id="id_formfield_author_input" name="author" value=""/>
  <span class="fielderror" id="id_formfield_author_message"></span>
 </p>

 <p class="formfield" id="id_formfield_title">
  <label for="id_formfield_title_input">Title</label>
  <input type="text" id="id_formfield_title_input" name="title" value=""/>
  <span class="fielderror" id="id_formfield_title_message"></span>
 </p>

 <input type="submit" name="submit" value="Add Book"/>

 </form>


=head1 DESCRIPTION

The B<HTML::FormsDj> module provides a comfortable way to maintain
HTML form input. Its main use is for L<Dancer> but can be used with
other perl application servers as well, since it doesn't require
L<Dancer> to run at all.

B<HTML::FormsDj> aims to behave as much as B<Django's> Forms system
with the excpetion to do it the perl way and without a B<save> feature.

It works as follows: You create a new form and tell it which form
variables it has to maintain and how to validate them. In your template
you can then put out the generated form. B<HTML::FormsDj> will
put back user input into the form if some of the data were invalid.
This way your user doesn't have to re-enter anything.

You can tweak the behavior and output as much as possible. You can
add your own CSS classes, CSS id's, error messages and so on.

=head1 CREATING A FORM

To create a form, you have to instanciate an B<HTML::FormsDj> object.
Any parameters have to be passed as a hash (of hashes) to B<new()>.

The most important parameter is the B<field> hash. Here you tell
the form, which form variables it has to maintain for you, of which
type they are and how to validate them.

 my $form = new HTML::FormsDj(
  field => {
    variablename   => {
      type     => 'text',
      validate => some_validator_func(),
      required => 1,
    },
    anothervariable => {
      # .. and so on
    }
  }
 );

A variable can have the following types:

B<text>: onelined text fields

B<password>: same as above but for passwords

B<textarea>: multilined text fields (for blobs etc) 

B<choice>: a select list

B<option>: a checkbox option list

The B<validate> parameter requires a L<Data::FormValidator>
constraint function. Refer to the documentation of this
module, how this works. B<HTML::FormsDj> will just pass
this constraint to Data::FormValidator.

The B<required> parameter tells the form, if the variable
is - obviously - required or not.

=head1 CUSTOMIZING THE FORM

As you may already have realized, we are missing something
here. A form variable on a web page requires a label. And
what about styling?

Enter B<meta>.

Using the B<meta> hash parameter to B<new()> you can tell
B<HTML::FormsDj> how to do the mentioned things above and
more.

Ok, so let's return to our book example from above and add
some meta configuration to it:

   my $form = new HTML::FormsDj(
      field => {
		title   => {
			    type     => 'text',
			    validate => valid_string(),
			    required => 1,
			},
		author  => {
			    type     => 'text',
			    validate => valid_string(),
			    required => 1,
			   },
	       },
      name => 'registerform',
      meta => {
                 fields => [
                             {
                             field    => 'title',
                             label    => 'Enter a book title',
                             message  => 'A book title must be at least 4 characters long',
                             classes  => [ qw(titlefield) ],
                             },
                             {
                             field    => 'author',
                             label    => 'Enter an author name',
                             message  => 'A book title must be at least 4 characters long',
                             classes  => [ qw(authorfield) ],
                             },
                           ]
      }
   );

So, what do we have here? B<meta> is a hashref which contains a hashkey B<fields>
which points to an arrayref, which consists of a list of hashrefs.

Easy to understand, isn't it?

If you disagree here - well, please hang on. I'll explain it deeper :)

=head2 META FIELD LIST

Ok, to put it simply: B<meta> is a hash (because in the future there maybe
more meta parameters available) with one element B<fields> which points
to a list of fields.

B<Please note: the order of appearance of fields does matter!>

Fields will be displayed in the generated HTML output in this order.

Each field B<must> have a B<field> parameter, which is the name
of the field and has to correspond to the form variable name
of the field you defined previously in B<new()>.

All other parameters are optional. If you omit them, or if you omit
the whole meta parameter, B<HTML::FormsDj> will generate it itself
using reasonable defaults based on the variable names.

Parameters of a field hash are:

=over

=item B<field>

As mentioned above, the name of the form variable.

=item B<label>

A label which will be put before the input field.

=item B<message>

A message, which will be shown if there are some
errors or if the field were missing.

=item B<classes>

A list (arrayref) of CSS class names to apply to the
field.

=item B<id>

A CSS id you may assign to the field.

=back

=head2 META FIELDSET

Sometimes a plain list of fields may not be sufficient, especially
if you have to render a large input form. You may use a B<fieldset>
instead of a B<field> to better organize the display of the form.

Again, using the example used above, you could write:

   my $form = new HTML::FormsDj(
      field => {
		title   => {
			    type     => 'text',
			    validate => valid_string(),
			    required => 1,
			},
		author  => {
			    type     => 'text',
			    validate => valid_string(),
			    required => 1,
			   },
	       },
      name => 'registerform',
      meta => {
                 fieldsets => [
                                {
                                  name        => 'titleset',
                                  description => 'Enter book title data here',
                                  legend      => 'Book Title',
                                  fields      => [
                                                   {
                                                    field    => 'title',
                                                    label    => 'Enter a book title',
                                                    message  => 'A book title must be at least 4 characters long',
                                                    classes  => [ qw(titlefield) ],
                                                   },
                                                  ]
                                },
                                {
                                  name        => 'authorset',
                                  description => 'Enter book author data here',
                                  legend      => 'Book Author',
                                  fields      => [
                                                   {
                                                    field    => 'author',
                                                    label    => 'Enter an author name',
                                                    message  => 'A book title must be at least 4 characters long',
                                                    classes  => [ qw(authorfield) ],
                                                   },
                                                  ]
                                },
                              ]
      }
   );

Ok, this looks a little bit more complicated. Essentially
there is just one more level in the definition. A fieldset
is just a list of groups of fields. It is defined as a list
(an arrayref) which contains hashes, one hash per fieldset.

Each fieldset hash consists of some parameters, like a B<name>
or a B<legend> plus a list of fields, which is exactly defined
as in the B<meta> parameter B<fields> as seen above.

The output of the form is just devided into fieldsets, which
is a HTML tag as well. Each fieldset will have a title, the B<legend>
parameter, an (optional) B<description> and a B<name>.

This is the very same as the META subclass in django forms
is working.

B<Please note: you cannot mix a field list and fieldsets!>

Only one of the two is possible.

If you omit the B<meta> parameter at all, B<HTML::FormsDj> will
always generate a plain field list.

=head2 ADDING DEFAULT VALUES

IN some cases you'll need to put some defaults for form
variables, eg. for choices or options.

You can do this by adding a B<default> parameter to
the field definition in your meta hash.

For text type variables this can just be a scalar. For choices
and options you can supply a hash- or an array reference.

An example for a choice:

  # other fields
  ,
  {
    field => 'redirect',
    label => 'Redirect to page',
    default => [
                   {
                    value => 1,
                    label => '/home'
                   },
                   {
                    value => 2,
                    label => '/profile'
                   }
                ],
  }
  ,
  # other fields

In this example we've a choice which contains two values
for the generated select form tag. Here we've used an array,
which is the preferred way since this preserves order.

However, you might also supply a hash:

  # other fields
  ,
  {
    field => 'redirect',
    label => 'Redirect to page',
    default => {
                 1 => '/home',
                 2 => '/profile'
                }
  }
  ,
  # other fields


=head1 DISPLAYING THE FORM

To display the form, you have a couple of choices.

=head2 as_p

The easiest way is to use the B<as_p> method. Usually you'll
call this method from your template.

In the Dancer world you have to do it this way:

Pass the form to the template:

 template 'addbook', { form => $form }

And in your template 'addbook.tt' you call B<as_p>:

 <% form.as_p %>

You have to take care of the HTML B<form> tag yourself. A complete
HTML form would look like this:

 <form name="addbook" method="post" action="/addbook">
 <% form.as_p %>
 <input type="submit" name="submit" value="Add Book"/>
 </form>

As you can see, you have to put the submit button yourself
as well. This is because some people might add Javascript to
the button or don't want to use such a button at all.

=head2 as_table

This display method generates a HTML table. Calling it works
the very same as B<as_p>:

 <% form.as_table %>

=head2 MANUAL RENDERING USING fields and fieldsets

Instead of letting HTML::FormsDj do the rendering of the form,
you may render it in your template yourself. You can access
the fields (or fieldsets containing fields, if any) from a
forms object from a template.

Let's render the form for our book author example manually:

 <form name="addbook" method="post" action="/addbook">
 <% FOREACH field = form.fields %>
  <p id="<% form.id %>">
   <% field.label %>:
   <input type="text" name="<% field.field %>" value="<% field.value %>"/>
   <span style="color: red"><% form.message %></span>
   <br/>
  </p>
 <% END %>
 <input type="submit" name="submit" value="Add Book"/>
 </form>

That's pretty easy. Of course you need to check for the
field type in your template, because different field types
require different html output. You can check for B<field.type>, eg:

 <% IF field.type == 'textarea' %>
   <textarea name="<% field.field %>"><% field.value %></textarea>
 <% END %>



=head2 as_is

This is in fact no display method, it rather just returns
the normalized B<meta> hash and NO HTML code. You can use
this to generate the HTML yourself, perhaps if the provided
methods here are not sufficient for you or if you have
to output something different than HTML (e.g. JSON or XML).

The structure returned will look like this (based on our
example above with some data filled in by a user):

 {
   'fields' => [
                 {
                   'classes' => [
                                  'formfield'
                                ],
                   'value'   => 'Neal Stephenson',
                   'default' => '',
                   'type'    => 'text',
                   'id'      => 'id_formfield_author',
                   'label'   => 'Author',
                   'field'   => 'author'
                 },
                 {
                   'classes' => [
                                  'formfield'
                                ],
                   'value'   => 'Anathem',
                   'default' => '',
                   'type'    => 'text',
                   'id'      => 'id_formfield_title',
                   'label'   => 'Title',
                   'field'   => 'title'
                 }
               ]
  };

Or, if it contains validation errors:

 {
   'fields' => [
                 {
                   'classes' => [
                                  'formfield'
                                ],
                   'value'   => '',
                   'default' => '',
                   'type'    => 'text',
                   'id'      => 'id_formfield_author',
                   'label'   => 'Author',
                   'field'   => 'author',
                   'message' => 'missing input',
                   'error'   => 'missing input',

                 },
                 {
                   'classes' => [
                                  'formfield'
                                ],
                   'value'   => 'Ana',
                   'default' => '',
                   'type'    => 'text',
                   'id'      => 'id_formfield_title',
                   'label'   => 'Title',
                   'field'   => 'title',
                   'message' => 'invalid input',
                   'error'   => 'valid_string',
                 }
               ]
  };


=head1 INPUT DATA VALIDATION

To validate the user input just fetch the HTTP POST
data and pass them to the form. The B<Dancer> way:

 my %input = params;
 my %clean = $form->cleandata(%input);

B<cleandata> now generates based on your configuration L<Data::FormValidator>
and calls its B<check> method to let it validate the input data.

It returns a plain perl hash containing the B<VALID> data. This
hash maybe incomplete if there were validation errors or required
fields were not filled in by the user.

Therefore, you'll have to check if validation were successfull:

=head2 CHECK VALIDATION STATUS

Use the method B<clean> to check if validation had errors. It returns
a true value if not.

Example:

 if ($form->clean() ) {
   # save the data and tell the user
 }
 else {
   # put the same form back to the user again
   # so the user has to retry
 }

=head2 CUSTOM CLEAN METHOD

Beside the described validation technique you may also supply
your own B<clean()> method to the form, which may do additional
checks, such as if a user exists in a database or the like.

You can do this by supplying a closure to the B<clean> parameter
(not method!) when you instantiate the form.

Example:

 my $form = new HTML::FormsDj(
      ..,
      clean      => sub {
        my (%clean) = @_;
        my $user = $db->resultset('User')->find({login => $clean{user}});
        if($user) {
          return (0, 'user exists');
        }
        else {
          return (1, '');
        }
      },
      ..
 );

In this example we're doing exactly this: we check if a
user already exists.

The closure will get the B<%clean> hash as a parameter,
which contains the clean validated form data.

B<Note: This closure will only called if all other validations
went successfull!>

The closure is expected to return a list with two values:
true or false and an error message.

=head2 USING Data::FormValidator ATTRIBUTES

The underlying validator module L<Data::FormValidator> supports
a couple of attributes which can be used to change its behavior.

You can supply such attributes to the form, which will be handed
over to L<Data::FormValidator>, eg:

 my $form = new HTML::FormsDj(
      ..,
      attributes => { filters  => ['trim'] },
      ..
 );

The B<attributes> parameter is just a hashref. Everything inside
will be supplied to B<Data::FormValidator::new()>. Refer to its
documentation which attributes could be used here.

=head2 ADVANCED CONTROL OF Data::FormValidator CONSTRAINTS

Usually B<HTML::FormsDj> generates the B<DFV Profile> used by the
B<Data::FormValidator::check()> method. Sometimes you might want
to supply your own, for instance if you need multiple validators
per variable or ir you want to modify the messages which will
be returned on errors and the like.

You can do this by using the B<dfv> parameter:

 my $form = new HTML::FormsDj(
      ..,
      dfv => {}
      ..
 );

Refer to L<Data::FormValidator#INPUT-PROFILE-SPECIFICATION>
how to specify/define the dfv profile.

In case you've got supplied a dfv profile, the form will
not generate its own and just use the one you supplied and
it will not check for errors or if it matches the B<field>
hash definition.

This technique is not recommended for the average user.


=head1 ERRORS AND DEBUGGING

You can use the form method B<dumpmeta>, which dumps out the
META hash, in your template to see what happens:

 <% form.dumpmeta %>

Beside errors per field there is also a global error
variable which can be put out using the B<error> method:

 <% form.error %>

=head1 CROSS SITE REQUEST FORGERY PROTECTION

B<This feature is experimental>.

B<HTML::FormsDj> provides CSRF attack protection. Refer to
L<http://www.squarefree.com/securitytips/web-developers.html#CSRF>
to learn what it is.

To enable CSRF protection, you'll set the B<csrf> parameter to
a true value:

 my $form = new HTML::FormsDj(
                 ..,
                 csrf => 1
                 ..
 );

If enabled, the form will generate a unique token for the form
based on the field names, some random number and current time.

This token must be set as a B<COOKIE> during the B<GET> request
to your form and the very same token has to exist as a B<HIDDEN
VARIABLE> in the form.

Since B<HTML::FormsDj> doesn't depend on L<Dancer> (or any other
perl app server), you are responsible for setting and retrieving
the cookie.

On POST request the value of the cookie must match the value
of the hidden variable. If one of them doesn't exist or the
two are not the same, B<clean()> returns B<FALSE>. In addition
no B<cleandata> will be returned and no validation will be done.

=head2 HOW TO USE CSRF PROTECTION IN A DANCER APP

First, enable it using the parameter mentioned above:

 my $form = new HTML::FormsDj(
                 ..,
                 csrf => 1
                 ..
 );

In your route for the GET request set the cookie. You can
retrieve the actual cookie value by using the B<csrfcookie>
method:

 cookie csrftoken => $form->getcsrf, expires => "15 minutes";
 template 'addbook', { form => $form };

Put this in your code where you're handling the GET request
of the form.

In your code for the POST request, you'll have to retrieve
the cookie and tell the form about it. This has to be done
B<BEFORE> you call B<clean>:

  if ( request->method() eq "POST" ) {
    my %input = params;
    $form->csrfcookie(cookie 'csrftoken');
    my %clean = $form->cleandata(%input);
    if ($form->clean() ) {
    ..

That's it. If you're using B<as_p> or B<as_table> you are
done and protected from this kind of attacks.

If you're creating your html form manually, you'll have to
put the hidden value into your template this way:

 <% form.csrftoken %>

=head2 WHY?

The forms module might not sound as the right place where
to do such things. Maybe a Dancer plugin for this would
be the better choice to implement such a feature.

However, my idea was, if I am already maintaining forms,
why not doing it in a secure way?

=head1 TODO

=over

=item add more unit tests

=back


=head1 SEE ALSO

I recommend you to read the following documents, which are supplied with Perl:

 perlreftut                     Perl references short introduction
 perlref                        Perl references, the rest of the story
 perldsc                        Perl data structures intro
 perllol                        Perl data structures: arrays of arrays

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 T. Linden

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 BUGS AND LIMITATIONS

See rt.cpan.org for current bugs, if any.

=head1 INCOMPATIBILITIES

None known.

=head1 DIAGNOSTICS

To debug HTML::FormsDj use the Perl debugger, see L<perldebug>.

=head1 DEPENDENCIES

B<HTML::FormsDj> depends on the module L<Data::FormValidator>.
It can be used with L<Dancer>, but this is no requirement.

=head1 AUTHOR

T. Linden <tlinden |AT| cpan.org>

=head1 VERSION

0.03

=cut
