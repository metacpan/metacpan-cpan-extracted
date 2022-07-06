use Test::More tests => 3;

use v5.36;
use Config::INI::Reader;

use Grizzly;

my $newest_version = '0.111';

my $config_hash    = Config::INI::Reader->read_file('dist.ini');
my $config_version = $config_hash->{_}->{version};

my $changes_file = 'CHANGES';
open( FH, $changes_file ) or die $!;
my @changes_arr     = <FH>;
my $changes_version = $changes_arr[0];
$changes_version =~ s/^\s+|\s+$//g;

if ( $changes_version =~ /\b$newest_version\b/ ) {
    $changes_version = $newest_version;
}

is( $Grizzly::VERSION, $newest_version, 'compares $Grizzly::VERSION == $newest_version' );
is( $config_version, $newest_version,
    'compares $config_version == $newest_version' );
is( $changes_version, $newest_version,
    'compares $changes_version == $newset_versionc' );

close(FH);
