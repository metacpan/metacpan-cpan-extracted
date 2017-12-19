#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Find;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );

our $VERSION = '0.32';

use constant CMD => "find";
use constant CMD_DESC => "List SVs matching given criteria";

=head1 NAME

C<Devel::MAT::Tool::Find> - list SVs matching given criteria

=head1 DESCRIPTION

This C<Devel::MAT> tool provides commands to search for SVs matching given
criteria.

=cut

=head1 COMMANDS

=cut

use constant CMD_SUBS => (
   "pv",
   "io",
);

package # hide
   Devel::MAT::Tool::Find::pv;
use base qw( Devel::MAT::Tool );

use constant CMD_DESC => "List PV SVs";

=head2 find pv

   pmat> find pv "boot"
   SCALAR(PV) at 0x556e4737d968: "boot_Devel::MAT::Dumper"
   SCALAR(PV) at 0x556e4733a160: "boot_Cwd"
   ...

Prints a list of all the scalar SVs that have a PV (string value) matching the
supplied pattern. Normally, the pattern is interpreted as a substring match,
but the C<--eq> and C<--regexp> options can alter this.

Takes the following named options:

=over 4

=item --eq

Interpret the pattern as a full string equality match, instead of substring.

=item --regexp, -r

Interpret the pattern as a regular expression, instead of a literal substring.

=item --ignorecase, -i

Match case-insensitively, for any of substring, equality or regexp match.

=back

=cut

use constant CMD_OPTS => (
   eq         => { help => "Pattern is an exact equality match" },
   regexp     => { help => "Pattern is a regular expression",
                   alias => "r" },
   ignorecase => { help => "Match case-insensitively",
                   alias => "i" },
);

use constant CMD_ARGS => (
   { name => "pattern", help => "string pattern" },
);

sub run
{
   my $self = shift;
   my %opts = %{ +shift };
   my ( $pattern ) = @_;

   my $flags = $opts{ignorecase} ? "i" : "";

   if( $opts{eq} ) {
      $pattern = qr/(?$flags)^\Q$pattern\E$/;
   }
   elsif( $opts{regexp} ) {
      $pattern = qr/(?$flags)$pattern/;
   }
   else {
      # substring
      $pattern = qr/(?$flags)\Q$pattern\E/;
   }

   foreach my $sv ( $self->df->heap ) {
      next unless $sv->type eq "SCALAR";
      next unless defined( my $pv = $sv->pv );
      next unless $pv =~ $pattern;

      Devel::MAT::Cmd->printf( "%s: %s\n",
         Devel::MAT::Cmd->format_sv( $sv ),
         Devel::MAT::Cmd->format_value( $pv, pv => 1 ),
      );
   }
}

package # hide
   Devel::MAT::Tool::Find::io;
use base qw( Devel::MAT::Tool );

use constant CMD_DESC => "List IO SVs";

=head2 find io

   pmat> find io 2
   IO()=IO::File at 0x55582b87f430: ifileno=2 ofileno=2

Searches for an IO handle that is associated with the given filenumber.

=cut

use constant CMD_ARGS => (
   { name => "fileno", help => "the file number" },
);

sub run
{
   my $self = shift;
   my ( $fileno ) = @_;

   foreach my $sv ( $self->df->heap ) {
      next unless $sv->type eq "IO";

      my $imatch = $sv->ifileno == $fileno;
      my $omatch = $sv->ofileno == $fileno;
      next unless $imatch or $omatch;

      Devel::MAT::Cmd->printf( "%s: %s %s\n",
         Devel::MAT::Cmd->format_sv( $sv ),
         "ifileno=" . ( $imatch ? Devel::MAT::Cmd->format_note( $sv->ifileno ) : $sv->ifileno ),
         "ofileno=" . ( $omatch ? Devel::MAT::Cmd->format_note( $sv->ofileno ) : $sv->ofileno ),
      );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
