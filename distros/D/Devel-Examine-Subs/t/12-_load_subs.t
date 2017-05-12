#!perl
use warnings;
use strict;

use Test::More tests => 6;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $file = 't/sample.data';
my $des = Devel::Examine::Subs->new(file => $file);
my $struct = $des->run();

{#2
    ok ( ref($struct) eq 'HASH', "complete structure is a hashref" );
}
{#3
    ok ( ref($struct->{$file}) eq 'HASH', "top level of struct are hashes" );
}
{#5
    my $sub = 'one';
    ok ( ref($struct->{$file}{subs}) eq 'HASH', "'subs' hard container is a hash" );
    ok ( ref($struct->{$file}{subs}{$sub}) eq 'HASH', "\$sub 3rd level is hash" );
    ok ( ref($struct->{$file}{subs}{$sub}{code}) eq 'ARRAY', "code 3rd level is array" );

}
