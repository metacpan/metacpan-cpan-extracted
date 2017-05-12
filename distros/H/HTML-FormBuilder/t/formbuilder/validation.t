#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use TestHelper;
use Test::More;
use Test::FailWarnings;
use Test::Exception;
use HTML::FormBuilder::Validation;
use HTML::FormBuilder::Select;

my $form_obj = create_form_object();

set_valid_input(\$form_obj);
is($form_obj->validate(),      1, '[validate=1]');
is($form_obj->get_has_error(), 0, '[get_has_error=0]');

is($form_obj->get_field_value('amount'),           123,   'amount=123');
is($form_obj->get_field_value('select_text_curr'), 'USD', 'select_text_curr=USD');
is($form_obj->get_field_value('w'),                'CR',  'w=CR');                   # test hidden value
is($form_obj->get_field_value('tnc'),              '1',   'tnc=1');                  # test checkbox value

set_valid_input(\$form_obj);
$form_obj->set_field_value('amount', 5);
is($form_obj->validate(),                        0,            'validate=0');
is($form_obj->get_has_error(),                   1,            'get_has_error=1');
is($form_obj->get_field_error_message('amount'), 'Too little', 'error message=Too little');

set_valid_input(\$form_obj);
$form_obj->set_field_value('amount', 501);
is($form_obj->validate(),                        0,          'validate=0');
is($form_obj->get_field_error_message('amount'), 'Too much', 'error message=Too much');

set_valid_input(\$form_obj);
$form_obj->set_field_value('amount', 'abc');
is($form_obj->validate(), 0, 'validate=0');
is($form_obj->get_field_error_message('amount'), 'Must be digit', 'error message=Must be digit');

set_valid_input(\$form_obj);
$form_obj->set_field_value('select_text_curr', '');
is($form_obj->validate(), 0, 'validate=0');
is($form_obj->get_field_error_message('select_text_curr'), 'Must be select', 'error message=Must be select');

set_valid_input(\$form_obj);
$form_obj->set_field_value('select_text_curr',   'USD');
$form_obj->set_field_value('select_text_amount', 'abc');
is($form_obj->validate(), 0, 'validate=0');
is($form_obj->get_field_error_message('select_text_amount'), 'Must be digits', 'error message=Must be digits');

set_valid_input(\$form_obj);
$form_obj->set_field_value('select_text_amount', '5');
is($form_obj->validate(),                                    0,            'validate=0');
is($form_obj->get_field_error_message('select_text_amount'), 'Too little', 'error message=Too little');

# Test on set_input_fields
my $input = {
    'name'               => 'Eric',
    'amount'             => '123',
    'select_text_curr'   => 'EUR',
    'select_text_amount' => '888',
    'submit'             => 'Submit',
    'test'               => '1',
};

$form_obj->set_input_fields($input);
is($form_obj->get_field_value('name'),               'Eric', 'name = Eric');
is($form_obj->get_field_value('amount'),             '123',  'amount = 123');
is($form_obj->get_field_value('select_text_curr'),   'EUR',  'select_text_curr = EUR');
is($form_obj->get_field_value('select_text_amount'), '888',  'select_text_amount = 888');
is($form_obj->get_field_value('test'),               undef,  'test = undef [not in form])');

$form_obj = create_form_object();

set_valid_input(\$form_obj);

my $expected_result = <<EOF;
<form action="http://localhost/some/where/test.cgi" class="formObject" id="id_test_form" method="post" name="name_test_form" onsubmit="return (function () { var bResult = true; var error_element_error_general = document.getElementById('error_general');document.getElementById('error_general').innerHTML = '';var input_element_name = document.getElementById('name');var error_element_error_name = document.getElementById('error_name');document.getElementById('error_name').innerHTML = '';if (input_element_name &&  error_element_error_name) {var regexp;var bInputResult = true;regexp = new RegExp('[a-z]+', 'i');if (bInputResult && !regexp.test(input_element_name.value)){error_element_error_name.innerHTML = decodeURIComponent('Not%20empty');bInputResult = false;}if (!bInputResult){bResult = bInputResult;}}var input_element_amount = document.getElementById('amount');var error_element_error_amount = document.getElementById('error_amount');document.getElementById('error_amount').innerHTML = '';if (input_element_amount &&  error_element_error_amount) {var regexp;var bInputResult = true;regexp = new RegExp('\\\\w+');if (bInputResult && !regexp.test(input_element_amount.value)){error_element_error_amount.innerHTML = decodeURIComponent('Not%20empty');bInputResult = false;}regexp = new RegExp('\\\\d+');if (bInputResult && !regexp.test(input_element_amount.value)){error_element_error_amount.innerHTML = decodeURIComponent('Must%20be%20digit');bInputResult = false;}if (bInputResult && input_element_amount.value < 50){error_element_error_amount.innerHTML = decodeURIComponent('Too%20little');bInputResult = false;}if (bInputResult && input_element_amount.value > 500){error_element_error_amount.innerHTML = decodeURIComponent('Too%20much');bInputResult = false;}if (bInputResult && !custom_amount_validation()){error_element_error_amount.innerHTML = decodeURIComponent('It%20is%20not%20good');bInputResult = false;}if (!bInputResult){bResult = bInputResult;}}var input_element_select_text_curr = document.getElementById('select_text_curr');var input_element_select_text_amount = document.getElementById('select_text_amount');var error_element_error_select_text = document.getElementById('error_select_text');document.getElementById('error_select_text').innerHTML = '';if (input_element_select_text_curr && input_element_select_text_amount &&  error_element_error_select_text) {var regexp;var bInputResult = true;regexp = new RegExp('\\\\w+');if (bInputResult && !regexp.test(input_element_select_text_curr.value)){error_element_error_select_text.innerHTML = decodeURIComponent('Must%20be%20select');bInputResult = false;}regexp = new RegExp('\\\\d+');if (bInputResult && !regexp.test(input_element_select_text_amount.value)){error_element_error_select_text.innerHTML = decodeURIComponent('Must%20be%20digits');bInputResult = false;}if (bInputResult && input_element_select_text_amount.value < 50){error_element_error_select_text.innerHTML = decodeURIComponent('Too%20little');bInputResult = false;}if (!bInputResult){bResult = bInputResult;}}var input_element_tnc = document.getElementById('tnc');var error_element_error_tnc = document.getElementById('error_tnc');document.getElementById('error_tnc').innerHTML = '';if (input_element_tnc &&  error_element_error_tnc) {var regexp;var bInputResult = true;if (bInputResult && input_element_tnc.checked === false){error_element_error_tnc.innerHTML = decodeURIComponent('In%20order%20to%20proceed%2C%20please%20agree%20to%20the%20terms%20%26%20condition');bInputResult = false;}if (!bInputResult){bResult = bInputResult;}}; if (bResult == false) { \$('#residence').attr('disabled', true); } return bResult; })();"><div class="rbox form">
    <div class="rbox-wrap">
        <fieldset><div class="grd-row-padding row clear"><p class="errorfield" id="error_general"></p></div><div class="grd-row-padding row clear"><div class="grd-grid-8"><input id="w" name="w" type="hidden" value="CR"></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="name">Name</label></div><div class="grd-grid-8"><input class=" text" id="name" maxlength="40" name="name" type="text" value="Omid"><p class="errorfield" id="error_name"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="amount">Amount</label></div><div class="grd-grid-8"><input class=" text" id="amount" maxlength="40" name="amount" type="text" value="123"><p class="errorfield" id="error_amount"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="select_text">select_text</label></div><div class="grd-grid-8"><select id="select_text_curr" name="select_text_curr"><option value="" ></option><option value="USD" SELECTED >USD</option><option value="EUR" >EUR</option></select><input class=" text" id="select_text_amount" name="select_text_amount" type="text" value="50"><p class="errorfield" id="error_select_text"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="tnc">I have read & agree to the terms & condition.</label></div><div class="grd-grid-8"><input checked="checked" id="tnc" name="tnc" type="checkbox" value="1"><p class="errorfield" id="error_tnc"></p></div></div></fieldset>
        <span class="tl">&nbsp;</span><span class="tr">&nbsp;</span><span class="bl">&nbsp;</span><span class="br">&nbsp;</span>
    </div>
</div>
</form>
EOF

chomp($expected_result);
is($form_obj->build, $expected_result, 'the result of build');
$form_obj = create_form_object();
lives_ok(sub { $form_obj->validate }, 'validate has no warnings');

sub set_valid_input {
    my $arg_ref = shift;

    ${$arg_ref}->set_field_value('name',               'Omid');
    ${$arg_ref}->set_field_value('amount',             '123');
    ${$arg_ref}->set_field_value('select_text_curr',   'USD');
    ${$arg_ref}->set_field_value('select_text_amount', '50');
    ${$arg_ref}->set_field_value('tnc',                1);
}

sub check_existance_on_builded_html {
    my $arg_ref = shift;

    my $form_object = $arg_ref->{'form_obj'};
    my $reg_exp     = $arg_ref->{'reg_exp'};

    return $form_object->build() =~ /$reg_exp/;

}

sub create_form_object {
    my $form_obj;

    # Form attributes require to create new form object
    my $form_attributes = {
        'name'   => 'name_test_form',
        'id'     => 'id_test_form',
        'method' => 'post',
        'action' => 'http://localhost/some/where/test.cgi',
        'class'  => 'formObject',
    };

    # Create new form object
    lives_ok {
        $form_obj = HTML::FormBuilder::Validation->new(
            data    => $form_attributes,
            classes => $classes
        );
    }
    'Create Form Validation';

    # Test object type
    isa_ok($form_obj, 'HTML::FormBuilder::Validation');

    my $fieldset = $form_obj->add_fieldset({});

    my $input_field_name = {
        'label' => {
            'text'     => 'Name',
            'for'      => 'name',
            'optional' => '0',
        },
        'input' => {
            'type'      => 'text',
            'id'        => 'name',
            'name'      => 'name',
            'maxlength' => 40,
            'value'     => '',
        },
        'error' => {
            'text'  => '',
            'id'    => 'error_name',
            'class' => 'errorfield',
        },
        'validation' => [{
                'type'             => 'regexp',
                'regexp'           => '[a-z]+',
                'case_insensitive' => 1,
                'err_msg'          => 'Not empty',
            },
        ],
    };

    my $input_field_amount = {
        'label' => {
            'text'     => 'Amount',
            'for'      => 'amount',
            'optional' => '0',
        },
        'input' => {
            'type'      => 'text',
            'id'        => 'amount',
            'name'      => 'amount',
            'maxlength' => 40,
            'value'     => '',
        },
        'error' => {
            'text'  => '',
            'id'    => 'error_amount',
            'class' => 'errorfield',
        },
        'validation' => [{
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
                'type'     => 'custom',
                'function' => 'custom_amount_validation()',
                'err_msg'  => 'It is not good',
            }
        ],
    };

    my $select_curr = HTML::FormBuilder::Select->new(
        'id'      => 'select_text_curr',
        'name'    => 'select_text_curr',
        'type'    => 'select',
        'options' => [{value => ''}, {value => 'USD'}, {value => 'EUR'}],
    );
    my $input_amount = {
        'id'    => 'select_text_amount',
        'name'  => 'select_text_amount',
        'type'  => 'text',
        'value' => ''
    };
    my $input_field_select_text = {
        'label' => {
            'text'     => 'select_text',
            'for'      => 'select_text',
            'optional' => '0',
        },
        'input' => [$select_curr, $input_amount],
        'error' => {
            'text'  => '',
            'id'    => 'error_select_text',
            'class' => 'errorfield',
        },
        'validation' => [{
                'type'    => 'regexp',
                'id'      => 'select_text_curr',
                'regexp'  => '\w+',
                'err_msg' => 'Must be select',
            },
            {
                'type'    => 'regexp',
                'id'      => 'select_text_amount',
                'regexp'  => '\d+',
                'err_msg' => 'Must be digits',
            },
            {
                'type'    => 'min_amount',
                'id'      => 'select_text_amount',
                'amount'  => 50,
                'err_msg' => 'Too little',
            },
        ],
    };
    my $checkbox_tnc = {
        'label' => {
            'text' => 'I have read & agree to the terms & condition.',
            'for'  => 'tnc',
        },
        'input' => {
            'type'  => 'checkbox',
            'id'    => 'tnc',
            'name'  => 'tnc',
            'value' => 1,
        },
        'error' => {
            'id'    => 'error_tnc',
            'class' => 'errorfield',
        },
        'validation' => [{
                'type'    => 'checkbox_checked',
                'err_msg' => 'In order to proceed, please agree to the terms & condition',
            }
        ],
    };

    $fieldset->add_field({
            'error' => {
                'id'    => 'error_general',
                'class' => 'errorfield',
            },
        });

    # Hidden fields
    my $input_hidden_field_broker = {
        'id'    => 'w',
        'name'  => 'w',
        'type'  => 'hidden',
        'value' => 'CR'
    };

    my $hidden_fields = {'input' => [$input_hidden_field_broker,]};
    $fieldset->add_field($hidden_fields);
    $fieldset->add_field($input_field_name);
    $fieldset->add_field($input_field_amount);
    $fieldset->add_field($input_field_select_text);
    $fieldset->add_field($checkbox_tnc);

    $form_obj->onsubmit_js_error("\$('#residence').attr('disabled', true)");

    return $form_obj;
}

done_testing;

