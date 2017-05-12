#!perl
use warnings;
use strict;

use Test::More tests => 3;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

    my $global_des = Devel::Examine::Subs->new(file => 't/sample.data', search => 'this', engine => '_test');

{#2
    $global_des->_config({engine => '_test_print'});
    ok ( $global_des->{params}{engine} eq '_test_print', "_config() properly sets \$self->{params}" );

}
{#3
    $global_des->_config({
                file => 't/sample.data',
                search => 'this',
                lines => 1,
                get => 'obj',
                test => 1,
              });

    is ( keys %{$global_des->{params}}, 6, "_config() sets \$self->{params}, and properly" );
}
{
    my $des = Devel::Examine::Subs->new(file => 't/sample.data');
    $des->run({clean_config => 1});
}
