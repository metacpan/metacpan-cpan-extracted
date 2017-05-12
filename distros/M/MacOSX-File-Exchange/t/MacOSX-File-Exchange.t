use Test::More
    tests => 14;

BEGIN {
    use_ok(MacOSX::File::Exchange => qw(:all));
};

my(@unlink,@filenames,@linknames,$order);

END {
    unlink(@unlink) if @unlink;
}

sub didexchange
{
    my($neworder,$result);

    foreach my $ix (0 .. 1) {
	my($fh, $got);

	open($fh, "<", $filenames[$ix])
	    or die "$filenames[$ix]: open: $!\n";
	$got = read($fh, $neworder, 1, $ix);
	defined($got)
	    or die "$filenames[$ix]: read: $!\n";
	$got
	    or die "$filenames[$ix]: read: Unexpected EOF\n";
	close($fh);
    }
    $result = $neworder eq reverse($order);
    $order = $neworder;
    $result;
}

ok(defined(&FSOPT_NOFOLLOW),
   "constant import");

foreach my $ix (0..1) {
    my($fh);

    $filenames[$ix] = "file$$-$ix";
    open($fh, ">", $filenames[$ix])
        or die "$filenames[$ix]: open: $!\n";
    push(@unlink, $filenames[$ix]);
    print $fh $ix
        or die "$filenames[$ix]: print: $!\n";
    close($fh)
        or die "$filenames[$ix]: close: $!\n";
    $linknames[$ix] = "link$$-$ix";
    symlink($filenames[$ix], $linknames[$ix])
	or die "$linknames[$ix]: symlink: $!\n";
    push(@unlink, $linknames[$ix]);
    $order .= $ix;
}

ok(exchangedata(@filenames),
   "default flags");
ok(didexchange(),
    "default flags did exchange");

ok(exchangedata(@filenames, 0),
   "explicit 0 flags");
ok(didexchange(),
   "explicit 0 flags did exchange");

ok(exchangedata(@filenames, FSOPT_NOFOLLOW),
   "explicit NOFOLLOW flags");
ok(didexchange(),
   "explicit NOFOLLOW flags did exchange");

ok(exchangedata(@linknames),
   "default flags through links");
ok(didexchange(),
   "default flags through links did exchange");

ok(exchangedata(@linknames, 0),
   "explicit 0 flags through links");
ok(didexchange(),
   "explicit 0 flags through links did exchange");

ok(! exchangedata(@linknames, FSOPT_NOFOLLOW),
   "explicit NOFOLLOW flags through links");
ok(! didexchange(),
   "explicit NOFOLLOW flags through links didn't exchange");

