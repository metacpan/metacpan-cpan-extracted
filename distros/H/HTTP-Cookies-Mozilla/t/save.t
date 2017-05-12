use Test::More 0.98;
use Text::Diff;

use HTTP::Cookies::Mozilla;

my $class = 'HTTP::Cookies::Mozilla';
use_ok( $class );

my $dist_file = 't/cookies.txt';
my $save_file = 't/cookies2.txt';

my %Domains = qw( .ebay.com 2 .usatoday.com 3 );


my $jar = HTTP::Cookies::Mozilla->new( File => $dist_file );
isa_ok( $jar, 'HTTP::Cookies::Mozilla' );

my $result = $jar->save( $save_file );

my $diff = Text::Diff::diff( $dist_file, $save_file );
my $same = not $diff;
ok( $same, 'Saved file is same as original' );
print STDERR $diff;

END { unlink $save_file }

done_testing();
