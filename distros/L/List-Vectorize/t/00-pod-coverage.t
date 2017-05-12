use Test::More;
use strict;

eval 'use Test::Pod::Coverage 1.04';
plan( skip_all =>'Test::Pod::Coverage 1.04 required for testing POD coverage' ) if ($@);

all_pod_coverage_ok({also_private => [qw(check_prototype
                                         is_array_ref
										 is_code_ref
										 is_glob_ref
										 is_hash_ref
										 is_numberic
										 is_ref_ref
										 is_scalar_ref
										 type_of)]});
