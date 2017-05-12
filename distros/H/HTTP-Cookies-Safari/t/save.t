use Test::More tests => 2;
use Text::Diff;

use HTTP::Cookies::Safari;

my $dist_file = 't/Cookies.plist';
my $save_file = 't/Cookies2.plist';

my %Domains = qw( .cnn.com 1 .usatoday.com 3 );


my $jar = HTTP::Cookies::Safari->new( File => $dist_file );
isa_ok( $jar, 'HTTP::Cookies::Safari' );

my $result = $jar->save( $save_file );

TODO: {
local $TODO = "How can I compare these files?";
my $diff = Text::Diff::diff( $dist_file, $save_file );
my $same = not $diff;
ok( $same, 'Saved file is same as original' );
#print STDERR $diff;
}

END { unlink $save_file }
