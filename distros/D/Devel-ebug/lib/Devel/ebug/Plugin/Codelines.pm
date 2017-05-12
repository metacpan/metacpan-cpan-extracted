package Devel::ebug::Plugin::Codelines;
$Devel::ebug::Plugin::Codelines::VERSION = '0.59';
use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(codelines);

# return some lines of code
sub codelines {
  my($self) = shift;
  my($filename, @lines);
  if (!defined($_[0]) || $_[0] =~ /^\d+$/) {
    $filename = $self->filename;
  } else {
    $filename = shift;
  }
  @lines = map { $_ -1 } @_;
  my $response = $self->talk({
    command  => "codelines",
    filename => $filename,
    lines    => \@lines,
  });
  return @{$response->{codelines}};
}

1;
