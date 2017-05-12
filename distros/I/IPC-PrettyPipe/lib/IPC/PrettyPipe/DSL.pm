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

package IPC::PrettyPipe::DSL;

use strict;
use warnings;

use Carp;
our @CARP_NOT;

use List::MoreUtils qw[ zip ];
use Safe::Isa;

use IPC::PrettyPipe;
use IPC::PrettyPipe::Cmd;
use IPC::PrettyPipe::Arg;
use IPC::PrettyPipe::Stream;

our $VERSION = '1.21';


use parent 'Exporter';

our %EXPORT_TAGS = (
    construct  => [ qw( ppipe ppcmd pparg ppstream ) ],
    attributes => [ qw( argpfx argsep ) ],
);

## no critic (ProhibitSubroutinePrototypes)
sub argsep($)    { IPC::PrettyPipe::Arg::Format->new( sep => @_ )    };
sub argpfx($)    { IPC::PrettyPipe::Arg::Format->new( pfx => @_ )    };


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

    return IPC::PrettyPipe::Arg->new( @arg, ( @arg == 1 ? () : ( fmt => $fmt->clone ) ) );

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


__END__

=head1 NAME

B<IPC::PrettyPipe::DSL> - shortcuts to building an B<IPC::PrettyPipe> object

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

B<IPC::PrettyPipe::DSL> provides some shortcut functions to make
building pipelines easier.


=head1 FUNCTIONS


Pipelines are created by chainging together commands with arguments.
Arguments which are options may have I<prefixes>, and options which
have values may have their names separated from their values by a
I<separator> string.

The B<L</ppipe>>, B<L</ppcmd>>, and B<L</pparg>> functions are used to create
pipelines, commands, and arguments.

The B<L</argpfx>>, and B<L</argsep>> functions are used to change the argument
prefix and separator strings.  Calls to these are embeded in lists of
arguments and commands, and change the argument prefixes and separator
strings for the succeeding entries.  These are called I<argument
attribute modifiers> and are documented in L</Argument Attribute
Modifiers>.

To specify stream redirection for either pipelines or commands, insert
either a B<L<IPC::PrettyPipe::Stream>> object or a string stream
specification (see L<IPC::PrettyPipe::Stream::Utils/Stream
Specification>).  If the redirection requires another parameter, it
should immediately follow the object or string specification.

=head2 Pipeline component construction

=over

=item B<ppipe>

  $pipe = ppipe @arg_attr_mods,
                @args;

  $pipe =
    ppipe

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




B<ppipe> creates an B<L<IPC::PrettyPipe>> object.  It is passed (in order)

=over

=item 1

An optional list of argument attribute modifiers, providing the defaults for
the returned B<L<IPC::PrettyPipe>> object.

=item 2

A list of one or more of the following

=over

=item *

A command name (i.e. a string), for a command without arguments.

=item *

an B<L<IPC::PrettyPipe::Cmd>> object

=item *

An arrayref. The first element is the command name; the rest are

=over

=item *

arguments;

=item *

argument attribute modifiers (which affect subsequent entries in the array); and

=item *

stream specifications or objects.

=back

These are passed to
B<L<IPC::PrettyPipe::Cmd::new|IPC::PrettyPipe::Cmd/new>> as the C<cmd>
and C<args> parameters.

=item *

Argument Attribute modifiers, which affect attributes for all of the commands
and arguments which follow.

=item *

A stream specification (L<IPC::PrettyPipe::Stream::Utils/Stream
Specification>), or an B<L<IPC::PrettyPipe::Stream>> object. If the
specification requires an additional parameter, the next value in
C<@args> is used.

=back

=back

=item B<ppcmd>

  $cmd = ppcmd @attribute_modifiers,
               $cmd,
               @cmd_args;

  $cmd = ppcmd 'cmd0', 'arg0', [ arg1 => $value1 ];
  $cmd = ppcmd argpfx '--',
             'cmd0', 'arg0', [ arg1 => $value1 ];

B<ppcmd> creates an B<L<IPC::PrettyPipe::Cmd>> object.  It is passed (in order)

=over

=item 1

An optional list of argument attribute modifiers, providing the defaults for
the returned B<L<IPC::PrettyPipe::Cmd>> object.

=item 2

The command name

=item 3

A list of command arguments, argument attribute modifiers, and stream specifications.
This list may contain

=over

=item *

Scalars, representing single arguments;

=item *

B<L<IPC::PrettyPipe::Arg>> objects;

=item *

Arrayrefs with pairs of names and values.  The arguments will be supplied to the
command in the order they appear;

=item *

Hashrefs with pairs of names and values. The arguments will be supplied to the
command in a random order;

=item *

B<L<IPC::PrettyPipe::Stream>> objects or stream specifications
(L<IPC::PrettyPipe::Stream::Utils/Stream Specification>).  If the
specification requires an additional parameter, the next value in
C<@cmd_args> will be used for that parameter.

=item *

argument attribute modifiers, changing the attributes for the arguments which follow in C<@cmd_args>.

=back

=back

=item B<pparg>

  $arg = pparg @attribute_modifiers,
               $name,
               $value;

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


=item B<ppstream>

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

=back

=head2 Argument Attribute Modifiers

Argument Attribute modifiers are functions which change the default
values of the argument prefix and separator strings (for more
information see L<IPC::PrettyPipe::Arg>).  There are two functions,

=over

=item B<argpfx>

=item B<argsep>

=back

which take a single argument (the new value of the attribute).

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

=head1 COPYRIGHT & LICENSE

Copyright 2014 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

   http://www.fsf.org/copyleft/gpl.html


=head1 AUTHOR

Diab Jerius E<lt>djerius@cfa.harvard.eduE<gt>
