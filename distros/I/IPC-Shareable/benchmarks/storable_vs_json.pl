#!/usr/bin/env perl
use warnings;
use strict;

use Benchmark qw(:all) ;
use Data::Dumper;
use IPC::Shareable;
use JSON qw(-convert_blessed_universally);
use Storable qw(freeze thaw);

if (@ARGV < 1){
    print "\n Need test count argument...\n\n";
    exit;
}

my %j_hash;
my %s_hash;

#timethese($ARGV[0],
#    {
#        json    => \&json,
#        store   => \&storable,
#    },
#);

cmpthese($ARGV[0],
    {
        json    => \&json,
        store   => \&storable,
    },
);

sub default {
     return {
        a => 1,
        b => 2,
        c => [qw(1 2 3)],
        d => {z => 26, y => 25},
    };
}
sub json {
    my $base_data = default();

    if (! %j_hash) {
        tie %j_hash, 'IPC::Shareable', {
            create     => 1,
            destroy    => 1,
            serializer => 'json'
        };
    }

    %j_hash = %$base_data;

    $j_hash{struct1} = {a => [qw(b c d)]};

    tied(%j_hash)->clean_up_all;
}
sub storable {
    my $base_data = default();

    if (! %s_hash) {
        tie %s_hash, 'IPC::Shareable', {
            create     => 1,
            destroy    => 1,
            serializer => 'storable'
        };
    }

    %s_hash = %$base_data;

    $s_hash{struct1} = {a => [qw(b c d)]};
#    $s_hash{struct2} = {a => [qw(b c d)]};
#    $s_hash{struct3} = {a => [qw(b c d)]};
#    $s_hash{struct4} = {a => [qw(b c d)]};
#    $s_hash{struct5} = {a => [qw(b c d)]};
#    $s_hash{struct6} = {a => [qw(b c d)]};
#    $s_hash{struct7} = {a => [qw(b c d)]};
#    $s_hash{struct8} = {a => [qw(b c d)]};

    tied(%s_hash)->clean_up_all;
}

__END__
