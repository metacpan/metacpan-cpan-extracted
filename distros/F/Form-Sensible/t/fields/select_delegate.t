## the test is below.  Foo is here for testing purposes.

package Foo;

use Moose;

has 'minimum' => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 1,
);

has 'maximum' => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 10,
);


sub my_numbers {
    my ($self, $caller, $prefix) = @_;
    
    my @results;
    
    for (my $i = $self->minimum ; $i <= $self->maximum; $i++) {
        push @results, { name => $prefix . " value $i", value => $i };
    }
    return \@results;
}

1;

## actual test starts here.
package main;

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
    return [map { name => $_, value => "foo_" .$_ }, qw/ five options are very good /];
}

############ same thing - only the 'flat' way.

my $form = Form::Sensible->create_form( {
                                            name => 'test',
                                            fields => [
                                                         { 
                                                            field_class => 'Select',
                                                            name => 'choices',
                                                            options_delegate => FSConnector( \&the_options )
                                                         },
                                                      ],
                                        } );

my $select_field = $form->field('choices');

ok( grep({ $_->{value} eq 'foo_very'} @{$select_field->get_options}), "Loaded options via function delegate");

$select_field->add_option('wheat', 'Wheat Bread');
$select_field->add_option('white', 'White Bread');
$select_field->add_option('sour', 'Sourdough Bread');

print Dumper($select_field->get_options);

ok( !(grep { $_->{value} eq 'white' } @{$select_field->get_options}), "Options added on select are ignored when delegate defined");


#print Dumper($select_field->options());

my $delegate_object = Foo->new( minimum => 5, maximum => 9 );

$select_field->options_delegate(FSConnector($delegate_object, 'my_numbers', "testpre"));

ok( (grep { $_->{name} =~ 'testpre value 7'} @{$select_field->get_options}), "Loaded options via object delegate");

#print Dumper($select_field->options());

my $form2 = Form::Sensible->create_form( {
                                            name => 'test',
                                            fields => [
                                                         { 
                                                            field_class => 'Select',
                                                            name => 'pickit',
                                                         },
                                                      ],
                                        } );

my $select_field2 = $form2->field('pickit');

$select_field2->add_option('wheat', 'Wheat Bread');
$select_field2->add_option('white', 'White Bread');
$select_field2->add_option('sour', 'Sourdough Bread');

#print Dumper($select_field2->options());

ok( (grep { $_->{value} eq 'white' } @{$select_field2->get_options}), "Select acting as it's own delegate works");


done_testing();
