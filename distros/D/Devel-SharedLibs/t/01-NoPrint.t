
use FindBin::libs;
use FindBin::libs   qw( base=t export=test_dir scalar );

use Test::More;
use File::Basename  qw( dirname );

my $print   = 'DEVEL_SHAREDLIBS_PRINT';

$ENV{ $print } = '';

my $exec = $test_dir . '/bin/exec-stdout';

-e $exec or BAIL_OUT "Missing test exec: '$exec'";

chomp ( my @output  = qx( $^X $exec 2>&1 ) );

ok ! $?, "$exec exits zero";

note "Output: $print = $ENV{ $print }\n", explain \@output;

ok ! $output, "False $print: no output.";

done_testing
__END__
