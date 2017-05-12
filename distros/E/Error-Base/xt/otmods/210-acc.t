use Test::More;

#~ # Load non-core modules conditionally
#~ BEGIN{
#~     eval{
#~         require Scalar::Util;               # General-utility scalar subroutines
#~     };
#~     $scalar_util_loaded      = !$@;         # loaded if no error
#~                                             #   must be package variable
#~                                             #       to escape BEGIN block
#~ }; ## BEGIN

#~ use lib ('inc', '../inc');                  # during P::F development only
use Path::Finder;

my $tc          ;
my $base        = 'Path-Finder: ';
my $diag        = $base;
my $got         ;
my $want        ;

$tc++;
$diag           = $base . 'new';
my $pf          = Path::Finder->new( -module => 'My::Module' );
pass($diag);                                # pass if we get this far

$tc++;
$diag           = $base . 'system';
my $path_system = $pf->system();        # get path to system-level config
pass($diag);                                # pass if we get this far

$tc++;
$diag           = $base . 'user';
my $path_user = $pf->user();            # get path to user-level config
pass($diag);                                # pass if we get this far

$tc++;
$diag           = $base . 'task';
my $path_task = $pf->task();            # get path to task-level config
pass($diag);                                # pass if we get this far






#~ my $path_user   = $pf->user();          #  "    "       user-level config
#~ my $path_task   = $pf->task();          #  "    "       task-level config



done_testing($tc);
