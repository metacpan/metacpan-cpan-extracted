# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 14 };
use DirDB::FTP;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.



ok(my $ftp = new DirDB::FTP 'tipjar.com','blat','test0');

ok(tie my %dcty, DirDB::FTP => $ftp, "/DDtest$$");

ok($$,$dcty{pid}->{pad}->{foo} = $$);
ok($$,$dcty{pid}->{pad}->{foo} );
ok(my $r = delete $dcty{pid} );
ok($$, $r->{pad}->{foo});


# print "\nCLEARING\n";
%dcty = ();

ok(tie my %dct, DirDB::FTP => $ftp, "/");

ok(HASH => ref($dct{"DDtest$$"}));


# print "\nDelete slice test\n";
@dcty{1..5} = qw{fee fi fo fum five};
# print "fi fo? ",delete( @dcty{2,3}),"\n";
ok("fi fo","@{[delete( @dcty{2,3})]}");

# print "fee fum five? ", (grep {defined $_} @dcty{1..5}),"\n";
ok( "fee fum five", "@{[grep {defined $_} @dcty{1..5}]}");

# my $$x = "reference test\n";
my $x = \"reference test\n";
# print $$x;
eval { $dcty{reftest} = $x };
ok($@);

my %x;
$x{something}='else';
$dcty{X} = \%x;	# should tie %x to dcty/X
$x{fruit} = 'banana';
ok('banana',$dcty{X}->{fruit});


# print "complex delete test\n";
my $href = delete $dct{"DDtest$$"};
# print "href is $href\n";
# print "has keys @{[keys %$href]}\n";
# print "has values @{[values %$href]}\n";
ok('banana',$href->{X}->{fruit});



