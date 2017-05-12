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

package IPC::PrettyPipe::Execute::IPC::Run;

use 5.10.0;

use Moo;
use Types::Standard qw[ InstanceOf ];

use Try::Tiny;
use IPC::Run ();

use Carp;

has pipe => (
    is       => 'ro',
    isa      => InstanceOf ['IPC::PrettyPipe'],
    required => 1,
);

# This attribute encapsulates an IPC::Run harness, tieing its creation
# to an IO::ReStoreFH object to ensure that filehandles are stored &
# restored properly.  The IPC::Run harness is created on-demand just
# before it is used.  A separate object could be used, but then
# IPC::PrettyPipe:Execute::IPC::Run turns into a *really* thin shell
# around it.  no need for an extra layer.


has _harness => (
    is      => 'ro',
    lazy    => 1,
    handles => [qw[ run start pump finish ]],
    clearer => 1,

    default => sub {

        my $self = shift;

        # While the harness is instantiated, we store the current fh's
        $self->_storefh;

        my @harness;

        for my $cmd ( @{ $self->pipe->cmds->elements } ) {

            push @harness, '|' if @harness;

            push @harness,
              [
                $cmd->cmd,
                map { $_->render( flatten => 1 ) } @{ $cmd->args->elements },
              ];

            push @harness,
              map { $_->spec, $_->has_file ? $_->file : () }
              @{ $cmd->streams->elements };
        }

        return IPC::Run::harness( @harness );
    },

);

# store the IO::Restore object; created on demand by _harness.default
# don't create it otherwise!
has _storefh => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $_[0]->pipe->_storefh },
    clearer => 1
);

# the IO::ReStoreFH object lives only as long as the
# IPC::Run harness object, and that lives only
# as long as necessary.
after 'run', 'finish' => sub {

    my $self = shift;

    try {

	# get rid of harness first to avoid possible closing of file
	# handles while the child is running.  of course the child
	# shouldn't be running at this point, but what the heck
        $self->_clear_harness;

    }

    catch {

        croak $_;

    }

    finally {

        $self->_clear_storefh;

    };

};

# this needs to go here 'cause this just defines the interface
with 'IPC::PrettyPipe::Executor';

1;


=head1 NAME

B<IPC::PrettyPipe::Execute::IPC::Run> - execution backend using B<IPC::Run>

=head1 SYNOPSIS

  use IPC::PrettyPipe::DSL;

  my $pipe = ppipe 'ls';
  $pipe->executor( 'IPC::Run' );

  # or, more explicitly
  my $executor = IPC::PrettyPipe::Execute::IPC::Run->new;
  $pipe->executor( $executor );


=head1 DESCRIPTION

B<IPC::PrettyPipe::Execute::IPC::Run> implements the
B<L<IPC::PrettyPipe::Executor>> role, providing an execution backend for
B<L<IPC::PrettyPipe>> using the B<L<IPC::Run>> module.

It also provides proxied access to the B<L<IPC::Run>> B<L<start|IPC::Run/start>>, B<L<pump|IPC::Run/pump>>, and
B<L<finish|IPC::Run/finish>> methods.  (It does not provide direct access to the
B<L<IPC::Run>> harness object).

When using the proxied methods, the caller must ensure that the
B<L</finish>> method is invoked to ensure that the parent processes'
file descriptors are properly restored.

=head1 Methods

=over

=item B<run>

Run the pipeline.

=item B<start>

Invoke the B<L<IPC::Run>> B<L<start|IPC::Run/start>> method.

=item B<pump>

Invoke the B<L<IPC::Run>> B<L<pump|IPC::Run/pump>> method.

=item B<finish>

Invoke the B<L<IPC::Run>> B<L<finish|IPC::Run/finish>> method.

=back


=head1 COPYRIGHT & LICENSE

Copyright 2014 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

   http://www.fsf.org/copyleft/gpl.html


=head1 AUTHOR

Diab Jerius E<lt>djerius@cfa.harvard.eduE<gt>

=cut
