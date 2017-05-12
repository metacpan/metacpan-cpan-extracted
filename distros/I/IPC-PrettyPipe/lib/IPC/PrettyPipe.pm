# --8<--8<--8<--8<--
#
# Copyright (C) 2014 Smithsonian Astrophysical Observatory
#
# This file is part of IPC::PrettyPipe
#
# IPC::PrettyPipe is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package IPC::PrettyPipe;

## no critic (RequireUseStrict)

our $VERSION = '0.03';

use Carp;

use List::Util qw[ sum first ];
use Module::Load qw[ load ];
use Module::Runtime qw[ check_module_name compose_module_name use_package_optimistically ];
use Safe::Isa;
use Try::Tiny;

use Types::Standard -all;
use Type::Params qw[ validate ];

use Moo;
use Moo::Role ();

use IPC::PrettyPipe::Types -all;

use IPC::PrettyPipe::Cmd;
use IPC::PrettyPipe::Queue;
use IPC::PrettyPipe::Arg::Format;



IPC::PrettyPipe::Arg::Format->shadow_attrs( fmt => sub { 'arg' . shift } );

has argfmt => (
  is => 'ro',
  lazy => 1,
  handles => IPC::PrettyPipe::Arg::Format->shadowed_attrs,
  default => sub { IPC::PrettyPipe::Arg::Format->new_from_attrs( shift ) },
);

has streams => (
    is       => 'ro',
    default  => sub { IPC::PrettyPipe::Queue->new },
    init_arg => undef,
);


has _init_cmds => (
    is       => 'ro',
    init_arg => 'cmds',
    coerce   => AutoArrayRef->coercion,
    isa => ArrayRef,
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
    isa     => ConsumerOf[ 'IPC::PrettyPipe::Executor' ],
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

has _renderer  => (
    is       => 'rw',
    isa     => ConsumerOf[ 'IPC::PrettyPipe::Renderer' ],
    handles  => 'IPC::PrettyPipe::Renderer',
    lazy    => 1,
    clearer => 1,
    default => sub {

	my $backend = $_[0]->_renderer_arg;

	## no critic (ProhibitAccessOfPrivateData)
	return $backend->$_does( 'IPC::PrettyPipe::Renderer' )
	  ? $backend
	  : $_[0]->_backend_factory( Render => $backend )
	  ;
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

    my $class = shift;

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
            cmd    => Str | Cmd,
	    args   => Optional,
            argfmt => Optional [ InstanceOf ['IPC::PrettyPipe::Arg::Format'] ],
            ( map { $_ => Optional [Str] } keys %{$argfmt_attrs} ),
        ] );


    my $cmd;

    $argfmt->copy_from( $attr->{argfmt} ) if defined $attr->{argfmt};
    $argfmt->copy_from( IPC::PrettyPipe::Arg::Format->new_from_hash( $attr ) );


    if ( $attr->{cmd}->$_isa( 'IPC::PrettyPipe::Cmd' ) ) {

        $cmd = delete $attr->{cmd};

        croak( "cannot specify additional arguments when passing a Cmd object\n" )
          if keys %$attr;
    }

    else {

        $cmd = IPC::PrettyPipe::Cmd->new( cmd => $attr->{cmd},
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

        elsif ( 'ARRAY' eq ref $t ) {

	    my $cmd = IPC::PrettyPipe::Cmd->new( cmd => shift( @$t ), argfmt => $argfmt->clone );
	    $cmd->ffadd( @$t);

            $self->add( $cmd );
        }

        elsif ( $t->$_isa( 'IPC::PrettyPipe::Stream' ) ) {

            $self->stream( $t );

        }

        elsif ( !ref $t ) {


            my $stream;

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

		# FIXME: this is the "fall through" which takes care
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
          IPC::PrettyPipe::Stream->new( spec => $spec, +@_ ? ( file => @_ ) : () )
			     );
    }

    else {

        croak( "illegal stream specification\n" );

    }


    return;
}

sub valmatch {

    my $self    = shift;
    my $pattern = shift;

    return sum 0, map { $_->valmatch( $pattern ) && 1 || 0 } @{ $self->cmds->elements };
}


sub valsubst {

    my $self = shift;

    my @args = ( shift, shift, @_ > 1 ? { @_ } : @_ );

    my ( $pattern, $value, $args ) =
      validate( \@args,
		RegexpRef,
		Str,
		Optional[ Dict[
			    lastvalue  => Optional[ Str ],
			    firstvalue => Optional[ Str ]
			   ] ],
	      );

    my $nmatch = $self->valmatch( $pattern );

    if ( $nmatch == 1 ) {

	## no critic (ProhibitAccessOfPrivateData)
        $args->{lastvalue} //= $args->{firstvalue} // $value;
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
				    { Render => 'Renderer',
				      Execute => 'Executor'}->{$type} );

    my $module = first { use_package_optimistically($_)->DOES( $role ) } $req,
	  compose_module_name( "IPC::PrettyPipe::$type", $req );

    croak( "requested $type module ($req) either doesn't exist or doesn't consume $role\n" )
      if ! defined $module;

    load $module;

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


__END__

=head1 NAME

B<IPC::PrettyPipe> - manage human readable external command execution pipelines

=head1 SYNOPSIS

  use IPC::PrettyPipe;

  my $pipe = new IPC::PrettyPipe;

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
entitites so that it can produce nicely formatted output.

It is designed to be used in conjunction with other modules which
actually execute pipelines, such as B<L<IPC::Run>>

This module (and its siblings B<L<IPC::PrettyPipe::Cmd>>,
B<L<IPC::PrettyPipe::Arg>>, and B<L<IPC::PrettyPipe::Stream>>) present
the object-oriented interface for manipulating the underlying
infrastructure.

For a simpler, more intuitive means of constructing pipelines, see
B<L<IPC::PrettyPipe::DSL>>.

=head2 Pipeline Rendering (Pretty Printing)

B<L<IPC::PrettyPipe>> doesn't render a pipeline directly; instead it
passes that job on to another object (which must consume the
B<L<IPC::PrettyPipe::Renderer>> role).

By default B<IPC::PrettyPipe> provides a renderer which uses
B<L<Template::Tiny>> to render a pipeline as if it were to be fed to a
POSIX shell (which can be handy for debugging complex pipelines).

The same renderer may be fed a different template to use, or it may be
replaced via the B<L</renderer>> attribute.

=head2 Pipeline Execution

Just as with rendering, B<IPC::PrettyPipe> doesn't execute a pipeline
on its own.  Instead it calls upon another object (which must consume
the B<L<IPC::PrettyPipe::Executor>> role).  By default it provides an
executor which uses B<L<IPC::Run>> to run the pipeline.  The executor
may be replaced via the B<L</executor>> attribute.

=head2 Rewriting Commands' argument values

Sometimes it's not possible to fill in an argument's value until after
a pipeline has been created.  The B<L</valsubst>> method allows
altering them after the fact.


=head1 METHODS

=over

=item new

  # initialize the pipe with commands
  $pipe = IPC::PrettyPipe->new( 
    cmds => [ $cmd1, $cmd2 ], %attrs
  );

  # initialize the pipe with a single command
  $pipe = IPC::PrettyPipe->new( $cmd );

  # create an empty pipeline, setting defaults
  $pipe = IPC::PrettyPipe->new( %attrs );

Create a new C<IPC::PrettyPipe> object. The available attributes are:

=over

=item C<cmds>

I<Optional>. The value should be an arrayref of commands to load into
the pipe.  The contents of the array are passed to the B<L</ffadd>>
method for processing.

=item C<argpfx>, C<argsep>

I<Optional>.  The default prefix and separation attributes for
arguments to commands.  See B<L<IPC::PrettyPipe::Arg>> for more
details.  These override any specified via the C<L</argfmt>> object.

=item C<argfmt>

I<Optional>. An B<L<IPC::PrettyPipe::Arg::Format>> object specifying
the default prefix and separation attributes for arguments to
commands.  May be overridden by C<L</argpfx>> and C<L</argsep>>.

=item C<executor>

I<Optional>. The means by which the pipeline will be executed.  It may
be either a class name or an object reference, and must consume the
B<L<IPC::PrettyPipe::Executor>> role.  It defaults to
C<L<IPC::PrettyPipe::Execute::IPC::Run>>.

=item C<renderer>

I<Optional>. The means by which the pipeline will be rendered.  It may
be either a class name or an object reference, and must consume the
B<L<IPC::PretyyPipe::Renderer>> role.  It defaults to
B<L<IPC::PrettyPipe::Render::Template::Tiny>>.

=back

=item B<add>

  $cmd_obj = $pipe->add( $cmd );
  $cmd_obj = $pipe->add( cmd => $cmd, %options );

Create an B<L<IPC::PrettyPipe::Cmd>> object, add it to the
B<IPC::PrettyPipe> object, and return a handle to it.  If passed
a single parameter, it is assumed to be a C<cmd> parameter.

This is a thin wrapper around the B<L<IPC::PrettyPipe::Cmd>> constructor,
taking the same parameters.  The only difference is that if the value
of the C<cmd> parameter is an B<L<IPC::PrettyPipe::Cmd>> object it
is inserted into the pipeline.

=item B<ffadd>

  $pipe->ffadd( @cmds );

A more relaxed means of adding commands. C<@cmds> may contain any
of the following items:

=over

=item *

an B<L<IPC::PrettyPipe::Cmd>> object

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
B<L<IPC::PrettyPipe::Cmd::new|IPC::PrettyPipe::Cmd/new>> as the C<cmd>
and C<args> parameters.

=item *

An B<L<IPC::PrettyPipe::Arg::Format>> object, specifying the argument
prefix and separator attributes for successive commands.

=back

=item B<argpfx>

=item B<argsep>

These methods retrieve (when called with no arguments) or modify (when
called with an argument) the similarly named object
attributes. Changing these affects the defaults for future command
arguments; it does not affect existing arguments.

See B<L<IPC::PrettyPipe::Arg>> for more information.

=item B<cmds>

  $cmds = $pipe->cmds;

Return a B<L<IPC::PrettyPipe::Queue>> object containing the
B<L<IPC::PrettyPipe::Cmd>> objects associated with the pipe.

=item B<render>

  my $string = $pipe->render

Return a prettified string of the pipeline.


=item B<run>

   $pipe->run

Execute the pipeline.

=item B<stream>

  $pipe->stream( $stream_spec );
  $pipe->stream( $stream_spec, $file );

Add an I/O stream to the pipeline.  See
L<IPC::PrettyPipe::Stream::Utils/Stream Specification> for more
information.

=item B<streams>

  $streams = $pipe->streams

Return a B<L<IPC::PrettyPipe::Queue>> object containing the
B<L<IPC::PrettyPipe::Stream>> objects associated with the pipe.

=item B<valmatch>

  $n = $pipe->valmatch( $pattern );

Returns the number of I<commands> with a value matching the passed
regular expression.  (This is B<not> equal to the number of total
I<values> which matched.  To determine this, iterate over each
command, calling it's B<L<valmatch|IPC::PrettyPipe::Cmd/valmatch>> method ).

=item B<valsubst>

   $pipe->valsubst( $pattern, $value, %attr );

Replace arguments to options whose arguments match the Perl regular
expression I<$pattern> with I<$value>.  The following attributes
are avaliable:


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
B<L<valsubst|IPC::PrettyPipe::Cmd/valsubst>> method directly.

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
  |	cmd2 \
  	  input stdin \
  	  output stdout \
  |	cmd3 \
  	  input stdin \
  	  output output_file

=back


=head1 COPYRIGHT & LICENSE

Copyright 2014 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

   http://www.fsf.org/copyleft/gpl.html


=head1 AUTHOR

Diab Jerius E<lt>djerius@cfa.harvard.eduE<gt>
