#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

{
    open( my $fh, '>', 't/05-tests-01test.cleartext' );
    print $fh "#!/usr/bin/env perl\n";
    print $fh "use strict;\nuse warnings;\nuse Test::More;\nok(1, 'Testing small file');\ndone_testing();\n";
    close( $fh );
}
ok( 1, 'Normal test created' );

{
    open( my $fh, '>', 't/05-tests-02largefile.cleartext' );
    print $fh "#!/usr/bin/env perl\n";
    for( my $i = 0; $i < 65536; $i++ ) {
        print $fh " ";
    }
    print $fh "\nuse strict;\nuse warnings;\nuse Test::More;\nok(1, 'Testing large file');\ndone_testing();\n";
    close( $fh );
}
ok( 1, 'LargeFile test created' );

done_testing();
