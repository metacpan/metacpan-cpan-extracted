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

############ same thing - only the 'flat' way.

my $form = Form::Sensible->create_form( {
                                            name => 'test',
                                            fields => [
                                                         { 
                                                            field_class => 'Text',
                                                            name => 'username',
                                                            validation => {  regex => '^[0-9a-z]*$'  }
                                                         },
                                                         {
                                                             field_class => 'Text',
                                                             name => 'password',
                                                             render_hints => {  field_type => 'password' }
                                                         },
                                                         {
                                                             field_class => 'Trigger',
                                                             name => 'submit'
                                                         }
                                                      ],
                                        } );

#print STDERR "***********\n";
$form->set_values({ username => 'test', password => ['test','whee'] });

#print Dumper($form->get_all_values());
#exit;

## here we should check these fields
is_deeply ({ username => 'test', password => 'test' } , { username => $form->field('username')->value, password => $form->field('password')->value }, 'Additional values on single-value fields are ignored');

## here we should add some field values
$form->set_values({ username => 'test', password => 'test' });

## here we should check these fields
is_deeply ({ username => 'test', password => 'test' } , { username => $form->field('username')->value, password => $form->field('password')->value }, 'Setting Values behaves properly');

## here we should make sure proper validation passes
my $validation_result = $form->validate();
is($validation_result->is_valid, 1, "Validates okay");

## here we should make sure improper validation is handled properly, aka fail for
## non-passing data
$form->set_values({ username => '*&#*&@)(*&)', password => 'test' });

$validation_result = $form->validate();
isnt($validation_result->is_valid, 1, "Validation fails when appropriate");

## reset and clear any existing state.
$form->clear_state();

## simulate catalyst params;
my $c_req_params = {};

$form->delegate_all_field_values_to_hashref($c_req_params);

#foreach my $field (values %{$form->fields()}) {
#    $field->value_delegate( FSConnector( sub { 
#                              my $caller = shift;
#                              
#                              if ($#_ > -1) {   
#                                  if (ref($_[0]) eq 'ARRAY' && !($caller->accepts_multiple)) {
#                                      $c_req_params->{$caller->name} = $_[0]->[0];
#                                  } else {
#                                      $c_req_params->{$caller->name} = $_[0];
#                                  }
#                              }
#                              return $c_req_params->{$caller->name}; 
#                          }
#                          ) );
#}

## checking externally stored value processing

#print Dumper($c_req_params);
#exit;

$c_req_params->{'username'} = 'foo';
$c_req_params->{'password'} = 'bar';


is_deeply ({ username => 'foo', password => 'bar' } , { username => $form->field('username')->value, password => $form->field('password')->value }, 'External value storage: Setting Values via external storage behaves properly');


$form->set_values({ username => 'test', password => 'test' });

is_deeply ({ username => 'test', password => 'test' } , $c_req_params, 'External value storage: Setting values via field objects sets values in the correct place');

## here we should add some field values
$form->set_values({ username => 'test', password => 'test' });

## here we should check these fields
is_deeply ({ username => 'test', password => 'test' } , { username => $form->field('username')->value, password => $form->field('password')->value }, 'External value storage: Setting Values behaves properly');

## here we should check these fields
$form->set_values({ username => 'test', password => ['test','whee'] });

is_deeply ({ username => 'test', password => 'test' } , { username => $form->field('username')->value, password => $form->field('password')->value }, 'External value storage: Additional values on single-value fields are ignored');


## here we should make sure proper validation passes
$validation_result = $form->validate();
is($validation_result->is_valid, 1, "External value storage: Validates okay");

## here we should make sure improper validation is handled properly, aka fail for
## non-passing data
$form->set_values({ username => '*&#*&@)(*&)', password => 'test' });

$validation_result = $form->validate();
isnt($validation_result->is_valid, 1, "External value storage: Validation fails when appropriate");

## here we should render the form, and make sure stuff lines up properly

done_testing();
