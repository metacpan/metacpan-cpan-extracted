use Test::More;

use v5.36;
use Config::INI::Reader;

use Loverl;

my $latest_version = '0.005';

my $config_hash     = Config::INI::Reader->read_file('dist.ini');
my $config_version  = $config_hash->{_}->{version};
my $changes_version = '';

my $changes_file = 'CHANGES';
open( FH, $changes_file ) or die $!;
my @changes_arr = <FH>;

foreach my $changes_arr (@changes_arr) {
    if ( $changes_arr =~ /\b$latest_version\b/ ) {
        $changes_version = $latest_version;
        last;
    }
}

close(FH);

is( $Loverl::VERSION, $latest_version,
    'checking if $Grizzly::VERSION is equal to $newest_version' );
is( $config_version, $latest_version,
    'checking if $config_version equal is to $newest_version' );
is( $changes_version, $latest_version,
    'checking if $changes_version equal is to $newset_versionc' );

done_testing();
