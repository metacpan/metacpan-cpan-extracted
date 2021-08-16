# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl -I/usr/local/bin t/File-Rename-script.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN {
    plan skip_all => "Need perl v5.12.0: no feature unicode_strings" 
        if $] < 5.012;
}
plan tests => 3;

push @INC, qw(blib/script) if -d 'blib';
unshift @INC, 't' if -d 't';
require 'testlib.pl';

my $script = script_name();
my $require_ok =  eval { require($script) };
die $@ unless $require_ok;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dir = tempdir();

my @files = create(qq(b\x{A0}g.txt));

SKIP: {
    skip "Can't create filename with NBSP", 1 unless @files;
    main_argv( '-u', '-e', 's/\s//', @files);
    is_deeply( [ sort( listdir( $dir ) ) ], [qw(bg.txt)], 'rename - unicode' );
}

File::Path::rmtree($dir);

require_ok 'File::Rename::Unicode';
cmp_ok( eval $File::Rename::Unicode::VERSION, '<=', eval $File::Rename::VERSION);

