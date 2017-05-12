use Test::More tests => 2;
use Text::Diff;

use HTTP::Cookies::Omniweb;

my $dist_file = 't/Cookies.xml';
my $save_file = 't/Cookies2.xml';

my %Domains = qw( .ebay.com 2 .usatoday.com 3 );

my $jar = HTTP::Cookies::Omniweb->new( File => $dist_file );
isa_ok( $jar, 'HTTP::Cookies::Omniweb' );

my $result = $jar->save( $save_file );

my $diff = Text::Diff::diff( $dist_file, $save_file );
my $same = not $diff;
ok( $same, 'Saved file is same as original' );
print STDERR $diff;

END { unlink $save_file }
