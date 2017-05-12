use Test::More;

# Load non-core modules conditionally
BEGIN{
    eval{
        require Scalar::Util;               # General-utility scalar subroutines
    };
    $scalar_util_loaded      = !$@;         # loaded if no error
                                            #   must be package variable
                                            #       to escape BEGIN block
}; ## BEGIN

#~ use lib ('inc', '../inc');                  # during P::F development only
use Path::Finder;

my $tc          ;
my $base        = 'Path-Finder: ';
my $diag        = $base;
my $got         ;
my $want        ;

$tc++;
$diag           = $base . 'load';
pass($diag);                                # pass if we get this far

$tc++;
$diag           = $base . 'new';
my $pf          = Path::Finder->new( -module => 'My::Module' );
if ($scalar_util_loaded) {
    $got            = Scalar::Util::blessed( $pf );
    $want           = 'Path::Finder';
}
else {
    diag('Recommended: Install Scalar::Util for a stricter test.');
    $got            = ref( $pf );
    $want           = 'HASH';
};
is( $got, $want, $diag );

#~ $tc++;
#~ $diag           = $base . 'system';
#~ my $path_system = $pf->system();        # get path to system-level config
#~ $got            = $path_system;
#~ $want           = 'setup/system';            
#~ is( $got, $want, $diag );
#~ 
#~ $tc++;
#~ $diag           = $base . 'user';
#~ my $path_user = $pf->user();            # get path to user-level config
#~ $got            = $path_user;
#~ $want           = 'setup/user';            
#~ is( $got, $want, $diag );
#~ 
#~ $tc++;
#~ $diag           = $base . 'task';
#~ my $path_task = $pf->task();            # get path to task-level config
#~ $got            = $path_task;
#~ $want           = 'setup/task';            
#~ is( $got, $want, $diag );






#~ my $path_user   = $pf->user();          #  "    "       user-level config
#~ my $path_task   = $pf->task();          #  "    "       task-level config



done_testing($tc);
