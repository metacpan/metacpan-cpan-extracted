#!perl -w

use strict;
use FindBin qw($Bin);
use File::Spec::Functions qw(catdir catfile);
use Test::More tests => 42;
use HTML::Mason::Interp;

BEGIN { use_ok('MasonX::Interp::WithCallbacks') }

my $key = 'myCallbackTester';

sub mydie { die "Ouch!" }
sub myfault { die bless {}, 'TestException' }

my %cbs = ( pkg_key => $key,
            cb_key  => 'mydie',
            cb      => \&mydie
          );

my %fault_cb = ( pkg_key => $key,
                 cb_key  => 'myfault',
                 cb      => \&myfault );

my $outbuf;
my %mason_params = (comp_root  => catdir($Bin, qw(htdocs)),
                    out_method => \$outbuf);

my $comp = 'dhandler';

##############################################################################
# Set up callback functions.
##############################################################################
# Check that we get a warning for when there are no callbacks.
{
    local $SIG{__WARN__} = sub {
        like( $_[0], qr/You didn't specify any callbacks/, "Check warning")
    };
    ok(  MasonX::Interp::WithCallbacks->new(%mason_params),
         "Construct Interp object without CBs" );
}

##############################################################################
# Try to construct a CBE object with a bad callback key.
my %c = %cbs;
$c{cb_key} = '';
eval {MasonX::Interp::WithCallbacks->new(%mason_params, callbacks => [\%c]) };
ok( my $err = $@, "Catch bad cb_key exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::Params' );
like( $err->error, qr/Missing or invalid callback key/,
      "Check bad cb_key error message" );

##############################################################################
# Try to construct a CBE object with a bad priority.
%c = %cbs;
$c{priority} = 'foo';
eval {MasonX::Interp::WithCallbacks->new(%mason_params, callbacks => [\%c]) };
ok( $err = $@, "Catch bad priority exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::Params' );
like( $err->error, qr/Not a valid priority: 'foo'/,
      "Check bad priority error message" );

##############################################################################
# Test a bad code ref.
my $msg = "Callback for package key 'myCallbackTester' and callback key " .
  "'coderef' not a code reference";
%c = %cbs;
$c{cb_key} = 'coderef';
$c{cb} = 'bogus'; # Ooops.
eval {MasonX::Interp::WithCallbacks->new(%mason_params, callbacks => [\%c]) };
ok( $err = $@, "Catch bad code ref exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::Params' );
like( $err->error, qr/$msg/, "Check bad code ref error message" );

##############################################################################
# Test for a used key.
%c = my %b = %cbs;
$c{cb_key} = $b{cb_key} = 'bar'; # Ooops.
eval {MasonX::Interp::WithCallbacks->new(%mason_params,
                                         callbacks => [\%c, \%b]) };
ok( $err = $@, "Catch used key exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::Params' );
like( $err->error,
      qr/Callback key 'bar' already used by package key '$key'/,
      "Check used key error message" );

##############################################################################
# Test a bad request code ref.
eval {MasonX::Interp::WithCallbacks->new(%mason_params,
                                         pre_callbacks => ['foo']) };
ok( $err = $@, "Catch bad request code ref exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::Params' );
like( $err->error,
      qr/Request pre callback not a code reference/,
      'Check bad request code ref exception' );

##############################################################################
# Construct one to be used for exceptions during the execution of callbacks.
##############################################################################
ok( my $interp = MasonX::Interp::WithCallbacks->new(%mason_params,
                                                    callbacks => [\%cbs, \%fault_cb]),
    "Construct Interp object" );
isa_ok($interp, 'MasonX::Interp::WithCallbacks' );

##############################################################################
# Test the callbacks themselves.
##############################################################################
# Make sure an exception get thrown for a non-existant package.
eval { $interp->exec($comp, 'NoSuchLuck|foo_cb' => 1) };
ok( $err = $@, "Catch bad package exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::InvalidKey' );
like( $err->error, qr/No such callback package 'NoSuchLuck'/,
      "Check bad package message" );
$outbuf = '';

##############################################################################
# Make sure an exception get thrown for a non-existant callback.
eval { $interp->exec($comp, "$key|foo_cb" => 1) };
ok( $err = $@, "Catch missing callback exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::InvalidKey' );
like( $err->error, qr/No callback found for callback key '$key|foo_cb'/,
      "Check missing callback message" );
$outbuf = '';

##############################################################################
# Now die from within our callback function.
eval { $interp->exec($comp, "$key|mydie_cb" => 1) };
ok( $err = $@, "Catch our exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::Execution' );
like( $err->error, qr/^Error thrown by callback: Ouch! at/,
      "Check our mydie message" );
like( $err->callback_error, qr/^Ouch! at/, "Check our die message" );
$outbuf = '';

##############################################################################
# Now throw our own exception.
eval { $interp->exec($comp, "$key|myfault_cb" => 1) };
ok( $err = $@, "Catch our exception" );
isa_ok($err, 'TestException' );
$outbuf = '';

##############################################################################
# Now test exception_handler.
ok( $interp = MasonX::Interp::WithCallbacks->new
    ( %mason_params,
      callbacks            => [\%cbs],
      cb_exception_handler => sub {
          like( $_[0], qr/^Ouch! at/, "Custom check our die message" );
      }), "Construct Interp object with custom exception handler" );
eval { $interp->exec($comp, "$key|mydie_cb" => 1) };
$outbuf = '';


1;
__END__
