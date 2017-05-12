package Devel::ebug::Plugin::Output;
$Devel::ebug::Plugin::Output::VERSION = '0.59';
use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(output);

# return stdout, stderr
sub output {
  my($self) = @_;
  my $response = $self->talk({ command => "output" });
  return ($response->{stdout}, $response->{stderr});
}


1;
