use strict;
use warnings;
use Data::Dump;
use lib '../lib', '../blib/arch', '../blib/lib';
use Dyn qw[:dcb];
$|++;
#
my $coderef = sub { warn 'Here'; return 88 };
my $cb      = dcbNewCallback( 'ifsdl)s', $coderef, 5 );

#my $cb = dcbNewCallback( 'i)s', $coderef, 5 );
#
warn $cb;
#
my $result = $cb->call( 12, 23.5, 3, 1.82, 9909 );    # Don't make these an array ref
warn;
#
warn $result;

#$cb->init();
warn;
{
    my $cb = dcbNewCallback(
        'i)v',
        sub { warn 'Here!' }

            #$coderef
        , 5
    );
    #
    warn $cb;
    #
    my $result = $cb->call(12);    # Don't make these an array ref

    #
    warn $result;
}
{
    my $cb = dcbNewCallback(
        'iZ)Z',
        sub {
            my ( $int, $name, $userdata ) = @_;

            #is $int, 100,    'int arg correct';
            #is $name, 'John', 'string arg is correct';
            ddx $userdata;
            return 'Hello, ' . $name;
        },
        [5]
    );
    my $result = $cb->call( 10, 'Bob' );
    warn $result;
}
