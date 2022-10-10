#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2022 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Future 0.02;

use v5.14;
use warnings;
use base qw( Devel::MAT::Tool );
Devel::MAT::Tool->VERSION( '0.49' );

use Carp;

use Syntax::Keyword::Match;
use String::Tagged;

use constant FOR_UI => 1;

use File::ShareDir qw( module_file );

=head1 NAME

C<Devel::MAT::Tool::Future> - analyse C<Future> logic

=head1 DESCRIPTION

This C<Devel::MAT> tool performs analysis of objects and code logic built
using the L<Future> module.

This version supports analysing code based on C<Future> version 0.24.

=cut

sub AUTOLOAD_TOOL
{
   shift;
   my ( $pmat ) = @_;
   return 1 if eval { $pmat->find_symbol( '%Future::' ) };
}

sub init_tool
{
   my $self = shift;

   my $df = $self->df;

   my $heap_total = scalar $df->heap;
   my $count;

   # Find all the classes that derive from Future
   $self->{classes} = \my %classes;
   $classes{Future}++;

   $count = 0;
   foreach my $sv ( $df->heap ) {
      $count++;
      $self->report_progress( sprintf "Finding Future subclasses in %d of %d (%.2f%%)",
         $count, $heap_total, 100*$count / $heap_total ) if ($count % 1000) == 0;

      next unless $sv->type eq "STASH";

      # populate the %classes hash
      $self->class_is_future( $sv );
   }

   $count = 0;
   foreach my $sv ( $df->heap ) {
      $count++;
      $self->report_progress( sprintf "Finding Future instances in %d of %d (%.2f%%)",
         $count, $heap_total, 100*$count / $heap_total ) if ($count % 1000) == 0;

      next unless my $pkg = $sv->blessed;

      $classes{ $pkg->stashname } and $sv->{tool_future}++;
   }

   $self->init_cmd;
}

sub init_cmd
{
   my $self = shift;

   Devel::MAT::Tool::Show->register_extra(
      sub {
         my ( $sv ) = @_;

         $sv->is_future or return undef;

         my $state = $sv->future_state;

         Devel::MAT::Cmd->printf( "  %s state %s\n",
            Devel::MAT::Cmd->format_symbol( "Future" ),
            $state,
         );

         match( $state : eq ) {
            case( "done" ) {
               my @result = $sv->future_result;
               my @str;
               push @str, "(empty)" if !@result;
               push @str, Devel::MAT::Cmd->format_sv_with_value( $result[0] ) if @result;
               push @str, "..." if @result > 1;

               Devel::MAT::Cmd->printf( "  %s result: %s\n",
                  Devel::MAT::Cmd->format_symbol( "Future" ),
                  String::Tagged->join( ", ", @str ),
               );
            }
            case( "failed" ) {
               my @failure = $sv->future_failure;
               my @str;
               push @str, "(empty)" if !@failure;
               if( @failure ) {
                  push @str, defined $failure[0]->pv
                     ? Devel::MAT::Cmd->format_value( $failure[0]->pv, pv => 1 )
                     : Devel::MAT::Cmd->format_sv( $failure[0] );
                  push @str, "..." if @failure > 1;
               }

               Devel::MAT::Cmd->printf( "  %s failure: %s\n",
                  Devel::MAT::Cmd->format_symbol( "Future" ),
                  String::Tagged->join( ", ", @str ),
               );
            }
         }
      }
   );
}

sub init_ui
{
   my $self = shift;
   my ( $ui ) = @_;

   foreach (qw( pending done failed cancelled )) {
      $ui->register_icon( name => "future-$_", svg => module_file( __PACKAGE__, "icons/future-$_.svg" ) );
   }

   $ui->provides_sv_detail(
      type   => "widget",
      title  => "Future",
      render => sub { $self->render_sv_detail( @_ ) },
   );
}

=head1 METHODS

=cut

=head2 class_is_future

   $ok = $tool->class_is_future( $pkg )

Returns true if the given package is a C<Future> class. C<$pkg> may be either
a C<Devel::MAT::SV> instance referring to a stash, or a plain string.

=cut

# TODO: This kind of logic might belong in Devel::MAT::SV itself

sub class_is_future
{
   my $self = shift;
   my ( $pkg ) = @_;
   ref $pkg or $pkg = $self->{pmat}->find_symbol( "%${pkg}::" ); # stash

   return $self->{classes}{$pkg->stashname} //= $self->_class_is_future( $pkg );
}

sub _class_is_future
{
   my $self = shift;
   my ( $pkg ) = @_;

   return 1 if $pkg->stashname eq "Future";

   my $isagv = $pkg->value( "ISA" ) or return 0;
   my $isaav = $isagv->array or return 0;

   foreach my $superclass ( $isaav->elems ) {
      return 1 if $self->class_is_future( $superclass->pv );
   }

   return 0;
}

=head1 SV METHODS

This tool adds the following SV methods.

=cut

=head2 is_future (SV)

   $ok = $sv->is_future

Returns true if the C<Devel::MAT::SV> instance represents a C<Future>
instance.

=cut

sub Devel::MAT::SV::is_future
{
   my $sv = shift;

   return defined $sv->{tool_future};
}

sub Devel::MAT::SV::_future_xs_struct
{
   my $sv = shift;

   $sv->basetype eq "SV" or return undef;

   my $ref = $sv->maybe_outref_named( "the FutureXS structure" ) or return undef;
   return $ref->sv;
}

=head2 future_state (SV)

   $state = $sv->future_state

Returns a string describing the state of the given C<Future> instance; one of
C<pending>, C<done>, C<failed> or C<cancelled>.

=cut

sub Devel::MAT::SV::future_state
{
   my $sv = shift;

   $sv->is_future or croak "$sv is not a Future";

   if( my $struct = $sv->_future_xs_struct ) {
      # Using Future::XS
      if( $struct->field_named( "cancelled" ) ) {
         return "cancelled";
      }
      elsif( $struct->maybe_field_named( "the failure AV" ) ) {
         return "failed";
      }
      elsif( $struct->field_named( "ready" ) ) {
         return "done";
      }
      else {
         return "pending";
      }
   }
   else {
      # Using Future::PP
      my $tmp;
      if( $tmp = $sv->value( "cancelled" ) and $tmp->uv ) {
         return "cancelled";
      }
      elsif( $tmp = $sv->value( "failure" ) ) {
         return "failed";
      }
      elsif( $tmp = $sv->value( "ready" ) and $tmp->uv ) {
         return "done";
      }
      else {
         return "pending";
      }
   }
}

=head2 future_result

   @result = $sv->future_result

Returns a list of SVs containing the result of a successful C<Future>.

=cut

sub Devel::MAT::SV::future_result
{
   my $sv = shift;

   $sv->is_future or croak "$sv is not a Future";

   if( my $struct = $sv->_future_xs_struct ) {
      # Using Future::XS
      return $struct->field_named( "the result AV" )->elems;
   }
   else {
      # Using Future::PP
      return $sv->value( "result" )->rv->elems;
   }
}

=head2 future_failure

   @failure = $sv->future_failure

Returns a list of SVs containing the failure of a failed C<Future>.

=cut

sub Devel::MAT::SV::future_failure
{
   my $sv = shift;

   $sv->is_future or croak "$sv is not a Future";

   if( my $struct = $sv->_future_xs_struct ) {
      # Using Future::XS
      return $struct->field_named( "the failure AV" )->elems;
   }
   else {
      # Using Future::XS
      return $sv->value( "failure" )->rv->elems;
   }
}

sub render_sv_detail
{
   my $self = shift;
   my ( $sv ) = @_;

   $self->is_future( $sv ) or return undef;

   my $state = $self->future_state( $sv );

   return Devel::MAT::UI->make_table(
      State => Devel::MAT::UI->make_widget_text_icon( ucfirst $state, "future-$state" ),
   );
}

=head1 EXTENSIONS TO FIND

=cut

package # hide
   Devel::MAT::Tool::Find::filter::future;
use base qw( Devel::MAT::Tool::Find::filter );

=head2 find future

   pmat> find future -f
   HASH(2)=Future at 0x55d43c854660: Future(failed) - SCALAR(PV) at 0x55d43c8546f0 = "It failed"

Lists SVs that are Future instances, optionally matching only futures in a
given state.

Takes the following named options

=over 4

=item --pending, -p

Lists only Futures in the pending state

=item --done, -d

Lists only Futures in the done state

=item --failed, -f

Lists only Futures in the failed state

=item --cancelled, -c

Lists only Futures in the cancelled state

=back

=cut

use constant FILTER_DESC => "Future instances";

use constant FILTER_OPTS => (
   pending   => { help => "only pending futures",
                  alias => "p" },
   done      => { help => "only done futures",
                  alias => "d" },
   failed    => { help => "only failed futures",
                  alias => "f" },
   cancelled => { help => "only cancelled futures",
                  alias => "c" },
);

sub build
{
   my $self = shift;
   my $inv = shift;
   my %opts = %{ +shift };

   my %only;
   $opts{$_} and $only{$_}++ for qw( pending done failed cancelled );

   return sub {
      my ( $sv ) = @_;

      return unless $sv->is_future;

      my $state = $sv->future_state;

      return if %only and !$only{$state};

      my $ret = String::Tagged->from_sprintf( "%s(%s)",
         Devel::MAT::Cmd->format_symbol( "Future" ), # TODO: full class name of this instance?
         Devel::MAT::Cmd->format_note( $state, 1 ),
      );

      match( $state : eq ) {
         case( "done" ) {
            my @result = $sv->future_result;
            $ret .= " - (empty)" if !@result;
            $ret .= " - " . Devel::MAT::Cmd->format_sv_with_value( $result[0] ) if @result;
            $ret .= ", ..." if @result > 1;
         }
         case( "failed" ) {
            my @failure = $sv->future_failure;
            $ret .= " - (empty)" if !@failure;
            if( @failure ) {
               $ret .= " - " . ( defined $failure[0]->pv
                     ? Devel::MAT::Cmd->format_value( $failure[0]->pv, pv => 1 )
                     : Devel::MAT::Cmd->format_sv( $failure[0] ) );
               $ret .= ", ..." if @failure > 1;
            }
         }
      }

      return $ret;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
