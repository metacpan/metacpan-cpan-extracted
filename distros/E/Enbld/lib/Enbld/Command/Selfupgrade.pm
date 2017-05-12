package Enbld::Command::Selfupgrade;

use strict;
use warnings;

use 5.010001;

use File::Spec;

use parent qw/Enbld::Command/;

require Enbld::Home;

sub do {
    Enbld::Home->initialize;

    my $cpanm = File::Spec->catfile( Enbld::Home->etc, 'cpanm' );

    download_cpanm() unless ( -e $cpanm );

    say "=====> Upgrade Enbld.";

    system( '/usr/bin/perl', $cpanm, 'Enbld', '-L', Enbld::Home->extlib );

    say "=====> Finish upgrade.";

    return $_[0];
}

sub download_cpanm {
    $File::Fetch::BLACKLIST = [ qw|lwp httptiny| ];

    my $ff       = File::Fetch->new( uri => 'http://xrl.us/cpanm' );
    my $where    = $ff->fetch( to => Enbld::Home->etc ) or die $ff->error;

    return $where;
}

1;
