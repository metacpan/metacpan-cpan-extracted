package Meta::Grapher::Moose::Renderer::Plantuml;

use strict;
use warnings;
use namespace::autoclean;
use autodie;

our $VERSION = '1.03';

use IPC::Run3;
use Meta::Grapher::Moose::Constants qw( CLASS ROLE P_ROLE ANON_ROLE );
use Meta::Grapher::Moose::Renderer::Plantuml::Class;
use Meta::Grapher::Moose::Renderer::Plantuml::Link;

use Moose;

with(
    'Meta::Grapher::Moose::Role::HasOutput',
    'Meta::Grapher::Moose::Role::Renderer',
);

has java_command => (
    is            => 'ro',
    isa           => 'Str',
    default       => 'java',
    documentation => 'The command to run the java binary. Defaults to "java"',
);

has plantuml_jar => (
    is      => 'ro',
    isa     => 'Str',
    default => 'plantuml.jar',
    documentation =>
        'Path to the plantuml.jar. Defaults to plantuml.jar in the current directory',
);

has formatting => (
    is            => 'ro',
    isa           => 'HashRef[Str]',
    builder       => '_build_formatting',
    documentation => 'Set specific spot markup for classes',
);

sub _build_formatting {
    return {
        CLASS()     => q{},
        ROLE()      => '<<R,#FF7700>>',
        P_ROLE()    => '<<P,orchid>>',
        ANON_ROLE() => '<<?,white>>',
    };
}

# Keep internal state of what we've seen until we're ready to render and
# create the source code.
has _plantuml_classes => (
    is      => 'ro',
    isa     => 'HashRef[Meta::Grapher::Moose::Renderer::Plantuml::Class]',
    default => sub { return {} },
    traits  => ['Hash'],
    handles => {
        _add_plantuml_class   => 'set',
        _get_plantuml_class   => 'get',
        _all_plantuml_classes => 'values',
    },
);

has _plantuml_links => (
    is      => 'ro',
    isa     => 'ArrayRef[Meta::Grapher::Moose::Renderer::Plantuml::Link]',
    default => sub { return [] },
    traits  => ['Array'],
    handles => {
        _add_plantuml_link  => 'push',
        _all_plantuml_links => 'elements',
    },
);

sub render {
    my $self = shift;

    my $src = $self->_calculate_source;

    my $fh;
    if ( $self->has_output ) {
        ## no critic (InputOutput::RequireBriefOpen)
        open $fh, '>:raw', $self->output;
        ## use critic
    }
    else {
        $fh = \*STDOUT;
    }

    if ( $self->format =~ /\A(?:src|plantuml)\z/ ) {
        print {$fh} $src or die $!;
        return;
    }

    return $self->_render_with_run3( $src, $fh );
}

sub _full_java_command {
    my $self = shift;

    # Run plantuml while accepting source on STDIN, outputing to STDOUT
    return $self->java_command, '-jar', $self->plantuml_jar, '-pipe',
        '-t' . $self->format;
}

sub _render_with_run3 {
    my $self = shift;
    my $src  = shift;
    my $fh   = shift;

    # note that errors just go to STDERR. This should be probably altered
    # to be something more user friendly at some point in the future.
    run3( [ $self->_full_java_command ], \$src, $fh );

    return;
}

sub add_package {
    my $self = shift;
    my %args = @_;

    $self->_add_plantuml_class(
        $args{id},
        Meta::Grapher::Moose::Renderer::Plantuml::Class->new(
            id               => $args{id},
            label            => $args{label},
            class_attributes => $args{attributes},
            class_methods    => $args{methods},
            class_type       => $args{type},
            formatting       => $self->formatting,
        )
    ) unless $self->_get_plantuml_class( $args{id} );

    return;
}

sub add_edge {
    my $self = shift;
    my %p    = @_;

    $self->_add_plantuml_link(
        Meta::Grapher::Moose::Renderer::Plantuml::Link->new(
            from => $p{from},
            to   => $p{to},
        )
    );

    return;
}

sub _calculate_source {
    my $self = shift;

    return '@startuml' . "\n" . join(
        q{},
        map      { $_->to_plantuml }
            sort { $a->id cmp $b->id } $self->_all_plantuml_classes
        )
        . join( q{}, sort map { $_->to_plantuml } $self->_all_plantuml_links )
        . '@enduml' . "\n";
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Render a Meta::Grapher::Moose as a graph using PlantUML

__END__

=pod

=encoding UTF-8

=head1 NAME

Meta::Grapher::Moose::Renderer::Plantuml - Render a Meta::Grapher::Moose as a graph using PlantUML

=head1 VERSION

version 1.03

=head1 SYNOPSIS

    Meta::Grapher::Moose->new(
        renderer => Meta::Grapher::Moose::Renderer::Plantuml->new(),
        ...
    );

=head1 DESCRIPTION

This is one of the standard renderers that ships as part of the
Meta-Grapher-Moose distribution.

It uses the PlantUML Java distribution to create graphs.

=for Pod::Coverage render add_package add_edge

=head1 ATTRIBUTES

This class accepts the following attributes:

=head2 java_command

The command to run the Java binary.

This defaults to 'java', so it'll use whatever Java is in the path.

=head2 plantuml_jar

The full path to the C<plantuml.jar> jar file.

This defaults to C<plantuml.jar>, meaning that it'll look for that jar in the
current working directory.

=head2 formatting

The specific spot markup that you want to apply to your classes depending on
what type your packages are. The default values are:

    {
        class => '',
        role  => '<<R,#FF7700>>',
        prole => '<<P,orchid>>',
    }

More documentation on specific spot markup can be found in the "Specific Spot"
section of L<http://plantuml.com/classes.html>.

=head1 BUGS

In order for PDF generation to work you must have several extra JAR files in
the same directory as C<plantuml.jar>. See L<http://plantuml.com/pdf.html>
for more details.

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
