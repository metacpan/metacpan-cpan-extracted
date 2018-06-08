# script to inline a file containing source code into a C string
use strict;
use warnings;

exit main();

sub main {
    if (!@ARGV) {
        process(*STDIN);
    }
    else {
        foreach my $file (@ARGV) {
            open my $fh, $file or die "Could not open $file: $!";
            process($fh);
        }
    }
    return 0;
}

sub process {
    my ($fh) = @_;

    printf("static const char* js_src =\n");
    while (my $line = <$fh>) {
        chomp($line);
        $line =~ s/\\/\\\\/g;
        $line =~ s/"/\\"/g;
        printf("        \"%s\\n\"\n", $line);
    }
    printf("    ;\n");
}
