use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;
use Form::Sensible;

#use Form::Sensible::Form;
#use Form::Sensible::Field::Text;
#use Form::Sensible::Field::Number;
#use Form::Sensible::Field::Trigger;
use Form::Sensible::Renderer::HTML;

my $form = Form::Sensible::Form->new(name=>'test');
my $textarea = Form::Sensible::Field::Text->new(name=>'test_field', validation => { regex => qr/^[0-9a-z]*$/  });

$form->add_field($textarea);
## old way
#$form->add_field(Form::Sensible::Field::Number->new(name=>'a_number', validation => { regex => qr/^[0-9]*$/  }));
$form->add_field({ field_class => 'Number', name => 'a_number', validation => { regex => qr/^[0-9]*$/ }});
$form->add_field({
                    field_class => 'Number',
                    name=>'another_number',
                    lower_bound => 18,
                    upper_bound => 89,
                    step => 10, 
                    validation => { regex => qr/^[0-9]*$/  },
                    render_hints => { field_type => 'select'},
                 });

$form->add_field(Form::Sensible::Field::Trigger->new(name=>'submit'));

$form->field('a_number')->value(17);
$form->field('another_number')->value(60);



my $dir = $FindBin::Bin;
my @dirs = split '/', $dir;
pop @dirs;
my $lib_dir = join('/', @dirs);

my $renderer = Form::Sensible::Renderer::HTML->new({ fs_template_dir => $lib_dir . '/share/templates' });

my $renderedform = $renderer->render($form);

my $firstformoutput = join("\n", $renderedform->start('/do_stuff'), $renderedform->messages, $renderedform->fields, $renderedform->end) . "\n";

my $flattenned_form = $form->flatten();
#print Dumper($flattenned_form);

## now we create the new form from the flattened version... let's see how it goes.
my $newform = Form::Sensible->create_form($flattenned_form);
$newform->field('a_number')->value(17);
$newform->field('another_number')->value(60);

my $renderer2 = Form::Sensible::Renderer::HTML->new({ fs_template_dir => $lib_dir . '/share/templates' });
my $rendered2form = $renderer->render($newform);

my $secondformoutput = join("\n", $rendered2form->start('/do_stuff'), $rendered2form->messages, $rendered2form->fields, $rendered2form->end) . "\n";

## debugging.
print $firstformoutput . "\n=======\n";
print $secondformoutput . "\n=======\n";

ok( $firstformoutput eq $secondformoutput, "flatten and deflatten work properly");
delete($flattenned_form->{'render_hints'});
my $subform_field = $form->add_field({ field_class => 'SubForm', name => 'subform_thing', form => $flattenned_form });

$renderedform = $renderer->render($form);

$firstformoutput = join("\n", $renderedform->start('/do_stuff'), $renderedform->messages, $renderedform->fields, $renderedform->end) . "\n";

print "\n\n\n\n\n\n" . $firstformoutput . "\n=======\n";
done_testing();
