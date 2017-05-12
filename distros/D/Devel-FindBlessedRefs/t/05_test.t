
use strict;
use Test;
use Devel::FindBlessedRefs qw(:all);

plan tests => 5;

my $testar = [
    (bless {test=>"yes1"}, "MyTestPackage"),
    (bless {test=>"yes2"}, "MyTestPackage"),
];

my @t = sort {$a->{test} cmp $b->{test}} find_refs("MyTestPackage");
ok( $t[0]{test}, "yes1" );
ok( $t[1]{test}, "yes2" );

# make sure @t doesn't contain weak refs not weak refs
$testar = [];
my @u = sort {$a->{test} cmp $b->{test}} find_refs("MyTestPackage");
ok( $u[0]{test}, "yes1" );
ok( $u[1]{test}, "yes2" );

# make sure the @t/@u are still mortal
@u = @t = ();
my @v = sort {$a->{test} cmp $b->{test}} find_refs("MyTestPackage");
ok( @v == 0 );
