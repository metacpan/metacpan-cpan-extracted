package HTML::FormBuilder;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.12';

use Carp;
use HTML::FormBuilder::FieldSet;
use String::Random ();
use Moo;
use namespace::clean;
use HTML::Entities;
extends qw(HTML::FormBuilder::Base);

has data => (
    is  => 'ro',
    isa => sub {
        my $data = shift;
        croak('data should be a hashref') unless ref($data) eq 'HASH';
        croak("Form must be given an id when instantiating a HTML::FormBuilder->new object in $0.") if !defined $data->{'id'};
    },
    default => sub {
        {};
    },
);

has fieldsets => (
    is  => 'rw',
    isa => sub {
        my $fieldsets = shift;
        return 1 unless $fieldsets;
        croak('fieldsets should be an arrayref')
            unless ref($fieldsets) eq 'ARRAY';
    },
    default => sub {
        [];
    },
);

has after_form => (
    is  => 'rw',
    isa => sub {
        return !ref($_[0]);
    });

has csrftoken => (is => 'ro');

sub BUILDARGS {
    my (undef, @args) = @_;
    my %args = (@args % 2) ? %{$args[0]} : @args;

    # set default class
    if ($args{classes}) {
        $args{classes} = {%{$HTML::FormBuilder::Base::CLASSES}, %{$args{classes}}};
    } else {
        $args{classes} = {%{$HTML::FormBuilder::Base::CLASSES}};
    }

    if (($args{csrftoken} // '') eq '1') {
        $args{csrftoken} = String::Random::random_regex('[a-zA-Z0-9]{16}');
    }

    $args{data}{method} ||= 'get';
    $args{data}{method} = 'get' if $args{data}{method} ne 'post';
    return \%args;
}

#####################################################################
# Usage      : Add a new fieldset to the form
# Purpose    : Allow the form object to carry more than 1 fieldsets
# Returns    : Fieldset object
# Parameters : Hash reference with keys in <fieldsets> supported attributes
# Comments   : Fieldset works like a table, which allow one form to
#              have more than 1 fieldset. Each Fieldset has its own
#              input fields.
# See Also   :
#####################################################################
sub add_fieldset {
    my $self  = shift;
    my $_args = shift;

    #check if the $args is a ref HASH
    croak("Parameters must in HASH reference in $0.")
        if (ref $_args ne 'HASH');

    my $fieldset = HTML::FormBuilder::FieldSet->new(
        data     => $_args,
        classes  => $self->classes,
        localize => $self->localize
    );

    push @{$self->{fieldsets}}, $fieldset;

    return $fieldset;
}

#####################################################################
# Usage      : Add a new input fields to the fieldset
# Purpose    : Check is the fieldset is created, and if is created
#              add the input field into the fieldset
# Returns    :
# Parameters : Hash reference with keys
#              'label'   => $ref_hash
#              'input'   => $ref_hash
#              'error'   => $ref_hash
#              'comment' => $ref_hash
# Comments   : check pod below to understand how to create different input fields
# See Also   :
#####################################################################
sub add_field {
    my $self           = shift;
    my $fieldset_index = shift;
    my $_args          = shift;

    #check if the fieldset_index is number
    croak("The fieldset_index should be a number")
        unless ($fieldset_index =~ /^\d+$/);

    #check if the fieldset array is already created
    croak("The fieldset does not exist in $0. form_id[$self->{data}{'id'}]")
        if ($fieldset_index > $#{$self->{fieldsets}});

    my $fieldset = $self->{fieldsets}[$fieldset_index];
    return $fieldset->add_field($_args);

}

#####################################################################
# Usage      : generate the form
# Purpose    : check and parse the parameters and generate the form
#              properly
# Returns    : form HTML
# Parameters : Fieldset index that would like to print, null to print all
# Comments   :
# See Also   :
# TODO       : seems the parameter fieldset index useless.
#####################################################################
sub build {
    my $self                 = shift;
    my $print_fieldset_index = shift;

    # build the fieldset, if $print_fieldset_index is specifed then
    # we only generate that praticular fieldset with that index
    my @fieldsets;
    if (defined $print_fieldset_index) {
        push @fieldsets, $self->{'fieldsets'}[$print_fieldset_index];
    } else {
        @fieldsets = @{$self->{'fieldsets'}};
    }

    my %grouped_fieldset;

    # build the form fieldset
    foreach my $fieldset (@fieldsets) {
        my ($fieldset_group, $fieldset_html) = $fieldset->build();
        push @{$grouped_fieldset{$fieldset_group}}, $fieldset_html;
    }

    my $fieldsets_html = '';
    foreach my $fieldset_group (sort keys %grouped_fieldset) {
        if ($fieldset_group ne 'no-group') {
            $fieldsets_html .= qq[<div id="$fieldset_group" class="$self->{classes}{fieldset_group}">];
        }

        foreach my $fieldset_html (@{$grouped_fieldset{$fieldset_group}}) {
            $fieldsets_html .= $fieldset_html;
        }

        if ($fieldset_group ne 'no-group') {
            $fieldsets_html .= '</div>';
        }
    }

    if ($self->csrftoken) {
        $fieldsets_html .= sprintf qq(<input type="hidden" name="csrftoken" value="%s"/>), $self->csrftoken;
    }

    my $html = $self->_build_element_and_attributes('form', $self->{data}, $fieldsets_html);

    if ($self->after_form) {
        $html .= $self->after_form;
    }

    return $html;
}

#
# This builds a bare-bone version of the form with all inputs hidden and only
# displays a confirmation button. It can be used for when we'd like to ask
# the Client to confirm what has been entered before processing.
#
# This output currently only outputs text or hidden fields, and ignores the
# rest. Extra functionality would need to be added to handle any type of form.
#
sub build_confirmation_button_with_all_inputs_hidden {
    my $self = shift;
    my @inputs;

    # get all inputs that are to be output as hidden
    foreach my $fieldset (@{$self->{'fieldsets'}}) {
        INPUT:
        foreach my $input_field (@{$fieldset->{'fields'}}) {
            my $data = $input_field->{data};
            next INPUT if (not defined $data->{'input'});

            push @inputs, @{$data->{'input'}};

        }
    }

    my $html = '';

    foreach my $input (@inputs) {
        next if ($input->{'type'} and $input->{'type'} eq 'submit');
        my $n = $input->{'name'} || '';
        my $val = $self->get_field_value($input->{'id'}) || '';
        $html .= qq{<input type="hidden" name="$n" value="$val"/>};
    }

    if ($self->csrftoken) {
        $html .= sprintf qq(<input type="hidden" name="csrftoken" value="%s"/>), $self->csrftoken;
    }

    $html .= '<input type="hidden" name="process" value="1"/>';
    $html .= _link_button({
        value => $self->_localize('Back'),
        class => $self->{classes}{backbutton},
        href  => 'javascript:history.go(-1)',
    });
    $html .= ' <span class="button"><button id="submit" class="button" type="submit">' . $self->_localize('Confirm') . '</button></span>';
    $html = $self->_build_element_and_attributes('form', $self->{data}, $html);

    return $html;
}

################################################################################
# Usage      : $form_obj->set_field_value('input_element_id', 'foo');
# Purpose    : Set input value based on input element id
# Returns    : none
# Parameters : $field_id: Input element ID
#              $field_value: Value (text)
# Comments   : Public
# See Also   : get_field_value
################################################################################
sub set_field_value {
    my $self        = shift;
    my $field_id    = shift;
    my $field_value = shift;
    return unless $field_id;

    my $input_field = $self->_get_input_field($field_id);
    return unless $input_field;

    my $data   = $input_field->{data};
    my $inputs = $data->{input};

    map {
        if ($_->{'id'} and $_->{'id'} eq $field_id) {
            if (eval { $_->can('value') }) {
                # for select box
                $_->value($field_value);
            } elsif ($_->{'type'} =~ /(?:text|textarea|password|hidden|file)/i) {
                $_->{'value'} = HTML::Entities::encode_entities($field_value // '');
            } elsif ($_->{'type'} eq 'checkbox') {
                # if value not set during $fieldset->add_field(), default to browser default value for checkbox: 'on'
                my $checkbox_value = $_->{'value'} // 'on';
                $_->{'checked'} = 'checked' if ($field_value eq $checkbox_value);
            }
        }
    } @{$inputs};
    return;
}

################################################################################
# Usage      : $form_obj->get_field_value('input_element_id');
# Purpose    : Get input value based on input element id
# Returns    : text (Input value) / undef
# Parameters : $field_id: Input element ID
# Comments   : Public
# See Also   : set_field_value
################################################################################
sub get_field_value {
    my $self     = shift;
    my $field_id = shift;

    my $input_field = $self->_get_input_field($field_id);
    return unless $input_field;

    my $inputs = $input_field->{data}{input};
    foreach my $input (@$inputs) {
        if ($input->{'id'} and $input->{'id'} eq $field_id) {
            if (eval { $input->can('value') }) {
                return $input->value;
            }
            return unless $input->{type};

            if ($input->{type} =~ /(?:text|textarea|password|hidden|file)/i) {
                return HTML::Entities::decode_entities($input->{value} // '');
            } elsif ($input->{type} eq 'checkbox' && $input->{checked} && $input->{checked} eq 'checked') {
                # if value not set during $fieldset->add_field(), default to browser default value for checkbox: 'on'
                return ($input->{value} // 'on');
            }
        }
    }
    return;
}

################################################################################
# Usage      : 1. $form_obj->set_field_error_message('input_element_id', 'some error');
#              2. $form_obj->set_field_error_message('error_element_id', 'some error');
# Purpose    : Set error message based on input element id or error element id
# Returns    : none
# Parameters : $field_id: Field ID (input or error)
#              $error_msg: Error message text
# Comments   : Public
# See Also   : get_field_error_message
################################################################################
sub set_field_error_message {
    my $self      = shift;
    my $field_id  = shift;
    my $error_msg = shift;

    my $input_field = $self->_get_input_field($field_id);
    if ($input_field) {
        $input_field->{data}{'error'}{'text'} = $error_msg;
        return;
    }

    my $error_field = $self->_get_error_field($field_id);
    if ($error_field) {
        $error_field->{data}{'error'}{'text'} = $error_msg;
        return;
    }
    return;
}

################################################################################
# Usage      : 1. $form_obj->get_field_error_message('input_element_id');
#              2. $form_obj->get_field_error_message('error_element_id');
# Purpose    : Get error message based on input element id or error element id
# Returns    : text (Error message)
# Parameters : $field_id: Field ID (input or error)
# Comments   : Public
# See Also   : set_field_error_message
################################################################################
sub get_field_error_message {
    my $self     = shift;
    my $field_id = shift;

    my $input_field = $self->_get_input_field($field_id);
    return $input_field->{data}{'error'}{'text'} if $input_field;

    my $error_field = $self->_get_error_field($field_id);
    return $error_field->{data}{'error'}{'text'} if $error_field;

    return;
}

#####################################################################
# Usage      : $self->_get_input_field('amount');
# Purpose    : Get the element based on input field id
# Returns    : Element contains input field
# Parameters : $field_id: Field ID
# Comments   : Private
# See Also   :
#####################################################################
sub _get_input_field {
    my $self     = shift;
    my $field_id = shift;

    return unless $field_id;
    foreach my $fieldset (@{$self->{'fieldsets'}}) {
        foreach my $input_field (@{$fieldset->{'fields'}}) {
            my $inputs = $input_field->{data}{input};
            foreach my $sub_input_field (@$inputs) {
                if (    $sub_input_field->{id}
                    and $sub_input_field->{id} eq $field_id)
                {
                    return $input_field;
                }
            }
        }
    }

    return;
}

#####################################################################
# Usage      : $self->_get_error_field('error_amount');
# Purpose    : Get the element based on error field id
# Returns    : Element contains error field
# Parameters : $error_id: Error ID
# Comments   : Private
# See Also   :
#####################################################################
sub _get_error_field {
    my $self     = shift;
    my $error_id = shift;

    return unless $error_id;

    #build the form fieldset
    foreach my $fieldset (@{$self->{'fieldsets'}}) {
        foreach my $input_field (@{$fieldset->{'fields'}}) {
            if (    $input_field->{data}{error}{id}
                and $input_field->{data}{error}{id} eq $error_id)
            {
                return $input_field;
            }
        }
    }
    return;
}

#####################################################################
# Usage      : $self->_link_button({value => 'back', class => 'backbutton', href => '})
# Purpose    : create link button html
# Returns    : HTML
# Parameters : {value, class, href}
# Comments   :
# See Also   :
#####################################################################
sub _link_button {
    my $args = shift;

    my $myclass = $args->{'class'} ? 'button ' . $args->{'class'} : 'button';

    my $myid     = $args->{'id'} ? 'id="' . $args->{'id'} . '"'      : '';
    my $myspanid = $args->{'id'} ? 'id="span_' . $args->{'id'} . '"' : '';

    return qq{<a class="$myclass" href="$args->{href}" $myid><span class="$myclass" $myspanid>$args->{value}</span></a>};
}

#####################################################################
# Usage      : $self->_wrap_fieldset($fieldset_html)
# Purpose    : wrap fieldset html by template
# Returns    : HTML
# Comments   :
# See Also   :
#####################################################################
sub _wrap_fieldset {
    my ($self, $fieldset_html) = @_;
    my $fieldset_template = <<EOF;
<div class="rbox form">
    <div class="rbox-wrap">
        $fieldset_html
        <span class="tl">&nbsp;</span><span class="tr">&nbsp;</span><span class="bl">&nbsp;</span><span class="br">&nbsp;</span>
    </div>
</div>
EOF

    return $fieldset_template;
}

1;

=head1 NAME

HTML::FormBuilder - A Multi-part HTML form

=head1 SYNOPSIS

    #define a form
    my $form = HTML::FormBuilder->new(
        data =>{id    => 'formid',
                class => 'formclass'},
        classes => {row => 'rowdev'})

    #create fieldset
    my $fieldset = $form->add_fieldset({id => 'fieldset1});

    #add field
    $fieldset->add_field({input => {name => 'name', type => 'text', value => 'Join'}});

    #set field value
    $form->set_field_value('name', 'Omid');

    #output the form
    print $form->build;

=head1 DESCRIPTION

Object-oriented module for displaying an HTML form.

=head2 Overview of Form's HTML structure

The root of the structure is the <form> element and follow by multiple <fieldset> elements.

In each <fieldset>, you can create rows which contain label, different input types, error message and comment <p> element.

Please refer to L</"A full sample result">

=head1 Attributes

=head2 data

The form attributes. It should be a hashref.

=head2 classes

The form classes. It should be a hashref. You can customize the form's layout by the classes.
The class names used are:

      fieldset_group
      no_stack_field_parent
      row_padding
      fieldset_footer
      comment
      row
      extra_tooltip_container
      backbutton
      required_asterisk
      inputtrailing
      label_column
      input_column
      hide_mobile

=head2 localize

The subroutine ref which can be called when translate something like 'Confirm'. The default value is no translating.

=head2 fieldsets

The fieldsets the form have.

=head1 Methods

=head2 new

    my $form = HTML::FormBuilder->new(
        data =>{id    => 'formid',
                class => 'formclass'},
        classes => {row => 'rowdev'})

The id is required for the form.

=head2 add_fieldset

    my $fieldset = $form->add_fieldset({id => 'fieldset1});

the parameter is the fieldset attributes.
It will return the fielset object.

=head2 add_field

      $form->add_field(0, {input => {name => 'name', type => 'text', value => 'Join'}});

The parameter is the fieldset index to which you want to add the field and the field attributes.

=head2 build

      print $form->build;

the data in the $form will be changed when build the form. So you cannot get the same result if you call build twice.

=head2 BUILDARGS

=head2 build_confirmation_button_with_all_inputs_hidden

=head2 csrftoken

=head2 get_field_error_message

=head2 get_field_value

=head2 set_field_error_message

=head2 set_field_value

=head1 Cookbook

=head2 a full sample

  # Before create a form, create a classes hash for the form
  my $classes = {comment => 'comment', 'input_column' => 'column'};
  # And maybe you need a localize function to translate something
  my $localize = sub {i18n(shift)};

  # First, create the Form object. The keys in the HASH reference is the attributes of the form
  $form_attributes => {'id'     => 'id_of_the_form',
                       'name'   => 'name_of_the_form',
                       'method' => 'post', # or get
                       'action' => 'page_to_submit',
                       'header' => 'My Form',
                       'localize' => $localize,
                       'classes'  => $classes,
                       };   #header of the form
  my $form = HTML::FormBuilder->new(data => $form_attributes, classes => $classes, localize => $localize);

  #Then create fieldset, the form is allow to have more than 1 fieldset
  #The keys in the HASH reference is the attributes of the fieldset

  $fieldset_attributes => {'id'      => 'id_of_the_fieldset',
                           'name'    => 'name_of_the_fieldset',
                           'class'   => 'myclass',
                           'header'  => 'User details',      #header of the fieldset
                           'comment' => 'please fill in',    #message at the top of the fieldset
                           'footer'  => '* - required',};    #message at the bottom of the fieldset
  };
  my $fieldset = $form->add_fieldset($fieldset_attributes);

  ####################################
  #Create the input fields.
  ####################################
  #When creating an input fields, there are 4 supported keys.
  #The keys are label, input, error, comment
  #  Label define the title of the input field
  #  Input define and create the actual input type
  #     In input fields, you can defined a key 'heading', which create a text before the input is displayed,
  #     however, if the input type is radio the text is behind the radio box
  #  Error message that go together with the input field when fail in validation
  #  Comment is the message added to explain the input field.

  ####################################
  ###Creating a input text
  ####################################

  my $input_text = {'label'   => {'text' => 'Register Name', for => 'name'},
                    'input'   => {'type' => 'text', 'value' => 'John', 'id' => 'name', 'name' => 'name', 'maxlength' => '22'},
                    'error'   => { 'id' => 'error_name' ,'text' => 'Name must be in alphanumeric', 'class' => 'errorfield hidden'},
                    'comment' => {'text' => 'Please tell us your name'}};

  ####################################
  ###Creating a select option
  ####################################
      my @options;
      push @options, {'value' => 'Mr', 'text' => 'Mr'};
      push @options, {'value' => 'Mrs', 'text' => 'Mrs'};

      my $input_select = {'label' => {'text' => 'Title', for => 'mrms'},
                          'input' => {'type' => 'select', 'id' => 'mrms', 'name' => 'mrms', 'options' => \@options},
                          'error' => {'text' => 'Please select a title', 'class' => 'errorfield hidden'}};


  ####################################
  ###Creating a hidden value
  ####################################
  my $input_hidden = {'input' => {'type' => 'hidden', 'value' => 'John', 'id' => 'name', 'name' => 'name'}};

  ####################################
  ###Creating a submit button
  ####################################
  my $input_submit_button = {'input' => {'type' => 'submit', 'value' => 'Submit Form', 'id' => 'submit', 'name' => 'submit'}};

  ###NOTES###
  Basically, you just need to change the type to the input type that you want and generate parameters with the input type's attributes

  ###########################################################
  ###Having more than 1 input field in a single row
  ###########################################################
  my $input_select_dobdd = {'type' => 'select', 'id' => 'dobdd', 'name' => 'dobdd', 'options' => \@ddoptions};
  my $input_select_dobmm = {'type' => 'select', 'id' => 'dobmm', 'name' => 'dobmm', 'options' => \@mmoptions};
  my $input_select_dobyy = {'type' => 'select', 'id' => 'dobyy', 'name' => 'dobyy', 'options' => \@yyoptions};
  my $input_select = {'label' => {'text' => 'Birthday', for => 'dobdd'},
                      'input' => [$input_select_dobdd, $input_select_dobmm, $input_select_dobyy],
                      'error' => {'text' => 'Invalid date.'}};

  #Then we add the input field into the Fieldset
  #You can add using index of the fieldset
  $fieldset->add_field($input_text);
  $fieldset->add_field($input_select);
  $fieldset->add_field($input_submit_button);

  ###########################################################
  ### Field value accessors
  ###########################################################
  $form->set_field_value('name', 'Omid');
  $form->get_field_value('name'); # Returns 'Omid'

  ###########################################################
  ### Error message accessors
  ###########################################################
  $form->set_field_error_message('name',       'Your name is not good :)');
  # or
  $form->set_field_error_message('error_name', 'Your name is not good :)');

  $form->get_field_error_message('name');       # Return 'Your name is not good :)'
  # or
  $form->get_field_error_message('error_name'); # Return 'Your name is not good :)'

  #Finally, we output the form
  print $form->build();


=head2 A full sample result

    <form id="onlineIDForm" method="post" action="">
       <fieldset id="fieldset_one" name="fieldset_one" class="formclass">
           <div>
                <label for="name">Register Name</label>
                <em>:</em>
                <input type="text" value="John" id="name" name="name">
                <p id = "error_name" class="errorfield hidden">Name must be in alphanumeric</p>
                <p>Please tell us your name</p>
           </div>
           <div>
                <label for="mrms">Title</label>
                <em>:</em>
                <select id="mrms" name="mrms">
                    <option value="Mr">Mr</option>
                    <option value="Mrs">Mrs</option>
                </select>
                <p class="errorfield hidden">Please select a title</p>
           </div>
           <div>
                <label for="dob">Birthday</label>
                <em>:</em>
                <select id="dobdd" name="dobdd">
                    <option value="1">1</option>
                    <option value="2">2</option>
                </select>
                <select id="dobmm" name="dobmm">
                    <option value="1">Jan</option>
                    <option value="2">Feb</option>
                </select>
                <select id="dobyy" name="dobyy">
                    <option value="1980">1980</option>
                    <option value="1981">1981</option>
                </select>
                <p class="errorfield hidden">Invalid date</p>
           </div>
           <div>
                <input type="submit" value="Submit Form" id="submit" name="submit">
           </div>
       </fieldset>
    </form>

=head2 How to create a form with validation

Please refer to <HTML::FormBuilder::Validation>

=head2 CROSS SITE REQUEST FORGERY PROTECTION

read <HTML::FormBuilder::Validation> for more details

=head1 AUTHOR

Chylli L<mailto:chylli@binary.com>

=head1 CONTRIBUTOR

Fayland Lam L<mailto:fayland@binary.com>

Tee Shuwn Yuan L<mailto:shuwnyuan@binary.com>

=head1 COPYRIGHT AND LICENSE

=cut

