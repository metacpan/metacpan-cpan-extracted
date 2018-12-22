package IPC::PrettyPipe::DSL;

# ABSTRACT: shortcuts to building an B<IPC::PrettyPipe> object

use strict;
use warnings;

our $VERSION = '0.12';

use Carp;
our @CARP_NOT;

use List::MoreUtils qw[ zip ];
use Safe::Isa;

use IPC::PrettyPipe;
use IPC::PrettyPipe::Cmd;
use IPC::PrettyPipe::Arg;
use IPC::PrettyPipe::Stream;

use parent 'Exporter';

our %EXPORT_TAGS = (
    construct  => [qw( ppipe ppcmd pparg ppstream )],
    attributes => [qw( argpfx argsep )],
);

## no critic (ProhibitSubroutinePrototypes)










sub argsep($) { IPC::PrettyPipe::Arg::Format->new( sep => @_ ) }
sub argpfx($) { IPC::PrettyPipe::Arg::Format->new( pfx => @_ ) }


our @EXPORT_OK = map { @{$_} } values %EXPORT_TAGS;
$EXPORT_TAGS{all} = \@EXPORT_OK;


























sub pparg {

    my $fmt = IPC::PrettyPipe::Arg::Format->new;

    while ( @_ && $_[0]->$_isa( 'IPC::PrettyPipe::Arg::Format' ) ) {

        shift()->copy_into( $fmt );
    }

    my @arg = @_;

    if ( @arg == 1 ) {

        unless ( 'HASH' eq ref $arg[0] ) {

            unshift @arg, 'name';

        }
    }

    elsif ( @arg == 2 ) {

        @arg = zip @{ [ 'name', 'value' ] }, @arg;

    }

    return IPC::PrettyPipe::Arg->new( @arg,
        ( @arg == 1 ? () : ( fmt => $fmt->clone ) ) );

}























sub ppstream {

    my @stream = @_;

    if ( @stream == 1 ) {

        unless ( 'HASH' eq ref $stream[0] ) {

            unshift @stream, 'spec';

        }
    }

    elsif ( @stream == 2 ) {

        @stream = zip @{ [ 'spec', 'file' ] }, @stream;

    }

    return IPC::PrettyPipe::Stream->new( @stream );
}


































































sub ppcmd {

    my $argfmt = IPC::PrettyPipe::Arg::Format->new;

    while ( @_ && $_[0]->$_isa( 'IPC::PrettyPipe::Arg::Format' ) ) {

        shift->copy_into( $argfmt );
    }

    my $cmd = IPC::PrettyPipe::Cmd->new( cmd => shift, argfmt => $argfmt );

    $cmd->ffadd( @_ );

    return $cmd;
}


























































































































sub ppipe {

    my $argfmt = IPC::PrettyPipe::Arg::Format->new;

    while ( @_ && $_[0]->$_isa( 'IPC::PrettyPipe::Arg::Format' ) ) {

        shift->copy_into( $argfmt );
    }

    my $pipe = IPC::PrettyPipe->new( argfmt => $argfmt );

    $pipe->ffadd( @_ );

    return $pipe;
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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory argpfx argsep pparg ppcmd
ppipe ppstream

=head1 NAME

IPC::PrettyPipe::DSL - shortcuts to building an B<IPC::PrettyPipe> object

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  use IPC::PrettyPipe::DSL qw[ :all ];

  $pipe =
	ppipe
        # one command per array
        [ 'mycmd',
              argsep '=',         # set default formatting attributes
              argpfx '-',
              $arg1, $arg2,       # boolean/switch arguments
              argpfx '--',        # switch argument prefix
              \@args_with_values  # ordered arguments with values
              \%args_with_values, # unordered arguments with values
              argpfx '',          # no prefixes for the rest
              @args_without_values,
              '2>', 'stderr_file' # automatic recognition of streams
        ],
        # another command
        [ 'myothercmd' => ... ],
        # manage pipeline streams
        '>', 'stdout_file';
  ;

  # or, create a command

  $cmd = ppcmd 'mycmd',
          argpfx '-',     # default for object
          $arg1, $arg2,
          argpfx '--',    # change for next arguments
          $long_arg1, $long_arg2;

  # and add it to a pipeline
  $pipe = ppipe $cmd;

  # and for completeness (but rarely used )
  $arg = pparg '-f';
  $arg = pparg [ -f => 'Makefile' ];
  $arg = pparg, argpfx '-', [ f => 'Makefile' ];

=head1 DESCRIPTION

B<IPC::PrettyPipe::DSL> provides some shortcut subroutines to make
building pipelines easier.

=head2 Pipeline construction

Pipelines are created by chaining together commands with arguments.
Arguments which are options may have I<prefixes>, and options which
have values may have their names separated from their values by a
I<separator> string.

The B<L</ppipe>>, B<L</ppcmd>>, and B<L</pparg>> subroutines are used to create
pipelines, commands, and arguments.

The B<L</argpfx>>, and B<L</argsep>> subroutines are used to change the argument
prefix and separator strings.  Calls to these are embedded in lists of
arguments and commands, and change the argument prefixes and separator
strings for the succeeding entries.  These are called I<argument
attribute modifiers> and are documented in L</Argument Attribute
Modifiers>.

To specify stream redirection for either pipelines or commands, insert
either a B<L<IPC::PrettyPipe::Stream>> object or a string stream
specification (see L<IPC::PrettyPipe::Stream::Utils/Stream
Specification>).  If the redirection requires another parameter, it
should immediately follow the object or string specification.

=head2 Argument Attribute Modifiers

The Argument Attribute modifiers (L</argpfx> and L</argsep> ) are
subroutines which change the default values of the argument prefix and
separator strings (for more information see L<IPC::PrettyPipe::Arg>).

Calls to them are typically embedded in lists of arguments and
commands, e.g.

  $p = ppipe argpfx '-',
             [ 'cmd0', 'arg0' ],
             argpfx '--',
             [ 'cmd1', argpfx('-'), 'arg1' ],
             [ 'cmd2', 'arg0' ];

and affect the default value of the attribute for the remainder of the
context in which they are specified.

For example, after the above code is run, the following holds:

  $p->argpfx eq '-'

  $p->cmds->[0]->argpfx eq '-'

  $p->cmds->[1]->argpfx eq '--'
  $p->cmds->[1]->args->[0]->argpfx eq '-'

  $p->cmds->[2]->argpfx eq '--'
  $p->cmds->[2]->args->[0]->argpfx eq '--'

=head1 SUBROUTINES

=head2 argpfx

=head2 argsep

These change the default values of the argument prefix and separator
strings.  They take a single argument, the new value of the attribute.

=head2 pparg

  $arg = pparg @attribute_modifiers, $name, $value;

B<pparg> creates an B<L<IPC::PrettyPipe::Arg>> object.   It is passed
(in order)

=over

=item 1

An optional list of argument attribute modifiers.

=item 2

The argument name.

=item 3

An optional value.

=back

=head2 ppstream

  $stream = ppstream $spec;
  $stream = ppstream $spec, $file;

B<ppstream> creates an B<L<IPC::PrettyPipe::Stream>> object.
It is passed (in order):

=over

=item 1

A stream specification

=item 2

An optional file name (if required by the stream specification).

=back

=head2 ppcmd

  $cmd = ppcmd @attribute_modifiers, $cmd, @cmd_args;

  $cmd = ppcmd 'cmd0', 'arg0', [ arg1 => $value1 ];
  $cmd = ppcmd argpfx '--',
             'cmd0', 'arg0', [ arg1 => $value1 ];

B<ppcmd> creates an B<L<IPC::PrettyPipe::Cmd>> object.  It is passed
(in order)

=over

=item 1

An optional list of argument attribute modifiers, providing the
defaults for the returned B<L<IPC::PrettyPipe::Cmd>> object.

=item 2

The command name

=item 3

A list of command arguments, argument attribute modifiers, and stream
specifications.  This list may contain

=over

=item *

Scalars, representing single arguments;

=item *

B<L<IPC::PrettyPipe::Arg>> objects;

=item *

Arrayrefs with pairs of names and values.  The arguments will be
supplied to the command in the order they appear;

=item *

Hashrefs with pairs of names and values. The arguments will be
supplied to the command in a random order;

=item *

B<L<IPC::PrettyPipe::Stream>> objects or stream specifications
(L<IPC::PrettyPipe::Stream::Utils/Stream Specification>).  If the
specification requires an additional parameter, the next value in
C<@cmd_args> will be used for that parameter.

=item *

argument attribute modifiers, changing the attributes for the
arguments which follow in C<@cmd_args>.

=back

=back

=head2 ppipe

  $pipe = ppipe @arg_attr_mods, @args;

  $pipe =  ppipe
           # set the default for this pipe
           argpfx( '--'),

           # cmd0 --arg0
           [ 'cmd0', 'arg0' ],

           # cmd1 --arg0 --arg1 $value1 --arg2 $value2
           [
             'cmd1', 'arg0', [ arg1 => $value1, arg2 => $value2 ],
           ],

           # tweak this for the following commands
           argpfx(''),

           # cmd2 arg0 arg1=$value1 arg2=$value2
           [
             'cmd2', 'arg0',
             argsep( '=' ),
             [ arg1 => $value1, arg2 => $value2 ],
           ],

           # tweak this for the following commands
           argpfx('--'),

           # cmd3 --arg0
           [ 'cmd3', 'arg0' ],

           # cmd4
           'cmd4';

B<ppipe> creates an B<L<IPC::PrettyPipe>> object.  It is passed (in
order)

=over

=item 1

An optional list of argument attribute modifiers, providing the
defaults for the returned B<L<IPC::PrettyPipe>> object.

=item 2

A list of one or more of the following

=over

=item *

A command name (i.e. a string), for a command without arguments.

=item *

an B<L<IPC::PrettyPipe::Cmd>> object

=item *

a B<L<IPC::PrettyPipe::Pipe>> object

=item *

An arrayref. The array may contain either a single
B<L<IPC::PrettyPipe::Pipe>> object or a number of elements, the first
of which being the command name with the rest being

=over

=item *

arguments;

=item *

argument attribute modifiers (which affect subsequent entries in the
array); and

=item *

stream specifications or objects.

=back

These are passed to
B<L<IPC::PrettyPipe::Cmd::new|IPC::PrettyPipe::Cmd/new>> as the C<cmd>
and C<args> parameters.

=item *

Argument Attribute modifiers, which affect attributes for all of the
commands and arguments which follow.

=item *

A stream specification (L<IPC::PrettyPipe::Stream::Utils/Stream
Specification>), or an B<L<IPC::PrettyPipe::Stream>> object. If the
specification requires an additional parameter, the next value in
C<@args> is used.

=back

=back

Note that C<ppipe> will use up all arguments passed to it. When
specifying nested pipes, make sure that the inner pipes don't grab
arguments meant for the outer ones. For example,

  ppipe [ 'cmd1' ], ppipe [ 'cmd2' ], '>', 'file';

redirects the output of the second, inner pipe, not the outer one.
Either of these will do that:

  ppipe [ 'cmd1' ], [ ppipe [ 'cmd2' ] ], '>', 'file';
  ppipe [ 'cmd1' ], ppipe( [ 'cmd2' ]), '>', 'file';

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
