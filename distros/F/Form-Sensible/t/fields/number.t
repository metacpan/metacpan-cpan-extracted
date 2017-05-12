use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Data::Dumper;
use Form::Sensible;

use Form::Sensible::Form;

my $lib_dir = $FindBin::Bin;
my @dirs = split '/', $lib_dir;
pop @dirs;
$lib_dir = join('/', @dirs);



my $form = Form::Sensible->create_form( {
                                            name => 'test',
                                            fields => [
                                                         {
                                                             field_class => 'Number',
                                                             name => 'numeric_integer',
                                                             integer_only => 1,
                                                         },
                                                         { 
                                                            field_class => 'Number',
                                                            name => 'numeric_step',
                                                            integer_only => 1,
                                                            lower_bound => 10,
                                                            upper_bound => 100,
                                                            step => 5,
                                                         },
                                                         { 
                                                            field_class => 'Number',
                                                            name => 'numeric_nostep',
                                                            integer_only => 0,
                                                            lower_bound => 10,
                                                            upper_bound => 200,
                                                         },
                                                         { 
                                                             field_class => 'Number',
                                                             name => 'exponent',
                                                             validation => {
                                                                 regex => qr/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/,
                                                             }
                                                          },
                                                      ],
                                        } );
                                    
## first, success     
$form->set_values({ 
                    string => 'a2z0to9',
                    numeric_integer => -10,
                    numeric_step => 25,
                    numeric_nostep => 122.7
                  });
                  
my $validation_result = $form->validate();

ok( $validation_result->is_valid(), "valid numbers values are considered valid");

$form->set_values({ 
                    string => 'a2z0to9',
                    numeric_integer => -10,
                    numeric_step => 25,
                    numeric_nostep => 122.7,
                    exponent => '1.72e22',
                  });
                  
$validation_result = $form->validate();

ok( $validation_result->is_valid(), "exponential notation is considered valid");

## fail on numeric_step
$form->set_values({ 
                    string => 'a2z0to9',
                    numeric_integer => 1,
                    numeric_step => 26,
                    numeric_nostep => 122.7,
                    exponent => '1.72e22',
                  });

$validation_result = $form->validate();

ok( !$validation_result->is_valid(), "Form is invalid with invalid field");

like( $validation_result->error_fields->{numeric_step}[0], qr/multiple of/, "Number field value is invalid based on step");

## fail on fraction
$form->set_values({ 
                    string => 'a2z0to9',
                    numeric_integer => 1.6,
                    numeric_step => 25.7,
                    numeric_nostep => 122.7,
                    exponent => '1.72e22',
                  });

$validation_result = $form->validate();

like( $validation_result->error_fields->{numeric_integer}[0], qr/an integer/,  "Number field value is invalid: fraction in integer only field");


## fail on fraction
$form->set_values({ 
                    string => 'a2z0to9',
                    numeric_integer => 'NaN',
                    numeric_step => 25.7,
                    numeric_nostep => 122.7,
                    exponent => '1.72e22',
                  });

$validation_result = $form->validate();

like( $validation_result->error_fields->{numeric_integer}[0], qr/not a number/,  "Number field value is invalid: non-number in number field");

## fail on too high
$form->set_values({ 
                    string => 'a2z0to9',
                    numeric_integer => 1,
                    numeric_step => 126,
                    numeric_nostep => 122.7,
                    exponent => '1.72e22',
                  });

$validation_result = $form->validate();

like( $validation_result->error_fields->{numeric_step}[0], qr/maximum allowed value/,  "Number field value is invalid: over maximum value");

## fail on too low 
$form->set_values({ 
                    string => 'a2z0to9',
                    numeric_step => 6,
                    numeric_integer => 1,
                    numeric_nostep => 122.7,
                    exponent => '1.72e22',
                  });

$validation_result = $form->validate();

like( $validation_result->error_fields->{numeric_step}[0], qr/minimum allowed value/,  "Number field value is invalid: under minimum value");

done_testing();
