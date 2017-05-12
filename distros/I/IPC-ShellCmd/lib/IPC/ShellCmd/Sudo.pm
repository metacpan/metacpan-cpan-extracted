package IPC::ShellCmd::Sudo;

use strict;
use Carp qw(croak);
use base qw(IPC::ShellCmd::ShBase);

=head1 NAME

  IPC::ShellCmd::Sudo - Chain sudo-ing to a different user before running the command

=head1 SYNOPSIS

    $cmd_obj->chain_prog(
        IPC::ShellCmd::Sudo->new(
	        User => 'cpanbuild',
            SetHome => 1,
        )
    );


=head1 DESCRIPTION

=head2 IPC::ShellCmd::Sudo->B<new>([I<$opt> => I<$val>, ...])

The only external method for this is the constructor. This sets up the
various arguments that are going to be used to generate the command-line.

Other methods on this are used by L<IPC::ShellCmd>, but it should only ever be
used inside of the B<chain_prog> method on a L<IPC::ShellCmd> object.

=over 4

=item B<User>

Specifies the username to sudo to

=item B<SetHome>

If true, this will cause sudo to set up $ENV{HOME} for the new user,
otherwise it will be that of the current user.

=back

=cut

sub chain {
    my $self = shift;
    my $cmd = shift;
    my $args = shift;

    my $cmd_string = $self->generate_sh_cmd($cmd, $args);

    my @sudo_args = ('sudo');

    push (@sudo_args, "-u", $self->{args}->{User})
	    if(defined $self->{args}->{User});

    push (@sudo_args, "-H")
	    if(defined $self->{args}->{SetHome} && $self->{args}->{SetHome});

    push (@sudo_args, "sh", "-c", $cmd_string);

    return @sudo_args;
}

=head1 BUGS

I don't know of any, but that doesn't mean they're not there.

=head1 AUTHORS

See L<IPC::ShellCmd> for authors.

=head1 LICENSE

See L<IPC::ShellCmd> for the license.

=cut

1;
