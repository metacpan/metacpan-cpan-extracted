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

sub the_options {
    return [ map { name => $_, value => "foo_" .$_ }, qw/ five options are very good /];
}

sub has_option {
    my ($array, $valuetolookfor) = @_;
    
    foreach my $item (@{$array}) {
        if ($item->{'value'} eq $valuetolookfor) {
            return 1;
        }
    }
    return 0;
}

############ same thing - only the 'flat' way.

my $form = Form::Sensible->create_form( {
                                            name => 'test',
                                            fields => [
                                                         { 
                                                            field_class => 'Select',
                                                            name => 'choices',
                                                            options => the_options()
                                                         },
                                                      ],
                                        } );

my $select_field = $form->field('choices');

ok(has_option($select_field->get_options, 'foo_five'), "Has options we expect from field creation");
ok(!has_option($select_field->get_options, 'white'), "Doesn't have option we haven't added yet.");

$select_field->add_option('wheat', 'Wheat Bread');
$select_field->add_option('white', 'White Bread');
$select_field->add_option('sour', 'Sourdough Bread');

ok(has_option($select_field->get_options, 'white'), "Has options we added programmatically");

$select_field->add_selection('white');

ok(ref($select_field->value()) ne 'ARRAY', 'value is not an array if accepts_multiple is off');

$select_field->add_selection('white', 'sour');

ok($select_field->value() eq 'white', 'only first option is used when accepts_multiple is off');


my @results = $select_field->validate();
ok($#results == -1, "Valid option passes validation.");

$select_field->value('junk');


ok(grep(/invalid/, $select_field->validate()), "Invalid option fails validation.");

$form = undef;
$form = Form::Sensible->create_form( {
                                            name => 'test',
                                            fields => [
                                                         { 
                                                            field_class => 'Select',
                                                            name => 'choices',
                                                            options => the_options(),
                                                            accepts_multiple => 1,
                                                         },
                                                      ],
                                        } );

$select_field = $form->field('choices');

$select_field->add_selection('foo_five');

ok(ref($select_field->value()) eq 'ARRAY', 'value is an array if accepts_multiple is on, even with only one selected item');

isa_ok($select_field->value(), 'ARRAY', 'value is an array, even with only one item');

$select_field->add_selection('foo_good');

is_deeply($select_field->value(), [ 'foo_five', 'foo_good' ], "all values added via add_selection are present");

$select_field->set_selection('foo_are', 'foo_very');

is_deeply($select_field->value(), [ 'foo_are', 'foo_very' ], "set_selection sets ONLY those requested");

$select_field->set_selection(['foo_good', 'foo_are']);

is_deeply($select_field->value(), [ 'foo_good', 'foo_are' ], "add_selection / set_selection can cope with a single arrayref of values");

$select_field->add_selection('foo_good');

is_deeply($select_field->value(), [ 'foo_good', 'foo_are' ], "add_selection prevents option duplication" );

$select_field->add_selection('foo_very', 'foo_very', 'foo_very');

is_deeply($select_field->value(), [ 'foo_good', 'foo_are', 'foo_very' ], "add_selection prevents option duplication, even within the same call" );



my @newresults = $select_field->validate();

ok($#newresults == -1, "multiple valid options on 'accepts_multiple' are ok.");



done_testing();
