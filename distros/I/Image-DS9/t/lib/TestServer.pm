package t::TestServer;

use strict;
use warnings;

use Test::Lib;
use My::Util 'yesno';

use Log::Any::Adapter Stderr => log_level => $ENV{IMAGE_DS9_LOGLEVEL} // 'warn';
use File::Spec::Functions qw( tmpdir );
use File::pushd;
use Image::DS9::Constants::V1 -terminate_ds9;

use parent 'Image::DS9';

use constant START_TIMEOUT => 30;
use constant DAEMONIZE     => 1;
use constant SERVER        => 'ImageDS9';

caller || do {

    require Getopt::Long;
    my %opts = (
        'daemonize'            => DAEMONIZE,
        'path'                 => 'ds9',
        'sleep'                => 0,
        'start_timeout'        => START_TIMEOUT,
        'terminate'            => !!0,
        'terminate_on_destroy' => 'no',
        'xpa_method'           => 'local',
        'xvfb'                 => !!0,
        'debug'                => !!0,
    );

    # override with Environment variables
    defined( $ENV{ 'TEST_IMAGE_DS9_' . uc $_ } )
      and $opts{$_} = $ENV{ 'TEST_IMAGE_DS9_' . uc $_ }
      for keys %opts;

    Getopt::Long::GetOptions(
        \%opts,            'daemonize',              'path=s',       'sleep=i',
        'start_timeout=i', 'terminate_on_destroy=s', 'xpa_method=s', 'terminate',
        'xvfb'
    ) or die( 'Error in command line arguments' );

    $ENV{ 'TEST_IMAGE_DS9_' . uc $_ } = $opts{$_} for keys %opts;
    my $ds9 = __PACKAGE__->new;    # keep it around for a while
    sleep( $opts{sleep} );
};

sub new {

    my $class   = shift;
    my $verbose = shift;

    # Some facilities (e.g. print) will only work if
    # XPA_METHOD=local
    $ENV{XPA_METHOD} = $ENV{TEST_IMAGE_DS9_XPA_METHOD} // 'local';

    if ( yesno( $ENV{TEST_IMAGE_DS9_TERMINATE} ) ) {
        return $class->SUPER::new( { Server => SERVER } )->quit;
    }

    # some test runners (e.g. yath) run tests in temp dirs which go
    # away after the test. when xpans is started automatically (when
    # ds9 registers its access point) its -l option is set to the current
    # directory.  when yath is done testing, that directory disappears, but
    # xpans is still using it to cache its connection info.  It gets amnesia,
    # and we start up another ds9.

    # so, need to ensure that the current directory is not ephemeral
    # if terminate_on_destroy is false.  Note that yath sets the
    # environment variable TMPDIR to its own TMPDIR, which goes away,
    # so temporarily unset it so we get the system's TMPDIR.

    my $test_value = $ENV{TEST_IMAGE_DS9_TERMINATE_ON_DESTROY} // 'yes';

    defined(
        my $terminate_on_destroy = {
            'yes'      => TERMINATE_DS9_YES,
            'no'       => TERMINATE_DS9_NO,
            'attached' => TERMINATE_DS9_ATTACHED,
            'started'  => TERMINATE_DS9_STARTED,
        }->{$test_value} ) or die( 'unknown value for terminate_on_destroy: ', $test_value );

    $test_value = $ENV{TEST_IMAGE_DS9_DAEMONIZE} // DAEMONIZE;
    defined( my $daemonize = yesno( $test_value ) )
      or die( 'unknown value for daemonize: ', $test_value );

    my $ds9 = $ENV{TEST_IMAGE_DS9_PATH} // 'ds9';

    $ds9 = [ 'xvfb-run', $ds9 ] if yesno( $ENV{TEST_IMAGE_DS9_XVFB} );

    delete local $ENV{TMPDIR};
    my $scope_guard = pushd( tmpdir );

    my %opts = (
        Server               => SERVER,
        ds9                  => $ds9,
        verbose              => $verbose,
        StartTimeOut         => $ENV{TEST_IMAGE_DS9_START_TIMEOUT} // START_TIMEOUT,
        auto_start           => 1,
        terminate_on_destroy => $terminate_on_destroy,
        daemonize            => $daemonize,
    );

    if ( yesno( $ENV{TEST_IMAGE_DS9_DEBUG} ) ) {
        use DDP;
        p %opts;
    }

    return $class->SUPER::new( \%opts );
}

1;
