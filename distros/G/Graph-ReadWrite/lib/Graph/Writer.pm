#
# Graph::Writer - perl base class for Graph file format writers
#
package Graph::Writer;
$Graph::Writer::VERSION = '2.09';
use 5.006;
use strict;
use warnings;

use IO::File;

#=======================================================================
#
# new () - constructor
#
# Create an instance of a Graph writer. This will not be invoked
# directly on this class, but will be inherited by writers for
# specific formats.
#
#=======================================================================
sub new
{
    my $class = shift;

    die "don't create an instance of $class!\n" if $class eq __PACKAGE__;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

#=======================================================================
#
# _init() - initialise instance
#
# This is for any instance-specific initialisation. The idea is that
# a sub-class will define an _init() method if it needs one.
# For future compatibility the class-specific method should invoke
# this.
#
#=======================================================================
sub _init
{
}


#=======================================================================
#
# write_graph() - write the specified graph to the specified file (handle)
#
# This is the public method that will be invoked to write a graph.
# The file can be specified either as a filename, or a filehandle.
#
#=======================================================================
sub write_graph
{
    my $self     = shift;
    my $graph    = shift;
    my $filename = shift;


    if (ref $filename)
    {
        $self->_write_graph($graph, $filename);
    }
    else
    {
        my $FILE = IO::File->new("> $filename");
        if (not defined $FILE)
        {
            warn "couldn't write to $filename: $!\n";
            return 0;
        }
        $self->_write_graph($graph, $FILE);
        $FILE->close();
    }

    return 1;
}

1;

__END__

=head1 NAME

Graph::Writer - base class for Graph file format writers

=head1 SYNOPSIS

  package Graph::Writer::MyFormat;
  use Graph::Writer;
  use vars qw(@ISA);
  @ISA = qw(Graph::Writer);

  sub _write_graph
  {
    my ($self, $graph, $FILE) = @_;

    # write $graph to $FILE
  }

=head1 DESCRIPTION

B<Graph::Writer> is a base class for Graph file format writers.
A particular subclass of Graph::Writer will handle a specific
file format, and generate a Graph, represented using Jarkko Hietaniemi's
Graph class.

You should never create an instance of this class yourself,
it is only meant for subclassing. If you try to create an instance
of Graph::Writer, the constructor will throw an exception.

=head1 METHODS

=head2 new()

Constructor - generate a new writer instance. This
is a virtual method, or whatever the correct lingo is.
You're not meant to call this on the base class,
it is inherited by the subclasses. Ie if you do something like:

  $writer = Graph::Writer->new();

It will throw an exception.

=head2 write_graph()

Read a graph from the specified file:

  $graph = $writer->write_graph($file);

The C<$file> argument can either be a filename,
or a filehandle for a previously opened file.

=head1 SUBCLASSING

To create your own graph format writer, create a module
which subclasses B<Graph::Writer>. For example, suppose
DGF is a directed graph format - create a B<Graph::Writer::DGF> module,
with the following structure:

  package Graph::Writer::DGF;

  use Graph::Writer;
  use vars qw(@ISA);
  @ISA = qw(Graph::Writer);

  sub _write_graph
  {
    my $self  = shift;
    my $graph = shift;
    my $FILE  = shift;

    while (<$FILE>)
    {
    }

    return 1;
  }

  1;

Note the leading underscore on the B<_write_graph()> method.
The base class provides the public method, and invokes the
private method which you're expected to provide, as above.

If you want to perform additional initialisation at
construction time, you can provide an B<_init()> method,
which will be invoked by the base class's constructor.
You should invoke the superclass's initialiser as well,
as follows:

  sub _init
  {
    my $self = shift;

    $self->SUPER::_init();

    # your initialisation here
  }

Someone can then use your class as follows:

  use Graph::Writer::DGF;

  $writer = Graph::Writer::DGF->new();
  $writer->write_graph($graph, 'foo.dgf');

=head1 SEE ALSO

=over 4

=item L<Graph>

Jarkko Hietaniemi's modules for representing directed graphs,
available from CPAN under modules/by-module/Graph/

=item Algorithms in Perl

The O'Reilly book has a chapter on directed graphs,
which is based around Jarkko's modules.

=item L<Graph::Writer::Dot>

A simple subclass of this class for writing graphs
in the file format used by dot, which is part of the
graphviz package from AT&T.

=item L<Graph::Writer::VCG>

A simple subclass of this class for writing graphs
in the file format used by VCG, a tool for visualising
directed graphs, initially developed for visualising
compiler graphs.

=item L<Graph::Writer::XML>

A simple subclass of this class for writing graphs
as XML, using a simple graph markup.

=item L<Graph::Reader>

A baseclass for Graph file format readers.

=back

=head1 REPOSITORY

L<https://github.com/neilb/Graph-ReadWrite>

=head1 AUTHOR

Neil Bowers E<lt>neil@bowers.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2001-2012, Neil Bowers. All rights reserved.
Copyright (c) 2001, Canon Research Centre Europe. All rights reserved.

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

