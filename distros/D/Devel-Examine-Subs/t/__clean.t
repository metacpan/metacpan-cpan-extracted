#!perl
use warnings;
use strict;

use Test::More;
use File::Copy qw(copy);

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

unlink 't/write_sample.data';

eval { 
    open my $copy_fh, '<', 't/write_sample.data'
      or die "Can't open the write test copied file: $!";
};

like ( $@, qr/open the write/, "Test sample.data unlinked/deleted successfully" );

my @files_to_delete = qw(
    t/replace_copy.data
    t/sample.data.bak
    t/sample.data.orig
    t/search_replace.data
    t/search_replace_cref.data
    t/search.replace.data.bak
    t/inject_after.data
    t/inject.debug
    t/test.bak
    t/test.data
    t/core_dump.debug
    t/cache_dump.debug
    t/config_dump.debug
    t/engine_dump.debug
    t/post_proc_dump.debug
    t/pre_proc_dump.debug
    t/remove.data
    t/add_func_engine.data
    t/add_func_postproc.data
    t/add_func_preproc.data
);
my @bak_glob = glob "*.bak";

push @files_to_delete, @bak_glob;

for (@files_to_delete){
    eval { unlink $_ if -f $_; };
    ok (! $@, "test file >>$_<< deleted ok" );
}

done_testing();
