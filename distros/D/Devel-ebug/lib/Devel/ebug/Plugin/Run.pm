package Devel::ebug::Plugin::Run;
$Devel::ebug::Plugin::Run::VERSION = '0.59';
use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(undo run return step next);

# undo
sub undo {
  my($self, $levels) = @_;
  $levels ||= 1;
  my $response = $self->talk({ command => "commands" });
  my @commands = @{$response->{commands}};
  pop @commands foreach 1..$levels;
#  use YAML; warn Dump \@commands;
  my $proc = $self->proc;
  $proc->die;
  $self->load;
  $self->talk($_) foreach @commands;
  $self->basic;
}



# run until a breakpoint
sub run {
  my($self) = @_;
  my $response = $self->talk({ command => "run" });
  $self->basic; # get basic information for the new line
}


# return from a subroutine
sub return {
  my($self, @values) = @_;
  my $values;
  $values = \@values if @values;
  my $response = $self->talk({
    command => "return",
    values  => $values,
 });
  $self->basic; # get basic information for the new line
}



# step onto the next line (going into subroutines)
sub step {
  my($self) = @_;
  my $response = $self->talk({ command => "step" });
  $self->basic; # get basic information for the new line
}

# step onto the next line (going over subroutines)
sub next {
  my($self) = @_;
  my $response = $self->talk({ command => "next" });
  $self->basic; # get basic information for the new line
}

1;
