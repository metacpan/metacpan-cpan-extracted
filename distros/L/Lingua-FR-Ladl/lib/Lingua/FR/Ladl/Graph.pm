package Lingua::FR::Ladl::Graph;
use base qw( Graph );

use strict; 
use warnings;
use English;
use Carp;

use version; our $VERSION = (q$Revision$) =~ /(\d+)/g;

use Readonly;

use Lingua::FR::Ladl::Exceptions;
use Lingua::FR::Ladl::Parametrizer;
use Lingua::FR::Ladl::Util;

use Class::Std;

{

  Readonly my %is_implemented_format => ( dot => \&_load_dot, );

  my %name_of : ATTR( :default('none') :name<name> );
  my %parameters_of : ATTR( :set<parameters> :get<parameters> ); # customization parameters

  my %graph_of : ATTR;
  my %frame_vertices_of : ATTR;
  
  ############# Utility subroutines #################################################################

  sub _load_dot {
    my ($file_name) = @_;

    use Graph::Reader::Dot;
    my $reader = Graph::Reader::Dot->new();
    $Graph::Reader::Dot::UseNodeAttr = 'yes';
    $Graph::Reader::Dot::UseEdgeAttr = 'yes';

    my $graph_ref = $reader->read_graph($file_name);

=for Error handling:
     Graph::Reader::Dot returns 0 and a warning on STDERR if it can't read the file
     I think throwing an exception is better.

=cut
    unless ($graph_ref) {
      croak "Error loading $file_name via Graph::Reader::Dot\n";
    };

    return $graph_ref;
  };

  sub BUILD {
    my ($self, $id, $arg_ref) = @_;

    my $class = ref($self);
    
    $graph_of{$id} = $class->SUPER::new();
    
    # parametrize with new default parametrizer
    my $param = Lingua::FR::Ladl::Parametrizer->new();
    $parameters_of{$id} = $param;
  };

  ############# Interface subroutines ##############################################################

  sub load {
    my ($self, $arg_ref) = @_;
    my $format = $arg_ref->{format};
    my $file_name = $arg_ref->{file};
    my $id = ident $self;

    unless ($is_implemented_format{$format}) {
      croak 'Format must be one of '.join(', ', keys %is_implemented_format).", not $format\n";
    }

    my $graph_ref = $is_implemented_format{$format}->($file_name);

    
    # set a default graph name, the basename of the file used for loading
    $self->set_name(_Name::from_file_name($file_name));

    $graph_of{$id} = $graph_ref;

    return $self;
  };

=for Discussion:
  I don't think it's possible to ultimately verify that this graph is a ladl graph
  so all we can do is to check whether is violates some basic properties or not.
  Some of these properties are:
  -must be a DAG
  -root vertices are boxes
  -has no isolated vertices

=cut
  
  sub is_plausible {
    my ($self) = @_;
    my $id = ident $self;

    unless ($graph_of{$id}) {
      croak "Graph is not initialised, maybe you should first call `load'?" 
    };
    
    my $g = $graph_of{$id};

    
    unless ( $g->is_dag() ) {
      carp "Graph is no DAG\n";
      return 0;
    };

    if ( grep { $g->get_vertex_attribute($_,'shape') ne 'record' } $g->source_vertices() ) {
      carp "Some source vertices are not record shaped\n";
      return 0;
    };

    if ( $g->isolated_vertices() ) {
      carp "Has isolated vertices\n";
      return 0;
    }
    
    return 1;
  }

  #############################################
  # Frame nodes are the source vertices of the graph
  #############################################
  sub get_frame_vertices_for {
    my ($self) = @_;
    my $id = ident $self;

    use Contextual::Return;
    if ($frame_vertices_of{$id}) {
      my $array_ref = $frame_vertices_of{$id};
      return (
              LIST          { @{ $array_ref }                          }
              SCALAR        { scalar( @{ $array_ref } )                }
              ARRAYREF      { $array_ref                               }
              STR           { join(' ', @{ $array_ref } )              }
              VOID          { print join(' ', @{ $array_ref } ).qq(\n) }
              DEFAULT       { croak qq(Bad context!\n)                 }
             );
    };

    my $g = $graph_of{$id} or X::NoGraphData->throw(
                                                    message => qq(Couldn't get frame vertices),
                                                    graph => $self,
                                                   );
    my @frame_vertices = $g->source_vertices();
    if (@frame_vertices) {
      $frame_vertices_of{$id} = \@frame_vertices;
    } else {
      carp qq(Warning: no frame vertices found\n);
    }
    
    my $array_ref = \@frame_vertices;
    return (
            LIST          { @{ $array_ref }                          }
            SCALAR        { scalar( @{ $array_ref } )                }
            ARRAYREF      { $array_ref                               }
            STR           { join(' ', @{ $array_ref } )              }
            VOID          { print join(' ', @{ $array_ref } ).qq(\n) }
            DEFAULT       { croak qq(Bad context!\n)                 }
           );
  }
  
};

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Graph - Perl extension for blah blah blah

=head1 VERSION

This document describes Graph version 0.0.1

=head1 SYNOPSIS

   use Graph;
   blah blah blah

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  

=head1 DESCRIPTION

Stub documentation for Graph, 
created by perlnow.el using template.el.


=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.

=over

=item load

  $lgraph->load( {format => 'dot', file=>'file_name'} )

Load a Ladl graph from a file in the dot format. Currently, this
is the only supported graph input format.

=item is_plausible

 $lgraph->is_plausible()

Checks whether it's plausible that this graph may be a Ladl graph.

NOTE:

It's probably not possible to ultimately check if a given graph may be
a Ladl graph. We only verify it doesn't violate some basic properties,
which as of now are:

=over

=item is a directed, acyclic Graph (a DAG)

=item the source vertices are boxes, i.e. their I<shape> attribute is I<record>.

=item has no isolated vertices

=back 

=item get_frame_vertices_for

Returns the frame vertices. Frame vertices of a Ladl graph are the source vertices.
Called in 

list context returns the list of frame vertices,

scalar context returns the number of elements of the list,

string context returns the concatenation of the vertices,

arrayref context return a reference to the list of frame vertices,

void context prints the stringified list.

=back



=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
<MODULE NAME> requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-<RT NAME>@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Ingrid Falk, E<lt>falk@localhost.E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Ingrid Falk

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
