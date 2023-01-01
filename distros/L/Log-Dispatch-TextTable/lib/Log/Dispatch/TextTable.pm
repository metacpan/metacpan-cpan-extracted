use strict;
use warnings;
package Log::Dispatch::TextTable 0.033;
use parent qw(Log::Dispatch::Output);
# ABSTRACT: log events to a textual table

use Log::Dispatch 2.0 ();
use Text::Table;

#pod =head1 SYNOPSIS
#pod
#pod   use Log::Dispatch;
#pod   use Log::Dispatch::TextTable;
#pod  
#pod   my $log = Log::Dispatch->new;
#pod  
#pod   $log->add(Log::Dispatch::TextTable->new(
#pod     name      => 'text_table',
#pod     min_level => 'debug',
#pod     flush_if  => sub { (shift)->event_count >= 60 },
#pod   ));
#pod  
#pod   while (@events) {
#pod     # every 60 events, a formatted table is printed to the screen
#pod     $log->warn($_);
#pod   }
#pod
#pod =head1 DESCRIPTION
#pod
#pod This provides a Log::Dispatch log output system that builds logged events into
#pod a textual table and, when done, does something with the table.  By default, it
#pod will print the table.
#pod
#pod =method new
#pod
#pod  my $table_log = Log::Dispatch::TextTable->new(\%arg);
#pod
#pod This method constructs a new Log::Dispatch::TextTable output object.  Valid
#pod arguments are:
#pod
#pod   send_to  - a coderef indicating where to send the logging table (optional)
#pod              defaults to print to stdout; see transmit method
#pod   flush_if - a coderef indicating whether, if ever, to flush (optional)
#pod              defaults to never flush; see should_flush and flush methods
#pod   columns  - an arrayref of columns to include in the table; message, level,
#pod              and time are always provided
#pod
#pod =cut

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

#pod =method log_message
#pod
#pod This is the method which performs the actual logging, as detailed by
#pod Log::Dispatch::Output.  It adds the data to the table and may flush.  (See
#pod L</should_flush>.)
#pod
#pod =cut

sub log_message {
  my ($self, %p) = @_;
  $p{time} = localtime unless exists $p{time};

  $self->table->add(
    @p{ @{ $self->{columns} } }
  );

  $self->flush(\%p) if $self->should_flush;
}

#pod =method table
#pod
#pod This method returns the Text::Table object being used for the log's logging.
#pod
#pod =cut

sub table { return $_[0]->{table} }

#pod =method entry_count
#pod
#pod This method returns the current number of entries in the table.
#pod
#pod =cut

sub entry_count {
  my ($self) = @_;
  $self->table->body_height;
}

#pod =method flush
#pod
#pod This method transmits the current table and then clears it.  This is useful for
#pod emptying large tables every now and then.
#pod
#pod =cut

sub flush {
  my ($self) = @_;
  $self->transmit;
  $self->table->clear;
}

#pod =method should_flush
#pod
#pod This method returns true if the logger is ready to flush its contents.  This is
#pod always false, unless a C<flush_if> callback was provided during instantiation.
#pod
#pod The callback is passed the Log::Dispatch::TextTable object and a reference to
#pod the last entry logged.
#pod
#pod =cut

sub should_flush {
  my ($self, $p) = @_;

  return unless (ref $self->{flush_if} eq 'CODE');

  return $self->{flush_if}->($self, $p);
}

#pod =method transmit
#pod
#pod This method sends out the table's current contents to their destination via
#pod the callback provided via the C<send_to> argument to C<new>.
#pod
#pod =cut

sub transmit {
  my ($self) = @_;
  $self->{send_to}->($self->table);
}

sub DESTROY {
  my ($self) = @_;
  $self->transmit;
}

#pod =head1 TODO
#pod
#pod I'd like to make it possible to transmit just the rows since the last transmit
#pod I<without> flushing, but Text::Table needs a bit of a patch for that.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::TextTable - log events to a textual table

=head1 VERSION

version 0.033

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

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

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

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Ricardo SIGNES Signes

=over 4

=item *

Ricardo SIGNES <rjbs@codesimply.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
