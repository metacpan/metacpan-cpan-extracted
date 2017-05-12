package Devel::ebug::Plugin::StackTrace;
$Devel::ebug::Plugin::StackTrace::VERSION = '0.59';
use strict;
use warnings;
use Scalar::Util qw(blessed);
use base qw(Exporter);
our @EXPORT = qw(stack_trace stack_trace_human stack_trace_human_args);

# return the stack trace
sub stack_trace {
  my($self) = @_;
  my $response = $self->talk({ command => "stack_trace" });
  return @{$response->{stack_trace}||[]};
}

# return the stack trace in a human-readable format
sub stack_trace_human {
  my($self) = @_;
  my @human;
  my @stack = $self->stack_trace;
  foreach my $frame (@stack) {
    my $subroutine = $frame->subroutine;
    my $package = $frame->package;
    my @args = $frame->args;
    my $first = $args[0];
    my $first_class = ref($first);
    my($subroutine_class, $subroutine_method) = $subroutine =~ /^(.+)::([^:])+?$/;
#    warn "first: $first, first class: $first_class, package: $package, subroutine: $subroutine ($subroutine_class :: $subroutine_method)\n";

    if (defined $first && blessed($first) && $subroutine =~ /^${first_class}::/ &&
    $subroutine =~ /^$package/) {
      $subroutine =~ s/^${first_class}:://;
      shift @args;
      push @human, "\$self->$subroutine" . $self->stack_trace_human_args(@args);
    } elsif (defined $first && blessed($first) && $subroutine =~ /^${first_class}::/) {
      $subroutine =~ s/^${first_class}:://;
      shift @args;
      my($name) = $first_class =~ /([^:]+)$/;
      $first = '$' . lc($name);
      push @human, "$first->$subroutine" . $self->stack_trace_human_args(@args);
    } elsif ($subroutine =~ s/^${package}:://) {
      push @human, "$subroutine" . $self->stack_trace_human_args(@args);
    } elsif (defined $first && $subroutine_class eq $first) {
      shift @args;
      push @human, "$first->new" . $self->stack_trace_human_args(@args);
    } else {
      push @human, "$subroutine" . $self->stack_trace_human_args(@args);
    }
  }
  return @human;
}

sub stack_trace_human_args {
  my($self, @args) = @_;
  foreach my $arg (@args) {
    if (not defined $arg) {
      $arg = "undef";
    } elsif (ref($arg) eq 'ARRAY') {
      $arg = "[...]";
    } elsif (ref($arg) eq 'HASH') {
      $arg = "{...}";
    } elsif (ref($arg)) {
      my($name) = ref($arg) =~ /([^:]+)$/;
      $arg = '$' . lc($name);
    } elsif ($arg =~ /^-?[\d.]+$/) {
      # number, do nothing
    } elsif ($arg =~ /^[\w:]*$/) {
      $arg =~ s/([\'\\])/\\$1/g;
      $arg = qq{'$arg'};
    } else {
      $arg =~ s/([\'\\])/\\$1/g;
      $arg = qq{"$arg"};
   }
  }
  return '(' . join(", ", @args) . ')';
}

1;
