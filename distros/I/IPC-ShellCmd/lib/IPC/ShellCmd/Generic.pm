package IPC::ShellCmd::Generic;

use strict;
use Carp qw(croak);
use base qw(IPC::ShellCmd::ShBase);

=head1 NAME

  IPC::ShellCmd::Generic - Chain a generic wrapper-type command

=head1 SYNOPSIS

    $cmd_obj->chain_prog(
        IPC::ShellCmd::Generic->new(
	        Prog => 'time',
			Args => ["-p"],
        )
    );


=head1 DESCRIPTION

=head2 IPC::ShellCmd::Generic->B<new>(Prog => I<$prog>, [I<$opt> => I<$val>, ...])

The only external method for this is the constructor. This sets up the
various arguments that are going to be used to generate the command-line.

Other methods on this are used by L<IPC::ShellCmd>, but it should only ever be
used inside of the B<chain_prog> method on a L<IPC::ShellCmd> object.

=over 4

=item B<Prog> I<REQUIRED>

The program to run, eg. tsocks, socksify, time

=item B<Args>

A set of arguments to the program before passing the command and args

=back

=cut

sub new {
    my $package = shift;
    my %args = @_;

    croak "Must specify a Prog argument"
        unless defined $args{Prog};

    my $self = bless { args => \%args }, $package;

    return $self;
}

sub chain {
    my $self = shift;
    my $cmd = shift;
    my $args = shift;

    my $cmd_string = $self->generate_sh_cmd($cmd, $args);

    my @generic = ($self->{args}->{Prog});

    push (@generic, @{$self->{args}->{Args}})
	    if(defined $self->{args}->{Args});

    push (@generic, "sh", "-c", $cmd_string);

    return @generic;
}

=head1 BUGS

I don't know of any, but that doesn't mean they're not there.

=head1 AUTHORS

See L<IPC::ShellCmd> for authors.

=head1 LICENSE

See L<IPC::ShellCmd> for the license.

=cut

1;
