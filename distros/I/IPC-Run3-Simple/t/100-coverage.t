
# These tests were created to satisfy Devel::Cover reports.  They are not
# exhaustive and should not be considered as a complete test case.

use Test::Most tests => 22;
use Test::NoWarnings;
use Carp;

BEGIN { use_ok( 'IPC::Run3::Simple', ':all' ) }

my @subs = qw(

  chomp_err chomp_out croak_on_err default_stderr default_stdin
  default_stdout tee_systemcall

);

ok( exists $main::{ $_ }, "$_ seems to have been imported" ) for @subs, 'run3';

my %expected_default = (

  CHOMP_ERR      => 1,
  CHOMP_OUT      => 1,
  CROAK_ON_ERR   => 0,
  DEFAULT_STDIN  => undef,
  DEFAULT_STDOUT => \my $out,
  DEFAULT_STDERR => \my $err,
  TEE_SYSTEMCALL => 0,

);

my %got_default;
eval "\$got_default{ $_ } = \$IPC::Run3::Simple::$_\n" for keys %expected_default;

cmp_deeply( \%got_default, \%expected_default, 'defaults match' );

my %change_option = (

  CHOMP_ERR      => '',
  CHOMP_OUT      => '',
  CROAK_ON_ERR   => 1,
  DEFAULT_STDIN  => \my $test_change_in,
  DEFAULT_STDOUT => \my $test_change_out,
  DEFAULT_STDERR => \my $test_change_err,
  TEE_SYSTEMCALL => 1,

);

for my $sub ( @subs ) {

  my $key = uc $sub;
  eval "$sub( \$change_option{ $key } )";
  croak $@ if $@;

}

my %got_changed;
eval "\$got_changed{ $_ } = \$IPC::Run3::Simple::$_ || ''\n" for keys %change_option;

cmp_deeply( \%got_changed, \%change_option, 'change options worked' );

# reset defaults

for my $sub ( @subs ) {

  my $key = uc $sub;
  eval "$sub( \$expected_default{ $key } )";
  croak $@ if $@;

}

# run3 expecting array or hash ref
throws_ok { run3() } qr/Expecting either an array ref or a hash ref/, 'not an array or hash ref caught';

# test basic system call
my ( $basic_stdout, $basic_stderr, $basic_syserr, $basic_time ) = run3( [ 'ls', $0 ] );
ok( $basic_syserr == 0, 'ls did not cause system error' );
is( $basic_stderr, '', 'ls did not report error on stderr' );
like( $basic_stdout, qr{^$0$},            "ls dumped $basic_stdout to stdout" );
like( $basic_time,   qr/^\d+(?:\.\d+)?$/, "ls took $basic_time seconds to run" );

# test syserr
my $exit   = 3;
my $syserr = $exit * 256;
my ( $syserr_stdout, $syserr_stderr, $syserr_syserr, $syserr_time ) = run3( [ 'perl', '-e', "exit $exit" ] );
is( $syserr_syserr, $syserr, "perl exit $exit caused correct system error ($syserr)" );
is( $syserr_stderr, '',      'perl exit $exit did not report error on stderr' );
is( $syserr_stdout, '',      "perl exit $exit dumped nothing stdout" );
like( $syserr_time, qr/^\d+(?:\.\d+)?$/, "perl exit $exit took $syserr_time seconds to run" );

# test debugging variable
$ENV{ DEBUG_IPCR3S_CALL }++;
my ( $debug_stdout, $debug_stderr, $debug_syserr, $debug_time ) = run3( [ 'ls', $0 ] );

#ok( $debug_syserr == 0, 'ls did not cause system error' );
#is( $debug_stderr, '', 'ls did not report error on stderr' );
cmp_deeply( $debug_stdout, [ 'ls', $0 ], "got what would be called back (@$debug_stdout)" );

#like( $debug_time, qr/^\d+(?:\.\d+)?$/, "ls took $debug_time seconds to run");
delete $ENV{ DEBUG_IPCR3S_CALL };
