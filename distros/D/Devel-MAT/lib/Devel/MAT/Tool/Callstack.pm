#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Callstack;

use strict;
use warnings;

our $VERSION = '0.25';

use constant CMD => "callstack";

=head1 NAME

C<Devel::MAT::Tool::Callstack> - display the call stack

=head1 DESCRIPTION

This C<Devel::MAT> tool displays the captured state of the call stack, showing
which functions have been called, and what their arguments were.

=cut

sub _stringify
{
   my ( $sv ) = @_;

   if( $sv->type eq "SCALAR" ) {
      if( defined $sv->pv ) {
         my $str = substr $sv->pv, 0, 32;
         $str =~ s/'/\\'/g;
         return qq('$str') . ( $sv->pvlen > 32 ? "..." : "" );
      }
      else {
         return $sv->nv // $sv->uv // "undef";
      }
   }
   elsif( $sv->type eq "REF" ) {
      return "REF => " . _stringify( $sv->rv );
   }
   elsif( $sv->blessed ) {
      return sprintf "%s=%s(0x%x)", $sv->blessed->stashname, $sv->type, $sv->addr;
   }
   else {
      return sprintf "%s(0x%x)", $sv->type, $sv->addr;
   }
}

sub new
{
   my $class = shift;
   return bless { df => shift->dumpfile }, $class;
}

=head1 COMMANDS

=head2 callstack

Prints details of the call stack, including arguments to functions.

=cut

sub run_cmd
{
   my $self = shift;

   foreach my $ctx ( $self->{df}->contexts ) {
      my $where;
      my @more;

      for( $ctx->type ) {
         if( $_ eq "SUB" ) {
            my $cv = $ctx->cv;
            $where = $cv->name;

            my $args = $ctx->args or last;
            my @args = $args->elems;

            push @more, "\$_[$_]: " . _stringify( $args[$_] ) for 0 .. $#args;

            my $self_padix = $cv->padix_from_padname( '$self' )
               or last;

            ( my $depth = $ctx->depth ) > -1 or last;

            my $pad = $cv->pad( $depth );

            if( my $self_sv = $pad->elem( $self_padix ) ) {
               push @more, "\$self: " . _stringify( $self_sv );
            }
            else {
               push @more, "no \$self";
            }
         }
         elsif( $_ eq "TRY" ) {
            $where = "eval {...}";
         }
         elsif( $_ eq "EVAL" ) {
            my $code = substr $ctx->code->pv, 0, 32;
            $code =~ s/\n.*//;
            $where = 'eval ("' . $code . '"...)';
         }
      }

      Devel::MAT::Cmd->printf( "%s: %s => %s\n", $ctx->location, $where, $ctx->gimme );
      Devel::MAT::Cmd->printf( "  %s\n", $_ ) for @more;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
