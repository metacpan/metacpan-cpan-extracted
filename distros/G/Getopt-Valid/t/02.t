#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;
use FindBin qw/ $Bin /;
use lib "$Bin/../lib";
use Data::Dumper;

# check module
use_ok( 'Getopt::Valid' );

my $input_ref = _get_input( 1 );
ok(
    scalar( grep {
        defined $input_ref->{ $_ }
        && $input_ref->{ $_ } eq 'arg'
    } qw/ some_arg other_arg with_underscore / ) == 3,
    'Replaced with underscore'
);

$input_ref = _get_input( 0 );
ok(
    scalar( grep {
        defined $input_ref->{ $_ }
        && $input_ref->{ $_ } eq 'arg'
    } qw/ some-arg other-arg with_underscore / ) == 3,
    'Not Replaced with underscore'
);





sub _get_input {
    my ( $underscore ) = @_;
    my %validator = (
        name       => 'Test',
        version    => '0.1.0',
        underscore => $underscore,
        struct     => [
            'some-arg|s=s'        => undef,
            'other-arg|o=s'       => undef,
            'with_underscore|w=s' => undef
        ]
    );
    my $underscore_str = $underscore ? 'Underscore' : 'No underscore';
    my $v = Getopt::Valid->new( \%validator );
    @ARGV = qw/ --some-arg arg --other-arg arg --with_underscore arg /;
    $v->collect_argv;
    $v->validate;
    return $v->valid_args();
}