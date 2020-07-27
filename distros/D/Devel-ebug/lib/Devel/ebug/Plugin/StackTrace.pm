package Devel::ebug::Plugin::StackTrace;

use strict;
use warnings;
use Scalar::Util qw(blessed);
use base qw(Exporter);
our @EXPORT = qw(stack_trace stack_trace_human stack_trace_human_args);

our $VERSION = '0.63'; # VERSION

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::ebug::Plugin::StackTrace

=head1 VERSION

version 0.63

=head1 AUTHOR

Original author: Leon Brocard E<lt>acme@astray.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Brock Wilcox E<lt>awwaiid@thelackthereof.orgE<gt>

Taisuke Yamada

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2020 by Leon Brocard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
