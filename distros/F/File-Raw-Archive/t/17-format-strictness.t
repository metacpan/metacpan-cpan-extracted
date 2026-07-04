#!perl
# format option strictness:
#   ustar - reject any field overflow (long names, large size/uid)
#   gnu   - allow long names via @LongLink, reject overflow that needs PAX
#   pax   - emit a PAX header for every entry needing escalation
#   auto  - smallest emission (default)
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);
my $longname = 'sub/' . ('p' x 240) . '.txt';

# format=ustar: long names croak.
{
    my $tar = "$dir/ustar.tar";
    my $w = File::Raw::Archive->create($tar, format => 'ustar');
    my $err;
    eval { $w->add(name => $longname, content => 'x'); 1 } or $err = $@;
    ok($err, 'format=ustar croaks on long name');
    $w->close;
}

# format=ustar: large uid croaks too (uid > 2097151 doesn't fit ustar's octal field).
{
    my $tar = "$dir/ustar-uid.tar";
    my $w = File::Raw::Archive->create($tar, format => 'ustar');
    my $err;
    eval { $w->add(name => 'big.txt', content => 'x', uid => 5_000_000); 1 } or $err = $@;
    ok($err, 'format=ustar croaks on uid > 2M');
    $w->close;
}

# format=gnu: long names OK (via @LongLink) but large uid croaks because
# only PAX can carry it.
{
    my $tar = "$dir/gnu.tar";
    my $w = File::Raw::Archive->create($tar, format => 'gnu');
    eval { $w->add(name => $longname, content => 'longname-content'); 1 }
        or fail("format=gnu rejected long name: $@");
    my $err;
    eval { $w->add(name => 'huge.txt', content => 'x', uid => 5_000_000); 1 } or $err = $@;
    ok($err, 'format=gnu croaks on uid > 2M (PAX needed, not @LongLink)');
    $w->close;
}

# format=pax: forces PAX header for every entry needing escalation,
# even when @LongLink would have sufficed.
{
    my $tar = "$dir/pax.tar";
    my $w = File::Raw::Archive->create($tar, format => 'pax');
    $w->add(name => $longname, content => 'pax-content');
    $w->close;

    # Verify a PAX 'x' typeflag block exists at offset 156 somewhere.
    open my $fh, '<:raw', $tar or die $!;
    my $found_x = 0;
    while (read($fh, my $block, 512) == 512) {
        last if $block eq "\0" x 512;
        $found_x++ if substr($block, 156, 1) eq 'x';
    }
    close $fh;
    ok($found_x >= 1, 'format=pax emits at least one PAX x header');

    my $r = File::Raw::Archive->open($tar);
    my $e = $r->next;
    is($e->name, $longname, 'pax: long name read back exactly');
    is($e->slurp, 'pax-content', 'pax: content readable');
    $r->close;
}

# format=auto: long-name-only escalation should NOT use PAX (uses @LongLink).
{
    my $tar = "$dir/auto.tar";
    my $w = File::Raw::Archive->create($tar, format => 'auto');
    $w->add(name => $longname, content => 'auto-content');
    $w->close;

    open my $fh, '<:raw', $tar or die $!;
    my ($found_x, $found_L) = (0, 0);
    while (read($fh, my $block, 512) == 512) {
        last if $block eq "\0" x 512;
        my $tflag = substr($block, 156, 1);
        $found_x++ if $tflag eq 'x';
        $found_L++ if $tflag eq 'L';
    }
    close $fh;
    is($found_x, 0, 'format=auto avoids PAX for name-only overflow');
    ok($found_L >= 1, 'format=auto uses GNU @LongLink for long name');

    my $r = File::Raw::Archive->open($tar);
    my $e = $r->next;
    is($e->name, $longname, 'auto: long name read back');
    $r->close;
}

done_testing;
