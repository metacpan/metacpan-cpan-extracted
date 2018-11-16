package IPC::PrettyPipe::Execute::IPC::Run;

# ABSTRACT: execution backend using IPC::Run

use 5.10.0;

use Types::Standard qw[ InstanceOf ];


use Try::Tiny;
use IPC::Run ();
use Carp ();

use Moo;
our $VERSION = '0.08';

use namespace::clean;


#pod =attr pipe
#pod
#pod The C<IPC::PrettyPipe> object which will provide the commands
#pod
#pod =cut

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

        Carp::croak $_;

    }

    finally {

        $self->_clear_storefh;

    };

};

# this needs to go here 'cause this just defines the interface
with 'IPC::PrettyPipe::Executor';

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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

IPC::PrettyPipe::Execute::IPC::Run - execution backend using IPC::Run

=head1 VERSION

version 0.08

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

=head1 ATTRIBUTES

=head2 pipe

The C<IPC::PrettyPipe> object which will provide the commands

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
