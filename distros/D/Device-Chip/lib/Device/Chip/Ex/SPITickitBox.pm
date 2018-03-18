#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk

package Device::Chip::Ex::SPITickitBox;

use strict;
use warnings;

use base 'Tickit::Widget::GridBox';

use Syntax::Keyword::Try;

use Tickit;
use Tickit::Widgets qw( GridBox Button Static Entry Choice );

Tickit::Style->load_style( <<'EOSTYLE' );
Static.readout {
  bg: "green"; fg: "black";
}
EOSTYLE

sub new
{
   my $class = shift;
   my ( $proto ) = @_;

   my $self = $class->SUPER::new(
      style => {
         row_spacing => 1,
         col_spacing => 1,
      },
   );

   $self->append_row(
      [
         Tickit::Widget::Static->new(
            text   => "Mode",
            valign => "middle",
         ),

         Tickit::Widget::Choice->new(
            choices => [
               [ 0, "Mode 0" ],
               [ 1, "Mode 1" ],
               [ 2, "Mode 2" ],
               [ 3, "Mode 3" ],
            ],
            on_changed => sub {
               my ( undef, $mode ) = @_;
               $proto->configure( mode => $mode );
            },
         ),
      ]
   );

   # Default to mode 0
   $proto->configure( mode => 0 );

   $self->append_row(
      [
         Tickit::Widget::Static->new(
            text   => "Write",
            valign => "middle",
         ),

         my $writeentry = Tickit::Widget::Entry->new,

         my $writebutton = Tickit::Widget::Button->new(
            label => "Write",
         ),
      ]
   );

   $writeentry->set_on_enter( sub {
      $writebutton->click;
   });
   $writebutton->set_on_click( sub {
      my $text = $writeentry->text;
      $writeentry->set_text( "" );

      try {
         $self->write( $text );
      }
      catch {
         print STDERR "TODO: Error $@";
      }
   });

   $self->append_row(
      [
         Tickit::Widget::Static->new(
            text   => "Read",
            valign => "middle",
         ),

         my $readsizeentry = Tickit::Widget::Entry->new,

         my $readbutton = Tickit::Widget::Button->new(
            label => "Read",
         ),
      ]
   );

   $readsizeentry->set_on_enter( sub {
      $readbutton->click;
   });
   $readbutton->set_on_click( sub {
      $self->read( $readsizeentry->text );
      $readsizeentry->set_text( "" );
   });

   $self->add( $self->rowcount, 1,
      $self->{readresultlabel} = Tickit::Widget::Static->new(
         text  => "",
         class => "readout",
      ),
      col_expand => 1,
      row_expand => 1,
   );

   # TODO: selection of SS GPIO line

   $self->{protocol} = $proto;

   return $self;
}

sub write
{
   my $self = shift;
   my ( $text ) = @_;

   my $bytes = "";

   local $_ = $text;
   while( length ) {
      s/^\s+// and next;

      s/^"// and do {
         s/^((?:[^"]*|\\.)*)//;
         my $str = $1;
         $bytes .= $str =~ s/\\(.)/$1/gr;
         s/^"// or die "Unterminated \" string\n";
      }, next;

      s/^0x// and do {
         s/^([[:xdigit:]]+)// or die "Unrecognised hex number\n";
         $bytes .= chr hex $1;
      }, next;

      s/^([[:digit:]]+)// and do {
         $bytes .= chr $1;
      }, next;

      die "Unrecognised input '" . substr( $_, 0, 5 ) . "'...\n";
   }

   $self->_do_readwrite( $bytes );
}

sub read
{
   my $self = shift;
   my ( $len ) = @_;

   $self->_do_readwrite( "\x00" x $len );
}

sub _do_readwrite
{
   my $self = shift;
   my ( $words_out ) = @_;

   my $words_in = $self->{protocol}->readwrite( $words_out )->get;

   $self->{readresultlabel}->set_text(
      join " ", map { sprintf "0x%02X", ord } split m//, $words_in,
   );
}

0x55AA;
