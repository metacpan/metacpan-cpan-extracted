#!perl
use warnings;
use strict;

use Test::More tests => 9;
use File::Copy qw(copy);

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $f = 't/sample.data';
my $wf = 't/write_sample.data';

copy $f, $wf;

{
    open my $fh, '<', $f or die $!;
    my @data = <$fh>;
    close $fh or die $!;

    open my $wfh, '>', $wf or die $!;

    for (@data){
        if (/sub seven/){
            s/seven/xxxxx/;
        }
        print $wfh $_;
    }

    close $wfh or die $!;
}
#2
eval {
    open my $wfh, '<', $wf
      or die "Can't open test written file $wf: $!";
};
ok (! $@, "copy of test sample file ok" );

open my $wfh, '<', $wf or die $!;

#3
my $fh;

eval {
    open $fh, '<', $f
      or die "Can't open original test file $f: $!";
};
ok (! $@, "can open orig test file after tie/untie/copy" );

my @wf = <$wfh>;
my @f = <$fh>;

my $count = scalar @f;
my @changes;

#4
for (0..$count){
    if ($wf[$_] and $wf[$_] ne $f[$_]){
        push @changes, $wf[$_];
    }
}
is ( scalar(@changes), 1, "search/replace does the right thing, in the right spot" );

#5
eval { close $fh; };
ok (! $@, "no problem closing the original test read file" );
close $fh;

#6
eval { close $wfh; };
ok (! $@, "no problem closing the test write file" );
close $wfh;

#7
eval { unlink $wf };
ok (! $@, "no problem deleting the test write file" );

#8
eval { open my $wfh, '<', $wf or die "Can't open $wfh: $!"; };
ok ($@, "after unlink of test write file, it can't be opened" );

#9
is (@changes, 1, "search_replace on one line replaces only one line" );

