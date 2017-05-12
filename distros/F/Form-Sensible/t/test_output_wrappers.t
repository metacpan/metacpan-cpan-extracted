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


my $form = Form::Sensible::Form->new(name=>'test');

my $username_field = Form::Sensible::Field::Text->new(  name=>'username', validation => { regex => qr/^[0-9a-z]*$/  });
$form->add_field($username_field);

my $password_field = Form::Sensible::Field::Text->new(  name=>'password',
                                                        render_hints => { field_type => 'password' } );
$form->add_field($password_field);

my $submit_button = Form::Sensible::Field::Trigger->new( name => 'submit' );
$form->add_field($submit_button);

my $renderer = Form::Sensible->get_renderer('HTML', { fs_template_dir => $lib_dir . '/share/templates' });
 
#print Dumper($renderer->include_paths);
my $output = $renderer->render($form)->complete;

############ same thing - only the 'flat' way.

$form = Form::Sensible->create_form( {
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

my $renderer2 = Form::Sensible->get_renderer('HTML', { fs_template_dir => $lib_dir . '/share/templates' });

my $output_2 = $renderer2->render($form)->complete;
    
ok( $output eq $output_2, "flat creation and programmatic creation produce the same results");

my $renderer3 = Form::Sensible->get_renderer('HTML', { fs_template_dir => $lib_dir . '/share/templates', base_theme => 'table' });

my $output_3 = $renderer3->render($form)->complete;

ok( $output_3 =~ /<table/, "Theme selection works");
# print $output_3;

#print $output_2;

## Checking that fields that don't accept multiple behave properly
$form->set_values({ username => ['test','foo'], password => 'test' });

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
is_deeply ({ username => '*&#*&@)(*&)', password => 'test' } , { username => $form->field('username')->value, password => $form->field('password')->value });

$validation_result = $form->validate();
isnt($validation_result->is_valid, 1, "Validation fails");

## here we should render the form, and make sure stuff lines up properly

done_testing();
