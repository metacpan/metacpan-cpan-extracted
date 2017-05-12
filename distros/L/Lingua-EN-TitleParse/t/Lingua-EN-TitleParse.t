# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-EN-TitleParse.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
require_ok ('Lingua::EN::TitleParse');

#########################

my $names = {
    'Mr Bloggs' => {
        title => 'Mr',
        name  => 'Bloggs',
    },
    'Mr. Bloggs' => {
        title => 'Mr.',
        name  => 'Bloggs',
    },
    'MR Bloggs' => {
        title => 'MR',
        name  => 'Bloggs',
    },
    'mr Bloggs' => {
        title => 'mr',
        name  => 'Bloggs',
    },
    'MrBloggs' => {
        title => '',
        name  => 'MrBloggs', # a single string is returned as is, otherwise "Drake" => "Dr ake"
    },
    'Mr  Bloggs' => {
        title => 'Mr',
        name  => 'Bloggs',
    },
    'Mr & Mrs Bloggs' => {
        title => 'Mr & Mrs',
        name  => 'Bloggs',
    },
    'Count Dracula' => {
        title => 'Count',
        name  => 'Dracula',
    },
    'Commander James Bond' => {
        title => 'Commander',
        name  => 'James Bond',
    },
    'Air Marshall Bloggs' => {
        title => 'Air Marshall',
        name  => 'Bloggs',
    },
    'Mother Teresa' => {
        title => 'Mother',
        name  => 'Teresa',
    },
    'Dr. Doolittle' => {
        title => 'Dr.',
        name  => 'Doolittle',
    },
};

note('OO interface');
# It's slightly more efficient if we use the OO interface when
# parsing a list of names.
my $title_obj = Lingua::EN::TitleParse->new();

foreach my $name (sort keys %$names) {

    my ($title, $remaining_name) = $title_obj->parse($name);

    is( $title, $names->{$name}{title}, sprintf("title for %s should be %s", $name, $names->{$name}{title}) );
    is( $remaining_name, $names->{$name}{name}, sprintf("name for %s should be %s", $name, $names->{$name}{name}) );
}

# Try the functional interface too
note('functional interface');
my $name = "Mr and Mrs Bloggs";
my ($title, $remaining_name) = Lingua::EN::TitleParse->parse($name);
is( $title, "Mr and Mrs", sprintf("title for %s should be %s", $name, "Mr and Mrs") );
is( $remaining_name, "Bloggs", sprintf("name for %s should be %s", $name, "Bloggs") );

# Use our own titles with the OO interface
note('try our own titles');
my @titles = ('Grandmaster Supreme High Inquisitor', 'High Inquisitor', 'Supreme High Inquisitor');
$title_obj = Lingua::EN::TitleParse->new( titles => \@titles );
$name = 'Supreme High Inquisitor John Cleese';
($title, $remaining_name) = $title_obj->parse($name);
is( $title, 'Supreme High Inquisitor', sprintf("title for %s should be %s", $name, 'Supreme High Inquisitor') );
is( $remaining_name, 'John Cleese', sprintf("name for %s should be %s", $name, 'John Cleese') );

# Retrieve the list of titles
note('retrieve titles');
my @check_titles = $title_obj->titles;
is_deeply(\@check_titles, \@titles, "Title retrieval"); 

# Try the non-OO title interface
@check_titles = Lingua::EN::TitleParse->titles;
ok(@check_titles, "Non-OO title retrieval");

# Optionally get cleaned titles on output
note('cleaned titles');
$title_obj = Lingua::EN::TitleParse->new( clean => 1 );
$name = "mR. Joe Bloggs";
($title, $remaining_name) = $title_obj->parse($name);
is( $title, 'Mr', sprintf("Clean title for %s should be %s", $name, 'Mr') );
is( $remaining_name, 'Joe Bloggs', sprintf("name for %s should be %s", $name, 'Joe Bloggs') );
 
# Without 'clean' turned on
note('comparing unclean to clean titles');
$title_obj = Lingua::EN::TitleParse->new();
($title, $remaining_name) = $title_obj->parse("mR. Joe Bloggs");
is( $title, 'mR.', sprintf("Without cleaning, the title for %s should be %s", $name, 'mR.') );
is( $remaining_name, 'Joe Bloggs', sprintf("name for %s should be %s", $name, 'Joe Bloggs') );

done_testing();
