#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use File::Digest qw(digest_files);
use File::Temp qw(tempdir);
use File::Slurper qw(write_text);

my $dir = tempdir(CLEANUP=>1);
write_text("$dir/1", "one");
write_text("$dir/2", "two");

subtest "unknown algoritm -> dies" => sub {
    dies_ok {
        digest_files(
            algorithm=>"foo", files=>["$dir/1", "$dir/2", "$dir/3"],
        );
    };
};

subtest "algoritm md5" => sub {
    my $res = digest_files(
        algorithm=>"md5", files=>["$dir/1", "$dir/2", "$dir/3"],
    );
    is($res->[0], 207) or diag explain $res;
    is_deeply(
        $res->[2],
        [
            {file=>"$dir/1", digest=>"f97c5d29941bfb1b2fdab0874906ab82"},
            {file=>"$dir/2", digest=>"b8a9f715dbb64fd5c56e7783c6820a61"},
        ],
    );
};

subtest "algoritm Digest (MD5)" => sub {
    my $res = digest_files(
        algorithm=>"Digest", digest_args=>['MD5'], files=>["$dir/1", "$dir/2", "$dir/3"],
    );
    is($res->[0], 207) or diag explain $res;
    is_deeply(
        $res->[2],
        [
            {file=>"$dir/1", digest=>"f97c5d29941bfb1b2fdab0874906ab82"},
            {file=>"$dir/2", digest=>"b8a9f715dbb64fd5c56e7783c6820a61"},
        ],
    );
};

subtest "algoritm sha1" => sub {
    my $res = digest_files(
        algorithm=>"sha1", files=>["$dir/1", "$dir/2", "$dir/3"],
    );
    is($res->[0], 207) or diag explain $res;
    is_deeply(
        $res->[2],
        [
            {file=>"$dir/1", digest=>"fe05bcdcdc4928012781a5f1a2a77cbb5398e106"},
            {file=>"$dir/2", digest=>"ad782ecdac770fc6eb9a62e44f90873fb97fb26b"},
        ],
    );
};

subtest "algoritm sha224" => sub {
    my $res = digest_files(
        algorithm=>"sha224", files=>["$dir/1", "$dir/2", "$dir/3"],
    );
    is($res->[0], 207) or diag explain $res;
    is_deeply(
        $res->[2],
        [
            {file=>"$dir/1", digest=>"7371e4047e2a524ba3f417cc5dedd64a5070638c1991b0c0b196f9af"},
            {file=>"$dir/2", digest=>"1fe7b53e290b5d08cecb164538911b71c2f069f9c8eb0e23be313ae2"},
        ],
    );
};

subtest "algoritm sha256" => sub {
    my $res = digest_files(
        algorithm=>"sha256", files=>["$dir/1", "$dir/2", "$dir/3"],
    );
    is($res->[0], 207) or diag explain $res;
    is_deeply(
        $res->[2],
        [
            {file=>"$dir/1", digest=>"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed"},
            {file=>"$dir/2", digest=>"3fc4ccfe745870e2c0d99f71f30ff0656c8dedd41cc1d7d3d376b0dbe685e2f3"},
        ],
    );
};

subtest "algoritm sha384" => sub {
    my $res = digest_files(
        algorithm=>"sha384", files=>["$dir/1", "$dir/2", "$dir/3"],
    );
    is($res->[0], 207) or diag explain $res;
    is_deeply(
        $res->[2],
        [
            {file=>"$dir/1", digest=>"5dbcbedb00d131a29e0593f976f2b43794293923919ad42766de817fec824a6262799fec8d04cb9b17c48e8eae912658"},
            {file=>"$dir/2", digest=>"0b5a10c7071b313d2feee9e3864155eabfc5494d1882a3284da1015af0cb648ef37c79c839d9fcb3120fd06e006a7be9"},
        ],
    );
};

subtest "algoritm sha512" => sub {
    my $res = digest_files(
        algorithm=>"sha512", files=>["$dir/1", "$dir/2", "$dir/3"],
    );
    is($res->[0], 207) or diag explain $res;
    is_deeply(
        $res->[2],
        [
            {file=>"$dir/1", digest=>"05f70341078acf6a06d423d21720f9643d5f953626d88a02636dc3a9e79582aeb0c820857fd3f8dc502aa8360d2c8fa97a985fda5b629b809cad18ffb62d3899"},
            {file=>"$dir/2", digest=>"928d50d1e24dab7cca62cfe84fcdcf9fc695160a278f91b5c0af22b709d82f8aa3b4955b3de9ba6d0a0eb7d932dc64c4d5c63fc2de87441ad2e5b929f9b67c5e"},
        ],
    );
};

subtest "algoritm sha512224" => sub {
    my $res = digest_files(
        algorithm=>"sha512224", files=>["$dir/1", "$dir/2", "$dir/3"],
    );
    is($res->[0], 207) or diag explain $res;
    is_deeply(
        $res->[2],
        [
            {file=>"$dir/1", digest=>"cc94ad2bf8fd8eaf788ceb4c036828b138bf54f876bf10782dc51577"},
            {file=>"$dir/2", digest=>"2f98aa1ea147926469afa2618d4cdd3ab256baec9575cd99d4239201"},
        ],
    );
};

subtest "algoritm sha512256" => sub {
    my $res = digest_files(
        algorithm=>"sha512256", files=>["$dir/1", "$dir/2", "$dir/3"],
    );
    is($res->[0], 207) or diag explain $res;
    is_deeply(
        $res->[2],
        [
            {file=>"$dir/1", digest=>"663c53aa2682638d9f41eddd25ddb82e714b1da9daa1ce4b3ef4455a8e42d8d3"},
            {file=>"$dir/2", digest=>"d22e87bb5c3c627912a1aa87cae1a68d14e6a6fb7925cbe53029086467381d9c"},
        ],
    );
};

subtest "algoritm crc32" => sub {
    my $res = digest_files(
        algorithm=>"crc32", files=>["$dir/1", "$dir/2", "$dir/3"],
    );
    is($res->[0], 207) or diag explain $res;
    is_deeply(
        $res->[2],
        [
            {file=>"$dir/1", digest=>"7a6c86f1"},
            {file=>"$dir/2", digest=>"11ca8a66"},
        ],
    );
};

done_testing;
