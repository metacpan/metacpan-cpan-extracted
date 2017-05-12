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

my ($form_obj, $result, $expect_result);

$form_obj = HTML::FormBuilder->new(
    data    => {id => 'testid'},
    classes => $classes
);
my $fieldset = $form_obj->add_fieldset({
    legend  => 'a legend',
    header  => 'header',
    comment => 'comment'
});

my $input_field_amount = {
    'label' => {
        'text'    => 'Amount',
        'for'     => 'amount',
        'tooltip' => {
            desc    => "this is a tool tip",
            img_url => "test.png"
        },
        'required_mark' => 1,
    },
    'input' => {
        'heading'   => 'heading',
        'type'      => 'text',
        'id'        => 'amount',
        'name'      => 'amount',
        'maxlength' => 40,
        'value'     => '',
    },
    'comment' => {text  => 'commenttext'},
    'error'   => [{text => 'errortext'}],
};

my $input_field_button = {
    'input' => {
        'type'  => 'button',
        'id'    => 'Button',
        'name'  => 'Button name',
        'value' => 'button value',
    },
};

$fieldset->add_field($input_field_amount);
$fieldset->add_field($input_field_button);

lives_ok(sub { $result = $form_obj->build }, 'build tooltip ok');
$expect_result = <<EOF;
<form id="testid" method="get"><div class="rbox form">
    <div class="rbox-wrap">
        <fieldset><legend>a legend</legend><h2>header</h2><div class="grd-grid-12"><p>comment</p></div><div class="grd-row-padding row clear"><div class="extra_tooltip_container"><label for="amount"><em class="required_asterisk">**</em>Amount</label> <a href='#' title='this is a tool tip' rel='tooltip'><img src="test.png" /></a></div><div class="grd-grid-8"><span id="inputheading">heading</span><input class=" text" id="amount" maxlength="40" name="amount" type="text"><br><p>commenttext</p><p>errortext</p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-8"><span class=" button"><button class=" button" id="Button" name="Button name" type="button" value="button value">button value</button></button></span></div></div></fieldset>
        <span class="tl">&nbsp;</span><span class="tr">&nbsp;</span><span class="bl">&nbsp;</span><span class="br">&nbsp;</span>
    </div>
</div>
</form>
EOF
chomp $expect_result;
is($result, $expect_result, 'tooltip and call_customer_support');

# test heading
$form_obj = HTML::FormBuilder->new(
    data    => {id => 'testid'},
    classes => $classes
);
$fieldset = $form_obj->add_fieldset({});

my $input_field1 = {
    'input' => {
        'heading'   => 'text heading',
        'type'      => 'text',
        'id'        => 'amount',
        'name'      => 'amount',
        'maxlength' => 40,
        'value'     => '',
    },
};

my $input_field2 = {
    'input' => {
        'heading' => 'checkbox heading',
        'type'    => 'checkbox',
        'id'      => 'single_checkbox',
        'name'    => 'single_checkbox',
        'value'   => 'SGLBOX',
    },
};

$fieldset->add_field($input_field1);
$fieldset->add_field($input_field2);
lives_ok(sub { $result = $form_obj->build }, 'build field with heading');

$expect_result = <<EOF;
<form id="testid" method="get"><div class="rbox form">
    <div class="rbox-wrap">
        <fieldset><div class="grd-row-padding row clear"><div class="grd-grid-8"><span id="inputheading">text heading</span><input class=" text" id="amount" maxlength="40" name="amount" type="text"></div></div><div class="grd-row-padding row clear"><div class="grd-grid-8"><input id="single_checkbox" name="single_checkbox" type="checkbox" value="SGLBOX"><span id="inputheading">checkbox heading</span><br /></div></div></fieldset>
        <span class="tl">&nbsp;</span><span class="tr">&nbsp;</span><span class="bl">&nbsp;</span><span class="br">&nbsp;</span>
    </div>
</div>
</form>
EOF

chomp($expect_result);
is($result, $expect_result, 'heading result ok');

# test build_confirmation_button_with_all_inputs_hidden
$form_obj = HTML::FormBuilder->new(
    data    => {id => 'testid'},
    classes => $classes
);
$fieldset = $form_obj->add_fieldset({
    legend  => 'a legend',
    header  => 'header',
    comment => 'comment'
});
$fieldset->add_field($input_field_amount);

lives_ok(
    sub {
        $result = $form_obj->build_confirmation_button_with_all_inputs_hidden;
    },
    'build_confirmation_button_with_all_inputs_hidden ok'
);

$expect_result = <<EOF;
<form id="testid" method="get"><input type="hidden" name="amount" value=""/><input type="hidden" name="process" value="1"/><a class="button backbutton" href="javascript:history.go(-1)" ><span class="button backbutton" >Back</span></a> <span class="button"><button id="submit" class="button" type="submit">Confirm</button></span></form>
EOF

chomp($expect_result);
is($result, $expect_result, 'result of build_confirmation_button_with_all_inputs_hidden');

################################################################################
# stacked
$form_obj = HTML::FormBuilder->new(
    data    => {id => 'testid'},
    classes => $classes
);
$fieldset = $form_obj->add_fieldset({stacked => 0});
lives_ok(sub { $result = $form_obj->build }, 'build field with heading');
$expect_result = <<EOF;
<form id="testid" method="get"><div class="rbox form">
    <div class="rbox-wrap">
        <fieldset><div class="grd-grid-12"></div></fieldset>
        <span class="tl">&nbsp;</span><span class="tr">&nbsp;</span><span class="bl">&nbsp;</span><span class="br">&nbsp;</span>
    </div>
</div>
</form>
EOF

chomp($expect_result);
is($result, $expect_result, 'result of stacked=0 fieldset');

$form_obj      = create_multiset_form();
$expect_result = <<'EOF';
<form action="http://localhost/some/where/test.cgi" class="formObject" id="id_test_form" method="post" name="name_test_form"><div class="rbox form">
    <div class="rbox-wrap">
        <fieldset><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="amount">Amount</label></div><div class="grd-grid-8"><input class=" text" id="amount" maxlength="40" name="amount" type="text"><p class="errorfield" id="error_amount"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="gender">gender</label></div><div class="grd-grid-8"><select id="gender" name="gender"><option value="male" SELECTED >male</option><option value="female" >female</option></select><p class="errorfield" id="error_gender"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="select_text">select_text</label></div><div class="grd-grid-8"><select id="select_text_curr" name="select_text_curr"><option value="USD" >USD</option><option value="EUR" >EUR</option></select><input class=" text" id="select_text_amount" name="select_text_amount" type="text" value="20"><p class="errorfield" id="error_select_text"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="Textarea">Textarea</label></div><div class="grd-grid-8"><textarea id="Textarea" name="Textarea">This is default value of textarea</textarea><p class="errorfield" id="error_Textarea"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="Password">Password</label></div><div class="grd-grid-8"><input class=" text" id="Password" name="Password" type="password" value="pa$$w0rd"><p class="errorfield" id="error_Password"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="single_checkbox">Single Checkbox</label></div><div class="grd-grid-8"><input id="single_checkbox" name="single_checkbox" type="checkbox" value="SGLBOX"></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="single_checkbox">Single Checkbox</label></div><div class="grd-grid-8"><input id="checkbox1" name="checkbox1" type="checkbox" value="BOX1"><input id="checkbox2" name="checkbox2" type="checkbox" value="BOX2"></div></div><div class="grd-row-padding row clear"><p class="errorfield" id="error_general"></p></div></fieldset>
        <span class="tl">&nbsp;</span><span class="tr">&nbsp;</span><span class="bl">&nbsp;</span><span class="br">&nbsp;</span>
    </div>
</div>
<div class="rbox form">
    <div class="rbox-wrap">
        <fieldset><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="amount">Amount</label></div><div class="grd-grid-8"><input class=" text" id="amount" maxlength="40" name="amount" type="text"><p class="errorfield" id="error_amount"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="gender">gender</label></div><div class="grd-grid-8"><select id="gender" name="gender"><option value="male" SELECTED >male</option><option value="female" >female</option></select><p class="errorfield" id="error_gender"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="select_text">select_text</label></div><div class="grd-grid-8"><select id="select_text_curr" name="select_text_curr"><option value="USD" >USD</option><option value="EUR" >EUR</option></select><input class=" text" id="select_text_amount" name="select_text_amount" type="text" value="20"><p class="errorfield" id="error_select_text"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="Textarea">Textarea</label></div><div class="grd-grid-8"><textarea id="Textarea" name="Textarea">This is default value of textarea</textarea><p class="errorfield" id="error_Textarea"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="Password">Password</label></div><div class="grd-grid-8"><input class=" text" id="Password" name="Password" type="password" value="pa$$w0rd"><p class="errorfield" id="error_Password"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="single_checkbox">Single Checkbox</label></div><div class="grd-grid-8"><input id="single_checkbox" name="single_checkbox" type="checkbox" value="SGLBOX"></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="single_checkbox">Single Checkbox</label></div><div class="grd-grid-8"><input id="checkbox1" name="checkbox1" type="checkbox" value="BOX1"><input id="checkbox2" name="checkbox2" type="checkbox" value="BOX2"></div></div><div class="grd-row-padding row clear"><p class="errorfield" id="error_general"></p></div></fieldset>
        <span class="tl">&nbsp;</span><span class="tr">&nbsp;</span><span class="bl">&nbsp;</span><span class="br">&nbsp;</span>
    </div>
</div>
<div class="rbox form">
    <div class="rbox-wrap">
        <fieldset><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="amount">Amount</label></div><div class="grd-grid-8"><input class=" text" id="amount" maxlength="40" name="amount" type="text"><p class="errorfield" id="error_amount"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="gender">gender</label></div><div class="grd-grid-8"><select id="gender" name="gender"><option value="male" SELECTED >male</option><option value="female" >female</option></select><p class="errorfield" id="error_gender"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="select_text">select_text</label></div><div class="grd-grid-8"><select id="select_text_curr" name="select_text_curr"><option value="USD" >USD</option><option value="EUR" >EUR</option></select><input class=" text" id="select_text_amount" name="select_text_amount" type="text" value="20"><p class="errorfield" id="error_select_text"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="Textarea">Textarea</label></div><div class="grd-grid-8"><textarea id="Textarea" name="Textarea">This is default value of textarea</textarea><p class="errorfield" id="error_Textarea"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="Password">Password</label></div><div class="grd-grid-8"><input class=" text" id="Password" name="Password" type="password" value="pa$$w0rd"><p class="errorfield" id="error_Password"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="single_checkbox">Single Checkbox</label></div><div class="grd-grid-8"><input id="single_checkbox" name="single_checkbox" type="checkbox" value="SGLBOX"></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="single_checkbox">Single Checkbox</label></div><div class="grd-grid-8"><input id="checkbox1" name="checkbox1" type="checkbox" value="BOX1"><input id="checkbox2" name="checkbox2" type="checkbox" value="BOX2"></div></div><div class="grd-row-padding row clear"><p class="errorfield" id="error_general"></p></div></fieldset>
        <span class="tl">&nbsp;</span><span class="tr">&nbsp;</span><span class="bl">&nbsp;</span><span class="br">&nbsp;</span>
    </div>
</div>
<div class="rbox form">
    <div class="rbox-wrap">
        <fieldset><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="amount">Amount</label></div><div class="grd-grid-8"><input class=" text" id="amount" maxlength="40" name="amount" type="text"><p class="errorfield" id="error_amount"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="gender">gender</label></div><div class="grd-grid-8"><select id="gender" name="gender"><option value="male" SELECTED >male</option><option value="female" >female</option></select><p class="errorfield" id="error_gender"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="select_text">select_text</label></div><div class="grd-grid-8"><select id="select_text_curr" name="select_text_curr"><option value="USD" >USD</option><option value="EUR" >EUR</option></select><input class=" text" id="select_text_amount" name="select_text_amount" type="text" value="20"><p class="errorfield" id="error_select_text"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="Textarea">Textarea</label></div><div class="grd-grid-8"><textarea id="Textarea" name="Textarea">This is default value of textarea</textarea><p class="errorfield" id="error_Textarea"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="Password">Password</label></div><div class="grd-grid-8"><input class=" text" id="Password" name="Password" type="password" value="pa$$w0rd"><p class="errorfield" id="error_Password"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="single_checkbox">Single Checkbox</label></div><div class="grd-grid-8"><input id="single_checkbox" name="single_checkbox" type="checkbox" value="SGLBOX"></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="single_checkbox">Single Checkbox</label></div><div class="grd-grid-8"><input id="checkbox1" name="checkbox1" type="checkbox" value="BOX1"><input id="checkbox2" name="checkbox2" type="checkbox" value="BOX2"></div></div><div class="grd-row-padding row clear"><p class="errorfield" id="error_general"></p></div></fieldset>
        <span class="tl">&nbsp;</span><span class="tr">&nbsp;</span><span class="bl">&nbsp;</span><span class="br">&nbsp;</span>
    </div>
</div>
<div class="rbox form">
    <div class="rbox-wrap">
        <fieldset><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="amount">Amount</label></div><div class="grd-grid-8"><input class=" text" id="amount" maxlength="40" name="amount" type="text"><p class="errorfield" id="error_amount"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="gender">gender</label></div><div class="grd-grid-8"><select id="gender" name="gender"><option value="male" SELECTED >male</option><option value="female" >female</option></select><p class="errorfield" id="error_gender"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="select_text">select_text</label></div><div class="grd-grid-8"><select id="select_text_curr" name="select_text_curr"><option value="USD" >USD</option><option value="EUR" >EUR</option></select><input class=" text" id="select_text_amount" name="select_text_amount" type="text" value="20"><p class="errorfield" id="error_select_text"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="Textarea">Textarea</label></div><div class="grd-grid-8"><textarea id="Textarea" name="Textarea">This is default value of textarea</textarea><p class="errorfield" id="error_Textarea"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="Password">Password</label></div><div class="grd-grid-8"><input class=" text" id="Password" name="Password" type="password" value="pa$$w0rd"><p class="errorfield" id="error_Password"></p></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="single_checkbox">Single Checkbox</label></div><div class="grd-grid-8"><input id="single_checkbox" name="single_checkbox" type="checkbox" value="SGLBOX"></div></div><div class="grd-row-padding row clear"><div class="grd-grid-4  form_label"><label for="single_checkbox">Single Checkbox</label></div><div class="grd-grid-8"><input id="checkbox1" name="checkbox1" type="checkbox" value="BOX1"><input id="checkbox2" name="checkbox2" type="checkbox" value="BOX2"></div></div><div class="grd-row-padding row clear"><p class="errorfield" id="error_general"></p></div></fieldset>
        <span class="tl">&nbsp;</span><span class="tr">&nbsp;</span><span class="bl">&nbsp;</span><span class="br">&nbsp;</span>
    </div>
</div>
</form>
EOF

chomp $expect_result;
lives_ok(sub { $result = $form_obj->build }, 'build multiset form ok');
is($result, $expect_result, 'build multiset form result ok');
done_testing();

sub create_multiset_form {
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

    for my $group ('', '', 'group1', 'group1', 'group2') {

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
    }
    return $form_obj;
}

