sub BEGIN {
    eval q<
        use FindBin;
        use lib "$FindBin::Bin/../lib";
    >;
}
use Jacode;

while (<>) {
    chop;
    Jacode::convert(*_, 'jis', 'sjis', 'z');
    print $_, "\n";
}

1;
__END__
