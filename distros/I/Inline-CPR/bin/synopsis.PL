use strict;
use File::Path;

my $bin = shift @ARGV;

mkpath "./examples/";
open OUT, "> ./examples/synopsis.cpr"
  or die "Can't open./examples/synopsis.pl for output\n";
print OUT <<END;
#!$bin/cpr

int main(void) {
        
    printf("Hello World, I'm running under Perl version %s\\n",
           CPR_eval("use Config; \$Config{version}")
          );

    return 0;
}
END

close OUT;
chmod 0755, "./examples/synopsis.cpr";
