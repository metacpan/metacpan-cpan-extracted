#!perl
use warnings;
use strict;

# for testing internal subs, either directly,
# or through an accessor

use Test::More tests => 5;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}
{#2
    my $des = Devel::Examine::Subs->new();
    eval { $des->has( file => 'badfile.none', search => 'text', ) };
    like ( $@, qr/Invalid file supplied/, "has() dies with error if file not found" );
}
{#2
    my $des = Devel::Examine::Subs->new();
    is ( ref $des, 'Devel::Examine::Subs', "new() instantiates a new blessed object" );
}
{#3-4
    my $des = _des(engine => '_test');

    my $cref = $des->_engine();

    is ( ref($cref), 'CODE', "new() will return an engine with {engine=>'engine'} param" );

    my $data = $cref->();

    is_deeply ({a=>1}, $data, "the return from the _test _engine() is what we expect" );
}
sub _des {  
    my $des =  Devel::Examine::Subs->new(@_); 
    return $des;
}

