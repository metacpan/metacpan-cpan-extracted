package Image::Synchronize::Logger;

use v5.10.0;

# I would have liked to use Log::Contextual, but I can't figure out
# how to make it play nice with Term::ProgressBar::Simple, and how to
# select the desired logging level based on a command-line option.

=head1 NAME

Image::Synchronize::Logger - a message logger for Imsync

=head1 SYNOPSIS

  # arrange to print to STDERR at level 0 and up
  $l1 = Image::Synchronize::Logger->new;

  $l1->log_message('unconditional', ' multiple arguments');
     # prints 'unconditional multiple arguments' to STDERR

  $l1->log_message($level, 'this too?');
     # prints 'this too?' to STDERR if $level is a number >= 0

  # Image::Synchronize::Logger->new() is equivalent to
  $l1 = Image::Synchronize::Logger->new({ name => '',
                              min_level => 0,
                              action => sub { print STDERR, @_ } });

  # arrange to print through the code reference at level 2 and up
  $l2 = Image::Synchronize::Logger->new({ name => 'myprinter',
                              min_level => 2,
                              action => sub { print 'Hey! ', @_; } });

  $l2->log_message(1, 'level 1');
     # not printed because verbosity level 1 is less than the minimum
     # level (2) defined for the single backend printer of the logger

  $l2->log_message(2, 'level 2');
     # prints 'Hey! level 2' to STDOUT

  # arrange to also print to a file at level 1 and up
  open $ofh, '>>', 'mylog.log';
  $l2->set_printer({ name => 'tofile',
                     min_level => 1,
                     action => sub { print $ofh @_ } });

  $l2->log_message(1, 'level 1');
     # prints 'level 1' to the file

  $l2->log_message(2, 'level 2');
     # prints 'level 2' to the file, and 'Hey! level 2' to STDOUT

  # change 'Hey!' to 'Wow!' for printing to STDOUT
  $l2->set_printer({ name => 'myprinter',
                     min_level => 2,
                     action => sub { print 'Wow! ', @_; } });

  $l2->log_message(2, 'level 2');
     # prints 'level 2' to the file, and 'Wow! level 2' to STDOUT

  # remove myprinter
  $l2->clear_printer('myprinter');

  $l2->log_message(2, 'level 2');
     # prints 'level 2' to the file

  # install as default logger
  $l2->set_as_default;

  # access the default logger
  $l = default_logger();

  # now these are equivalent:
  $l2->log_message(@args);
  log_message(@args);

  # the arguments can be code references, which get evaluated with no
  # arguments.
  $l2->log_message(2, sub { 'This is some text' });
     # prints 'This is some text' to the file

  # arguments that are array references get the referenced array
  # interpolated.  These are equivalent:
  $l->log_message(1, 'this', [' is', ' text']);
  $l->log_message(1, 'this', ' is', ' text');

  # log a message when the message verbosity is at least 2 or if
  # option 'X' is equal to 'foo'
  $l->set_printer({ name => '',
                    min_level => 2,
                    action => sub { print @_; } });
  $l->set_printer_condition('', 'foo condition', 
                            sub { $_->{X} eq 'foo' });
  $l->log_message(1, @args);    # not printed, verbosity too low
  $l->log_message(1, { X => 'bar' }, @args);   # not printed
  $l->log_message(1, { X => 'foo' }, @args);   # args get printed

=head1 SUBROUTINES/METHODS

=over

=cut

use warnings;
use strict;

use parent 'Exporter';
our @EXPORT_OK = qw(
  default_logger
  log_error
  log_message
  log_warn
  set_printer
);

use Carp;
use Scalar::Util qw(blessed looks_like_number);

my $default_printer = sub { print STDERR @_ };

=item new

  $l = Image::Synchronize::Logger->new($name, $min_level, $coderef);
  $l = Image::Synchronize::Logger->new({ name => $name,
                             min_level => $min_level,
                             bitflags => $bitflags,
                             action => $coderef });
  $l = Image::Synchronize::Logger->new;
    # equivalent to  ->new({ name => '',
                             min_level => 0,
                             action => sub { print STDERR @_ } });

Constructs a new instance of the class for logging messages to one or
more back-end printers, based on a minimum verbosity level and/or bit
flags.

C<$name> is the name of the back-end printer, through which it can be
queried or modified later.

C<$min_level> is the minimum verbosity level of the back-end printer.
A logged message gets printed through the back-end printer if its
verbosity level is at least as great as C<$min_level>.

C<$bitflags> is a number that identifies which bits of the verbosity
level are bit flags.  If a message is logged at a verbosity level that
includes any of those bits, then that message gets logged through the
current back-end printer.

C<$coderef> is a code reference that says how the message should be
printed.  The messages to be logged show up in C<@_> inside that code
reference.

=cut

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  return $self->set_printer(@_)->ensure_printer_;
}

# $logger->ensure_printer_
#
# Ensure that the logger has at least one back-end printer.  If it
# doesn't have a back-end printer yet, then install a default printer
# (with name '') that prints to STDERR.
#
# Returns the logger object.
sub ensure_printer_ {
  my ($self) = @_;
  unless ( keys %{ $self->{printers} } ) {
    $self->{printers}->{''} = {
      min_level => 0,
      action    => $default_printer
    };
  }
  return $self;
}

sub get_logger_ {
  if ( blessed( $_[0]->[0] ) && $_[0]->[0]->isa('Image::Synchronize::Logger') )
  {
    shift @{ $_[0] };
  }
  else {
    default_logger();
  }
}

=item clear_printer

  $l->clear_printer($name);
  clear_printer($name);         # default logger

Removes the named back-end printer from the logger.  If no printer by
that name is known to the logger, then does nothing.  If removal of
the back-end printer leaves the logger without any back-end printers,
then installs a default back-end printer (with name C<''>) that prints
to STDERR.

Returns the logger object.

=cut

sub clear_printer {
  my $logger = get_logger_( \@_ );
  my ($name) = @_;
  delete $logger->{printers}->{$name};
  $logger->ensure_printer_;
  return $logger;
}

=item set_printer_condition

  $l->set_printer_condition($printer_name, $condition_name, $code_ref);

Adds the C<$code_ref> as a printer condition with name
C<$condition_name> to the back-end printer with name C<$printer_name>.

=cut

sub set_printer_condition {
  my $logger = get_logger_( \@_ );
  my ( $printer_name, $condition_name, $code_ref ) = @_;
  croak "Back-end printer '$printer_name' is not defined for the logger.\n"
    unless exists $logger->{printers}->{$printer_name};
  if ( defined $code_ref ) {
    $logger->{conditions}->{$condition_name} = $code_ref;
  }
  else {
    delete $logger->{conditions}->{$condition_name};
    delete $logger->{conditions} unless keys %{ $logger->{conditions} };
  }
  $logger;
}

=item default_logger

  $default_logger = default_logger();

Returns the default logger, which is an instance of C<Image::Synchronize::Logger>.

=cut

my $default_logger;

sub default_logger {
  $default_logger //= Image::Synchronize::Logger->new;
  return $default_logger;
}

=item log

  $l->log_message($level, { %options }, @arguments);
  # $level and %options are optional

  # or use the default logger
  log_message($level, { %options }, @arguments);

Log a message through all applicable back-end printers of the logger.

If the first specified argument is a scalar number, then it represents
the verbosity level of the message.  The verbosity level defaults to
0.

If, after removing the verbosity level if any, the first specified
argument is a hash reference, then it represents information to pass
to the special condition evaluator of the printer, if defined.

The remaining arguments represent values to print.  If any of them are
code references, then they are evaluated before printing, with no
arguments.  Evaluation is done only if the message gets printed
through at least one of the back-end printers, so if any of the values
to be printed are expensive to evaluate, then wrap them in an
anonymous sub to prevent them from being evaluated if they aren't
needed.

Returns the logger object.

The message gets printed through the back-end printer if C<$level>
matches the printer's maximum verbosity level or bit flag or if any of
the printer's special conditions are met.

The printer's maximum verbosity level (if specified) is matched if
C<$level> is less than or equal to that maximum verbosity level.

The printer's bit flag (if specified) is matched if at least one of
the bits in the printer's bit flag are set in C<$level>.

If the printer has one or more special conditions defined
(L<set_printer_condition>), then the code reference for each of those
conditions gets evaluated with C<{%options}> as argument, and the
condition is met if it evaluates to a true value.

=cut

sub log_message {
  my $logger       = get_logger_( \@_ );
  my $level        = shift if looks_like_number( $_[0] );
  my $options_href = shift if ref $_[0] eq 'HASH';
  my @args         = @_;
  my $was_evaluated;
  foreach my $name ( sort keys %{ $logger->{printers} } ) {
    my $printer  = $logger->{printers}->{$name};
    my $do_print = 1;
    if ( defined $level ) {
      my $printer_bitflags = $printer->{bitflags};
      $do_print = 0
        if ( defined($printer_bitflags)
        && ( $level & $printer_bitflags ) == 0 );
      my $printer_level = $printer->{min_level};
      $do_print = 0
        if ( defined $printer_level && $level < $printer_level );
    }
    if ( not($do_print) && exists $logger->{conditions} ) {
      foreach my $condition_name ( sort keys %{ $logger->{conditions} } ) {
        local $_ = $options_href;
        $do_print = 1, last
          if $logger->{conditions}->{$condition_name}->($_);
      }
    }
    if ($do_print) {
      unless ($was_evaluated) {
        @args = map { ref eq 'CODE' ? $_->() : $_ } @args;
        $was_evaluated = 1;
      }
      $printer->{action}->(@args);
    }
  }
  return $logger;
}

=item log_error

  $l->log_error(@messages);
  log_error(@messages);

Logs the C<@messages> (at verbosity levels 0 and up) prefixed by
C<'ERROR: '>.

=cut

sub log_error {
  my $logger = get_logger_( \@_ );
  return $logger->log_message( 'ERROR: ', @_ );
}

=item log_warn

  $l->log_warn(@messages);
  log_warn(@messages);

Logs the C<@messages> (at verbosity levels 0 and up) prefixed by
C<'WARNING: '>.

=cut

sub log_warn {
  my $logger = get_logger_( \@_ );
  return $logger->log_message( 'WARNING: ', @_ );
}

=item set_as_default

  $l->set_as_default;

Installs C<$l> (an Image::Synchronize::Logger) as the default logger, to be
returned by L<default_logger()>.

Returns the logger object.

=cut

sub set_as_default {
  my ($self) = @_;
  if ( blessed($self) && $self->isa('Image::Synchronize::Logger') ) {
    $default_logger = $self;
  }
  else {
    croak "Expected Image::Synchronize::Logger or descendant\n";
  }
  return $self;
}

=item set_printer

  # with a logger object
  $l->set_printer($name, $level, $coderef);
  $l->set_printer({ name => $name,
                    min_level => $level,
                    bitflags => $flags,
                    action => $coderef });
  $l->set_printer;
  # equivalent to ->set_printer('', 0, sub { print STDERR @_ })

  # or the same with the default logger
  set_printer(...);

Sets a back-end printer of logger C<$l>, or of the default logger,
replacing any previous back-end printer with the same name.

See L<new> for details of the arguments.

Returns the object.

=cut

sub set_printer {
  my $logger = get_logger_( \@_ );
  my ( $name, $level, $bitflags, $code );
  if ( scalar(@_) == 1 ) {    # expect { ... }
    if ( ref $_[0] eq 'HASH' ) {
      my $h = $_[0];
      $name = $h->{name} // '';
      croak "Expected 'action' element in hash" unless defined $h->{action};
      $logger->{printers}->{$name} = {
        defined( $h->{min_level} ) ? ( min_level => $h->{min_level} ) : (),
        defined( $h->{bitflags} )  ? ( bitflags  => $h->{bitflags} )  : (),
        action => $h->{action}
      };
    }
    else {
      croak "Expected single hash or 3 arguments";
    }
  }
  elsif ( scalar(@_) == 0 ) {
    return $logger->set_printer(
      {
        action => sub { print STDERR @_ }
      }
    );
  }
  elsif ( scalar(@_) != 3 ) {
    croak "Need name, min_level, action to define a back-end printer";
  }
  else {
    ( $name, $level, $code ) = @_;
    $logger->{printers}->{$name} = {
      min_level => $level,
      action    => $code
    };
  }
  return $logger;
}

=back

=head1 AUTHOR

Louis Strous <LS@quae.nl>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016 Louis Strous.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
