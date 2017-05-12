package IPC::ShellCmd::SSH;

use strict;
use Carp qw(croak);
use base qw(IPC::ShellCmd::ShBase);

=head1 NAME

  IPC::ShellCmd::SSH - Chain ssh-ing to a host before running the command

=head1 SYNOPSIS

    $cmd_obj->chain_prog(
        IPC::ShellCmd::SSH->new(
	        User => 'cpanbuild',
            Host => '10.0.0.1'
        )
    );

=head1 DESCRIPTION

=head2 IPC::ShellCmd::SSH->B<new>(Host => I<$host>, [I<$opt> => I<$val>, ...])

The only external method for this is the constructor. This sets up the
various arguments that are going to be used to generate the command-line.

Other methods on this are used by L<IPC::ShellCmd>, but it should only ever be
used inside of the B<chain_prog> method on a L<IPC::ShellCmd> object.

The only required argument is the host.

=over 4

=item B<Host> I<REQUIRED>

Specifies the host to ssh to. Since this is done by invoking the command-line
ssh client, this can be a short hostname that is part of the local ssh config.

=item B<User>

Specifies the username on the remote host

=item B<Port>

Specifies the port to connect to on the remote host

=item B<ForwardAgent>

If specified, then if true will enable agent forwarding (say for dealing with
a bastion host), and if false will explicitly disable it. If not specified it
will be the ssh default.

=item B<ForwardX11>

If specified, then if true will enable X11 forwarding, and if false will disable
it. If not specified, this will be the ssh default.

=item B<AllocateTty>

If specified, then if true will force allocation of a tty, and if false will
disable it. If not specified, this will be the ssh default.

=item B<IdentityFile>

Specifies the ssh private key to use.

=back

=cut

sub new {
    my $package = shift;
    my %args = @_;

    croak "Must specify a Host argument"
	unless defined $args{Host};

    my $self = bless { args => \%args }, $package;

    return $self;
}

sub chain {
    my $self = shift;
    my $cmd = shift;
    my $args = shift;

    my $cmd_string = $self->generate_sh_cmd($cmd, $args);

    my @ssh_args = ('ssh');

    push (@ssh_args, "-l", $self->{args}->{User})
	    if(defined $self->{args}->{User});

    push (@ssh_args, "-p", $self->{args}->{Port})
	    if(defined $self->{args}->{Port});

    push (@ssh_args, "-i", $self->{args}->{IdentityFile})
	    if(defined $self->{args}->{IdentityFile});

    push (@ssh_args, "-A")
	    if(defined $self->{args}->{ForwardAgent} && $self->{args}->{ForwardAgent});

    push (@ssh_args, "-a")
	    if(defined $self->{args}->{ForwardAgent} && !$self->{args}->{ForwardAgent});

    push (@ssh_args, "-X")
	    if(defined $self->{args}->{ForwardX11} && $self->{args}->{ForwardX11});

    push (@ssh_args, "-x")
	    if(defined $self->{args}->{ForwardX11} && !$self->{args}->{ForwardX11});

    push (@ssh_args, "-t")
	    if(defined $self->{args}->{AllocateTty} && $self->{args}->{AllocateTty});

    push (@ssh_args, "-T")
	    if(defined $self->{args}->{AllocateTty} && !$self->{args}->{AllocateTty});

    push (@ssh_args, $self->{args}->{Host}, $cmd_string);

    return @ssh_args;
}

=head1 BUGS

I don't know of any, but that doesn't mean they're not there.

=head1 AUTHORS

See L<IPC::ShellCmd> for authors.

=head1 LICENSE

See L<IPC::ShellCmd> for the license.

=cut

1;
