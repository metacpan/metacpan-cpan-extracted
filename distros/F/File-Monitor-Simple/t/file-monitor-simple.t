use Test::More 'no_plan';
use File::Monitor::Simple;
use File::Spec::Functions; # provides catfile
use Data::Dumper;

use strict;

my $watcher = File::Monitor::Simple->new(
        directory => 't',
        regex     => '\.txt$',
);

my $tmp_txt  = catfile('t', 'tmp.txt');
# fails RE
my $tmp_text = catfile('t', 'tmp.text');

# warm up
my @changed_files = $watcher->watch;

unlink $tmp_txt, $tmp_text; # just in case;
open (T1,">$tmp_txt") || die "couldn't open $tmp_txt: $!";
print T1 "new"; 
close (T1);

{
    my @changed_files = $watcher->watch;
    like($changed_files[0], qr/tmp.txt/, "basic test of adding a new file");
}

{
    my @changed_files = $watcher->watch;
    is_deeply(\@changed_files,[], "a new file disappears on the next watch") ;
}
{
     open (T1,">$tmp_text") || die "couldn't open $tmp_text: $!";
     print T1 "newer"; 
     close (T1);
    my @changed_files = $watcher->watch;
    is_deeply(\@changed_files,[], "a file that doesn't match the RE doesn't trigger it.") ;
}
{
    open (T2,">$tmp_txt") || die "couldn't open $tmp_txt: $!";
    print T2 "newer"; 
    close (T2);

    my @changed_files = $watcher->watch;
    like($changed_files[0], qr/tmp.txt/, "a changed file triggers the change.") 
        || diag  Dumper ('changed files:',\@changed_files);
}
{
    my @changed_files = $watcher->watch;
    is_deeply(\@changed_files,[], "a changed file disappears on the next watch") ;
}
{
    unlink $tmp_txt || diag "failed to unlink $!";
    my @changed_files = $watcher->watch;
    like($changed_files[0], qr/tmp.txt/, "a deleted file triggers the change.") ;
}
{
    my @changed_files = $watcher->watch;
    is_deeply(\@changed_files,[], "a deleted file disappears on the next watch") ;
}

END {
 unlink $tmp_txt, $tmp_text;
}
