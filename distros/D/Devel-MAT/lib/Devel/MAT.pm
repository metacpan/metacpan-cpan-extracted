#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2022 -- leonerd@leonerd.org.uk

package Devel::MAT 0.49;

use v5.14;
use warnings;

use Carp;
use List::Util qw( first pairs );
use List::UtilsBy qw( sort_by );

use Syntax::Keyword::Match;

use Devel::MAT::Dumpfile;
use Devel::MAT::Graph;

use Devel::MAT::InternalTools;

use Module::Pluggable
   sub_name => "_available_tools",
   search_path => [ "Devel::MAT::Tool" ],
   require => 1;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Devel::MAT> - Perl Memory Analysis Tool

=head1 USER GUIDE

B<NEW USERS:>

If you are new to the C<Devel::MAT> set of tools, this is probably not the
document you want to start with. If you are interested in using C<Devel::MAT>
to help diagnose memory-related problems in a F<perl> program you instead want
to read the user guide, at L<Devel::MAT::UserGuide>.

If you are writing tooling modules to extend the abilities of C<Devel::MAT>
then this may indeed by the document for you; read on...

=head1 DESCRIPTION

A C<Devel::MAT> instance loads a heapdump file, and provides a container to
store analysis tools to work on it. Tools may be provided that conform to the
L<Devel::MAT::Tool> API, which can help analyse the data and interact with the
explorer user interface by using the methods in the L<Devel::MAT::UI> package.

=head2 File Format

The dump file format is still under development, so at present no guarantees
are made on whether files can be loaded over mismatching versions of
C<Devel::MAT>. However, as of version 0.11 the format should be more
extensible, allowing new SV fields to be added without breaking loading - older
tools will ignore new fields and newer tools will just load undef for fields
absent in older files. As the distribution approaches maturity the format will
be made more stable.

=cut

=head1 CONSTRUCTOR

=cut

=head2 load

   $pmat = Devel::MAT->load( $path, %args )

Loads a heap dump file from the given path, and returns a new C<Devel::MAT>
instance wrapping it.

=cut

sub load
{
   my $class = shift;

   my $df = Devel::MAT::Dumpfile->load( @_ );

   return bless {
      df => $df,
   }, $class;
}

=head1 METHODS

=cut

=head2 dumpfile

   $df = $pmat->dumpfile

Returns the underlying L<Devel::MAT::Dumpfile> instance backing this analysis
object.

=cut

sub dumpfile
{
   my $self = shift;
   return $self->{df};
}

=head2 available_tools

   @tools = $pmat->available_tools

Lists the L<Devel::MAT::Tool> classes that are installed and available.

=cut

{
   my @TOOLS;
   my $TOOLS_LOADED;

   sub available_tools
   {
      my $self = shift;

      return @TOOLS if $TOOLS_LOADED;

      $TOOLS_LOADED++;
      @TOOLS = map { $_ =~ s/^Devel::MAT::Tool:://; $_ } $self->_available_tools;

      foreach my $name ( @TOOLS ) {
         my $tool_class = "Devel::MAT::Tool::$name";
         next unless $tool_class->can( "AUTOLOAD_TOOL" ) and $tool_class->AUTOLOAD_TOOL( $self );

         $self->{tools}{$name} ||= $tool_class->new( $self );
      }

      return @TOOLS;
   }
}

=head2 load_tool

   $tool = $pmat->load_tool( $name )

Loads the named L<Devel::MAT::Tool> class.

=cut

sub load_tool
{
   my $self = shift;
   my ( $name, %args ) = @_;

   # Ensure tools are 'require'd
   $self->available_tools;

   my $tool_class = "Devel::MAT::Tool::$name";
   return $self->{tools}{$name} ||= $tool_class->new( $self, %args );
}

sub load_tool_for_command
{
   my $self = shift;
   my ( $cmd, %args ) = @_;

   return $self->{tools_by_command}{$cmd} ||= do {
      my $name = first {
         my $class = "Devel::MAT::Tool::$_";
         $class->can( "CMD" ) and $class->CMD eq $cmd
      } $self->available_tools or die "Unrecognised command '$cmd'\n";

      $self->load_tool( $name, %args );
   };
}

=head2 has_tool

   $bool = $pmat->has_tool( $name )

Returns true if the named tool is already loaded.

=cut

sub has_tool
{
   my $self = shift;
   my ( $name ) = @_;

   return defined $self->{tools}{$name};
}

=head2 run_command

   $pmat->run_command( $inv )

Runs a tool command given by the L<Commandable::Invocation> instance.

=cut

sub run_command
{
   my $self = shift;
   my ( $inv, %args ) = @_;

   my $cmd = $inv->pull_token;

   $self->load_tool_for_command( $cmd,
      progress => $args{process},
   )->run_cmd( $inv );
}

=head2 inref_graph

   $node = $pmat->inref_graph( $sv, %opts )

Traces the tree of inrefs from C<$sv> back towards the known roots, returning
a L<Devel::MAT::Graph> node object representing it, within a graph of reverse
references back to the known roots.

This method will load L<Devel::MAT::Tool::Inrefs> if it isn't yet loaded.

The following named options are recognised:

=over 4

=item depth => INT

If specified, stop recursing after the specified count. A depth of 1 will only
include immediately referring SVs, 2 will print the referrers of those, etc.
Nodes with inrefs that were trimmed because of this limit will appear to be
roots with a special name of C<EDEPTH>.

=item strong => BOOL

=item direct => BOOL

Specifies the type of inrefs followed. By default all inrefs are followed.
Passing C<strong> will follow only strong direct inrefs. Passing C<direct>
will follow only direct inrefs.

=item elide => BOOL

If true, attempt to neaten up the output by skipping over certain structures.

C<REF()>-type SVs will be skipped to their referrant.

Members of the symbol table will be printed as being a 'root' element of the
given symbol name.

C<PAD>s and C<PADLIST>s will be skipped to their referring C<CODE>, giving
shorter output for lexical variables.

=back

=cut

sub inref_graph
{
   my $self = shift;
   my ( $sv, %opts ) = @_;

   my $graph = $opts{graph} //= Devel::MAT::Graph->new( $self->dumpfile );

   # TODO: allow separate values for these
   my $elide_rv  = $opts{elide};
   my $elide_sym = $opts{elide};
   my $elide_pad = $opts{elide};

   $self->load_tool( "Inrefs" );

   if( $sv->immortal ) {
      my $desc = $sv->type eq "UNDEF" ? "undef" :
                 $sv->uv              ? "true" :
                                        "false";
      $graph->add_root( $sv,
         Devel::MAT::SV::Reference( $desc, strong => undef ) );
      return $graph->get_sv_node( $sv );
   }

   my $name;
   my $foundsv;
   if( $elide_sym and $name = $sv->symname and
         $name !~ m/^&.*::__ANON__$/ and
         $foundsv = eval { $self->find_symbol( $sv->symname ) } and
         $foundsv->addr == $sv->addr
      ) {
      $graph->add_root( $sv,
         Devel::MAT::SV::Reference( "the symbol '" . Devel::MAT::Cmd->format_symbol( $name, $sv ) . "'", strong => undef ) );
      return $graph->get_sv_node( $sv );
   }
   if( $elide_sym and $sv->type eq "GLOB" and $name = $sv->stashname ) {
      $graph->add_root( $sv,
         Devel::MAT::SV::Reference( "the glob '" . Devel::MAT::Cmd->format_symbol( "*$name", $sv ) . '"', strong => undef ) );
      return $graph->get_sv_node( $sv );
   }

   $graph->add_sv( $sv );

   my @inrefs = $opts{strong} ? $sv->inrefs_strong :
                $opts{direct} ? $sv->inrefs_direct :
                                $sv->inrefs;

   # If we didn't find anything at the given option level, try harder
   if( !@inrefs and $opts{strong} ) {
      @inrefs = $sv->inrefs_direct;
   }
   if( !@inrefs and $opts{direct} ) {
      @inrefs = $sv->inrefs;
   }

   if( $elide_rv ) {
      @inrefs = map { sub {
         return $_ unless $_->sv and
                          $_->sv->type eq "REF" and
                          $_->name eq "the referrant";

         my $rv = $_->sv;
         my @rvrefs = $opts{strong} ? $rv->inrefs_strong :
                      $opts{direct} ? $rv->inrefs_direct :
                                      $rv->inrefs;

         return $_ unless @rvrefs == 1;

         # Add 'via RV' marker
         return map {
            Devel::MAT::SV::Reference( Devel::MAT::Cmd->format_note( "(via RV)" ) . " " . $_->name,
               $_->strength, $_->sv )
         } @rvrefs;
      }->() } @inrefs;
   }

   if( $elide_pad ) {
      @inrefs = map { sub {
         return $_ unless $_->sv and
                          $_->sv->type eq "PAD";
         my $pad = $_->sv;
         my $cv = $pad->padcv;
         # Even if the CV isn't active, this might be a state variable so we
         # must always consider pad(1) at least.
         my ( $depth ) = grep { $cv->pad( $_ ) == $pad } ( 1 .. ( $cv->depth || 1 ) );
         return Devel::MAT::SV::Reference( $_->name . " at depth $depth", $_->strength, $cv );
      }->() } @inrefs;
   }

   foreach my $ref ( sort_by { $_->name } @inrefs ) {
      if( !defined $ref->sv ) {
         $graph->add_root( $sv, $ref );
         next;
      }

      if( defined $opts{depth} and not $opts{depth} ) {
         $graph->add_root( $sv, "EDEPTH" );
         last;
      }

      my @me;
      if( $graph->has_sv( $ref->sv ) ) {
         $graph->add_ref( $ref->sv, $sv, $ref );
         # Don't recurse into it as it was already found
      }
      else {
         $graph->add_sv( $ref->sv ); # add first to stop inf. loops

         defined $opts{depth} ? $self->inref_graph( $ref->sv, %opts, depth => $opts{depth}-1 )
                              : $self->inref_graph( $ref->sv, %opts );
         $graph->add_ref( $ref->sv, $sv, $ref );
      }
   }

   return $graph->get_sv_node( $sv );
}

=head2 find_symbol

   $sv = $pmat->find_symbol( $name )

Attempts to walk the symbol table looking for a symbol of the given name,
which must include the sigil.

   $Package::Name::symbol_name => to return a SCALAR SV
   @Package::Name::symbol_name => to return an ARRAY SV
   %Package::Name::symbol_name => to return a HASH SV
   &Package::Name::symbol_name => to return a CODE SV

=cut

sub find_symbol
{
   my $self = shift;
   my ( $name ) = @_;

   my ( $sigil, $globname ) = $name =~ m/^([\$\@%&])(.*)$/ or
      croak "Could not parse sigil from $name";

   my $stashvalue = $self->find_stashvalue( $globname );

   # Perl 5.22 may take CODE shortcuts
   if( $sigil eq '&' and $stashvalue->type eq "REF" ) {
      return $stashvalue->rv;
   }

   $stashvalue->type eq "GLOB" or
      croak "$globname is not a GLOB";

   my $slot = ( $sigil eq '$' ) ? "scalar" :
              ( $sigil eq '@' ) ? "array"  :
              ( $sigil eq '%' ) ? "hash"   :
              ( $sigil eq '&' ) ? "code"   :
                                  die "ARGH"; # won't happen

   my $sv = $stashvalue->$slot or
      croak "\*$globname has no $slot slot";
   return $sv;
}

=head2 find_glob

   $gv = $pmat->find_glob( $name )

Attempts to walk the symbol table looking for a symbol of the given name,
returning the C<GLOB> object if found.

=head2 find_stash

   $stash = $pmat->find_stash( $name )

Attempts to walk the symbol table looking for a stash of the given name.

=cut

sub find_stashvalue
{
   my $self = shift;
   my ( $name ) = @_;

   my ( $parent, $shortname ) = $name =~ m/^(?:(.*)::)?(.+?)$/;

   my $stash;
   if( defined $parent and length $parent ) {
      $stash = $self->find_stash( $parent );
   }
   else {
      $stash = $self->dumpfile->defstash;
   }

   my $sv = $stash->value( $shortname ) or
      croak $stash->stashname . " has no symbol $shortname";
   return $sv;
}

sub find_glob
{
   my $self = shift;
   my ( $name ) = @_;

   my $sv = $self->find_stashvalue( $name ) or return;
   $sv->type eq "GLOB" or
      croak "$name is not a GLOB";

   return $sv;
}

sub find_stash
{
   my $self = shift;
   my ( $name ) = @_;

   my $gv = $self->find_glob( $name . "::" );
   return $gv->hash ||
      croak "$name has no hash";
}

# Some base implementations of Devel::MAT::Cmd formatters

push @Devel::MAT::Cmd::ISA, qw( Devel::MAT::Cmd::_base );

package
   Devel::MAT::Cmd::_base;

use B qw( perlstring );
use List::Util qw( max );

sub print_table
{
   my $self = shift;
   my ( $rows, %opts ) = @_;

   if( $opts{headings} ) {
      my @headings = map { $self->format_heading( $_ ) } @{ $opts{headings} };
      $rows = [ \@headings, @$rows ];
   }

   return unless @$rows;

   my $cols = max map { scalar @$_ } @$rows;

   my @colwidths = map {
      my $colidx = $_;
      # TODO: consider a unicode/terminal-aware version of length here
      max map { length($_->[$colidx]) // 0 } @$rows;
   } 0 .. $cols-1;

   my $align = $opts{align} // "";
   $align = [ ( $align ) x $cols ] if !ref $align;

   my $sep = $opts{sep} // " ";
   $sep = [ ( $sep ) x ($cols - 1) ] if !ref $sep;

   my @leftalign = map { ($align->[$_]//"") ne "right" } 0 .. $cols-1;

   my $format = join( "",
      ( " " x ( $opts{indent} // 0 ) ),
      ( map {
         my $col = $_;
         my $width = $colwidths[$col];
         my $flags = $leftalign[$col] ? "-" : "";
         # If final column should be left-aligned don't bother with width
         $width = "" if $col == $cols-1 and $leftalign[$col];

         ( $col ? $sep->[$col-1] : "" ) . "%${flags}${width}s"
      } 0 .. $cols-1 ),
   ) . "\n";

   foreach my $row ( @$rows ) {
      my @row = @$row;
      @row or @row = map { "-"x$colwidths[$_] } ( 0 .. $cols-1 );
      push @row, "" while @row < $cols; # pad with spaces
      $self->printf( $format, @row );
   }
}

sub format_note
{
   shift;
   my ( $str, $idx ) = @_;

   return $str;
}

sub _format_sv
{
   shift;
   my ( $ret ) = @_;

   return $ret;
}

sub format_sv
{
   shift;
   my ( $sv ) = @_;

   my $ret = $sv->desc;

   if( my $blessed = $sv->blessed ) {
      $ret .= "=" . Devel::MAT::Cmd->format_symbol( $blessed->stashname, $blessed );
   }

   $ret .= sprintf " at %#x", $sv->addr;

   if( my $rootname = $sv->rootname ) {
      $ret .= "=" . Devel::MAT::Cmd->format_note( $rootname, 1 );
   }

   return Devel::MAT::Cmd->_format_sv( $ret, $sv );
}

sub _format_value
{
   shift;
   my ( $val ) = @_;

   return $val;
}

sub format_value
{
   shift;
   my ( $val, %opts ) = @_;

   my $text;
   if( $opts{key} ) {
      my $strval = $val;
      if( $opts{stash} && $strval =~ m/^([\x00-\x1f])([a-zA-Z0-9_]*)$/ ) {
         $strval = "^" . chr( 64 + ord $1 ) . $2;
      }
      elsif( $strval !~ m/^[a-zA-Z_][a-zA-Z0-9_]*$/ ) {
         $strval = perlstring( $val );
      }

      return "{" . Devel::MAT::Cmd->_format_value( $strval ) . "}";
   }
   elsif( $opts{index} ) {
      return "[" . Devel::MAT::Cmd->_format_value( $val+0 ) . "]";
   }
   elsif( $opts{pv} ) {
      my $truncated;
      if( my $maxlen = $opts{maxlen} // 64 ) {
         ( $truncated = length $val > $maxlen ) and
            substr( $val, $maxlen ) = "";
      }

      return Devel::MAT::Cmd->_format_value(
         perlstring( $val ) . ( $truncated ? "..." : "" )
      );
   }
   else {
      return Devel::MAT::Cmd->_format_value( $val );
   }
}

sub format_symbol
{
   shift;
   my ( $name ) = @_;

   return $name;
}

sub format_bytes
{
   shift;
   my ( $bytes ) = @_;

   if( $bytes < 1024 ) {
      return sprintf "%d bytes", $bytes;
   }
   if( $bytes < 1024**2 ) {
      return sprintf "%.1f KiB", $bytes / 1024;
   }
   if( $bytes < 1024**3 ) {
      return sprintf "%.1f MiB", $bytes / 1024**2;
   }
   if( $bytes < 1024**4 ) {
      return sprintf "%.1f GiB", $bytes / 1024**3;
   }
   return sprintf "%.1f TiB", $bytes / 1024**4;
}

sub format_sv_with_value
{
   my $self = shift;
   my ( $sv ) = @_;

   my $repr = $self->format_sv( $sv );

   match( $sv->type : eq ) {
      case( "SCALAR" ) {
         my @reprs;

         my $num;
         defined( $num = $sv->nv // $sv->uv ) and
            push @reprs, $self->format_value( $num, nv => 1 );

         defined $sv->pv and
            push @reprs, $self->format_value( $sv->pv, pv => 1 );

         # Dualvars
         return "$repr = $reprs[0] / $reprs[1]" if @reprs > 1;

         return "$repr = $reprs[0]" if @reprs;
      }
      case( "BOOL" ) {
         return "$repr = " . $self->format_value( $sv->uv ? "true" : "false" );
      }
      case( "REF" ) {
         #return "REF => NULL" if !$sv->rv;
         return "$repr => " . $self->format_sv_with_value( $sv->rv ) if $sv->rv;
      }
      case( "ARRAY" ) {
         return $repr if $sv->blessed;

         my $n_elems = $sv->elems;
         return "$repr = []" if !$n_elems;

         my $elem = $self->format_sv( $sv->elem( 0 ) );
         $elem .= ", ..." if $n_elems > 1;

         return "$repr = [$elem]";
      }
      case( "HASH" ) {
         return $repr if $sv->blessed;

         my $n_values = $sv->values;
         return "$repr = {}" if !$n_values;

         my $key = ( $sv->keys )[0]; # pick one at random
         my $value = $self->format_value( $key, key => 1 ) . " => " . $self->format_sv( $sv->value( $key ) );
         $value .= ", ..." if $n_values > 1;

         return "$repr = {$value}";
      }
      case( "GLOB" ) {
         return "$repr is " . $self->format_symbol( "*" . $sv->stashname, $sv );
      }
      case( "STASH" ) {
         return "$repr is " . $self->format_symbol( $sv->stashname, $sv );
      }
   }

   return $repr;
}

sub format_heading
{
   shift;
   my ( $text, $level ) = @_;

   return "$text";
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
