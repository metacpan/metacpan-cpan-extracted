
use FindBin::libs;
use FindBin::libs   qw( base=t export=test_dir scalar );

use Test::More;
use File::Basename  qw( dirname );

my $print   = 'DEVEL_SHAREDLIBS_PRINT';

$ENV{ $print } = 1;

my $exec = $test_dir . '/bin/exec-stdout';

note "Test: '$exec'";

-e $exec or BAIL_OUT "Missing test exec: '$exec'";

chomp( my @output  = qx( $^X $exec ) );
my $err = $?;

diag "Output: $exec (\$ENV{ $print } = $ENV{ $print })\n", explain \@output;

ok ! $err, "$exec exits zero";

ok @output, "True $print: has output.";

ok -e $_, "Existing: '$_'"  for grep /^[^#]/, @output;

done_testing
__END__
