#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2020 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Find 0.53;

use v5.14;
use warnings;
use base qw( Devel::MAT::Tool );

use Scalar::Util qw( blessed );

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
   while( length $inv->peek_remaining ) {
      push @filters, $self->build_filter( $inv );
   }

   if( $opts{count} ) {
      my $count = 0;
      SV: foreach my $sv ( $self->df->heap ) {
         foreach my $filter ( @filters ) {
            my $ret = $filter->( $sv ) or next SV;
            if( !blessed $ret and ref $ret eq "HASH" ) {
               $sv = $ret->{sv} if $ret->{sv};
            }
         }

         $count++;
      }

      Devel::MAT::Cmd->printf( "Total: %s SVs\n", $count ) if $opts{count};
      return;
   }

   my @svs = $self->df->heap;
   my ( $sv, @output );
   Devel::MAT::Tool::more->paginate( sub {
      my ( $count ) = @_;
      SV: while( $sv = shift @svs ) {
         @output = ();

         foreach my $filter ( @filters ) {
            my $ret = $filter->( $sv ) or next SV;
            # Allow filters to alter the search as we go
            if( !blessed $ret and ref $ret eq "HASH" ) {
               $sv = $ret->{sv} if $ret->{sv};
               push @output, $ret->{output} if $ret->{output};
            }
            else {
               push @output, $ret;
            }
         }

         my $fmt = "%s";
         $fmt .= ": " . join( " ", ( "%s" ) x @output ) if @output;

         Devel::MAT::Cmd->printf( "$fmt\n",
            Devel::MAT::Cmd->format_sv( $sv ),
            @output
         );

         last SV unless $count--;
      }

      return !!@svs;
   } );
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

use constant FILTER_OPTS => ();
sub CMD_OPTS { shift->FILTER_OPTS }

use constant CMD_ARGS_SV => 0;

use constant FILTER_ARGS => ();
sub CMD_ARGS { shift->FILTER_ARGS }

package # hide
   Devel::MAT::Tool::Find::filter::num;
use base qw( Devel::MAT::Tool::Find::filter );

use constant FILTER_DESC => "Numerical (IV, UV or NV) SVs";

use constant FILTER_OPTS => (
   iv => { help => "Include IVs" },
   uv => { help => "Include UVs" },
   nv => { help => "Include NVs" },
);

use constant FILTER_ARGS => (
   { name => "value", help => "match value" },
);

=head2 num

   pmat> find num
   SCALAR(UV) at 0x555555a1e9c0: 5
   SCALAR(UV) at 0x555555c4f1b0: 2
   SCALAR(UV) at 0x555555aa0dc0: 18446744073709551615

Prints a list of all the scalar SVs that have a numerical value, optionally
filtering for only an exact value.

Takes the following named options:

=over 4

=item --nv, --iv, --uv

Find only numerical SVs of the given types. If no options present, any
numerical SV will be found.

=back

=cut

sub build
{
   my $self = shift;
   shift; # inv
   my %opts = %{ +shift };
   my ( $value ) = @_;

   $opts{iv} or $opts{uv} or $opts{nv} or
      $opts{iv} = $opts{uv} = $opts{nv} = 1;

   return sub {
      my ( $sv ) = @_;
      return unless $sv->type eq "SCALAR";

      if( $opts{nv} and defined( my $nv = $sv->nv ) ) {
         defined $value and $nv != $value and return;
         return Devel::MAT::Cmd->format_value( $nv, nv => 1 );
      }

      if( $opts{iv} and defined( my $iv = $sv->iv ) ) {
         defined $value and $iv != $value and return;
         return Devel::MAT::Cmd->format_value( $iv, iv => 1 );
      }

      if( $opts{uv} and defined( my $uv = $sv->uv ) ) {
         defined $value and $uv != $value and return;
         return Devel::MAT::Cmd->format_value( $uv, uv => 1 );
      }
   };
}

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
   Devel::MAT::Tool::Find::filter::cv;
use base qw( Devel::MAT::Tool::Find::filter );

use constant FILTER_DESC => "Code CVs";

use constant FILTER_OPTS => (
   xsub    => { help => "Is an XSUB" },
   package => { help => "In the given package",
                type => "s",
                alias => "p" },
   file    => { help => "Location is the given file",
                type => "s",
                alias => "f" },
);

sub build
{
   my $self = shift;
   my $inv = shift;
   my %opts = %{ +shift };

   return sub {
      my ( $sv ) = @_;
      return unless $sv->type eq "CODE";
      if( $opts{xsub} ) {
         return if !$sv->is_xsub;
      }
      if( $opts{package} ) {
         my $stash = $sv->glob ? $sv->glob->stash : return;
         return if $stash->stashname ne $opts{package};
      }
      if( $opts{file} ) {
         return if $sv->file ne $opts{file};
      }

      # Selected
      if( my $symname = $sv->symname ) {
         return Devel::MAT::Cmd->format_symbol( $symname );
      }
      else {
         return "__ANON__";
      }
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
      return unless $stash->stashname eq $package;
      return Devel::MAT::Cmd->format_value( $stash->stashname );
   };
}

package # hide
   Devel::MAT::Tool::Find::filter::lexical;
use base qw( Devel::MAT::Tool::Find::filter );

=head2 lexical

   pmat> find lexical $x
   UNDEF() at 0x56426e97c8b0: $x at depth 1 of CODE(PP) at 0x56426e97c5e0
   ...

Searches for SVs that are lexical variables of the given name.

=cut

use constant FILTER_DESC => "lexical variables";

use constant FILTER_ARGS => (
   { name => "name", help => "the variable name", required => 1 },
);

use constant FILTER_OPTS => (
   inactive => { help => "Include variables in non-live pads",
                 alias => "I" },
);

sub build
{
   my $self = shift;
   my $inv = shift;
   my %opts = %{ +shift };
   my ( $name ) = @_;

   defined $name or
      die "Expected variable name for 'lexical' filter";

   # We'll actually match pad which contains such a lexical. then redirect the
   # search onto the SV itself
   return sub {
      my ( $pad ) = @_;
      return unless $pad->type eq "PAD";
      return unless my $sv = $pad->maybe_lexvar( $name );

      my $cv = $pad->padcv;

      my $depth;
      my @pads = $cv->pads;
      $pad == $pads[$_] and $depth = $_+1 and last
         for 0 .. $#pads;

      # This isn't a real hit unless the pad is live
      my $is_live = $depth <= $cv->depth;
      return unless $is_live || $opts{inactive};

      return {
         sv     => $sv,
         output => String::Tagged->from_sprintf( "%s at depth %d%s of %s",
            Devel::MAT::Cmd->format_note( $name, 1 ),
            $depth, $is_live ? "" : Devel::MAT::Cmd->format_note( " [inactive]", 2 ),
            Devel::MAT::Cmd->format_sv( $cv )
         ),
      };
   };
}

package # hide
   Devel::MAT::Tool::Find::filter::struct;
use base qw( Devel::MAT::Tool::Find::filter );

=head2 struct

   pmat> find struct Module::Name/Type
   C_STRUCT(Module::Name/Type) at 0x55e0c3017bf0: Module::Name/Type
   ...

Searches for SVs that are C structures of the given type name.

=cut

use constant FILTER_DESC => "structs";

use constant FILTER_ARGS => (
   { name => "name", help => "the structure type name", required => 1 },
);

sub build
{
   my $self = shift;
   my $inv = shift;
   my ( $name ) = @_;

   defined $name or
      die "Expected structure type name for 'struct' filter";

   return sub {
      my ( $struct ) = @_;
      return unless $struct->type eq "C_STRUCT";
      my $type = $struct->structtype;
      return unless $type->name eq $name;

      return Devel::MAT::Cmd->format_value( $type->name );
   };
}

package # hide
   Devel::MAT::Tool::Find::filter::magic;;
use base qw( Devel::MAT::Tool::Find::filter );

=head2 magic

=cut

use constant FILTER_DESC => "SVs with magic";

use constant FILTER_OPTS => (
   vtbl => { help => "the VTBL pointer",
             type => "x",
             alias => "v" },
);

sub build
{
   my $self = shift;
   my $inv = shift;
   my %opts = %{ +shift };

   if( my $vtbl = $opts{vtbl} ) {
      return sub {
         my ( $sv ) = @_;
         my @magics = $sv->magic or return;
         foreach my $magic ( @magics ) {
            next unless defined $magic->vtbl and $magic->vtbl == $vtbl;

            my $ret = String::Tagged->from_sprintf( "magic type '%s'",
               $magic->type,
            );

            $ret .= ", with object " . Devel::MAT::Cmd->format_sv( $magic->obj ) if $magic->obj;

            $ret .= ", with pointer " . Devel::MAT::Cmd->format_sv( $magic->ptr ) if $magic->ptr;

            return $ret;
         }
      };
   }

   die "Expected --vtbl\n";
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
