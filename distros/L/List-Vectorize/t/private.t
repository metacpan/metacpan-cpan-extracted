use Test::More tests => 42;
use strict;

BEGIN { use_ok('List::Vectorize') }

my $p = [0.01, 0.02, 0.05, 0.7];
my $ecd = List::Vectorize::_ecdf($p);
is_deeply($ecd, [0.01, 0.03, 0.08, 0.78]);


my $i = List::Vectorize::_get_index_from_p(0.005, $ecd);
is($i, 0);
$i = List::Vectorize::_get_index_from_p(0.01, $ecd);
is($i, 1);
$i = List::Vectorize::_get_index_from_p(0.015, $ecd);
is($i, 1);
$i = List::Vectorize::_get_index_from_p(0.03, $ecd);
is($i, 2);
$i = List::Vectorize::_get_index_from_p(0.8, $ecd);
is($i, 3);

is(List::Vectorize::is_numberic(1)+0, 1);
is(List::Vectorize::is_numberic(1.1)+0, 1);
is(List::Vectorize::is_numberic(-1)+0, 1);
is(List::Vectorize::is_numberic(-1.1)+0, 1);

is(List::Vectorize::is_array_ref([1,2])+0, 1);
is(List::Vectorize::is_array_ref([])+0, 1);
is(List::Vectorize::is_array_ref(1)+0, 0);
is(List::Vectorize::is_array_ref(undef)+0, 0);

is(List::Vectorize::is_hash_ref({a=>1, b=>2})+0, 1);
is(List::Vectorize::is_hash_ref({})+0, 1);
is(List::Vectorize::is_hash_ref(1)+0, 0);
is(List::Vectorize::is_hash_ref(undef)+0, 0);

is(List::Vectorize::is_scalar_ref(\"a")+0, 1);
is(List::Vectorize::is_scalar_ref([])+0, 0);
is(List::Vectorize::is_scalar_ref(1)+0, 0);
is(List::Vectorize::is_scalar_ref(undef)+0, 0);

my $f = sub {1};
is(List::Vectorize::is_code_ref($f)+0, 1);
is(List::Vectorize::is_code_ref(sub{1})+0, 1);
is(List::Vectorize::is_code_ref(1)+0, 0);
is(List::Vectorize::is_code_ref(undef)+0, 0);

my $fh = *STDIN;
is(List::Vectorize::is_glob_ref(\*STDIN)+0, 1);
is(List::Vectorize::is_glob_ref(\$fh)+0, 1);
is(List::Vectorize::is_glob_ref(1)+0, 0);
is(List::Vectorize::is_glob_ref(undef)+0, 0);

is(List::Vectorize::is_ref_ref(\[1,2])+0, 1);
is(List::Vectorize::is_ref_ref(\\1)+0, 1);
is(List::Vectorize::is_ref_ref(1)+0, 0);
is(List::Vectorize::is_ref_ref(undef)+0, 0);

is(List::Vectorize::type_of(1), "SCALAR");
is(List::Vectorize::type_of([1, 2, 3]), "ARRAY_REF");
is(List::Vectorize::type_of({a=>1, b=>2}), "HASH_REF");
is(List::Vectorize::type_of(\\1), "REF_REF");
is(List::Vectorize::type_of(*STDIN), "GLOB");
is(List::Vectorize::type_of($fh), "GLOB");
is(List::Vectorize::type_of(\$fh), "GLOB_REF");

diag('testing private subroutines');