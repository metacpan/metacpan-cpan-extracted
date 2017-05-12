use strict;
use warnings;
package Log::Dispatch::TextTable;
{
  $Log::Dispatch::TextTable::VERSION = '0.032';
}
use parent qw(Log::Dispatch::Output);
# ABSTRACT: log events to a textual table

use Log::Dispatch 2.0 ();
use Text::Table;


sub new {
  my ($class, %arg) = @_;

  # when done, by default, print out the passed-in table
  $arg{send_to} ||= sub { print $_[0] };

  # construct the column list, using the default if no columns were given
  my @columns = $arg{columns} ? @{ $arg{columns} } : qw(time level message);
  my @header  = map { $_, \q{ | } } @columns;
  $#header--; # drop the final |-divider

  my $table = Text::Table->new(@header);

  my $self = {
    columns  => \@columns,
    table    => $table,
    send_to  => $arg{send_to},
    flush_if => $arg{flush_if},
  };

  bless $self => $class;

  # this is our duty as a well-behaved Log::Dispatch plugin
  $self->_basic_init(%arg);

  return $self;
}


sub log_message {
  my ($self, %p) = @_;
  $p{time} = localtime unless exists $p{time};

  $self->table->add(
    @p{ @{ $self->{columns} } }
  );

  $self->flush(\%p) if $self->should_flush;
}


sub table { return $_[0]->{table} }


sub entry_count {
  my ($self) = @_;
  $self->table->body_height;
}


sub flush {
  my ($self) = @_;
  $self->transmit;
  $self->table->clear;
}


sub should_flush {
  my ($self, $p) = @_;

  return unless (ref $self->{flush_if} eq 'CODE');

  return $self->{flush_if}->($self, $p);
}


sub transmit {
  my ($self) = @_;
  $self->{send_to}->($self->table);
}

sub DESTROY {
  my ($self) = @_;
  $self->transmit;
}


1;

__END__

=pod

=head1 NAME

Log::Dispatch::TextTable - log events to a textual table

=head1 VERSION

version 0.032

=head1 SYNOPSIS

  use Log::Dispatch;
  use Log::Dispatch::TextTable;
 
  my $log = Log::Dispatch->new;
 
  $log->add(Log::Dispatch::TextTable->new(
    name      => 'text_table',
    min_level => 'debug',
    flush_if  => sub { (shift)->event_count >= 60 },
  ));
 
  while (@events) {
    # every 60 events, a formatted table is printed to the screen
    $log->warn($_);
  }

=head1 DESCRIPTION

This provides a Log::Dispatch log output system that builds logged events into
a textual table and, when done, does something with the table.  By default, it
will print the table.

=head1 METHODS

=head2 new

 my $table_log = Log::Dispatch::TextTable->new(\%arg);

This method constructs a new Log::Dispatch::TextTable output object.  Valid
arguments are:

  send_to  - a coderef indicating where to send the logging table (optional)
             defaults to print to stdout; see transmit method
  flush_if - a coderef indicating whether, if ever, to flush (optional)
             defaults to never flush; see should_flush and flush methods
  columns  - an arrayref of columns to include in the table; message, level,
             and time are always provided

=head2 log_message

This is the method which performs the actual logging, as detailed by
Log::Dispatch::Output.  It adds the data to the table and may flush.  (See
L</should_flush>.)

=head2 table

This method returns the Text::Table object being used for the log's logging.

=head2 entry_count

This method returns the current number of entries in the table.

=head2 flush

This method transmits the current table and then clears it.  This is useful for
emptying large tables every now and then.

=head2 should_flush

This method returns true if the logger is ready to flush its contents.  This is
always false, unless a C<flush_if> callback was provided during instantiation.

The callback is passed the Log::Dispatch::TextTable object and a reference to
the last entry logged.

=head2 transmit

This method sends out the table's current contents to their destination via
the callback provided via the C<send_to> argument to C<new>.

=head1 TODO

I'd like to make it possible to transmit just the rows since the last transmit
I<without> flushing, but Text::Table needs a bit of a patch for that.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
