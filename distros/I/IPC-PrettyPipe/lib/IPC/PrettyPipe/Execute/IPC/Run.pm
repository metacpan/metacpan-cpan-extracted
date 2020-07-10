package IPC::PrettyPipe::Execute::IPC::Run;

# ABSTRACT: execution backend using IPC::Run

use 5.10.0;

use Types::Standard qw[ InstanceOf ];


use Try::Tiny;
use IPC::Run ();
use Carp     ();

use Moo;
our $VERSION = '0.13';

use namespace::clean;

# This attribute encapsulates an IPC::Run harness, tieing its creation
# to an IO::ReStoreFH object to ensure that filehandles are stored &
# restored properly.  The IPC::Run harness is created on-demand just
# before it is used.

has _harness => (
    is      => 'rwp',
    clearer => 1,
    predicate => 1,
    init_arg => undef,
);

# store the IO::Restore object; created on demand by _harness.default
# don't create it otherwise!
has _storefh => (
    is      => 'rwp',
    predicate => 1,
    init_arg => undef,
    clearer => 1
);

sub _create_harness {
    my ( $self, $pipe ) = @_;

    # While the harness is instantiated, we store the current fh's
    $self->_set__storefh( $pipe->_storefh);

    my @harness;

    my @cmds = @{ $pipe->cmds->elements };

    while ( @cmds ) {

        my $cmd = shift @cmds;

        if ( $cmd->isa( 'IPC::PrettyPipe::Cmd' ) ) {

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
        elsif ( $cmd->isa( 'IPC::PrettyPipe' ) ) {

            croak( "cannot chain sub-pipes which have streams" )
              unless $cmd->streams->empty;
            unshift @cmds, @{ $cmd->cmds->elements };
        }
    }

    $self->_set__harness( IPC::Run::harness(@harness) );
}











sub run {
    my ( $self, $pipe ) = @_;
    $self->_create_harness( $pipe);
    $self->_harness->run;
}










sub start {
    my ( $self, $pipe ) = @_;
    $self->_create_harness( $pipe );
    $self->_harness->start;
}








sub pump {
    my $self = shift;
    Carp::croak( "must call run method to create harness\n" )
        unless $self->_has_harness;
    $self->_harness->pump;
}







sub finish {
    my $self = shift;
    Carp::croak( "must call run method to create harness\n" )
        unless $self->_has_harness;
    $self->_harness->finish;
}

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

version 0.13

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

It does not support inner pipes with non-default streams.  For
example, this is supported:

  ppipe [ 'cmd1' ],
        [ ppipe ['cmd2.1'],
                ['cmd2.2'],
        ],
        '>', $file;

while this is not:

  ppipe [ 'cmd1' ],
        [ ppipe ['cmd2.1'],
                ['cmd2.2'],
               '>', $file
        ];

It also provides proxied access to the B<L<IPC::Run>>
B<L<start|IPC::Run/start>>, B<L<pump|IPC::Run/pump>>, and
B<L<finish|IPC::Run/finish>> methods.  (It does not provide direct
access to the B<L<IPC::Run>> harness object).

When using the proxied methods, the caller must ensure that the
B<L</finish>> method is invoked to ensure that the parent processes'
file descriptors are properly restored.

=head1 METHODS

=head2 run

  $self->run( $pipe );

Run the pipeline.

=head2 start

  $self->start( $pipe );

Create a L<IPC::Run> harness and invoke its L<start|IPC::Run/start>
method.

=head2 pump

Invoke the B<L<IPC::Run>> B<L<pump|IPC::Run/pump>> method.

=head2 finish

Invoke the B<L<IPC::Run>> B<L<finish|IPC::Run/finish>> method.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-ipc-prettypipe@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=IPC-PrettyPipe

=head2 Source

Source is available at

  https://gitlab.com/djerius/ipc-prettypipe

and may be cloned from

  https://gitlab.com/djerius/ipc-prettypipe.git

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
