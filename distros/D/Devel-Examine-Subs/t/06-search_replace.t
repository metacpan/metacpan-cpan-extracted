#!perl
use warnings;
use strict;

use Carp;
use Test::More tests => 40;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my %params = (
                file => 't/sample.data',
                copy => 't/search_replace.data',
                post_proc => ['file_lines_contain', 'subs', 'objects'],
                engine => 'search_replace',
#                engine_dump => 1,
              );

my $des = Devel::Examine::Subs->new(%params);
my $struct;

eval {
    $struct = $des->search_replace();
};

ok ($@, "search_replace() croaks if a substitution cref isn't sent in" );

undef $@;

my $cref = sub { $_[0] =~ s/this/that/g; };
$struct = $des->search_replace(exec => $cref);

ok ( ref($struct) eq 'ARRAY', "search_replace engine returns an aref" );
ok ( ref($struct->[0]) eq 'ARRAY', "elems of search_replace return are arefs" );
is ( @{$struct->[0]}, 2, "only two elems in each elem in search_replace return" );

for (0..4){
    is (@{$struct->[$_]}, 2, "all elems in search_replace return contain 2 elems" );
    ok ($struct->[$_][0] =~ /this/, "first elem of each elem in s_r contains search" );
    ok ($struct->[$_][1] =~ /that/, "first elem of each elem in s_r contains replace" );
}

delete $params{engine};
delete $params{post_proc};

my $m_struct = $des->search_replace(exec => $cref);

ok ( ref($m_struct) eq 'ARRAY', "search_replace() returns an aref" );
ok ( ref($m_struct->[0]) eq 'ARRAY', "elems of search_replace() return are arefs" );
is ( @{$m_struct->[0]}, 2, "only two elems in each elem in search_replace() return" );

for (0..4){
    is (@{$m_struct->[$_]}, 2, "all elems in search_replace() return contain 2 elems" );
    ok ($m_struct->[$_][0] =~ /this/, "first elem of each elem in s_r() contains search" );
    ok ($m_struct->[$_][1] =~ /that/, "first elem of each elem in s_r() contains replace" );
}

{

    undef %params;

    my $des = Devel::Examine::Subs->new(%params);

    eval {
        $cref = sub {};
        $des->search_replace(code => $cref);
    };

    like ($@, qr/without specifying a file/, "search_replace() croaks if no file is sent in" );


}
{
    my $des = Devel::Examine::Subs->new(file => 't/sample.data');

    eval {
        $des->search_replace;
    };

    like ($@, qr/code reference/, "search_replace() dies if it doesn't see exec param");
}
