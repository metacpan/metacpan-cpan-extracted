sub BEGIN {
    eval q<
        use FindBin;
        use lib "$FindBin::Bin/../lib";
    >;
}
use Jacode;

while (<>) {
    chop;
    Jacode::convert(*_, 'sjis', 'euc');
    print $_, "\n";
}

1;
__END__
