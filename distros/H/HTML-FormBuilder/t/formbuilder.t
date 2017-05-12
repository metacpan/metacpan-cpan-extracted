#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";
use TestHelper;
use Test::More;
use Test::FailWarnings;
use Test::Exception;
use HTML::FormBuilder;
use HTML::FormBuilder::Select;

my $form_obj;

################################################################################
# test new
lives_ok(sub { $form_obj = HTML::FormBuilder->new(data => {id => 'form1'}) }, 'create form ok');
is($form_obj->{data}{method}, 'get', 'default method of form');
is_deeply($form_obj->{fieldsets}, [], 'default fieldset');
is($form_obj->build, '<form id="form1" method="get"></form>', 'generate a blank form');
lives_ok(sub { create_form_object()->build }, 'build ok');

my $result;
$form_obj = HTML::FormBuilder->new(
    data => {
        id => 'testid',
    },
    localize => sub { "will " . shift },
    classes  => $classes,

);
my $expect_result =
    '<form id="testid" method="get"><input type="hidden" name="process" value="1"/><a class="button backbutton" href="javascript:history.go(-1)" ><span class="button backbutton" >will Back</span></a> <span class="button"><button id="submit" class="button" type="submit">will Confirm</button></span></form>';
lives_ok(
    sub {
        $result = $form_obj->build_confirmation_button_with_all_inputs_hidden;
    },
    'build confirmation_button_with_all_inputs_hidden  ok'
);
is($result, $expect_result, 'the result of build confirmation_button_with_all_inputs_hidden with arg localize');

################################################################################
# test after_from

$form_obj = HTML::FormBuilder->new(
    data => {
        id => 'testid',
    });
$form_obj->after_form("<div>afterform</div>");
lives_ok(sub { $result = $form_obj->build }, 'build form with some args');
like($result, qr/<div>afterform<\/div>/, 'add afterform info');

################################################################################
# test required_mark

$form_obj = HTML::FormBuilder->new(
    data => {
        id => 'testid',
    });
my $fieldset = $form_obj->add_fieldset({});
$fieldset->add_field({
        label => {
            text          => "it is a label",
            required_mark => 1
        }});

lives_ok(sub { $result = $form_obj->build }, 'build form with some args');
like($result, qr/<em class="required_asterisk">\*\*<\/em>/, 'has em');

################################################################################
# test hide_mobile

$form_obj = HTML::FormBuilder->new(
    data => {
        id => 'testid',
    },
    classes => $classes,
);
$fieldset = $form_obj->add_fieldset({});
$fieldset->add_field({label => {}});

lives_ok(sub { $result = $form_obj->build }, 'build form with some args');
like($result,
    qr{<fieldset><div class="grd-row-padding row clear"><div class="grd-grid-4 grd-hide-mobile form_label"><label></label></div></div></fieldset>},
    'hide mobile');

################################################################################
# test fieldset_group
$form_obj = HTML::FormBuilder->new(
    data => {
        id => 'testid',
    },
    classes => $classes,
);
$fieldset = $form_obj->add_fieldset({group => 'fieldsetgroup'});
lives_ok(sub { $result = $form_obj->build }, 'build form with some args');
like($result, qr{<div id="fieldsetgroup" class="toggle-content">}, 'has fieldsetgroup');

################################################################################
# test class
$form_obj = HTML::FormBuilder->new(
    data => {
        id => 'testid',
    },
    classes => {test_class => 'test-class'},
);
is($form_obj->{classes}{'test_class'},  'test-class',  'test class method ok');
is($form_obj->{classes}{'row_padding'}, 'row_padding', 'test class method ok');

#is($form_obj->class('no_such_class'), '', 'test class method ok');

################################################################################
# test fieldset footer
$form_obj = HTML::FormBuilder->new(
    data => {
        id => 'testid',
    },
    classes => $classes,
);
$fieldset = $form_obj->add_fieldset({footer => 'this is footer of fieldset'});
lives_ok(sub { $result = $form_obj->build }, 'build form with some args');
like($result, qr{<div class="row comment">this is footer of fieldset</div></fieldset>}, 'has footer');

################################################################################
# test input trailling
$form_obj = HTML::FormBuilder->new(
    data => {
        id => 'testid',
    });
$fieldset = $form_obj->add_fieldset({});
$fieldset->add_field({input => {trailing => "This is trailling"}});
lives_ok(sub { $result = $form_obj->build }, 'build form with some args');
like($result, qr{<span class="inputtrailing">This is trailling</span>}, 'has footer');

################################################################################
# test add_fieldset
$form_obj = HTML::FormBuilder->new(data => {id => 'testid'});
$fieldset = $form_obj->add_fieldset({id => 'fieldset1'});
isa_ok($fieldset, 'HTML::FormBuilder::FieldSet', 'return a fieldset object');
is($fieldset->data->{id}, 'fieldset1', 'fieldset value is correct');
################################################################################
# test add_field
$form_obj = HTML::FormBuilder->new(data => {id => 'testid'});
throws_ok(sub { $form_obj->add_field('0abc') }, qr/fieldset_index should be a number/, 'fieldset_index should be a number');
throws_ok(sub { $form_obj->add_field(123) },    qr/fieldset does not exist/,           'fieldset should be exist');

{
    $form_obj = create_form_object();

    # Test set_field_value and get_field_value
    $form_obj->set_field_value('amount', 100);
    Test::More::is($form_obj->get_field_value('amount'), 100, 'Test accessor of fields of form object. [set_field_value, get_field_value]');

    # Test set_field_value and get_field_value [before select]
    Test::More::is($form_obj->get_field_value('gender'),
        'male', 'Test accessor of fields of form object [Select - male]. [set_field_value, get_field_value]');

    # Test set_field_value and get_field_value
    $form_obj->set_field_value('gender', 'female');
    Test::More::is($form_obj->get_field_value('gender'),
        'female', 'Test accessor of fields of form object [Select - female]. [set_field_value, get_field_value]');

    # Test set_field_value and get_field_value
    $form_obj->set_field_value('select_text_curr', 'EUR');
    Test::More::is($form_obj->get_field_value('select_text_curr'),
        'EUR', 'Test accessor of array fields of form object [Select - EUR]. [set_field_value, get_field_value]');

    # Test set_field_value and get_field_value
    Test::More::is($form_obj->get_field_value('select_text_amount'),
        20, 'Test accessor of array fields of form object [text - 20(default value)]. [set_field_value, get_field_value]');

    # Test set_field_value and get_field_value
    $form_obj->set_field_value('select_text_amount', 50);
    Test::More::is($form_obj->get_field_value('select_text_amount'),
        50, 'Test accessor of array fields of form object [text - 50]. [set_field_value, get_field_value]');

    # Test set_field_value and get_field_value
    Test::More::is(
        $form_obj->get_field_value('Textarea'),
        'This is default value of textarea',
        'Test accessor of fields of form object [textarea - \'This is default value of textarea\'(default value)]. [set_field_value, get_field_value]'
    );

    # Test set_field_value and get_field_value
    $form_obj->set_field_value('Textarea', 'It should be changed now...');
    Test::More::is(
        $form_obj->get_field_value('Textarea'),
        'It should be changed now...',
        'Test accessor of fields of form object [text - \'It should be changed now...\']. [set_field_value, get_field_value]'
    );

    # Test set_field_value and get_field_value
    Test::More::is($form_obj->get_field_value('Password'),
        'pa$$w0rd', 'Test accessor of fields of form object [password - pa$$w0rd(default value)]. [set_field_value, get_field_value]');

    # Test set_field_value and get_field_value
    $form_obj->set_field_value('Password', 'Baghali');
    Test::More::is($form_obj->get_field_value('Password'),
        'Baghali', 'Test accessor of fields of form object [password - Baghali]. [set_field_value, get_field_value]');

    # Test set_field_value and get_field_value
    Test::More::is($form_obj->get_field_value('single_checkbox'),
        undef, 'Test accessor of fields of form object [single_checkbox - (Not checked)]. [set_field_value, get_field_value]');

    # Test set_field_value and get_field_value
    $form_obj->set_field_value('single_checkbox', 'SGLBOX');
    Test::More::is($form_obj->get_field_value('single_checkbox'),
        'SGLBOX', 'Test accessor of fields of form object [single_checkbox - SGLBOX]. [set_field_value, get_field_value]');

    # Test set_field_value and get_field_value
    Test::More::is($form_obj->get_field_value('checkbox1'),
        undef, 'Test accessor of fields of form object [checkbox1 - (Not checked)]. [set_field_value, get_field_value]');
    Test::More::is($form_obj->get_field_value('checkbox2'),
        undef, 'Test accessor of fields of form object [checkbox2 - (Not checked)]. [set_field_value, get_field_value]');

    # Test set_field_value and get_field_value
    $form_obj->set_field_value('checkbox1', 'BOX1');
    $form_obj->set_field_value('checkbox2', 'BOX2');
    Test::More::is($form_obj->get_field_value('checkbox1'),
        'BOX1', 'Test accessor of fields of form object [checkbox1 - BOX1]. [set_field_value, get_field_value]');
    Test::More::is($form_obj->get_field_value('checkbox2'),
        'BOX2', 'Test accessor of fields of form object [checkbox2 - BOX2]. [set_field_value, get_field_value]');

    # Test set_field_error_message
    $form_obj->set_field_error_message('amount', 'It is not good');
    Test::More::is(
        $form_obj->get_field_error_message('amount'),
        'It is not good',
        'Test accessor of fields of form object. [set_field_error_message, get_field_error_message]'
    );

    # Test set_field_error_message
    $form_obj->set_field_error_message('error_general', 'There is a general error.');
    Test::More::is(
        $form_obj->get_field_error_message('error_general'),
        'There is a general error.',
        'Test accessor of general error of form object . [set_field_error_message, get_field_error_message]'
    );

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
    Test::Exception::lives_ok {
        $form_obj = HTML::FormBuilder->new(
            data    => $form_attributes,
            classes => $classes
        );
    }
    'Create Form';

    # Test object type
    Test::More::isa_ok($form_obj, 'HTML::FormBuilder');

    my $fieldset = $form_obj->add_fieldset({});

    my $input_field_amount = {
        'label' => {
            'text' => 'Amount',
            'for'  => 'amount',
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

    my $input_field_gender = {
        'label' => {
            'text' => 'gender',
            'for'  => 'gender',
        },
        'input' => HTML::FormBuilder::Select->new(
            'id'      => 'gender',
            'name'    => 'gender',
            'options' => [{value => 'male'}, {value => 'female'}],
            'values'  => ['male'],
        ),
        'error' => {
            'text'  => '',
            'id'    => 'error_gender',
            'class' => 'errorfield',
        },
    };

    my $select_curr = HTML::FormBuilder::Select->new(
        'id'      => 'select_text_curr',
        'name'    => 'select_text_curr',
        'options' => [{value => 'USD'}, {value => "EUR"}],
    );
    my $input_amount = {
        'id'    => 'select_text_amount',
        'name'  => 'select_text_amount',
        'type'  => 'text',
        'value' => '20'
    };
    my $input_field_select_text = {
        'label' => {
            'text' => 'select_text',
            'for'  => 'select_text',
        },
        'input' => [$select_curr, $input_amount],
        'error' => {
            'text'  => '',
            'id'    => 'error_select_text',
            'class' => 'errorfield',
        },
    };

    my $input_field_textarea = {
        'label' => {
            'text' => 'Textarea',
            'for'  => 'Textarea',
        },
        'input' => {
            'type'  => 'textarea',
            'id'    => 'Textarea',
            'name'  => 'Textarea',
            'value' => 'This is default value of textarea',
        },
        'error' => {
            'text'  => '',
            'id'    => 'error_Textarea',
            'class' => 'errorfield',
        },
    };

    my $input_field_password = {
        'label' => {
            'text' => 'Password',
            'for'  => 'Password',
        },
        'input' => {
            'type'  => 'password',
            'id'    => 'Password',
            'name'  => 'Password',
            'value' => 'pa$$w0rd',
        },
        'error' => {
            'text'  => '',
            'id'    => 'error_Password',
            'class' => 'errorfield',
        },
    };

    my $input_field_single_checkbox = {
        'label' => {
            'text' => 'Single Checkbox',
            'for'  => 'single_checkbox',
        },
        'input' => {
            'type'  => 'checkbox',
            'id'    => 'single_checkbox',
            'name'  => 'single_checkbox',
            'value' => 'SGLBOX',
        },
    };

    my $input_field_array_checkbox = {
        'label' => {
            'text' => 'Single Checkbox',
            'for'  => 'single_checkbox',
        },
        'input' => [{
                'type'  => 'checkbox',
                'id'    => 'checkbox1',
                'name'  => 'checkbox1',
                'value' => 'BOX1',
            },
            {
                'type'  => 'checkbox',
                'id'    => 'checkbox2',
                'name'  => 'checkbox2',
                'value' => 'BOX2',
            },
        ],
    };

    my $general_error_message_field = {
        'error' => {
            'text'  => '',
            'id'    => 'error_general',
            'class' => 'errorfield',
        },
    };

    $fieldset->add_field($input_field_amount);
    $fieldset->add_field($input_field_gender);
    $fieldset->add_field($input_field_select_text);
    $fieldset->add_field($input_field_textarea);
    $fieldset->add_field($input_field_password);
    $fieldset->add_field($input_field_single_checkbox);
    $fieldset->add_field($input_field_array_checkbox);
    $fieldset->add_field($general_error_message_field);

    return $form_obj;
}

sub check_existance_on_builded_html {
    my $arg_ref = shift;

    my $form_object = $arg_ref->{'form_obj'};
    my $reg_exp     = $arg_ref->{'reg_exp'};

    return $form_object->build() =~ /$reg_exp/;

}

$expect_result = <<'EOF';
<form action="http://localhost/some/where/test.cgi" class="formObject" id="id_test_form" method="post" name="name_test_form"><div class="rbox form">
    <div class="rbox-wrap">
        <fieldset><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="amount">Amount</label></div><div class="grd-grid-8"><input class=" text" id="amount" maxlength="40" name="amount" type="text"><p class="errorfield" id="error_amount"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="gender">gender</label></div><div class="grd-grid-8"><select id="gender" name="gender"><option value="male" SELECTED >male</option><option value="female" >female</option></select><p class="errorfield" id="error_gender"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="select_text">select_text</label></div><div class="grd-grid-8"><select id="select_text_curr" name="select_text_curr"><option value="USD" >USD</option><option value="EUR" >EUR</option></select><input class=" text" id="select_text_amount" name="select_text_amount" type="text" value="20"><p class="errorfield" id="error_select_text"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="Textarea">Textarea</label></div><div class="grd-grid-8"><textarea id="Textarea" name="Textarea">This is default value of textarea</textarea><p class="errorfield" id="error_Textarea"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="Password">Password</label></div><div class="grd-grid-8"><input class=" text" id="Password" name="Password" type="password" value="pa$$w0rd"><p class="errorfield" id="error_Password"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="single_checkbox">Single Checkbox</label></div><div class="grd-grid-8"><input id="single_checkbox" name="single_checkbox" type="checkbox" value="SGLBOX"></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="single_checkbox">Single Checkbox</label></div><div class="grd-grid-8"><input id="checkbox1" name="checkbox1" type="checkbox" value="BOX1"><input id="checkbox2" name="checkbox2" type="checkbox" value="BOX2"></div></div><div class="grd-row-padding row clear"><p class="errorfield" id="error_general"></p></div></fieldset>
        <span class="tl">&nbsp;</span><span class="tr">&nbsp;</span><span class="bl">&nbsp;</span><span class="br">&nbsp;</span>
    </div>
</div>
</form>
EOF
chomp($expect_result);
is(create_form_object()->build(), $expect_result, ' the result is right');

done_testing;

