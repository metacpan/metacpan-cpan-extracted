sub BEGIN {
    eval q<
        use FindBin;
        use lib "$FindBin::Bin/..";
    >;
}
require 'lib/jacode.pl';

while (<>) {
    chop;
    &jacode'convert(*_, 'sjis');
    print $_, "\n";
}

1;
__END__
