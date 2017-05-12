#
# Graph::Reader - perl base class for Graph file format readers
#
package Graph::Reader;
$Graph::Reader::VERSION = '2.09';
use 5.006;
use strict;
use warnings;

use IO::File;
use Graph;

#=======================================================================
#
# new () - constructor
#
#=======================================================================
sub new
{
    my $class = shift;
    my %args  = @_;

    die "don't create an instance of $class!\n" if $class eq __PACKAGE__;

    my $self = bless {}, $class;

    $self->_init(\%args);

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
# read_graph() - create a Graph and read the given file into it
#
# This is the public method that will be invoked to read a graph.
# The file can be specified either as a filename, or a filehandle.
#
#=======================================================================
sub read_graph
{
    my $self     = shift;
    my $filename = shift;

    my $graph    = Graph->new();
    my $FILE;


    if (ref $filename)
    {
        $self->_read_graph($graph, $filename);
    }
    else
    {
        $FILE = IO::File->new("< $filename");
        if (not defined $FILE)
        {
            warn "couldn't read from $filename: $!\n";
            return 0;
        }
        $self->_read_graph($graph, $FILE);
        $FILE->close();
    }

    return $graph;
}

1;

__END__

=head1 NAME

Graph::Reader - base class for Graph file format readers

=head1 SYNOPSIS

  package Graph::Reader::MyFormat;
  use Graph::Reader;
  use vars qw(@ISA);
  @ISA = qw(Graph::Reader);

  sub _read_graph
  {
    my ($self, $graph, $FILE) = @_;

    # read $FILE and populate $graph
  }

=head1 DESCRIPTION

B<Graph::Reader> is a base class for Graph file format readers.
A particular subclass of Graph::Reader will handle a specific
file format, and generate a Graph, represented using Jarkko Hietaniemi's
Graph class.

You should never create an instance of this class yourself,
it is only meant for subclassing. If you try to create an instance
of Graph::Reader, the constructor will throw an exception.

=head1 METHODS

=head2 new()

Constructor - generate a new reader instance. This
is a virtual method, or whatever the correct lingo is.
You're not meant to call this on the base class,
it is inherited by the subclasses. Ie if you do something like:

  $reader = Graph::Reader->new();

It will throw an exception.

=head2 read_graph()

Read a graph from the specified file:

  $graph = $reader->read_graph($file);

The C<$file> argument can either be a filename,
or a filehandle for a previously opened file.

=head1 SUBCLASSING

To create your own graph format reader, create a module
which subclasses B<Graph::Reader>. For example, suppose
DGF is a directed graph format - create a B<Graph::Reader::DGF> module,
with the following structure:

  package Graph::Reader::DGF;

  use Graph::Reader;
  use vars qw(@ISA);
  @ISA = qw(Graph::Reader);

  sub _read_graph
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

Note the leading underscore on the B<_read_graph()> method.
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

  use Graph::Reader::DGF;

  $reader = Graph::Reader::DGF->new();
  $graph = $reader->read_graph('foo.dgf');

=head1 SEE ALSO

=over 4

=item L<Graph>

Jarkko Hietaniemi's modules for representing directed graphs,
available from CPAN under modules/by-module/Graph/

=item Algorithms in Perl

This O'Reilly book has a chapter on directed graphs,
which is based around Jarkko's modules.

=item L<Graph::Reader::XML>

A simple subclass of this class for reading a simple XML format
for directed graphs.

=item L<Graph::Writer>

A baseclass for Graph file format writers.

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

