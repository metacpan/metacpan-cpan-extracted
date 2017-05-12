#!perl 
use warnings;
use strict;

use Test::More;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $file = 't/sample.data';

my %p = (
    file => $file, 
    post_proc => 'subs',
    engine => 'objects',
);

my $des = Devel::Examine::Subs->new(%p);

my $objects = $des->run();

for my $o (@$objects){
    if ($o->name() eq 'eight'){
        is ($o->start(), 49, "sub eight starts at the right line");
        is ($o->end(), 51, "sub eight ends at the right line");
        is ($o->line_count(), 3, "sub eight has 3 lines, including def and }");
    } 
    if ($o->name() eq 'two'){
        is ($o->start(), 17, "sub two starts at the right line");
        is ($o->end(), 21, "sub two ends at the right line");
        is ($o->line_count(), 5, "sub two has 5 lines, including def and }");
    } 
}
eval { $objects = $des->objects(); };
ok (! $@, "objects() is callable and works" );

for my $o (@$objects) {
    if ($o->name() eq 'four') {
        is ( $o->start(), 30, "sub four starts at the right line" );
        is ( $o->end(), 35, "sub four ends at the right line" );
        is ( $o->line_count(), 6,
            "sub four has six lines, including the def and closing brace" );
    }

    if ($o->name() eq 'six'){
        is ($o->start(), 43, "sub six starts at the right line");
        is ($o->end(), 45, "sub six starts at the right line");
        is ($o->line_count(), 3, "sub six has 4 lines, including the def and closing brace" );
    } 
}

{
    my %params = (file => 't/test');
    my $des = Devel::Examine::Subs->new(%params);
    my $struct = $des->objects();

    for my $file (keys %$struct){

        for my $o (@{ $struct->{$file} }){
            if ($file eq 't/files/other.pm') {
                if ($o->name() eq 'four') {
                    is ( $o->start(), 28,
                        "sub four starts at the right line in dir" );
                    is ( $o->end(), 33,
                        "sub four ends at the right line in dir" );
                }
                if ($o->name() eq 'six') {
                    is ( $o->start(), 41,
                        "sub six starts at the right line in dir" );
                    is ( $o->end(), 43,
                        "sub six starts at the right line in dir" );
                }
                if ($o->name() eq 'eight') {
                    is ( $o->start(), 47,
                        "sub eight starts at the right line in dir" );
                    is ( $o->end(), 49,
                        "sub eight ends at the right line in dir" );
                }
                if ($o->name() eq 'two') {
                    is ( $o->start(), 15,
                        "sub two starts at the right line in dir" );
                    is ( $o->end(), 19,
                        "sub two starts at the right line in dir" );
                }
            }
            if ($file eq 't/test/files/module.pm'){
                if ($o->name() eq 'four') {
                    is ( $o->start(), 17,
                        "sub four starts at the right line in dir" );
                    is ( $o->end(), 20,
                        "sub four ends at the right line in dir" );
                }
                if ($o->name() eq 'two') {
                    is ( $o->start(), 9,
                        "sub two starts at the right line in dir" );
                    is ( $o->end(), 12,
                        "sub two starts at the right line in dir" );
                }
            }
        }
    }
}
{
    my %params = (file => 't/sample.data');
    my $des = Devel::Examine::Subs->new(%params);

    my $subs = $des->objects(objects_in_hash => 1);

    is (keys %$subs, 11, "objects_in_hash has proper number of keys");

    for (keys %$subs){
        is (ref $subs->{$_}, 'Devel::Examine::Subs::Sub', "sub $_ is a proper object");
        my @methods = qw(name start end lines line_count code);
        my $obj = $subs->{$_};
        for my $m (@methods){
            ok ($obj->$m ne '', "objects in a hash can >$m<" );
        }
    }
}

done_testing();
