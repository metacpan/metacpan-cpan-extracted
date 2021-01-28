use strict;
use warnings;
package Log::Dispatch::Array;
{
  $Log::Dispatch::Array::VERSION = '1.003';
}
use parent qw(Log::Dispatch::Output);
# ABSTRACT: log events to an array (reference)


sub new {
  my ($class, %arg) = @_;
  $arg{array} ||= [];

  my $self = { array => $arg{array} };

  bless $self => $class;

  # this is our duty as a well-behaved Log::Dispatch plugin
  $self->_basic_init(%arg);

  return $self;
}


sub array { $_[0]->{array} }


sub log_message {
  my ($self, %p) = @_;
  push @{ $self->array }, { %p };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Array - log events to an array (reference)

=head1 VERSION

version 1.003

=head1 SYNOPSIS

  use Log::Dispatch;
  use Log::Dispatch::Array;

  my $log = Log::Dispatch->new;

  my $target = [];

  $log->add(Log::Dispatch::Array->new(
    name      => 'text_table',
    min_level => 'debug',
    array     => $target,
  ));

  $log->warn($_) for @events;

  # now $target refers to an array of events

=head1 DESCRIPTION

This provides a Log::Dispatch log output system that appends logged events to
an array reference.  This is probably only useful for testing the logging of
your code.

=head1 METHODS

=head2 new

 my $table_log = Log::Dispatch::Array->new(\%arg);

This method constructs a new Log::Dispatch::Array output object.  Valid
arguments are:

  array - a reference to an array to append to; defaults to an attr on
          $table_log

=head2 array

This method returns a reference to the array to which logging is being
performed.

=head2 log_message

This is the method which performs the actual logging, as detailed by
Log::Dispatch::Output.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
