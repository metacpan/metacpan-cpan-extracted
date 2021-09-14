#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package IO::Term::Status 0.01;

use v5.14;
use warnings;
use base qw( IO::Handle );

my $EL        = "\e[K";
my $CLEARLINE = "\r$EL";
my $PREVLINE  = "\eM";
my $PREVLINEHOME = "\r$PREVLINE";

use constant HAVE_STRING_TAGGED_TERMINAL => defined eval {
   require String::Tagged::Terminal;
};

=head1 NAME

C<IO::Term::Status> - print log lines to a terminal with a running status bar

=head1 SYNOPSIS

   use IO::Term::Status;

   my $io = IO::Term::Status->new_for_stdout;

   $io->set_status( "Running" );

   my @items = ...;

   foreach my $idx ( 0 .. $#items ) {
      $io->set_status( sprintf "Running | %d of %d", $idx+1, scalar @items );

      my $item = $items[$idx];
      $io->print_line( "Processing item $item..." );
      ...
   }

   $io->set_status( "" );   # Clear the status line before exiting

=head1 DESCRIPTION

This module provides a subclass of L<IO::Handle> for maintaining a running
status display on the terminal. It presumes the terminal can handle basic ANSI
control characters (thus is not suitable for printing to log files, etc).

The "status bar" consists of a single additional line of text, printed below
the current log of output. More lines of regular log can be printed using the
L</print_line> method, which maintains the running status bar below the
output.

=head2 With C<String::Tagged>

If the L<String::Tagged::Terminal> module is available, then the status string
can set to an instance of L<String::Tagged>, obeying the
L<String::Tagged::Formatting> tag conventions. This will be converted to
terminal output.

As an extra convenience, whatever the prevailing background colour is at the
end of the string will be preserved for line-erase purposes, meaning that
colour will extend the entire width of the status bar line.

=cut

*is_string_tagged = HAVE_STRING_TAGGED_TERMINAL ?
   # It would be nice if we could #ifdef HAVE_PERL_VERSION(...)
   ( $^V ge v5.32 ) ?
      do { eval 'use experimental "isa"; sub { $_[0] isa String::Tagged }' } :
      do { require Scalar::Util; sub { Scalar::Util::blessed($_[0]) and $_[0]->isa( "String::Tagged" ) } }
   : sub { 0 };

=head1 CONSTRUCTORS

=head2 new

   $io = IO::Term::Status->new

Constructs a new L<IO::Handle> subclassed instance of this type.

=head2 new_for_stdout

   $io = IO::Term::Status->new_for_stdout

Constructs a new instance wrapping the C<STDOUT> filehandle, with autoflush
turned on. This is usually what you want for printing regular output to the
controlling terminal.

=cut

sub new_for_stdout
{
   my $self = shift->new( @_ );

   $self->fdopen( STDOUT->fileno, "w" );
   $self->autoflush(1);

   return $self;
}

=head1 METHODS

=cut

sub _build_status
{
   my ( $status ) = @_;

   if( is_string_tagged( $status ) ) {
      my $termstr = String::Tagged::Terminal->new_from_formatting( $status )
         ->build_terminal;
      # Hack the EL in before any SGR reset at the end
      $termstr =~ s/\e\[m$/$EL\e[m/
         or $termstr .= $EL;
      return $termstr;
   }
   elsif( length $status ) {
      return $status . $EL;
   }
   else {
      return "";
   }
}

=head2 print_line

   $io->print_line( @args )

Prints a new line from the given arguments, joined as a string. C<@args>
should not contain the terminating linefeed.

This line is printed above any pending partial line.

=cut

sub print_line
{
   my $self = shift;
   my $partial = ${*$self}{its_partial};
   my $status  = ${*$self}{its_status};

   $self->print( join "",
      ( length $status ? (
         # Clear the current status first in case the line is wider than the
         # terminal width
         ( length $partial ? $CLEARLINE : () ),
         "\n", $CLEARLINE, $PREVLINE,
      ) : () ),
      # Print the new content
      @_, "\n",
      ( length $status ? (
         # Leave an empty space for the partial
         $CLEARLINE, "\n",
         # Print the status
         _build_status( $status ),
         # Go back and print the partial
         $PREVLINEHOME
      ) : () ),
      ( length $partial ? $partial : () ),
   );
}

=head2 more_partial

   $io->more_partial( $more )

Adds more text to the pending partial line displayed at the bottom, after any
complete lines.

=cut

sub more_partial
{
   my $self = shift;
   my ( $more ) = @_;

   ${*$self}{its_partial} .= $more;

   $self->print( $more );
}

=head2 replace_partial

   $io->replace_partial( $more )

Replace the content of the pending partial line displayed at the bottom.

=cut

sub replace_partial
{
   my $self = shift;
   my ( $partial ) = @_;

   ${*$self}{its_partial} = $partial;

   $self->print( $CLEARLINE . $partial );
}

=head2 finish_partial

   $io->finish_partial( $more )

Adds more text to the pending partial line then turns it into a complete line
that gets printed.

=cut

sub finish_partial
{
   my $self = shift;
   my ( $more ) = @_;

   my $status  = ${*$self}{its_status};

   undef ${*$self}{its_partial};

   $self->print( join "",
      ( length $more ? $more : () ),
      "\n", $CLEARLINE,
      ( length $status ? (
         # Leave an empty space for the partial
         "\n",
         # Print the status
         _build_status( $status ),
         # Go back and print the partial
         $PREVLINEHOME
      ) : () )
   );
}

=head2 set_status

   $io->set_status( $status )

Sets the status message string.

=cut

sub set_status
{
   my $self = shift;
   my ( $status ) = @_;

   my $partial = ${*$self}{its_partial};

   ${*$self}{its_status} = $status;

   $self->print( join "",
      # Move to status line
      "\n",
      # Reprint the status
      $CLEARLINE,
      _build_status( $status ),
      # Go back and print the partial
      $PREVLINEHOME,
      ( length $partial ? $partial : () ),
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
