#!perl 
use warnings;
use strict;

use File::Copy;
use Data::Dumper;
use Test::More tests => 65;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $base_file = 't/sample.data';
my $work_file = 't/sub_def.data';
my $orig_file = 't/orig/sub_def.data';

eval { copy $base_file, $work_file; };

ok (! $@, "files copied ok");

my $des = Devel::Examine::Subs->new(
                    file => $work_file,
               );

my $code = ['trace();'];

$des->inject( inject_after_sub_def => $code);

open my $orig_fh, '<', $orig_file or die $!;
open my $work_fh, '<', $work_file or die $!;

my @work = <$work_fh>;
my @orig = <$orig_fh>;

close $work_fh;
close $orig_fh;

my $i = -1;

for my $e (@work){

    $i++;

    if ($i == 6) {
        ok ($e ne $orig[$i], "the broken line >$i< doesn't match" );
        next;
    }

    ok ($e eq $orig[$i], "Line $i in workfile matches orig file")
}


eval { unlink $work_file; };

ok (! $@, "files unlinked properly");
