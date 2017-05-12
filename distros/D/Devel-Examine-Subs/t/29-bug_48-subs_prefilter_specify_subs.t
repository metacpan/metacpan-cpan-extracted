#!perl
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 35;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new();

my %params = (
            file => 't/sample.data',
        );

{#2
    my $res = $des->all(%params);
    ok ( ref($res) eq 'ARRAY', "After fix, all() still returns an array" );
}
{#3
    $params{include} = [qw(eight)];

    my $res = $des->all(%params);
    ok ( ref($res) eq 'ARRAY', "all() returns array after setting 'include' param" );
    is ( @$res, 1, "_proc() returns only a single sub when asked to via 'include'" );
}
{#2
    #delete $params->{include};
    $params{exclude} = [qw(two)];
    my $res = $des->all(%params);
   
    ok ((grep {$_ !~ /two/} @$res), "#FIXED!!!: this test shows that _config cleanup must be done! w/o removing 'inc', 'exc' breaks" );
}
{#3
    $params{include} = undef;
    $params{exclude} = [qw(two)];
    my $res = $des->all(%params);
   
    ok ( ! (grep {'two' eq $_} @$res), "excluded sub isn't included" );
    is ( @$res, 10, "_proc() returns correct data when used with 'exclude'" );
}
{#4
    $params{include} = undef;
    $params{exclude} = [qw(two four six eight)];
    my $res = $des->all(%params);
   
    for my $exc (@{ $params{exclude} }){ 
        ok ( ! (grep {$exc eq $_} @$res), "excluded sub >$exc< isn't included" );
    }
    is ( @$res, 7, "_proc() returns correct data when used with 'exclude'" );
}
{#5
    $params{include} = [qw(two four six eight)];
    $params{exclude} = undef;
    my $res = $des->all(%params);
   
    for my $inc (@{ $params{include} }){ 
        ok ((grep /$inc/, @$res), "included sub >$inc< is included" );
    }
    is ( @$res, 4, "_proc() returns correct data when used with 'include'" );
}
{#6
    $params{include} = [qw(two four six eight)];
    $params{exclude} = [qw(one five)];

    my $res = $des->all(%params);

    for my $item (@$res){   
        #ok ((grep /$item/, @{$params->{include}}), "included items not included" );
        ok ((! grep /$item/, @{$params{exclude}}), "excluded items not included" );
        is ( @$res, 9, "_proc() include with exclude does the right thing" );
    }
}
