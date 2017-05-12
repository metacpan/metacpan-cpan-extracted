#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;

run_test(
    4,
    sub {
        $DB::single=1;
        13;
    },
    \&test_1,
    'done',
);
    
sub test_1 {
    my($db, $loc) = @_;
    Test::More::ok($db->is_loaded($INC{'Devel/Chitin.pm'}), 'Devel::Chitin is_loaded');
    Test::More::ok(! $db->is_loaded('Non/Loaded/Module.pm'), 'Non::Loaded::Module not is_loaded');

    my @files = $db->loaded_files();
    Test::More::ok(scalar(@files), 'Get list of loaded_files');
    Test::More::ok(scalar(grep { $_ eq $INC{'Devel/Chitin.pm'} } @files), 'Devel::Chitin is in the list');
}
