#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;

BEGIN {
    use_ok('Debian::Control::FromCPAN');
    use_ok('Debian::Dependency');
};

my $ctl = 'Debian::Control::FromCPAN';
my $dep = 'Debian::Dependency';

dies_ok {
    $ctl->prune_simple_perl_dep( $dep->new('perl|perl-modules') )
} 'prune_simple_perl_dep croaks on alternatives';

is( $ctl->prune_perl_dep( $dep->new('perl-modules (>= 5.16)') ) . '',
    'perl (>= 5.16)',
    'perl-modules is converted to perl'
);

is( $ctl->prune_perl_dep( $dep->new('perl-modules (>= 5.16)|foo') ) . '',
    'perl (>= 5.16) | foo',
    'perl-modules is converted to perl in alternatives'
);

is( $ctl->prune_perl_dep( $dep->new('perl-base') ),
    undef, 'plain dependency on perl-base is redundant' );

is( $ctl->prune_perl_dep( $dep->new('perl'), 1 ) . '',
    'perl', 'perl is not build-essential' );

is( $ctl->prune_perl_dep( $dep->new('perl-modules'), 1 ) . '',
    'perl', 'perl-modules is not build-essential' );

is( $ctl->prune_perl_dep( $dep->new('foo|perl-modules') ),
    undef, 'redundant alternative makes redundant the whole' );

is( $ctl->prune_perl_dep( $dep->new('perl (>= 5.14.1)') ),
    undef, 'perl 5.14.1 is ancient' );

is( $ctl->prune_perl_dep( $dep->new('perl (= 5.14.1)') ) . '',
    'perl (= 5.14.1)',
    'perl =5.14.1 is left intact'
);

is( ( $ctl->find_debs_for_modules( { 'ExtUtils::ParseXS' => '3.08' } ) )[0]
        . '',
    'perl (>= 5.15.6)',
    'ExtUtils::ParseXS 3.08 is in perl 5.15.6'
);
