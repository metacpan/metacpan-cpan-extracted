package HTML::FormBuilder::Validation;

use strict;
use warnings;

use Carp;
use Class::Std::Utils;

use Encode;
use URI::Escape;
use HTML::Entities;

use Moo;
use namespace::clean;
extends qw(HTML::FormBuilder);

our $VERSION = '0.12';    ## VERSION

has has_error_of => (
    is      => 'rw',
    default => 0,
    isa     => sub {
        croak('has_error_of should be 0 or 1') unless $_[0] == 0 || $_[0] == 1;
    },
);

has custom_server_side_check_of => (
    is  => 'rw',
    isa => sub {
        croak('custom_server_side_check_of should be code')
            unless ref $_[0] eq 'CODE';
    });

has onsubmit_js_error => (
    is      => 'rw',
    default => '',
);

########################################################################
# Usage      : $form_validation_obj->set_input_fields(\%input);
# Purpose    : Set input fields value based on last submit form.
# Returns    : none
# Parameters : \%input: HASH ref to %input
# Comments   : Public
#              NOTE: This subroutine can use only if fields have same
#              name and id.
#              (i.e. <input id="name" name="name" type="text" />)
# See Also   : n / a
########################################################################
sub set_input_fields {
    my $self  = shift;
    my $input = shift;

    for my $element_id (keys %{$input}) {
        if ($element_id eq 'csrftoken') {
            $self->{__input_csrftoken} = $input->{$element_id};
        } else {
            $self->set_field_value($element_id, $input->{$element_id});
        }
    }
    return;
}

sub build {
    my $self                 = shift;
    my $print_fieldset_index = shift;

    my $javascript_validation = '';

    # build the fieldset, if $print_fieldset_index is specifed then we only generate that praticular fieldset with that index
    my @fieldsets;
    if (defined $print_fieldset_index) {
        push @fieldsets, $self->{'fieldsets'}->[$print_fieldset_index];
    } else {
        @fieldsets = @{$self->{'fieldsets'}};
    }

    # build the form fieldset
    foreach my $fieldset (@fieldsets) {
        foreach my $input_field (@{$fieldset->{'fields'}}) {

            # build inputs javascript validation
            my $validation = $self->_build_javascript_validation({'input_field' => $input_field})
                || '';
            $javascript_validation .= $validation;
        }
    }

    my $onsubmit_js_error = $self->onsubmit_js_error;
    if ($onsubmit_js_error) {
        $onsubmit_js_error = "if (bResult == false) { $onsubmit_js_error; }";
    }
    $self->{data}{'onsubmit'} = "return (function () { var bResult = true; $javascript_validation; $onsubmit_js_error return bResult; })();";

    return $self->SUPER::build();
}

########################################################################
# Usage      : $form_validation_obj->validate();
# Purpose    : Validate form input
# Returns    : true (No ERROR) / false
# Parameters : none
# Comments   : Public
# See Also   : n / a
########################################################################
sub validate {
    my $self = shift;

    if ($self->csrftoken) {
        $self->validate_csrf() or return 0;
    }

    my @fieldsets = @{$self->{'fieldsets'}};
    foreach my $fieldset (@fieldsets) {
        INPUT_FIELD:
        foreach my $input_field (@{$fieldset->{'fields'}}) {
            my $data = $input_field->{data};
            if ($data->{'input'} and $data->{'error'}->{'id'}) {
                foreach my $input_element (@{$data->{'input'}}) {
                    if (eval { $input_element->{'input'}->can('value') }
                        and (not defined $self->get_field_value($input_element->{'id'})))
                    {
                        $self->set_field_error_message($input_element->{'id'}, $self->_localize('Invalid amount'));
                        next INPUT_FIELD;
                    }
                }
            }

            # Validate each field
            if (    defined $data->{'validation'}
                and $data->{'input'}
                and $data->{'error'}->{'id'})
            {
                $self->_validate_field({
                    'validation'    => $data->{'validation'},
                    'input_element' => $data->{'input'},
                });
            }
        }
    }

    if ($self->custom_server_side_check_of) {
        $self->custom_server_side_check_of->();
    }

    return ($self->get_has_error) ? 0 : 1;
}

sub validate_csrf {
    my ($self) = @_;

    if (($self->{__input_csrftoken} // '') eq $self->csrftoken) {
        return 1;
    }

    $self->_set_has_error();
    return 0;
}

sub is_error_found_in {
    my $self             = shift;
    my $input_element_id = shift;

    return $self->get_field_error_message($input_element_id);
}

########################################################################
# Usage      : $self->_set_has_error();
# Purpose    : Set has error to indicate form has error and should be
#              rebuild again.
# Returns    : none
# Parameters : none
# Comments   : Private
# See Also   : n / a
########################################################################
sub _set_has_error {
    my $self = shift;

    $self->has_error_of(1);
    return;
}

########################################################################
# Usage      : $form_validation_obj->get_has_error();
# Purpose    : Check if form has error
# Returns    : 0 / 1
# Parameters : none
# Comments   : Public
# See Also   : n / a
########################################################################
sub get_has_error {
    my $self = shift;
    return $self->has_error_of;
}

sub set_field_error_message {
    my $self          = shift;
    my $element_id    = shift;
    my $error_message = shift;

    $self->SUPER::set_field_error_message($element_id, $error_message);
    if ($error_message) {
        $self->_set_has_error();
    }
    return;
}

########################################################################
# Usage      : $self->_build_javascript_validation
#              ({
#                 'validation'       => $input_field->{'validation'},
#                 'input_element'    => $input_field->{'input'},
#                 'error_element_id' => $input_field->{'error'}->{'id'},
#              });
# Purpose    : Create javascript validation code.
# Returns    : text (Javascript code)
# Parameters : $arg_ref:
#              {
#                'validation': ARRAY ref to $input_field->{'validation'}
#                'input_element': HASH ref to input element
#                'error_element_id': error element id
#              }
# Comments   : Private
# See Also   : build()
########################################################################
sub _build_javascript_validation {
    my $self    = shift;
    my $arg_ref = shift;
    my $javascript;

    my $input_field = $arg_ref->{'input_field'};

    my $data = $input_field->{data};
    if (    defined $data->{'validation'}
        and $data->{'input'}
        and $data->{'error'}->{'id'})
    {

        my @validations      = @{$data->{'validation'}};
        my $input_element    = $data->{'input'};
        my $error_element_id = $data->{'error'}->{'id'};

        my $input_element_id;
        my $input_element_conditions;

        foreach my $input_field (@{$input_element}) {
            if (defined $input_field->{'id'}) {
                $input_element_id = $input_field->{'id'};
                $javascript               .= "var input_element_$input_element_id = document.getElementById('$input_element_id');";
                $input_element_conditions .= "input_element_$input_element_id && ";
            }
        }

        $javascript .=
              "var error_element_$error_element_id = document.getElementById('$error_element_id');"
            . "document.getElementById('$error_element_id').innerHTML = '';"
            . "if ($input_element_conditions error_element_$error_element_id) {"
            . 'var regexp;'
            . 'var bInputResult = true;';

        foreach my $validation (@validations) {
            next
                unless ($validation->{'type'} =~ /(?:regexp|min_amount|max_amount|checkbox_checked|custom)/);
            $javascript .= $self->_build_single_javascript_validation($validation, $input_element_id, $error_element_id);
        }

        $javascript .= 'if (!bInputResult)' . '{' . 'bResult = bInputResult;' . '}' . '}';

    }

    # get the general error field (contain only error message without input)
    elsif ( defined $data->{'error'}
        and defined $data->{'error'}->{'id'})
    {
        my $error_id = $data->{'error'}->{'id'};

        $javascript = "var error_element_$error_id = document.getElementById('$error_id');" . "document.getElementById('$error_id').innerHTML = '';";
    }

    return $javascript;
}

########################################################################
# Usage      : $self->_build_single_validation
#              ($validation, $input_element_id, $error_element_id);
# Purpose    : Create javascript validation code for a validation.
# Returns    : text (Javascript code)
# Parameters : validation, input_element_id, error_element_id
# Comments   : Private
# See Also   : build()
########################################################################
sub _build_single_javascript_validation {
    my $self             = shift;
    my $validation       = shift;
    my $input_element_id = shift;
    my $error_element_id = shift;

    my $javascript = '';
    my $err_msg    = _encode_text($validation->{'err_msg'});

    # if the id define in the validation hash, meaning input has more than 1 fields, the validation is validated against the id
    if ($validation->{'id'} and length $validation->{'id'} > 0) {
        $input_element_id = $validation->{'id'};
    }

    my $error_if_true = $validation->{error_if_true} ? '' : '!';
    my $test = '';
    if ($validation->{'type'} eq 'regexp') {
        my $regexp = $validation->{'regexp'};
        $regexp =~ s/(\\|')/\\$1/g;
        $javascript .=
            ($validation->{'case_insensitive'})
            ? "regexp = new RegExp('$regexp', 'i');"
            : "regexp = new RegExp('$regexp');";

        $test = qq[${error_if_true}regexp.test(input_element_$input_element_id.value)];
    }

    # Min Max amount checking
    elsif ($validation->{'type'} =~ /^(min|max)_amount$/) {
        my $op = $1 eq 'min' ? '<' : '>';
        $test = qq[input_element_$input_element_id.value $op $validation->{amount}];
    }

    # checkbox checked checking
    elsif ($validation->{'type'} eq 'checkbox_checked') {
        $test = qq[input_element_$input_element_id.checked === false];
    }

    # Custom checking
    elsif ($validation->{'type'} eq 'custom') {
        $test = qq[${error_if_true}$validation->{function}];
    }
    $javascript .= qq[if (bInputResult && $test){error_element_$error_element_id.innerHTML = decodeURIComponent('$err_msg');bInputResult = false;}];

    return $javascript;
}

########################################################################
# Usage      : $form_validation_obj->set_server_side_checks($custom_server_side_sub_ref);
# Purpose    : Set custom server side validation
# Returns    : none
# Parameters : $server_side_check_sub_ref: sub ref
# Comments   : Public
# See Also   : n / a
########################################################################
sub set_server_side_checks {
    my $self                      = shift;
    my $server_side_check_sub_ref = shift;
    $self->custom_server_side_check_of($server_side_check_sub_ref);
    return;
}

########################################################################
# Usage      : $self->_validate_field({
#                'validation'    => $input_field->{'validation'},
#                'input_element' => $input_field->{'input'},
#              });
# Purpose    : Server side validation base on type of validation
# Returns    : none
# Parameters : $arg_ref:
#              {
#                'validation': ARRAY ref to $input_field->{'validation'}
#                'input_element': HASH ref to input element
#              }
# Comments   : Private
# See Also   : validate()
########################################################################
sub _validate_field {
    my $self    = shift;
    my $arg_ref = shift;

    my @validations   = @{$arg_ref->{'validation'}};
    my $input_element = $arg_ref->{'input_element'};
    my $input_element_id;
    my $field_value;

    foreach my $validation (@validations) {
        if (    $validation->{'type'}
            and $validation->{'type'} =~ /(?:regexp|min_amount|max_amount|checkbox_checked)/)
        {

            # The input_element must be an array. so if validation no 'id', then we use the first element's id
            # because the array should be just one element.
            $input_element_id = $validation->{id} || $input_element->[0]{id};

            # Check with whitespace trimmed from both ends to make sure that it's reasonable.
            $field_value = $self->get_field_value($input_element_id) || '';
            # $field_value =~ s/^\s+|\s+$//g;
            $field_value =~ s/\A\s+//;
            $field_value =~ s/\s+\z//;

            if ($validation->{'type'} eq 'regexp') {
                my $regexp =
                    ($validation->{'case_insensitive'})
                    ? qr{$validation->{'regexp'}}i
                    : qr{$validation->{'regexp'}};
                if ($validation->{error_if_true} && $field_value =~ $regexp
                    || !$validation->{error_if_true} && $field_value !~ $regexp)
                {
                    $self->set_field_error_message($input_element_id, $validation->{'err_msg'});
                    return 0;
                }
            }

            # Min amount checking
            elsif ($validation->{'type'} eq 'min_amount' && $field_value < $validation->{'amount'}
                || $validation->{'type'} eq 'max_amount' && $field_value > $validation->{'amount'})
            {
                $self->set_field_error_message($input_element_id, $validation->{'err_msg'});
                return 0;
            }

            elsif ($validation->{'type'} eq 'checkbox_checked' && !$field_value) {
                $self->set_field_error_message($input_element_id, $validation->{'err_msg'});
                return 0;
            }
        }
    }
    return 1;
}

sub _encode_text {
    my $text = shift;

    return unless ($text);

    # javascript cant load html entities
    $text = Encode::encode("UTF-8", HTML::Entities::decode_entities($text));
    $text = URI::Escape::uri_escape($text);
    $text =~ s/(['"\\])/\\$1/g;

    return $text;
}

1;

=head1 NAME

HTML::FormBuilder::Validation - An extension of the Form object, to allow for javascript-side validation of inputs
and also server-side validation after the form is POSTed

=head1 SYNOPSIS

First, create the Form object. The keys in the HASH reference is the attributes
of the form.

    # Form attributes require to create new form object
    my $form_attributes =
    {
        'name'     => 'name_test_form',
        'id'       => 'id_test_form',
        'method'   => 'post',
        'action'   => "http://www.domain.com/contact.cgi",
        'class'    => 'formObject',
    };
    my $form_obj = new HTML::FormBuilder::Validation(data => $form_attributes);

    my $fieldset = $form_obj->add_fieldset({});


=head2 Create the input fields with validation

This is quite similar to creating input field in Form object. Likewise you can
add validation to HASH reference as the attribute of input field.

Below you can see the sample included four types of validation:

1. regexp: Just write the reqular expression that should be apply to the value

2. min_amount: Needs both type=min_amount and also minimum amount that declared
in amount

3. max_amount: Just like min_amount

4. checkbox_checked: Ensure checkbox is checked by user

5. custom: Just the javascript function call with parameters should be given to.
It only specifies client side validation.

    my $input_field_amount =
    {
        'label' =>
        {
            'text'     => 'Amount',
            'for'      => 'amount',
            'optional' => '0',
        },
        'input' =>
        {
            'type'      => 'text',
            'id'        => 'amount',
            'name'      => 'amount',
            'maxlength' => 40,
            'value'     => '',
        },
        'error' =>
        {
            'text' => '',
            'id'    => 'error_amount',
            'class' => 'errorfield',
        },
        'validation' =>
        [
            {
                'type'    => 'regexp',
                'regexp'  => '\w+',
                'err_msg' => 'Not empty',
            },
            {
                'type'    => 'regexp',
                'regexp'  => '\d+',
                'err_msg' => 'Must be digit',
            },
            {
                'type'    => 'min_amount',
                'amount'  => 50,
                'err_msg' => 'Too little',
            },
            {
                'type'    => 'max_amount',
                'amount'  => 500,
                'err_msg' => 'Too much',
            },
            {
                'type' => 'custom',
                'function' => 'custom_amount_validation()',
                'err_msg' => 'It is not good',
            },
        ],
    };

    my $terms_and_condition_checkbox =
    {
        'label' =>
        {
            'text'     => 'I have read & agree to the terms & condition of the site',
            'for'      => 'tnc',
        },
        'input' =>
        {
            'type'      => 'checkbox',
            'id'        => 'tnc',
            'name'      => 'tnc',
            'value'     => '1',             # optional
        },
        'error' =>
        {
            'id'    => 'error_tnc',
            'class' => 'errorfield',
        },
        'validation' =>
        [
            {
                'type'    => 'checkbox_checked',
                'err_msg' => 'In order to proceed, you need to agree to the terms & condition',
            },
        ],
    };

Below is another example with two different fields. In this matter we need to
indicate the id of each field in validation attributes.

    my $select_curr =
    {
        'id'      => 'select_text_curr',
        'name'    => 'select_text_curr',
        'type'    => 'select',
        'options' => '<option value=""></option><option value="USD">USD</option><option value="EUR">EUR</option>',
    };
    my $input_amount =
    {
        'id'    => 'select_text_amount',
        'name'  => 'select_text_amount',
        'type'  => 'text',
        'value' => ''
    };
    my $input_field_select_text =
    {
        'label' =>
        {
            'text'     => 'select_text',
            'for'      => 'select_text',
        },
        'input' => [ $select_curr, $input_amount ],
        'error' =>
        {
            'text'  => '',
            'id'    => 'error_select_text',
            'class' => 'errorfield',
        },
        'validation' =>
        [
            {
                'type' => 'regexp',
                'id'   => 'select_text_curr',
                'regexp'  => '\w+',
                'err_msg' => 'Must be select',
            },
            {
                'type' => 'regexp',
                'id'   => 'select_text_amount',
                'regexp'  => '\d+',
                'err_msg' => 'Must be digits',
            },
            {
                'type' => 'min_amount',
                'id'   => 'select_text_amount',
                'amount'  => 50,
                'err_msg' => 'Too little',
            },
        ],
    };

    my $general_error_field =
    {
        'error' =>
        {
            'text' => '',
            'id' => 'error_general',
            'class' => 'errorfield'
        },
    };

=head2 Adding input fields to form object

Here is just add fields to the form object like before.

    $form_obj->add_field($fieldset_index, $general_error_field);
    $form_obj->add_field($fieldset_index, $input_field_amount);
    $form_obj->add_field($fieldset_index, $input_field_select_text);

=head2 Define Javascript code to be run, during onsubmit input validation error

This javascript code will be run before onsubmit return false

    $form_obj->onsubmit_js_error("\$('#residence').attr('disabled', true);");
    $form_obj->onsubmit_js_error('onsubmit_error_disable_fields()');

=head2 Custom javascript validation

Custom javascript validation should be defined and assigned to the form object.
Note that, the name and parameters should be the same as the way you indicate
function call in validation attributes.

You can see a sample below:

    my $custom_javascript = qq~
        function custom_amount_validation()
        {
            var input_amount = document.getElementById('amount');
            if (input_amount.value == 100)
            {
                return false;
            }
            return true;
        }~;

=head2 Custom server side validation

The custom server side validation is quite similar to javascript. A reference to
a subrotine should be pass to form object.

    my $custom_server_side_sub_ref = sub {
        if ($form_obj->get_field_value('name') eq 'felix')
        {
            $form_obj->set_field_error_message('name', 'felix is not allow to use this page');
            $form_obj->set_field_error_message('error_general', 'There is an error !!!');
        }
    };

    $form_obj->set_server_side_checks($custom_server_side_sub_ref);

=head2 Use form object in cgi files

Somewhere in cgi files you can just print the result of build().

    print $form_obj->build();

In submit you need to fill form values, use set_input_fields(\%input) and pass
%input HASH and then show what ever you want in result of validation. Just like
below:

    if (not $form_obj->validate())
    {
        print '<h1>Test Form</h1>';
        print $form_obj->build();
    }
    else
    {
        print '<h1>Success !!!</h1>';
    }

    code_exit();

=head1 Attributes

=head2 has_error_of

The tag that error happened during validation

=head2 custom_server_side_check_of

The custom server side subroutine that will be run on server side.

=head2 onsubmit_js_error

javasript code to run during onsubmit error by javasript validation

=head1 METHODS

=head2 set_input_fields

    $form_validation_obj->set_input_fields({username => $username});

assign value to the input fields

=head2 validate

    $form_validation_obj->validate();

validate form input and return true or false

=head2 is_error_found_in

    $form_validation_obj->is_error_found_in($input_element_id);

check the erorr is founded in the input element or not

=head2 get_has_error

=head2 set_field_error_message

=head2 set_server_side_checks

=head2 validate_csrf

=head1 CROSS SITE REQUEST FORGERY PROTECTION

for plain CGI or other framework, read Dancer example below.

=head2 CSRF and Dancer

=over 4

=item * create form HTML and store csrftoken in session

    my $form = HTML::FormBuilder::Validation->new(data => $form_attributes, csrftoken => 1);
    ...
    my $html = $form->build;

    # save csrf token in session or cookie
    session(__csrftoken => $form->csrftoken);

=item * validate csrftoken on form submit

    my $csrftoken = session('__csrftoken');
    my $form = HTML::FormBuilder::Validation->new(data => $form_attributes, csrftoken => $csrftoken);
    $form->validate_csrf() or die 'CSRF failed.';
    # or call
    if ( $form->validate() ) { # it calls validate_csrf inside
        # Yap! it's ok
    } else {
        # NOTE we do not have error for csrf on form HTML build
        # show form again with $form->build
    }

=back

=head2 CSRF and Mojolicious

if you're using Mojolicious and have DefaultHelpers plugin enabled, it's simple to add csrftoken in Validation->new as below:

    my $form = HTML::FormBuilder::Validation->new(data => $form_attributes, csrftoken => $c->csrf_token);

Mojolicious $c->csrf_token will handle the session part for you.

=head1 AUTHOR

Chylli L<mailto:chylli@binary.com>

=head1 CONTRIBUTOR

Fayland Lam L<mailto:fayland@binary.com>

Tee Shuwn Yuan L<mailto:shuwnyuan@binary.com>

=head1 COPYRIGHT AND LICENSE

=cut
