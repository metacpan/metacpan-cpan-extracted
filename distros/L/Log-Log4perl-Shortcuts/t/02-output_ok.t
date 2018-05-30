#/usr/bin/env perl
use Test::More;
use Test::Warn;
use Test::Output;
use Test::NoWarnings;
use Test::Exception;
use File::HomeDir;
diag( "Running my tests" );








my $tests = 9; # keep on line 17 for ,i (increment and ,d (decrement)
plan tests => $tests;


combined_like (\&trace, qr/\[TRACE] I am a trace message./, 'Prints trace message');
combined_like (\&info, qr/\[INFO ] I am an info message./, 'Prints info message');
combined_like (\&warn, qr/\[WARN ] I am a warning message./, 'Prints warning message');
combined_like (\&debug, qr/\[DEBUG].*I am a debug message./s, 'Prints debug message');
combined_like (\&fatal, qr/\[FATAL] I am a fatal message./s, 'Prints fatal message');
combined_like (\&error, qr/\[ERROR] I am an error message./s, 'Prints error message');
combined_like (\&stack, qr/\[TRACE].*Logger/s, 'Prints stack trace message');

sub trace {
  my $obj = Logger->new( );
  $obj->trace;
}

sub stack {
  my $obj = Logger->new( );
  $obj->stack;
}

sub info {
  my $obj = Logger->new( );
  $obj->info;
}

sub warn {
  my $obj = Logger->new( );
  $obj->warn;
}

sub debug {
  my $obj = Logger->new( );
  $obj->debug;
}

sub fatal {
  my $obj = Logger->new( );
  dies_ok { $obj->fatal } 'fatal kills ok';
}

sub error {
  my $obj = Logger->new( );
  $obj->error;
}

package Logger;
use Log::Log4perl::Shortcuts qw(:all);
use Moose;

sub trace {
  logt('I am a trace message.');
}

sub stack {
  logc();
}

sub info {
  logi('I am an info message.');
}

sub warn {
  logw('I am a warning message.');
}

sub debug {
  logd('I am a debug message.');
}

sub fatal {
  logf('I am a fatal message.');
}

sub error {
  loge('I am an error message.');
}

