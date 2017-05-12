#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::More;
use HTML::FormBuilder;
use HTML::FormBuilder::Validation;

my $form = HTML::FormBuilder->new(
    data      => {id => 'test'},
    csrftoken => 1
);
my $fieldset = $form->add_fieldset({});
$fieldset->add_field({
        input => {
            name  => 'name',
            type  => 'text',
            value => 'Join'
        }});
my $html = $form->build;
ok(index($html, '<input type="hidden" name="csrftoken" value="') > -1);

## test build_confirmation_button_with_all_inputs_hidden as well
$html = $form->build_confirmation_button_with_all_inputs_hidden;
ok(index($html, '<input type="hidden" name="csrftoken" value="') > -1);

## try validate
$form = HTML::FormBuilder::Validation->new(
    data      => {id => 'test'},
    csrftoken => 1
);
$fieldset = $form->add_fieldset({});
$fieldset->add_field({
        input => {
            name  => 'name',
            type  => 'text',
            value => 'Join'
        }});
$html = $form->build;
my ($csrftoken) = ($html =~ m{<input type="hidden" name="csrftoken" value="(\w+)"});
ok($csrftoken);

$form = HTML::FormBuilder::Validation->new(
    data      => {id => 'test'},
    csrftoken => $csrftoken
);
$fieldset = $form->add_fieldset({});
$fieldset->add_field({
        input => {
            name  => 'name',
            type  => 'text',
            value => 'Join'
        }});
$form->set_input_fields({csrftoken => $csrftoken});

ok($form->validate());

$form->set_input_fields({csrftoken => 'dummy'});
ok(!$form->validate());

done_testing;

