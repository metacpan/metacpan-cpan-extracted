package Meta::Grapher::Moose::CommandLine;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.03';

# This globally changes the underlying Getopt::Long behavior to allow passing
# through of unprocessed dash arguments without error, which allows us to have
# multiple classes to have an attempt to read the file. Ideally this wouldn't
# be a global setting, but the conclusion of #moose is that this is good
# enough
use Getopt::Long qw(:config pass_through);
use Meta::Grapher::Moose;
use Module::Runtime qw(require_module);

use Moose;

has renderer => (
    is            => 'ro',
    isa           => 'Str',
    default       => 'graphviz',
    documentation => 'The name of the renderer to use',
);

with 'MooseX::Getopt::Dashes';

sub run {
    my $class = shift;
    my $self  = $class->new_with_options;

    my $renderer_classname
        = 'Meta::Grapher::Moose::Renderer::' . ucfirst lc $self->renderer;
    require_module($renderer_classname);

    # Any command line options that we didn't consume are passed onto the
    # renderer so it gets a chance to process them.
    my $renderer = $renderer_classname->new_with_options(
        argv => $self->extra_argv,
    );

    # We pass our main object any command line options that aren't consumed by
    # the renderer and this class
    my $grapher = Meta::Grapher::Moose->new_with_options(
        renderer => $renderer,
        argv     => $renderer->extra_argv,
    );

    $grapher->run;

    return;
}

# We can't just override this since the method created for us was installed
# directly in this class. Instead wrap it with around and
around print_usage_text => sub {
    ## no critic (InputOutput::RequireCheckedSyscalls)
    print <<'TEXT';
Many more command line options are available depending on they type of
renderer you are using. Please refer to the documentation for the individual
renderers or use "perldoc graph-meta.pl" for an overview.
TEXT
};

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Module supporting command line interface for Meta::Grapher::Moose

__END__

=pod

=encoding UTF-8

=head1 NAME

Meta::Grapher::Moose::CommandLine - Module supporting command line interface for Meta::Grapher::Moose

=head1 VERSION

version 1.03

=head1 SYNOPSIS

    Meta::Grapher::Moose::CommandLine->run;

=head1 DESCRIPTION

This is the module behind the F<graph-meta.pl> script. You probably want to go
read the documentation for that instead.

=head1 ATTRIBUTES

This class accepts the following attributes:

=head2 renderer

The name of the renderer we should instantiate and pass to
L<Meta::Grapher::Moose> to render the graph with.

This will be converted to a class name by uppercasing the first character,
lowercasing all other characters and prepending
C<Meta::Grapher::Moose::Renderer::> to it.

Defaults to C<graphviz>.

=head1 METHODS

This class provides the following methods:

=head2 Meta::Grapher::Moose::CommandLine->run

Class method. Parses the command line options and creates a graph.

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
