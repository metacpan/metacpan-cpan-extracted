#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2018 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Find;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );

our $VERSION = '0.39';

use constant CMD => "find";
use constant CMD_DESC => "List SVs matching given criteria";

use constant CMD_OPTS => (
   count => { help => "Just print a count of the matching SVs",
              alias => "C" },
);

use Module::Pluggable
   sub_name => "FILTERS",
   search_path => [ "Devel::MAT::Tool::Find::filter" ],
   require => 1;

=head1 NAME

C<Devel::MAT::Tool::Find> - list SVs matching given criteria

=head1 DESCRIPTION

This C<Devel::MAT> tool provides a command to search for SVs matching given
criteria.

=cut

=head1 COMMANDS

=cut

=head2 find

   pmat> find io
   IO()=IO::File at 0x55a7e4d88760: ifileno=1 ofileno=1
   ...

Prints a list of all the SVs that match the given filter criteria.

Takes the following named options:

=over 4

=item --count, -C

Just count the matching SVs and print the total

=back

=cut

# TODO(leonerd): This is ugly; taking over ->run_cmd directly. See if we can
# integrate it better
sub run_cmd
{
   my $self = shift;
   my ( $inv ) = @_;

   my %opts = %{ $self->get_opts_from_inv( $inv, { $self->CMD_OPTS },
      permute => 0,
   ) };

   my @filters;
   while( length $inv->remaining ) {
      push @filters, $self->build_filter( $inv );
   }

   my $count = 0;

   SV: foreach my $sv ( $self->df->heap ) {
      my @output;

      # false => omit
      # 1     => include
      # else  => include with output value

      foreach my $filter ( @filters ) {
         my $o = $filter->( $sv ) or next SV;
         push @output, $o unless $o eq "1";
      }

      my $fmt = "%s";
      $fmt .= ": " . join( " ", ( "%s" ) x @output ) if @output;

      $count++, next if $opts{count};

      Devel::MAT::Cmd->printf( "$fmt\n",
         Devel::MAT::Cmd->format_sv( $sv ),
         @output
      );
   }

   Devel::MAT::Cmd->printf( "Total: %s SVs\n", $count ) if $opts{count};
}

sub help_cmd
{
   Devel::MAT::Cmd->printf( "\nSYNOPSIS:\n" );
   Devel::MAT::Cmd->printf( "  find [FILTER...]\n" );

   Devel::MAT::Cmd->printf( "\nFILTERS:\n" );

   foreach my $pkg ( FILTERS ) {
      my $name = $pkg =~ s/^Devel::MAT::Tool::Find::filter:://r;

      Devel::MAT::Cmd->printf( "  %s %s - %s\n",
         Devel::MAT::Cmd->format_note( "find" ),
         Devel::MAT::Cmd->format_note( $name ),
         $pkg->FILTER_DESC,
      );
   }
}

# to make help work
sub find_subcommand { return "Devel::MAT::Tool::Find::filter::$_[1]" }

sub build_filter
{
   my $self = shift;
   my ( $inv ) = @_;

   my $name = $inv->pull_token;
   my $filterpkg = "Devel::MAT::Tool::Find::filter::$name";
   $filterpkg->can( "build" ) or
      die "Unknown filter type '$name'";

   my @args;

   if( my %optspec = $filterpkg->FILTER_OPTS ) {
      push @args, $self->get_opts_from_inv( $inv, \%optspec );
   }

   if( my @argspec = $filterpkg->FILTER_ARGS ) {
      push @args, $self->get_args_from_inv( $inv, @argspec );
   }

   return $filterpkg->build( $inv, @args );
}

=head1 FILTERS

=cut

package # hide
   Devel::MAT::Tool::Find::filter;

sub CMD_DESC { return "find " . shift->FILTER_DESC }

use constant CMD_SUBS => ();

use constant FILTER_OPTS => ();
sub CMD_OPTS { shift->FILTER_OPTS }

use constant CMD_ARGS_SV => 0;

use constant FILTER_ARGS => ();
sub CMD_ARGS { shift->FILTER_ARGS }

package # hide
   Devel::MAT::Tool::Find::filter::pv;
use base qw( Devel::MAT::Tool::Find::filter );

use constant FILTER_DESC => "PV (string) SVs";

use constant FILTER_OPTS => (
   eq         => { help => "Pattern is an exact equality match" },
   regexp     => { help => "Pattern is a regular expression",
                   alias => "r" },
   ignorecase => { help => "Match case-insensitively",
                   alias => "i" },
);

use constant FILTER_ARGS => (
   { name => "pattern", help => "string pattern", required => 1 },
);

=head2 pv

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

sub build
{
   my $self = shift;
   shift; # inv
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

   return sub {
      my ( $sv ) = @_;
      return unless $sv->type eq "SCALAR";
      return unless defined( my $pv = $sv->pv );
      return unless $pv =~ $pattern;

      return Devel::MAT::Cmd->format_value( $pv, pv => 1 );
   };
}

package # hide
   Devel::MAT::Tool::Find::filter::io;
use base qw( Devel::MAT::Tool::Find::filter );

use constant FILTER_DESC => "IO SVs";

use constant FILTER_OPTS => (
   fileno => { help => "Match only this filenumber",
               type => "i",
               alias => "f" },
);

=head2 io

   pmat> find io
   IO()=IO::File at 0x55a7e4d88760: ifileno=1 ofileno=1
   ...

   pmat> find io -f 2
   IO()=IO::File at 0x55582b87f430: ifileno=2 ofileno=2

Searches for IO handles

Takes the following named options:

=over 4

=item --fileno, -f INT

Match only IO handles associated with the given filenumber.

=back

=cut

sub build
{
   my $self = shift;
   my $inv = shift;
   my %opts = %{ +shift };

   # Back-compat
   if( !defined $opts{fileno} and ( $inv->peek_token // "" ) =~ m/^\d+$/ ) {
      $opts{fileno} = $inv->pull_token;
   }

   if( defined( my $fileno = $opts{fileno} ) ) {
      return sub {
         my ( $sv ) = @_;
         return unless $sv->type eq "IO";

         my $imatch = $sv->ifileno == $fileno;
         my $omatch = $sv->ofileno == $fileno;
         return unless $imatch or $omatch;

         return String::Tagged->from_sprintf( "ifileno=%s ofileno=%s",
            $imatch ? Devel::MAT::Cmd->format_note( $sv->ifileno ) : $sv->ifileno,
            $omatch ? Devel::MAT::Cmd->format_note( $sv->ofileno ) : $sv->ofileno,
         );
      }
   }
   else {
      return sub {
         my ( $sv ) = @_;
         return unless $sv->type eq "IO";
         return String::Tagged->from_sprintf( "ifileno=%s ofileno=%s",
            $sv->ifileno,
            $sv->ofileno,
         );
      }
   }
}

package # hide
   Devel::MAT::Tool::Find::filter::blessed;
use base qw( Devel::MAT::Tool::Find::filter );

=head2 blessed

   pmat> find blessed Config
   HASH(26)=Config at 0x55bd56c28930

Searches for SVs blessed into the given package name.

=cut

use constant FILTER_DESC => "blessed SVs";

use constant FILTER_ARGS => (
   { name => "package", help => "the blessed package", required => 1 },
);

sub build
{
   my $self = shift;
   my ( $inv, $package ) = @_;

   defined $package or
      die "Expected package name for 'blessed' filter";

   return sub {
      my ( $sv ) = @_;
      return unless my $stash = $sv->blessed;
      return $stash->stashname eq $package;
   };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
