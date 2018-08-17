#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2018 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Reachability;

use strict;
use warnings;

our $VERSION = '0.39';

use constant FOR_UI => 1;

use List::Util qw( pairvalues );

=head1 NAME

C<Devel::MAT::Tool::Reachability> - analyse how SVs are reachable

=head1 DESCRIPTION

This C<Devel::MAT> tool determines which SVs are reachable via any known roots
and which are not. For reachable SVs, they are classified into several broad
categories:

=over 2

=item *

SVs that directly make up the symbol table.

=item *

SVs that form the padlist of functions or store the names of lexical
variables.

=item *

SVs that hold the value of lexical variables.

=item *

User data stored in package globals, lexical variables, or referenced
recursively via structures stored in them.

=item *

Miscellaneous other SVs that are used to implement the internals of the
interpreter.

=back

=cut

use constant {
   REACH_SYMTAB   => 1,
   REACH_USER     => 2,
   REACH_PADLIST  => 3,
   REACH_LEXICAL  => 4,
   REACH_INTERNAL => 5,
};

sub new
{
   my $class = shift;
   my ( $pmat, %args ) = @_;

   *Devel::MAT::SV::reachable = sub {
      my $sv = shift;
      return $sv->{tool_reachable};
   };

   $class->mark_reachable( $pmat->dumpfile, progress => $args{progress} );

   return $class;
}

my @ICONS = (
   "none", "symtab", "user", "padlist", "lexical", "internal"
);
sub _reach2icon
{
   my ( $sv ) = @_;
   my $reach = $sv->{tool_reachable} // 0;

   my $icon = $ICONS[$reach] // die "Unknown reachability value $reach";
   return "reachable-$icon";
}

sub init_ui
{
   my $self = shift;
   my ( $ui ) = @_;

   foreach ( @ICONS ) {
      $ui->register_icon(
         name => "reachable-$_",
         svg  => "icons/reachable-$_.svg"
      );
   }

   my $column = $ui->provides_svlist_column(
      title => "R",
      type  => "icon",
   );

   $ui->provides_sv_detail(
      title  => "Reachable",
      type   => "icon",
      render => \&_reach2icon,
   );

   $ui->set_svlist_column_values(
      column => $column,
      from   => \&_reach2icon,
   );
}

sub mark_reachable
{
   my $self = shift;
   my ( $df, %args ) = @_;

   my $progress = $args{progress};

   my @user;
   my @internal;

   # First, walk the symbol table
   {
      my @symtab = ( $df->defstash );
      $symtab[0]->{tool_reachable} = REACH_SYMTAB;

      my $count = 0;
      while( @symtab ) {
         my $stash = shift @symtab;
         $stash->type eq "STASH" or die "ARGH! Encountered non-stash ".$stash->desc_addr;

         my @more_symtab;
         my @more_user;

         foreach my $key ( $stash->keys ) {
            my $value = $stash->value( $key );

            # Keys ending :: signify sub-stashes
            if( $key =~ m/::$/ ) {
               push @more_symtab, $value->hash;
            }
            # Otherwise it might be a glob
            elsif( $value->type eq "GLOB" ) {
               my $gv = $value;
               $gv->{tool_reachable} = REACH_SYMTAB;

               defined $_ and push @more_user, $_ for
                  $gv->scalar, $gv->array, $gv->hash, $gv->code, $gv->io, $gv->form;
            }
            # Otherwise it might be a SCALAR/ARRAY/HASH directly in the STASH
            else {
               push @more_user, $value;
            }

            $count++;
            $progress->( sprintf "Walking symbol table %d...", $count ) if $progress and $count % 1000 == 0;
         }

         !$_->{tool_reachable} and
            $_->{tool_reachable} = REACH_SYMTAB, push @symtab, $_ for @more_symtab;

         !$_->{tool_reachable} and
            $_->{tool_reachable} = REACH_USER, push @user, $_ for @more_user;

         !$_->{tool_reachable} and
            $_->{tool_reachable} = REACH_INTERNAL, push @internal, $_ for
               $stash->backrefs,
                $stash->mro_linearall,
                $stash->mro_linearcurrent,
                $stash->mro_nextmethod,
                $stash->mro_isa,
                grep { defined } $stash->magic_svs;

         $count++;
         $progress->( sprintf "Walking symbol table %d...", $count ) if $progress and $count % 1000 == 0;
      }
   }

   # Next the reachable user data, recursively
   {
      push @user, $df->main_cv;
      my $count = 0;
      while( @user ) {
         my $sv = shift @user or next;

         my @more_user;
         my @more_internal;

         for( $sv->type ) {
            if   ( $_ eq "REF" )    { push @more_user, $sv->rv if $sv->rv }
            elsif( $_ eq "ARRAY" )  { push @more_user, $sv->elems; }
            elsif( $_ eq "HASH" )   { push @more_user, $sv->values; }
            elsif( $_ eq "GLOB" ) {
               my $gv = $sv;
               next if $gv->{tool_reachable}; # already on symbol table

               warn "Found non-SYMTAB GLOB " . $gv->desc_addr . " user reachable\n";
               # Hard to know if the GV is being used for GVSV, GVAV, GVHV or GVCV
               push @more_user, $gv->scalar, $gv->array, $gv->hash, $gv->code, $gv->egv, $gv->io, $gv->form;
            }
            elsif( $_ eq "CODE" ) {
               my $cv = $sv;

               my @more_padlist;
               my @more_lexical;

               push @more_padlist, $cv->padlist;

               my $padnames_av = $cv->padnames_av;
               if( $padnames_av ) {
                  push @more_padlist, $padnames_av, $padnames_av->elems;
               }

               foreach my $pad ( $cv->pads ) {
                  $pad or next;
                  push @more_padlist, $pad;

                  # PAD slot 0 is always @_
                  if( my $argsav = $pad->elem( 0 ) ) {
                     push @more_internal, $argsav;
                  }

                  foreach my $padix ( 1 .. $pad->elems-1 ) {
                     my $padname_sv = $padnames_av ? $padnames_av->elem( $padix ) : undef;
                     my $padname = $padname_sv && $padname_sv->type eq "SCALAR" ?
                        $padname_sv->pv : undef;

                     my $padsv = $pad->elem( $padix ) or next;
                     $padsv->immortal and next;

                     if( $padname and $padname eq "&" ) {
                        # Slots named "&" are closure prototype subs
                        push @more_user, $padsv;
                     }
                     elsif( $padname ) {
                        # Other named slots are lexical vars
                        push @more_lexical, $padsv;
                     }
                     else {
                        # Unnamed slots are just part of the padlist
                        push @more_internal, $padsv;
                     }
                  }
               }

               $_ and push @more_user, $_ for
                  $cv->scope, $cv->constval, $cv->constants, $cv->globrefs;

               $_ and !$_->{tool_reachable} and
                  $_->{tool_reachable} = REACH_PADLIST for @more_padlist;

               $_ and !$_->{tool_reachable} and
                  $_->{tool_reachable} = REACH_LEXICAL, push @user, $_ for @more_lexical;
            }
            elsif( $_ eq "LVALUE" ) {
               my $lv = $sv;

               push @more_internal, $lv->target if $lv->target;
            }
            elsif( $_ =~ m/^(?:UNDEF|SCALAR|IO|REGEXP|FORMAT)$/ ) { } # ignore

            else { warn "Not sure what to do with user data item ".$sv->desc_addr."\n"; }
         }

         $_ and !$_->{tool_reachable} and !$_->immortal and
            $_->{tool_reachable} = REACH_USER, push @user, $_ for @more_user;

         $_ and !$_->{tool_reachable} and !$_->immortal and
            $_->{tool_reachable} = REACH_INTERNAL, push @internal, $_ for
               @more_internal,
               grep { defined } $sv->magic_svs;

         $count++;
         $progress->( sprintf "Marking user reachability %d...", $count ) if $progress and $count % 1000 == 0;
      }
   }

   # Finally internals
   {
      push @internal, pairvalues $df->roots;
      my $count = 0;
      while( @internal ) {
         my $sv = shift @internal or next;
         next if $sv->{tool_reachable};

         $sv->{tool_reachable} = REACH_INTERNAL;

         push @internal, map { $_->sv ? $_->sv : () } $sv->outrefs;

         $count++;
         $progress->( sprintf "Marking internal reachability %d...", $count ) if $progress and $count % 1000 == 0;
      }
   }
}

=head1 SV METHODS

This tool adds the following SV methods.

=head2 reachable

   $r = $sv->reachable

Returns true if the SV is reachable from a known root.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
