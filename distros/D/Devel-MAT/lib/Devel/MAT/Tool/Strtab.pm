#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Strtab 0.54;

use v5.14;
use warnings;
use base qw( Devel::MAT::Tool );

use Syntax::Keyword::Match;

use constant CMD => "strtab";
use constant CMD_DESC => "Show information about the shared strings table (PL_strtab)";

=head1 NAME

C<Devel::MAT::Tool::Strtab> - show information about the shared string table

=head1 DESCRIPTION

This C<Devel::MAT> tool provides a command for listing entries from the shared
string table, and identifying places where those strings are used.

=cut

=head1 COMMANDS

=cut

=head2 strtab

   pmat> strtab
   ...

Prints a list of the keys from the shared string table. For each entry, it
attempts to identify other places where the string is shared.

Takes the following named options:

=over 4

=item --count, -c MAX

Show at most this number of values (default 10).

=item --skip, -s COUNT

Skip over this number of keys initially before starting to print.

=item --no-sort, -n

Don't bother to sort keys before printing. Keys will be printed in no
particular order (though the order will at least be stable between successive
invocations of the command during the same session).

=back

Takes the following positional arguments:

=over 4

=item *

Optional filter pattern. If present, will only count and display keys matching
the given regexp. Must be specified in the form C</PATTERN/> with optional
trailing flags. The only permitted flags are C<adilmsux>.

=back

=cut

use constant CMD_OPTS => (
   count => { help => "maximum count of values to print",
              type => "i",
              alias => "c",
              default => 10 },
   skip => { help => "count of keys to skip initially before printing",
             type => "i",
             alias => "s" },
   no_sort => { help => "don't sort keys before printing",
                alias => "n" },
);

use constant CMD_ARGS => (
   { name => "filter", help => "optional pattern to filter keys by" },
);

sub _init_hek_users
{
   my $self = shift;

   my %hek_users;

   foreach my $sv ( $self->df->heap ) {
      my $hek;

      match( $sv->type : eq ) {
         case( "HASH" ) {
            next if $sv == $self->df->strtab;

            foreach my $key ( $sv->keys ) {
               $hek = $sv->hek_at( $key ) and
                  push @{ $hek_users{$hek} }, $sv;
            }
         }
         case( "GLOB" ),
         case( "CODE" ) {
            $hek = $sv->name_hek and
               push @{ $hek_users{$hek} }, $sv;
         }
         case( "SCALAR" ) {
            $hek = $sv->shared_hek and
               push @{ $hek_users{$hek} }, $sv;
         }
      }
   }

   return \%hek_users;
}

sub run
{
   my $self = shift;
   my %opts = %{ +shift };
   my ( $filter ) = @_;

   my $strtab = $self->df->strtab;

   my @keys = $strtab->keys;
   if( length $filter ) {
      $filter =~ m/^\/(.*)\/([adilmsux]*)$/ or
         die "Filter must be a /PATTERN.../ with optional flags";
      my ( $pattern, $flags ) = ( $1, $2 );
      my $re = qr/(?$flags:$pattern)/;
      @keys = grep { $_ =~ $re } @keys;
   }
   @keys = sort @keys unless $opts{no_sort};
   splice @keys, 0, $opts{skip} if $opts{skip};

   my $hek_users = $self->{hek_users} //= $self->_init_hek_users;

   Devel::MAT::Tool::more->paginate( { pagesize => $opts{count} }, sub {
      my ( $count ) = @_;
      my @rows;
      foreach my $key ( splice @keys, 0, $count ) {
         my $hek = $strtab->hek_at( $key );

         push @rows, [
            Devel::MAT::Cmd->format_value( $key, key => 1 ),
            "HEK at " . Devel::MAT::Cmd->format_value( $hek, addr => 1 ),
         ];

         my $users = $hek_users->{$hek} or next;

         foreach my $sv ( @$users ) {
            match( $sv->type : eq ) {
               case( "HASH" ) {
                  push @rows, [
                     "  key of " . Devel::MAT::Cmd->format_sv( $sv ),
                     "",
                  ];
               }
               case( "GLOB" ),
               case( "CODE" ) {
                  push @rows, [
                     "  name of " . Devel::MAT::Cmd->format_sv( $sv ),
                     "",
                  ];
               }
               case( "SCALAR" ) {
                  push @rows, [
                     "  shared PV of " . Devel::MAT::Cmd->format_sv( $sv ),
                     "",
                  ];
               }
            }
         }
      }

      Devel::MAT::Cmd->print_table( \@rows, indent => 2 );

      my $morecount = @keys;
      Devel::MAT::Cmd->printf( "  ... (%d more)\n", $morecount ) if $morecount;
      return $morecount;
   } );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
