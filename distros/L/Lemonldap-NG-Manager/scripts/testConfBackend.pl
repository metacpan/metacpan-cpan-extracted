#!/usr/bin/perl

use strict;
use Getopt::Long;
use Lemonldap::NG::Common::Conf;
use Test::More tests => 12;

my %opts;
my $result = GetOptions( \%opts, 'help|h', 'module|m=s', 'options|o=s' );

if ( $opts{help} or not( $opts{module} ) ) {
    print STDERR qq/
               ## Lemonldap::NG configuration module tester ##

Usage:
    $0 --module=<New> --options='{ some => "parameter" }'

<New> must be the last word of Perl package: file must be named
Lemonldap::NG::Common::Conf::New

/;
    exit 1;
}

my $module = $opts{module};

my $args = eval $opts{options} // {};

my $currentConf;

# 1
ok(
    $currentConf = Lemonldap::NG::Common::Conf->new( {
            confFile => 'test/lemonldap-ng.ini',
            noCache  => 1,
        }
    ),
    'Load test conf module'
);
$Lemonldap::NG::Common::Conf::msg = '';

# 2
my $new;
ok(
    $new = Lemonldap::NG::Common::Conf->new( {
            type => $module,
            %$args,
            force       => 1,
            noCache     => 1,
            cfgNumFixed => 1,
        }
    ),
    'Load new module'
);

# 3
ok( ref($new), "New conf object ($Lemonldap::NG::Common::Conf::msg)" );
$Lemonldap::NG::Common::Conf::msg = '';

# 4
my $cfgNum;
ok( $cfgNum = $currentConf->lastCfg(), 'Test configuration available' );

# 5
my $conf;
ok(
    $conf = $currentConf->getConf( { cfgNum => $cfgNum } ),
    "Get test conf ($Lemonldap::NG::Common::Conf::msg)"
);
$Lemonldap::NG::Common::Conf::msg = '';

$conf->{cfgNum}++;
my $r;

# 6
eval { $new->delete( $conf->{cfgNum} ) };
ok( $r = $new->saveConf($conf),
    "Store conf in new module ($Lemonldap::NG::Common::Conf::msg)" );
$Lemonldap::NG::Common::Conf::msg = '';

# 7
ok( $r == $conf->{cfgNum}, 'Return cfgNum' );

# 8
ok( [ $new->available() ],
    "Some conf are available ($Lemonldap::NG::Common::Conf::msg)" );
$Lemonldap::NG::Common::Conf::msg = '';

# 9
ok( $r == $new->lastCfg(),
    "New conf is available ($Lemonldap::NG::Common::Conf::msg)" );
$Lemonldap::NG::Common::Conf::msg = '';

# 10
my $nc;
ok(
    $nc = $new->getConf( { cfgNum => $r } ),
    "Get new conf ($Lemonldap::NG::Common::Conf::msg)"
);
$Lemonldap::NG::Common::Conf::msg = '';

# 11
ok( $nc->{cfgNum} == $r, 'Good cfgNum in new conf' );

# 12
ok( $new->delete($r), "Delete conf ($Lemonldap::NG::Common::Conf::msg)" );
$Lemonldap::NG::Common::Conf::msg = '';

