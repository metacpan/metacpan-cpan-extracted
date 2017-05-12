package Graph::Template;

use strict;

BEGIN {
    use Graph::Template::Base;
    use vars qw ($VERSION @ISA);

    $VERSION  = '0.05';
    @ISA      = qw (Graph::Template::Base);
}

use File::Basename;
use IO::File;
use XML::Parser;

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->parse_xml($self->{FILENAME})
        if defined $self->{FILENAME};

    return $self;
}

sub param
{
    my $self = shift;

    # Allow an arbitrary number of hashrefs, so long as they're the first things
    # into param(). Put each one onto the end, de-referenced.
    push @_, %{shift @_} while UNIVERSAL::isa($_[0], 'HASH');

    (@_ % 2)
        && die __PACKAGE__, "->param() : Odd number of parameters to param()\n";

    my %params = @_;
    $params{uc $_} = delete $params{$_} for keys %params;
    @{$self->{PARAM_MAP}}{keys %params} = @params{keys %params};

    return 1;
}

sub write_file
{
    my $self = shift;
    my ($filename) = @_;

    my ($graph, $method) = $self->_prepare_output;

    open IMG, ">$filename"
        or die "Cannot open '$filename' for writing: $!\n";
    binmode IMG;
    print IMG $graph->$method;
    close IMG;
}

sub output
{
    my $self = shift;

    my ($graph, $method) = $self->_prepare_output;

    binmode STDOUT;
    $graph->$method;
}

sub parse
{
    my $self = shift;

    $self->parse_xml(@_);
}

sub parse_xml
{
    my $self = shift;
    my ($filename) = @_;

    my ($fname, $dirname) = fileparse($filename);

    my @stack;
    my $parser = XML::Parser->new(
        Base => $dirname,
        Handlers => {
            Start => sub {
                shift;

                my $name = uc shift;

                my $node = Graph::Template::Factory->create_node($name, @_);
                die "'$name' (@_) didn't make a node!\n" unless defined $node;

                if ($name eq 'GRAPH')
                {
                    push @{$self->{GRAPHS}}, $node;
                }
                elsif ($name eq 'VAR')
                {
                    return unless @stack;

                    if (exists $stack[-1]{TXTOBJ} &&
                        $stack[-1]{TXTOBJ}->isa('TEXTOBJECT'))
                    {
                        push @{$stack[-1]{TXTOBJ}{STACK}}, $node;
                    }

                }
                else
                {
                    push @{$stack[-1]{ELEMENTS}}, $node
                        if @stack;
                }
                push @stack, $node;
            },
            Char => sub {
                shift;
                return unless @stack;

                my $parent = $stack[-1];

                if (
                    exists $parent->{TXTOBJ}
                        &&
                    $parent->{TXTOBJ}->isa('TEXTOBJECT')
                ) {
                    push @{$parent->{TXTOBJ}{STACK}}, @_;
                }
            },
            End => sub {
                shift;
                return unless @stack;

                pop @stack if $stack[-1]->isa(uc $_[0]);
            },
        },
    );

    {
        my $fh = IO::File->new($filename)
            || die "Cannot open '$filename' for reading: $!\n";

        $parser->parse(do { local $/ = undef; <$fh> });

        $fh->close;
    }

    return 1;
}

sub _prepare_output
{
    my $self = shift;
    my ($graph) = @_;

    my $context = Graph::Template::Factory->create(
        'CONTEXT',

        PARAM_MAP => [ $self->{PARAM_MAP} ],
    );

    foreach my $graph (@{$self->{GRAPHS}})
    {
        foreach my $method (qw( enter_scope render exit_scope ))
        {
            $graph->$method($context);
        }
    }

    return ($context->plotted_graph, $context->format);
}

sub register { shift; Graph::Template::Factory::register(@_) }

1;
__END__

=head1 NAME

Graph::Template - Graph::Template

=head1 SYNOPSIS

First, make a template. This is an XML file, describing the layout of the
spreadsheet.

For example, test.xml:

  <graph>
      <title text="Testing Title"/>
      <xlabel text="X Label"/>
      <ylabel text="Y Label"/>
      <data name="test_data">
          <datapoint value="$x_point"/>
          <datapoint value="$y_point"/>
      </data>
  </workbook>

Now, create a small program to use it:

  #!/usr/bin/perl -w
  use Graph::Template

  # Create the Graph template
  my $template = Graph::Template->new(
      filename => 'test.xml',
  );

  my @data;
  for (1 .. 3)
  {
      push @data, {
          x_point => $_,
          y_point => 4 - $_,
      };
  }

  # Add a few parameters
  $template->param(
      test_data => \@data,
  );

  $template->write_file('test.png');

If everything worked, then you should have a graph in your work directory called
test.png that looks something like:

           Testing Title
  5 +-------------------------+
    |                         |
    |                         |
  4 +                         |
    |                         |
    |                         |
  3 +   +-----+               |
    |   |     |               |
    |   |     |               |
  2 +   |     |-----+         |
    |   |     |     |         |
    |   |     |     |         |
  1 +   |     |     |-----+   |
    |   |     |     |     |   |
    |   |     |     |     |   |
  0 +---+-----+-----+-----+---+
           1     2     3

=head1 DESCRIPTION

This is a module used for templating Graph files. Its genesis came from the
need to use the same datastructure as HTML::Template, but provide Graph files
instead. The existing modules don't do the trick, as they require separate
logic from what HTML::Template needs.

Currently, only a small subset of the planned features are supported. This is
meant to be a test of the waters, to see what features people actually want.

=head1 MOTIVATION
                                                                                
I do a lot of Perl/CGI for reporting purposes. Usually, I've been asked for
HTML, PDF, and Excel. Recently, I've been asked to do graphs, using the exact
same data.  Instead of writing graphing-specific code, I preferred to do it once
in a template.

=head1 USAGE

=head2 new()

This creates a Graph::Template object. If passed a filename parameter, it will
parse the template in the given file. (You can also use the parse() method,
described below.)

=head2 param()

This method is exactly like HTML::Template's param() method. Although, I will
be adding more to this section later, please see HTML::Template's description
for info right now.

=head2 parse() / parse_xml()

This method actually parses the template file. It can either be called
separately or through the new() call. It will die() if it cannot handle any
situation.

=head2 write_file()

Create the Graph file and write it to the specified filename. This is when the
actual merging of the template and the parameters occurs.

=head2 output()

It will act just like HTML::Template's output() method, returning the resultant
file as a stream, usually for output to the web.

=head1 SUPPORTED NODES

This is just a list of nodes. See the other classes in for more details on
specific parameters and the like.

=over 4

=item * GRAPH

=item * TITLE

=item * XLABEL / YLABEL

=item * DATA

=item * DATAPOINT

=back 4

=head1 BUGS

None, that I know of. (But there aren't many features, neither!)

=head1 SUPPORT

This is currently beta-quality software. It's built on the new PDF::Template
technology, which was just released.  The featureset is extremely limited, but I
expect to be adding on to it very soon.

=head1 AUTHOR

    Rob Kinyon
    rkinyon@columbus.rr.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1), HTML::Template, GD::Graph, GD.

=cut
