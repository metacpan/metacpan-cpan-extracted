package TestExporter;

use Moo;
use TestRouter;

extends 'Log::Contextual';

sub router {
  our $Router ||= TestRouter->new
}

1;
