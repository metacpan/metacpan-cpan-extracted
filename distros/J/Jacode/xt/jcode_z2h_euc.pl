sub BEGIN {
    eval q<
        use FindBin;
        use lib "$FindBin::Bin/../lib";
    >;
}
use Jacode;

while (<>) {
    chop;
    Jacode::convert(*_, 'euc', 'sjis', 'h');
    print $_, "\n";
}

1;
__END__
