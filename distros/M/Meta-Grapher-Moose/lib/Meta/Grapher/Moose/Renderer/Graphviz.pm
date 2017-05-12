package Meta::Grapher::Moose::Renderer::Graphviz;

use strict;
use warnings;
use namespace::autoclean;
use autodie;

our $VERSION = '1.03';

use File::Temp qw( tempfile );
use GraphViz2;
use Meta::Grapher::Moose::Constants qw( CLASS ROLE P_ROLE ANON_ROLE );

use Moose;

with(
    'Meta::Grapher::Moose::Role::HasOutput',
    'Meta::Grapher::Moose::Role::Renderer',
);

has _graph => (
    is      => 'ro',
    isa     => 'GraphViz2',
    lazy    => 1,
    builder => '_build_graph',
);

has output => (
    is  => 'ro',
    isa => 'Str',
);

# TODO: Make this configurable from the command line, either by accepting some
# sort of JSON-as-command-line-argument-flag setting, or by having multiple
# attributes that *are* individually settable and are lazily built into this
# formatting hashref if nothing is passed.
has formatting => (
    is      => 'ro',
    isa     => 'HashRef[HashRef]',
    builder => '_build_formatting',
);

sub render {
    my $self = shift;

    # are we rendering to a named file or a temp file?
    my $output = (
        $self->has_output ? $self->output : do {
            my ( undef, $filename ) = tempfile();
            $filename;
            }
    );

    $self->_graph->run(
        format => ( $self->format eq 'src' ? 'dot' : $self->format ),
        output_file => $output,
    );

    # If we were rendering to STDOUT, send to STDOUT
    unless ( $self->has_output ) {
        open my $fh, '<:raw', $output;
        while (<$fh>) {
            print or die $!;
        }
        close $fh;
        unlink $output;
    }

    return;
}

sub _build_graph {
    return GraphViz2->new;
}

sub add_package {
    my $self = shift;
    my %args = @_;

    $self->_graph->add_node(
        name  => $args{id},
        label => $args{label},
        %{ $self->formatting->{ $args{type} } },
    );

    return;
}

sub _build_formatting {
    my @std = (
        fontname => 'Helvetica',
        fontsize => 9,
        shape    => 'rect',
    );

    return {
        CLASS()     => { @std, style => 'bold', },
        ROLE()      => { @std, },
        P_ROLE()    => { @std, style => 'dashed', },
        ANON_ROLE() => { @std, style => 'dotted', },
    };
}

sub add_edge {
    my $self = shift;
    my %p    = @_;

    $self->_graph->add_edge(
        from   => $p{from},
        to     => $p{to},
        weight => $p{weight},
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Render a Meta::Grapher::Moose as a graph using GraphViz2

__END__

=pod

=encoding UTF-8

=head1 NAME

Meta::Grapher::Moose::Renderer::Graphviz - Render a Meta::Grapher::Moose as a graph using GraphViz2

=head1 VERSION

version 1.03

=head1 SYNOPSIS

    Meta::Grapher::Moose->new(
        renderer => Meta::Grapher::Moose::Renderer::Graphviz->new(),
        ...
    );

=head1 DESCRIPTION

This is one of the standard renderers that ships as part of the
Meta-Grapher-Moose distribution.

It uses the L<GraphViz2> module to use GraphViz to create graphs.

=head2 Attributes

=head3 output

The name of the file that output should be written to. For example C<foo.png>.
If no output is specified then output will be sent to STDOUT.

=head3 format

The format of the output; Accepts any value that GraphViz2 will accept,
including C<png>, C<jpg>, C<svg>, C<pdf> and C<dot>

If this is not specified then, if possible, it will be extracted from the
extension of the C<output>. If either the C<output> has not been set or the
output filename has no file extension then the output will default to
outputting raw dot source code.

=head3 formatting

The GraphViz attributes that you want to apply to your package nodes depending
on what type they are. The default values are:

    {
        class => {
            fontname => 'Helvetica',
            fontsize => 9,
            shape    => 'rect',
            style    => 'bold',
        },
        role => {
            fontname => 'Helvetica',
            fontsize => 9,
            shape    => 'rect',
        },
        prole => {
            fontname => 'Helvetica',
            fontsize => 9,
            shape    => 'rect',
            style    => 'dotted',
        },
        anonrole => {
            fontname => 'Helvetica',
            fontsize => 9,
            shape    => 'rect',
            style    => 'dashed',
        },
    }

More information on GraphViz attributes can be found at
L<http://www.graphviz.org/doc/info/attrs.html>

=for Pod::Coverage render add_package add_edge

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=Meta-Grapher-Moose>
(or L<bug-meta-grapher-moose@rt.cpan.org|mailto:bug-meta-grapher-moose@rt.cpan.org>).

I am also usually active on IRC as 'drolsky' on C<irc://irc.perl.org>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
