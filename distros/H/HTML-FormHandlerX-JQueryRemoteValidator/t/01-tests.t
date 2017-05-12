#!perl -T
use 5.006;
use strict;
use warnings;
use Test::Lib;
use Test::More;
use Test::LongString;

use lib 't/lib';

use TestForm;

plan tests => 5;

my $test_spec = {
'rules' => {
   'TestForm.password' => {
       'remote' => {
         'url' => '/ajax/formvalidator/TestForm/TestForm.password',
         'data' => 'TestForm_data_collector',
         'type' => 'POST'
       }
     },
   'TestForm.password2' => {
        'remote' => {
          'type' => 'POST',
          'data' => 'TestForm_data_collector',
          'url' => '/ajax/formvalidator/TestForm/TestForm.password2'
        }
      },
   'TestForm.lname' => {
    'remote' => {
      'type' => 'POST',
      'data' => 'TestForm_data_collector',
      'url' => '/ajax/formvalidator/TestForm/TestForm.lname'
    }
  },
   'TestForm.fname' => {
    'remote' => {
      'data' => 'TestForm_data_collector',
      'url' => '/ajax/formvalidator/TestForm/TestForm.fname',
      'type' => 'POST'
    }
  },
   'TestForm.email' => {
    'remote' => {
      'type' => 'POST',
      'url' => '/ajax/formvalidator/TestForm/TestForm.email',
      'data' => 'TestForm_data_collector'
    }
  }
     },
'messages' => {}
};

my $test_js1 =
q[  var TestForm_data_collector = {
    "TestForm.email": function () { return $("#TestForm\\\\.email").val() },
    "TestForm.fname": function () { return $("#TestForm\\\\.fname").val() },
    "TestForm.id": function () { return $("#TestForm\\\\.id").val() },
    "TestForm.lname": function () { return $("#TestForm\\\\.lname").val() },
    "TestForm.password": function () { return $("#TestForm\\\\.password").val() },
    "TestForm.password2": function () { return $("#TestForm\\\\.password2").val() }
  };];

my $test_js2 =
q[  $(document).ready(function() {
    $.getScript("http://ajax.aspnetcdn.com/ajax/jquery.validate/1.14.0/jquery.validate.min.js", function () {
      if (typeof TestForm_validation_spec !== 'undefined') {
        $('form#TestForm').validate({
          rules: TestForm_validation_spec.rules,
          submitHandler: function(form) { form.submit(); }
        });
      }
    });
  });];

my $form = TestForm->new;

my $spec = $form->_data_for_validation_spec;
my $js = $form->_js_code_for_validation_scripts;
my $html = $form->render;

#use Text::Diff;
#warn diff \$test_js2, \$js;
#warn $html;

is_deeply($spec, $test_spec);

contains_string($js, $test_js1, 'javascript data_collector generated OK');
contains_string($js, $test_js2, 'javascript doc_ready generated OK');
contains_string($html, $test_js1, 'javascript data_collector in HTML');
contains_string($html, $test_js2, 'javascript doc_ready in HTML');



