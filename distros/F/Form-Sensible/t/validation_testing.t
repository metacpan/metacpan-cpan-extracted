use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
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
                                                            field_class => 'Text',
                                                            name => 'string',
                                                            validation => {  
                                                                            regex => '^[0-9a-z]*$',
                                                                            required => 1,
                                                                          }
                                                         },
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
                                                            validation => { 
                                                                            code => sub { 
                                                                                            ## number can not be 172.
                                                                                            ## we don't like 172.
                                                                                            my $value = shift;
                                                                                            my $field = shift;
                                                                                            if ($value == 172) {
                                                                                                return "We don't like 172.";
                                                                                            } else {
                                                                                                return undef;
                                                                                            }
                                                                                        }
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

ok( $validation_result->is_valid(), "valid forms values are considered valid");

## fail on code ref
$form->set_values({ 
                    string => 'a2z0to9',
                    numeric_integer => 1,
                    numeric_step => 25,
                    numeric_nostep => 172
                  });

$validation_result = $form->validate();

like( $validation_result->error_fields->{numeric_nostep}[0], qr/We don't/,  "Number field value is invalid: coderef");

## fail on string regex
$form->set_values({ 
                    string => 'ZZZ0to9',
                    numeric_integer => 1,
                    numeric_step => 25,
                    numeric_nostep => 122.7
                  });

$validation_result = $form->validate();

like( $validation_result->error_fields->{string}[0], qr/invalid/,  "String field value is invalid: regex");

$form->clear_state();

ok( !defined($form->validator_result), 'clear_state() clears out validation results');

## fail on string regex
$form->set_values({ 
                    numeric_integer => 1,
                    numeric_step => 25,
                    numeric_nostep => 122.7
                  });

$validation_result = $form->validate();

like( $validation_result->error_fields->{string}[0], qr/not provided/,  "values don't bleed across clear_state()");

done_testing();
