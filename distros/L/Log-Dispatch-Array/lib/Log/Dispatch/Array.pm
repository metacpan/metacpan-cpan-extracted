use strict;
use warnings;
package Log::Dispatch::Array 1.005;
use parent qw(Log::Dispatch::Output);
# ABSTRACT: log events to an array (reference)

#pod =head1 SYNOPSIS
#pod
#pod   use Log::Dispatch;
#pod   use Log::Dispatch::Array;
#pod
#pod   my $log = Log::Dispatch->new;
#pod
#pod   my $target = [];
#pod
#pod   $log->add(Log::Dispatch::Array->new(
#pod     name      => 'text_table',
#pod     min_level => 'debug',
#pod     array     => $target,
#pod   ));
#pod
#pod   $log->warn($_) for @events;
#pod
#pod   # now $target refers to an array of events
#pod
#pod =head1 DESCRIPTION
#pod
#pod This provides a Log::Dispatch log output system that appends logged events to
#pod an array reference.  This is probably only useful for testing the logging of
#pod your code.
#pod
#pod =method new
#pod
#pod  my $table_log = Log::Dispatch::Array->new(\%arg);
#pod
#pod This method constructs a new Log::Dispatch::Array output object.  Valid
#pod arguments are:
#pod
#pod   array - a reference to an array to append to; defaults to an attr on
#pod           $table_log
#pod
#pod =cut

sub new {
  my ($class, %arg) = @_;
  $arg{array} ||= [];

  my $self = { array => $arg{array} };

  bless $self => $class;

  # this is our duty as a well-behaved Log::Dispatch plugin
  $self->_basic_init(%arg);

  return $self;
}

#pod =method array
#pod
#pod This method returns a reference to the array to which logging is being
#pod performed.
#pod
#pod =cut

sub array { $_[0]->{array} }

#pod =method log_message
#pod
#pod This is the method which performs the actual logging, as detailed by
#pod Log::Dispatch::Output.
#pod
#pod =cut

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

version 1.005

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

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

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

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
