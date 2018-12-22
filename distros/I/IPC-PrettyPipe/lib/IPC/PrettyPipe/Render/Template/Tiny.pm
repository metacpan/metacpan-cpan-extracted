package IPC::PrettyPipe::Render::Template::Tiny;

# ABSTRACT: rendering backend using B<Template::Tiny>

use Carp;
use Template::Tiny;
use Safe::Isa;

use Text::Tabs qw[ expand ];
use Types::Standard -all;
use Type::Params qw[ validate ];

use Moo;


our $VERSION = '0.12';

BEGIN {
    if ( $^O =~ /Win32/i ) {
        require Win32::Console::ANSI;
    }
}
use Term::ANSIColor ();

use namespace::clean;


























has pipe => (
    is       => 'rw',
    isa      => InstanceOf ['IPC::PrettyPipe'],
    required => 1,
);
















has colors => (
    is      => 'rw',
    isa     => HashRef,
    default => sub {
        {
            cmd => {
                cmd    => 'blue',
                stream => {
                    spec => 'red',
                    file => 'green',
                },
                arg => {
                    name  => 'red',
                    sep   => 'yellow',
                    value => 'green',
                },
            },
            pipe => {
                stream => {
                    spec => 'red',
                    file => 'green',
                },
            },
        };
    },
);



















has cmd_template => (
    is      => 'rw',
    default => <<"EOT",
[%- indent %][% color.cmd.cmd %][% cmd.quoted_cmd %][% color.reset %]
[%- FOREACH arg IN cmd.args.elements %]\\
[% indent %][% indent %][% color.cmd.arg.pfx %][% arg.pfx %][% color.cmd.arg.name %][% arg.quoted_name %]
[%- IF arg.has_value %][%- IF arg.sep %][% color.cmd.arg.sep %][% arg.sep %][% ELSE %] [% END %]
[%- color.cmd.arg.value %][% arg.quoted_value %][% END %][% color.reset %]
[%- END %]
[%- FOREACH stream IN cmd.streams.elements %]\\
[% indent %][% indent %][% color.cmd.stream.spec %][% stream.spec -%]
[% IF stream.has_file %] [% color.cmd.stream.file %][% stream.quoted_file %][% color.reset %][% END %]
[%- END -%]
EOT
);


















has pipe_template => (

    is => 'rw',

    default => <<"EOT",
[% indent %][% IF pipe.streams.empty %][% ELSE %](\\
[% END %][% cmds %]
[%- IF pipe.streams.empty %][% ELSE %]\\
[% indent %])[% FOREACH stream IN pipe.streams.elements -%]
[% IF stream.first %]\t[% ELSE %]\\
\t[% indent %][% END -%]
[% color.pipe.stream.spec %][% stream.spec -%]
[% IF stream.has_file %] [% color.pipe.stream.file %][% stream.quoted_file %][% color.reset %][% END %]
[%- END -%]
[%- END -%]
EOT
);

sub _colorize {

    my ( $tmpl, $colors ) = @_;

    ## no critic (ProhibitAccessOfPrivateData)

    while ( my ( $node, $value ) = each %$tmpl ) {

        if ( ref $value ) {

            $colors->{$node} = {};
            _colorize( $value, $colors->{$node} );

        }

        else {
            $colors->{$node} = Term::ANSIColor::color( $value );
        }

    }

}



















sub render {

    my $self = shift;

    my ( $args ) = validate(
        \@_,
        slurpy Dict [
            colorize => Optional [Bool],
        ] );

    $args->{colorize} //= 1;    ## no critic (ProhibitAccessOfPrivateData)

    my %color;
    _colorize( $self->colors, \%color );

    $color{reset} = Term::ANSIColor::color( 'reset' )
      if keys %color;

    local $Text::Tabs::tabstop = 2;

    # generate non-colorized version so can get length of records to
    # pad out any continuation lines
    my @output;
    $self->_render_pipe( $self->pipe, { indent => '' },  \@output);

    my @records = map { expand( $_ ) } map { split( /\n/, $_ ) } @output;
    my @lengths = map { length } @records;
    my $max = List::Util::max( @lengths ) + 4;

    if ( $args->{colorize} ) {
        @output = ();
        $self->_render_pipe( $self->pipe, { indent => '', color => \%color },  \@output);
        @records = map { expand( $_ ) } map { split( /\n/, $_ ) } @output;
    }

    foreach ( @records ) {
        my $pad =  ' ' x ($max - shift @lengths);
        s/\\$/$pad \\/;
    }

    return join ("\n", @records ) . "\n";
}

sub _render_pipe {

    my $self = shift;

    my ( $pipe, $process_args, $output ) = @_;

    my %process_args = %{$process_args};

    my @output;

    for my $cmd ( @{ $pipe->cmds->elements } ) {
        if ( $cmd->isa( 'IPC::PrettyPipe' ) ) {
            local $process_args{indent} = $process_args{indent} . "\t";
            $self->_render_pipe( $cmd, \%process_args, \@output );
        }
        else {
            local $process_args{indent} = $process_args{indent} . "\t";
            push @output, '';
            local $process_args{cmd} = $cmd;
            Template::Tiny->new->process( \$self->cmd_template, \%process_args,
                \( $output[-1] ) );
        }
    }

    $process_args{cmds} = join( "\\\n|", @output );
    $process_args{pipe} = $pipe;
    push @{$output}, '';
    Template::Tiny->new->process( \$self->pipe_template, \%process_args,
        \( $output->[-1] ) );
    return;
}


with 'IPC::PrettyPipe::Renderer';

1;

#
# This file is part of IPC-PrettyPipe
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory cmds renderer

=head1 NAME

IPC::PrettyPipe::Render::Template::Tiny - rendering backend using B<Template::Tiny>

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  use IPC::PrettyPipe::DSL;

  my $pipe = ppipe 'ls';
  $pipe->renderer( 'Template::Tiny' );

  # or, more explicitly
  my $renderer = IPC::PrettyPipe::Render::Template::Tiny->new;
  $pipe->renderer( $renderer );

=head1 DESCRIPTION

B<IPC::PrettyPipe::Render::Template::Tiny> implements the
L<IPC::PrettyPipe::Renderer> role, providing a rendering backend for
L<IPC::PrettyPipe> using the L<Template::Tiny> module.

=head1 ATTRIBUTES

=head2 pipe

The L<IPC::PrettyPipe> object to render.

=head2 pipe

  $pipe = $renderer->pipe;
  $renderer->pipe( $pipe );

Retrieve or set the L<IPC::PrettyPipe> object to render.

=head2 colors

A color specification; see L</Rendered Colors>.

=head2 cmd_template

A L<Template::Tiny> template to generate output for commands.  See L</Rendering
Templates>.

=head2 pipe_template

A L<Template::Tiny> template to generate output for pipes.  See L</Rendering
Templates>.

=head1 METHODS

=head2 new

  $renderer = IPC::PrettyPipe::Render::Template::Tiny->new( %attr );

Construct a new renderer.  Typically this is done automatically by L<IPC::PrettyPipe>.

=head2 colors

  $colors = $renderer->colors;
  $renderer->colors( $colors );

Retrieve or set the colors to be output; see L</Rendered Colors>.

=head2 cmd_template

  $cmd_template = $renderer->cmd_template;
  $renderer->cmd_template( $cmd_template );

Retrieve or set the L<Template::Tiny> template used to generate output
for commands.  See L</Rendering Templates>.

=head2 pipe_template

  $pipe_template = $renderer->pipe_template;
  $renderer->pipe_template( $pipe_template );

Retrieve or set the L<Template::Tiny> template used to generate output
for pipes.  See L</Rendering Templates>.

=head2 render

  $renderer->render( %options );

The following options are available:

=over

=item *

colorize

If true (the default) the output is colorized using L<Term::AnsiColor>.

=back

=head1 CONFIGURATION

=head2 Rendering Templates

Because pipes may be nested and L<Template::Tiny> cannot handle
recursive logic, there are two templates, C<cmd_template> for commands
and C<pipe_template> for pipes.

L<Template::Tiny> also doesn't support loop constructs, so the
L<IPC::PrettyPipe> L<streams|IPC::PrettyPipe/streams> and
L<cmds|IPC::PrettyPipe/cmds> methods return L<IPC::PrettyPipe::Queue>
objects, which provide methods for determining if the lists are empty.

  [% IF pipe.streams.empty %][% ELSE %](\t\\
  [% END -%]

Note that L<Template::Tiny> resolves object methods with the same syntax as it
resolves hash entries.

Iteration looks like this:

  [%- FOREACH cmd IN pipe.cmds.elements %]
  [% END %]

An L<IPC::PrettyPipe::Queue::Element> has additional methods which
indicates whether it is the first or last in its queue.

  [%- IF cmd.first %]  [% ELSE %]\t\\
  | [% END %]

The templates are passed the following parameters:

=over

=item C<indent>

Indentation is performed via tab stops.  C<indent> is augmented with
additional tab characters (C<\t>) for nested pipes.

=item C<pipe>

This is passed only to the C<pipe_template>.

C<pipe> is the L<IPC::PrettyPipe> object.

=item C<cmd>

This is passed only to the C<cmd_template>

C<cmd> is the L<IPC::PrettyPipe::Cmd> object.

=item C<cmds>

This is passed only to the C<pipe_template>.
It contains the rendered commands in the pipe.

=item C<color>

This is the hashref specified by the C<colors> attribute or method.
It contains an additional element C<reset> which can be used to reset
all colors at once.  Here's an example bit of template to output
and colorize a command:

  [% color.cmd.cmd %][% cmd.cmd %][% color.reset %]

=back

Use the default templates (encoded into the source file for
B<IPC::PrettyPipe::Render::Template::Tiny>) as a basis for
exploration.

=head2 Rendered Colors

The C<colors> attribute and method may be used to change
the colors used to render the pipeline.  Colors are
stored as a hashref with the following default contents:

  cmd => {
      cmd    => 'blue',
      stream => {
          spec => 'red',
          file => 'green',
      },
      arg => {
          name  => 'red',
          sep   => 'yellow',
          value => 'green',
      },
  },
  pipe => {
      stream => {
          spec => 'red',
          file => 'green',
      },
  },

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=IPC-PrettyPipe> or by
email to
L<bug-IPC-PrettyPipe@rt.cpan.org|mailto:bug-IPC-PrettyPipe@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/ipc-prettypipe>
and may be cloned from L<git://github.com/djerius/ipc-prettypipe.git>

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<IPC::PrettyPipe|IPC::PrettyPipe>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
