# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Geo-Demo-Zipskinny.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
BEGIN { use_ok('Geo::Demo::Zipskinny') };
BEGIN { use_ok('Data::Dumper') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok ( my $zip = new Geo::Demo::Zipskinny(), 'created object ok' );
ok ( -f 'data/99546.html', 'data input file exists' );
ok ( open( my $fh, 'data/99546.html' ), 'opened data input file' );
ok ( my $content = join('', <$fh>), 'read data input file' );
ok ( my $res = $zip->parse( $content ), 'parsed input ok' );

ok ( $res->{'general'}{'city'} eq 'ADAK' );
ok ( $res->{'income'}{'200000+'} == 0 );
ok ( $res->{'race'}{'Native American'} == 34 );
ok ( $res->{'age'}{'male'}{'0-9'} == 7.3 );
ok ( $res = $zip->get('00601') );
#warn Data::Dumper::Dumper( $res );
