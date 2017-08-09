package Test2::Tools::NoteStderr;

use strict;
use warnings;
use Test2::API qw( context );
use base qw( Exporter );

our @EXPORT_OK = qw( note_stderr );

BEGIN {
  eval q{
    use Capture::Tiny qw( capture_stderr );
  };
  if($@)
  {
    eval q{
      sub capture_stderr (&) { $_[0]->() };
    };
  }
}

sub note_stderr (&)
{
  my($code) = @_;
  my($stderr, $exception) = capture_stderr {
    eval {
      $code->();
    };
    $@;
  };
  my $ctx = context();
  $ctx->note($stderr);
  $ctx->release;
  die $exception if $exception;
  return;
}

1;
