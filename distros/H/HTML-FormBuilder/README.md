# HTML::FormBuilder
[![Build Status](https://travis-ci.org/binary-com/perl-HTML-FormBuilder.svg?branch=master)](https://travis-ci.org/binary-com/perl-HTML-FormBuilder)
[![codecov](https://codecov.io/gh/binary-com/perl-HTML-FormBuilder/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-HTML-FormBuilder)

An object-oriented module for building and displaying HTML form.

```perl
my $form = HTML::FormBuilder->new(
    data => {
        name    => 'form_name',
        id      => 'form_id',
        class   => 'form_class',
        method  => 'post',
    },
    classes => { row => 'rowdev' });

my $fieldset = $form->add_fieldset({
    id      => 'fieldset1',
    legend  => 'fieldset1',
});

my $input1 = {
    label => {
        text    => 'input1',
        for     => 'input1',
    },
    input => {
        name    => 'name',
        type    => 'text',
        value   => 'Join'
    }};

$fieldset->add_field($input1);
$form->set_field_value('name', 'Omid');
print $form->build;


my $form2 = HTML::FormBuilder::Validation->new(
    data => {
        name    => 'form2_name',
        id      => 'form2_id',
        class   => 'form2_class',
        method  => 'post'
    },
    classes => {row => 'rowdev'});

my $fieldset2 = $form2->add_fieldset({
    id      => 'fieldset2',
    legend  => 'fieldset2',
});

my $select_fruit = {
    id      => 'fruit',
    name    => 'fruit',
    options => [
        {
            value => 'apple',
            text  => 'apple',
        },
        {
            value => 'orange',
            text  => 'orange'
        }
    ]};

my $input2 = {
    label => {
        text    => 'Select fruit',
        for     => 'fruit',
    },
    input => [$select_fruit],
    error => {
        text    => '',
        id      => 'errorfruit',
        class   => 'errorfield',
    },
    validation => [{
        type    => 'regexp',
        id      => 'fruit',
        regexp  => '^[a-zA-Z0-9- ]+$',
        err_msg => 'Please select fruit',
    }],
};

$fieldset2->add_field($input2);
$form->validate;
$form->build;

```

#### INSTALLATION



To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

#### SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc HTML::FormBuilder
    perldoc HTML::FormBuilder::Validation
    perldoc HTML::FormBuilder::FieldSet
    perldoc HTML::FormBuilder::Field
    perldoc HTML::FormBuilder::Select

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-FormBuilder

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/HTML-FormBuilder

    CPAN Ratings
        http://cpanratings.perl.org/d/HTML-FormBuilder

    Search CPAN
        http://search.cpan.org/dist/HTML-FormBuilder/


####COPYRIGHT

Copyright (C) 2015 binary.com

