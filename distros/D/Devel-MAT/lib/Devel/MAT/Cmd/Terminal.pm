#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk

package Devel::MAT::Cmd::Terminal;

use strict;
use warnings;

our $VERSION = '0.42';

use String::Tagged 0.15;  # sprintf
use String::Tagged::Terminal 0.03;  # ->print_to_terminal

use constant CAN_COLOUR => -t STDOUT;

=head1 NAME

C<Devel::MAT::Cmd::Terminal> - provide the L<Devel::MAT::Cmd> API on a terminal

=head1 DESCRIPTION

This module provides an implementation of the methods required for the
L<Devel::MAT::Cmd> API that outputs formatted text to a terminal. This is
performed by using L<String::Tagged::Terminal>.

=cut

my @FG = (
   3, # yellow
   6, # cyan
   5, # magenta
);

sub Devel::MAT::Cmd::printf
{
   shift;
   my ( $fmt, @args ) = @_;

   my $str = String::Tagged::Terminal->from_sprintf( $fmt, @args );

   CAN_COLOUR ? $str->print_to_terminal : print "$str";

   return length $str;
}

sub Devel::MAT::Cmd::format_note
{
   shift;
   my ( $str, $idx ) = @_;
   $idx //= 0;

   return String::Tagged->new_tagged( $str,
      bold    => 1,
      fgindex => $FG[$idx % 3],
   );
}

sub Devel::MAT::Cmd::_format_sv
{
   shift;
   my ( $ret, $sv ) = @_;

   return String::Tagged->new_tagged( $ret, bold => 1, italic => 1 );
}

sub Devel::MAT::Cmd::_format_value
{
   shift;
   return String::Tagged->new_tagged( $_[0], fgindex => 5+8 );
}

sub Devel::MAT::Cmd::format_symbol
{
   shift;
   my ( $name ) = @_;

   return String::Tagged->new_tagged( $name,
      fgindex => 2,
   );
}

sub Devel::MAT::Cmd::format_heading
{
   shift;
   my ( $text, $level ) = @_;

   $level //= 1;
   $level %= 3;

   return String::Tagged->new_tagged( $text,
      $level == 0 ? ( bold => 1 ) :
      $level == 1 ? ( under => 1 ) :
      $level == 2 ? ( fgindex => 6, under => 1 ) : (),
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
