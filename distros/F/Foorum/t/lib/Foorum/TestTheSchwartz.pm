package Foorum::TestTheSchwartz;

use strict;
use warnings;
use base qw/Exporter/;
use Test::More;
use FindBin qw/$Bin/;
use DBI;
our @EXPORT = ( @Test::More::EXPORT, 'run_test' );

eval 'require DBD::SQLite';    ## no critic (ProhibitStringyEval)
plan skip_all => 'this test requires DBD::SQLite' if $@;
eval 'require File::Temp';     ## no critic (ProhibitStringyEval)
plan skip_all => 'this test requires File::Temp' if $@;
eval 'require TheSchwartz::Moosified;';    ## no critic (ProhibitStringyEval)
plan skip_all => 'this test requires TheSchwartz::Moosified' if $@;

sub run_test {
    my $code = shift;
    my $db_file = File::Spec->catfile( $Bin, '..', 'lib', 'Foorum',
        'theschwartz.db' );
    my $dbh
        = DBI->connect( "dbi:SQLite:dbname=$db_file", '', '',
        { RaiseError => 1 } )
        or die $DBI::err;

    # work around for DBD::SQLite's resource leak
    tie my %blackhole, 'Foorum::TestTheSchwartz::Blackhole';
    $dbh->{CachedKids} = \%blackhole;

    $code->($dbh);    # do test

    $dbh->disconnect;
}

{

    package Foorum::TestTheSchwartz::Blackhole;
    use base qw/Tie::Hash/;
    sub TIEHASH { bless {}, shift }
    sub STORE { }     # nop
    sub FETCH { }     # nop
}

1;

