#!/usr/bin/perl

use lib qw(lib examples);

use Test::More tests => 6;

use_ok('datasource', 'data samples');

my $class = q(Iterator::BreakOn);
use_ok($class);

my %totals = (
    'AVILA'     =>  0.0,
    'BADAJOZ'   =>  0.0,
    'MADRID'    =>  0.0,
);

my $dh = 'datasource';
my $iter = $class->new( 'datasource'    => $dh->new(),
                        private         => \%totals,
                        getmethod       => 'get',
                        on_every        => \&_acum_location,
                        on_last         => \&_fix_float_numbers,
                    );

cmp_ok(ref($iter),'eq',$class, "${class}::new returns a valid object"); 

$iter->run();

cmp_ok($totals{AVILA},  "==","4089.84","total amount for AVILA");
cmp_ok($totals{BADAJOZ},"==",6081.22,"total amount for BADAJOZ");
cmp_ok($totals{MADRID}, "==","5353.03","total amount for MADRID");

sub _acum_location {
    my  $self   =   shift;
    my  $data   =   $self->item();
    my  $totals =   $self->private();
    my  $amount =   $data->get('amount');

    $totals->{$data->get('location')} += $amount if $amount;

    return;
}

sub _fix_float_numbers {
    my  $self   =   shift;
    my  $totals =   $self->private();

    foreach my $name (keys( %{totals} )) {
        $totals{$name} = sprintf("%0.2f", $totals{$name});
    }

    return;
}


