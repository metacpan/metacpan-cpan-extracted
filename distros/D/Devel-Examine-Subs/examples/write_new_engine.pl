#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;
use File::Copy;

my $file = 't/sample.data';
my $orig = 't/sample.data.orig';

my %params = (
                file => $file,
                search => 'this',
#                pre_proc => ,
#                pre_proc_return => 1,
#                pre_proc_dump => 1,
                post_proc => ['file_lines_contain'],
#                post_proc_dump => 1,
#                post_proc_return => 1,
                engine => dumps(),
#                engine_return => 1,
#                engine_dump => 1,
#                core_dump => 1,
#                copy => 't/inject_after.data',
#                code => ['# comment line one', '# comment line 2' ],
              );

#<des>
sub dumps {

    return sub {

        my $p = shift;
        my $struct = shift;

        return $struct;
    };
}
#</des>

my $install = 0; # set this to true to install

if ($install){
    my $des = Devel::Examine::Subs->new;
    my $ret = $des->add_functionality(add_functionality => 'engine');
    print "\n$ret\n";
}
else {
    my $des = Devel::Examine::Subs->new(%params);
    my $struct = $des->run(\%params);
    print Dumper $struct;
}
