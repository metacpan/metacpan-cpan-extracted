package IPC::PrettyPipe;

# ABSTRACT: manage human readable external command execution pipelines

use strict;
use warnings;

our $VERSION = '0.12';
use Carp;

use List::Util qw[ sum ];
use Module::Load qw[ load ];
use Module::Runtime
  qw[ check_module_name compose_module_name use_package_optimistically ];
use Safe::Isa;
use Try::Tiny;

use Types::Standard -all;
use Type::Params qw[ validate ];

use IPC::PrettyPipe::Types -all;

use IPC::PrettyPipe::Cmd;
use IPC::PrettyPipe::Queue;
use IPC::PrettyPipe::Arg::Format;

use Moo;
use Moo::Role ();

with 'IPC::PrettyPipe::Queue::Element';

use namespace::clean;

BEGIN {
    IPC::PrettyPipe::Arg::Format->shadow_attrs( fmt => sub { 'arg' . shift } );
}

























has argfmt => (
    is      => 'ro',
    lazy    => 1,
    handles => IPC::PrettyPipe::Arg::Format->shadowed_attrs,
    default => sub { IPC::PrettyPipe::Arg::Format->new_from_attrs( shift ) },
);






















has streams => (
    is       => 'ro',
    default  => sub { IPC::PrettyPipe::Queue->new },
    init_arg => undef,
);


has _init_cmds => (
    is        => 'ro',
    init_arg  => 'cmds',
    coerce    => AutoArrayRef->coercion,
    isa       => ArrayRef,
    default   => sub { [] },
    predicate => 1,
    clearer   => 1,
);


















# must delay building cmds until all attributes have been specified
has cmds => (
    is       => 'ro',
    default  => sub { IPC::PrettyPipe::Queue->new },
    init_arg => undef,
);

has _executor_arg => (
    is       => 'rw',
    init_arg => 'executor',
    default  => sub { 'IPC::Run' },
    trigger  => sub { $_[0]->_clear_executor },
);


has _executor => (
    is      => 'rw',
    isa     => ConsumerOf ['IPC::PrettyPipe::Executor'],
    handles => 'IPC::PrettyPipe::Executor',
    lazy    => 1,
    clearer => 1,
    default => sub {

        my $backend = $_[0]->_executor_arg;

        ## no critic (ProhibitAccessOfPrivateData)
        return $backend->$_does( 'IPC::PrettyPipe::Executor' )
          ? $backend
          : $_[0]->_backend_factory( Execute => $backend );
    },
);











sub executor {
    my $self = shift;

    $self->_executor_arg( @_ )
      if @_;

    return $self->_executor;
}










has _renderer_arg => (
    is       => 'rw',
    init_arg => 'renderer',
    default  => sub { 'Template::Tiny' },
    trigger  => sub { $_[0]->_clear_renderer },
);

has _renderer => (
    is      => 'rw',
    isa     => ConsumerOf ['IPC::PrettyPipe::Renderer'],
    handles => 'IPC::PrettyPipe::Renderer',
    lazy    => 1,
    clearer => 1,
    default => sub {

        my $backend = $_[0]->_renderer_arg;

        ## no critic (ProhibitAccessOfPrivateData)
        return $backend->$_does( 'IPC::PrettyPipe::Renderer' )
          ? $backend
          : $_[0]->_backend_factory( Render => $backend );
    },
);










sub renderer {
    my $self = shift;

    $self->_renderer_arg( @_ )
      if @_;

    return $self->_renderer;
}














# accept:
#  new( \%hash )
#  new( $cmd )
#  new( @stuff )
sub BUILDARGS {

    shift;

    return
        @_ == 1
      ? 'HASH' eq ref( $_[0] )
          ? $_[0]
          : { cmds => $_[0] }
      : {@_};

}


sub BUILD {

    my $self = shift;

    if ( $self->_has_init_cmds ) {

        $self->ffadd( @{ $self->_init_cmds } );
        $self->_clear_init_cmds;
    }

    return;

}



































sub add {

    my $self = shift;

    unshift @_, 'cmd' if @_ == 1;

    ## no critic (ProhibitAccessOfPrivateData)

    my $argfmt = $self->argfmt->clone;

    my $argfmt_attrs = IPC::PrettyPipe::Arg::Format->shadowed_attrs;

    my ( $attr ) = validate(
        \@_,
        slurpy Dict [
            cmd    => Str | Cmd | Pipe,
            args   => Optional,
            argfmt => Optional [ InstanceOf ['IPC::PrettyPipe::Arg::Format'] ],
            ( map { $_ => Optional [Str] } keys %{$argfmt_attrs} ),
        ] );


    my $cmd;

    $argfmt->copy_from( $attr->{argfmt} ) if defined $attr->{argfmt};
    $argfmt->copy_from( IPC::PrettyPipe::Arg::Format->new_from_hash( $attr ) );


    if ( $attr->{cmd}->$_isa( 'IPC::PrettyPipe::Cmd' ) ) {

        $cmd = delete $attr->{cmd};

        croak(
            "cannot specify additional arguments when passing a Cmd object\n" )
          if keys %$attr;
    }

    elsif ( $attr->{cmd}->$_isa( 'IPC::PrettyPipe' ) ) {

        $cmd = delete $attr->{cmd};

        croak(
            "cannot specify additional arguments when passing a Pipe object\n" )
          if keys %$attr;
    }

    else {

        $cmd = IPC::PrettyPipe::Cmd->new(
            cmd    => $attr->{cmd},
            argfmt => $argfmt->clone,
            exists $attr->{args} ? ( args => $attr->{args} ) : (),
        );
    }

    $self->cmds->push( $cmd );

    return $cmd;
}










































sub ffadd {

    my $self = shift;
    my @args = @_;

    my $argfmt = $self->argfmt->clone;

    for ( my $idx = 0 ; $idx < @args ; $idx++ ) {

        my $t = $args[$idx];

        if ( $t->$_isa( 'IPC::PrettyPipe::Arg::Format' ) ) {

            $t->copy_into( $argfmt );

        }

        elsif ( $t->$_isa( 'IPC::PrettyPipe::Cmd' ) ) {

            $self->add( $t );

        }

        elsif ( $t->$_isa( 'IPC::PrettyPipe' ) ) {

            $self->add( $t );

        }

        elsif ( 'ARRAY' eq ref $t ) {

            my $cmd;

            if ( ( $cmd = $t->[0])->$_isa( 'IPC::PrettyPipe' ) ) {
                croak( "In an array containing an IPC::PrettyPipe object, it must be the only element\n" )
                  if @$t > 1;
            }

            else {

                $cmd = IPC::PrettyPipe::Cmd->new(
                                                    cmd    => shift( @$t ),
                                                    argfmt => $argfmt->clone
                                                   );
                $cmd->ffadd( @$t );
            }

            $self->add( $cmd );
        }

        elsif ( $t->$_isa( 'IPC::PrettyPipe::Stream' ) ) {

            $self->stream( $t );

        }

        elsif ( !ref $t ) {

            try {

                my $stream = IPC::PrettyPipe::Stream->new(
                    spec   => $t,
                    strict => 0,
                );

                if ( $stream->requires_file ) {

                    croak( "arg[$idx]: stream operator $t requires a file\n" )
                      if ++$idx == @args;

                    $stream->file( $args[$idx] );
                }

                $self->stream( $stream );
            }
            catch {

                die $_ unless /requires a file|cannot parse/;

                # This is the "fall through" which takes care
                # of calling with a simple string argument, which is
                # taken to be a command to run.  It probably shouldn't
                # be buried at this level of the code.

                $self->add( cmd => $t, argfmt => $argfmt );
            };

        }

        else {

            croak( "arg[$idx]: unrecognized parameter to ffadd\n" );

        }

    }

}












sub stream {

    my $self = shift;

    my $spec = shift;

    if ( $spec->$_isa( 'IPC::PrettyPipe::Stream' ) ) {

        croak( "too many arguments\n" )
          if @_;

        $self->streams->push( $spec );

    }

    elsif ( !ref $spec ) {

        $self->streams->push(
            IPC::PrettyPipe::Stream->new(
                spec => $spec,
                +@_ ? ( file => @_ ) : () ) );
    }

    else {

        croak( "illegal stream specification\n" );

    }


    return;
}












sub valmatch {

    my $self    = shift;
    my $pattern = shift;

    return sum 0,
      map { $_->valmatch( $pattern ) && 1 || 0 } @{ $self->cmds->elements };
}






































































sub valsubst {

    my $self = shift;

    my @args = ( shift, shift, @_ > 1 ? {@_} : @_ );

    my ( $pattern, $value, $args ) = validate(
        \@args,
        RegexpRef,
        Str,
        Optional [
            Dict [
                lastvalue  => Optional [Str],
                firstvalue => Optional [Str] ]
        ],
    );

    my $nmatch = $self->valmatch( $pattern );

    if ( $nmatch == 1 ) {

        ## no critic (ProhibitAccessOfPrivateData)
        $args->{lastvalue}  //= $args->{firstvalue} // $value;
        $args->{firstvalue} //= $args->{lastvalue};

    }
    else {

        ## no critic (ProhibitAccessOfPrivateData)
        $args->{lastvalue}  ||= $value;
        $args->{firstvalue} ||= $value;
    }

    my $match = 0;
    foreach ( @{ $self->cmds->elements } ) {

        ## no critic (ProhibitAccessOfPrivateData)

        $match++
          if $_->valsubst( $pattern,
              $match == 0 ? $args->{firstvalue}
            : $match == ( $nmatch - 1 ) ? $args->{lastvalue}
            :                             $value );
    }

    return $match;
}

sub _backend_factory {

    my ( $self, $type, $req ) = ( shift, shift, shift );

    check_module_name( $req );

    my $role = compose_module_name( __PACKAGE__,
        {
            Render  => 'Renderer',
            Execute => 'Executor'
        }->{$type} );

    my $module;

    for my $try ( $req, compose_module_name( "IPC::PrettyPipe::$type", $req ) )
    {
        next unless use_package_optimistically( $try )->DOES( $role );

        $module = $try;
        last;
    }

    croak(
        "requested $type module ($req) either doesn't exist or doesn't consume $role\n"
    ) if !defined $module;

    return $module->new( pipe => $self, @_ );
}


sub _storefh {

    my $self = shift;

    my $sfh = IO::ReStoreFH->new;

    for my $stream ( @{ $self->streams->elements } ) {

        my ( $sub, @fh ) = $stream->apply;

        $sfh->store( $_ ) foreach @fh;

        $sub->();
    }

    return $sfh;
}

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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory argfmt argpfx argsep cmds
ffadd renderer valmatch valsubst

=head1 NAME

IPC::PrettyPipe - manage human readable external command execution pipelines

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  use IPC::PrettyPipe;

  my $pipe = IPC::PrettyPipe->new;

  $pipe->add( $command, %options );
  $pipe->add( cmd => $command, %options );

  $pipe->stream( $stream_op, $stream_file );

  $cmd = $pipe->add( $command );
  $cmd->add( $args );

  print $pipe->render, "\n";

=head1 DESCRIPTION

Connecting a series of programs via pipes is a time honored tradition.
When it comes to displaying them for debug or informational purposes,
simple dumps may suffice for simple pipelines, but when the number of
programs and arguments grows large, it can become difficult to understand
the overall structure of the pipeline.

B<IPC::PrettyPipe> provides a mechanism to construct and output
readable external command execution pipelines.  It does this by
treating commands, their options, and the options' values as separate
entities so that it can produce nicely formatted output.

It is designed to be used in conjunction with other modules which
actually execute pipelines, such as L<IPC::Run>.

This module (and its siblings L<IPC::PrettyPipe::Cmd>,
L<IPC::PrettyPipe::Arg>, and L<IPC::PrettyPipe::Stream>) present
the object-oriented interface for manipulating the underlying
infrastructure.

For a simpler, more intuitive means of constructing pipelines, see
L<IPC::PrettyPipe::DSL>.

=head2 Pipeline Rendering (Pretty Printing)

L<IPC::PrettyPipe> doesn't render a pipeline directly; instead it
passes that job on to another object (which must consume the
L<IPC::PrettyPipe::Renderer> role).

By default B<IPC::PrettyPipe> provides a renderer which uses
L<Template::Tiny> to render a pipeline as if it were to be fed to a
POSIX shell (which can be handy for debugging complex pipelines).

The same renderer may be fed a different template to use, or it may be
replaced via the L</renderer> attribute.

=head2 Pipeline Execution

Just as with rendering, B<IPC::PrettyPipe> doesn't execute a pipeline
on its own.  Instead it calls upon another object (which must consume
the L<IPC::PrettyPipe::Executor> role).  By default it provides an
executor which uses L<IPC::Run> to run the pipeline.  The executor
may be replaced via the L</executor> attribute.

=head2 Rewriting Commands' argument values

Sometimes it's not possible to fill in an argument's value until after
a pipeline has been created.  The L</valsubst> method allows
altering them after the fact.

=head1 ATTRIBUTES

=head2 argfmt

I<Optional>. An L<IPC::PrettyPipe::Arg::Format> object specifying
the default prefix and separation attributes for arguments to
commands.  May be overridden by L</argpfx> and L</argsep>.

=head2 argpfx

=head2 argsep

I<Optional>.  The default prefix and separation attributes for
arguments to commands.  See L<IPC::PrettyPipe::Arg> for more
details.  These override any specified via the L</argfmt> object.

=head2 streams

  $streams = $pipe->streams;

A L<IPC::PrettyPipe::Queue> object containing the
L<IPC::PrettyPipe::Stream> objects associated with the pipe. Created
automatically.

=head2 cmds

I<Optional>. The value should be an arrayref of commands to load into
the pipe.  The contents of the array are passed to the L</ffadd>
method for processing.

=head2 executor

I<Optional>. The means by which the pipeline will be executed.  It may
be either a class name or an object reference, and must consume the
L<IPC::PrettyPipe::Executor> role.  It defaults to
L<IPC::PrettyPipe::Execute::IPC::Run>.

=head2 renderer

I<Optional>. The means by which the pipeline will be rendered.  It may
be either a class name or an object reference, and must consume the
L<IPC::PretyyPipe::Renderer> role.  It defaults to
L<IPC::PrettyPipe::Render::Template::Tiny>.

=head1 METHODS

=head2 new

  # initialize the pipe with commands
  $pipe = IPC::PrettyPipe->new(
    cmds => [ $cmd1, $cmd2 ], %attrs
  );

  # initialize the pipe with a single command
  $pipe = IPC::PrettyPipe->new( $cmd );

  # create an empty pipeline, setting defaults
  $pipe = IPC::PrettyPipe->new( %attrs );

=head2 B<cmds>

  $cmds = $pipe->cmds;

Return a L<IPC::PrettyPipe::Queue> object containing the
L<IPC::PrettyPipe::Cmd> objects associated with the pipe.

=head2 run

   $pipe->run

Execute the pipeline.

=head2 render

  my $string = $pipe->render

Return a prettified string of the pipeline.

=head2 add

  $cmd_obj = $pipe->add( cmd => $cmd, %options );

Create an L<IPC::PrettyPipe::Cmd> object, add it to the
B<IPC::PrettyPipe> object, and return a handle to it.  C<%options> are
the same as for the L<IPC::PrettyPipe::Cmd> constructor.

C<add> may also be passed a single parameter, which may be one of:

=over

=item $cmd_obj = $pipe->add( $cmd_name );

The name of a command

=item $cmd_obj = $pipe->add( $cmd_obj );

An existing C<IPC::PrettyPipe::Cmd> object

=item $pipe_obj = $pipe->add( $pipe_obj );

An existing C<IPC::PrettyPipe> object.  This is intended to allow
pipes to be nested.  However, nested pipes with non-default
streams may not be supported by the pipe executor.

=back

=head2 ffadd

  $pipe->ffadd( @cmds );

A more relaxed means of adding commands. C<@cmds> may contain any
of the following items:

=over

=item *

an L<IPC::PrettyPipe::Cmd> object

=item *

A command name (i.e. a string), for a command without arguments.

=item *

A string which matches a stream specification
(L<IPC::PrettyPipe::Stream::Utils/Stream Specification>), which will cause
a new I/O stream to be attached to the pipeline.  If the specification
requires an additional parameter, the next value in C<@cmds> will be
used for that parameter.

=item *

An arrayref. The first element is the command name; the rest are its
arguments; these are passed to
L<IPC::PrettyPipe::Cmd::new|IPC::PrettyPipe::Cmd/new> as the C<cmd>
and C<args> parameters.

=item *

An L<IPC::PrettyPipe::Arg::Format> object, specifying the argument
prefix and separator attributes for successive commands.

=back

=head2 stream

  $pipe->stream( $stream_spec );
  $pipe->stream( $stream_spec, $file );

Add an I/O stream to the pipeline.  See
L<IPC::PrettyPipe::Stream::Utils/Stream Specification> for more
information.

=head2 valmatch

  $n = $pipe->valmatch( $pattern );

Returns the number of I<commands> with a value matching the passed
regular expression.  (This is B<not> equal to the number of total
I<values> which matched.  To determine this, iterate over each
command, calling it's L<valmatch|IPC::PrettyPipe::Cmd/valmatch> method ).

=head2 valsubst

   $pipe->valsubst( $pattern, $value, %attr );

Replace arguments to options whose arguments match the Perl regular
expression I<$pattern> with I<$value>.  The following attributes
are available:

=over

=item C<firstvalue>

The first matched argument will be replaced with this value

=item C<lastvalue>

The last matched argument will be replaced with this value.

=back

Note that matching is done on a per-command basis, not per-argument
basis, so that if a command has multiple matching values, they will
all use the same replacement string.  To perform more specific
changes, use each command's
L<valsubst|IPC::PrettyPipe::Cmd/valsubst> method directly.

Here's an example where the commands use parameters C<input> and
C<output> to indicate where they should write.  The strings "stdout"
and "stdin" are special and indicate the standard streams. Using
B<valsubst> allows an easy update of the pipeline after construction
to specify the correct streams.

  $p = new IPC::PrettyPipe;

  $p->add( cmd => 'cmd1',
           args => [ [ input  => 'INPUT',
                       output => 'OUTPUT' ] ] );

  $p->add( cmd => 'cmd2',
           args => [ [ input  => 'INPUT',
                       output => 'OUTPUT' ] ] );

  $p->add( cmd => 'cmd3',
           args => [ [ input  => 'INPUT',
                       output => 'OUTPUT' ] ] );

  $p->valsubst( qr/OUTPUT/, 'stdout',
                lastvalue => 'output_file' );

  $p->valsubst( qr/INPUT/, 'stdin',
                firstvalue => 'input_file' );

  print $p->render, "\n"

results in

        cmd1 \
          input input_file \
          output stdout \
  |     cmd2 \
          input stdin \
          output stdout \
  |     cmd3 \
          input stdin \
          output output_file

=for Pod::Coverage BUILDARGS BUILD

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

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
