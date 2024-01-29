package HealthCheck::Diagnostic::SSH;

use strict;
use warnings;

use parent 'HealthCheck::Diagnostic';

use Net::SSH::Perl ();

# ABSTRACT: Verify SSH connectivity to specified host.
use version;
our $VERSION = 'v0.1.0'; # VERSION

sub new {
    my ($class, @params) = @_;

    my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
        ? %{ $params[0] } : @params;

    return $class->SUPER::new(
        id     => 'ssh',
        label  => 'SSH',
        %params,
    );
}

sub check {
    my ($self, %params) = @_;

    # Make it so that the diagnostic can be used as an instance or a
    # class, and the `check` params get preference.
    if ( ref $self ) {
        $params{ $_ } = $self->{ $_ }
            foreach grep { ! defined $params{ $_ } } keys %$self;
    }

    # The host is the only required parameter.
    return {
        id     => $params{'id'},
        label  => $params{'label'},
        status => 'UNKNOWN',
        info   => "Missing required input: No host specified",
    } unless $params{host};

    return $self->SUPER::check(%params);
}

sub run {
    my ($self, %params) = @_;

    # Get our description of the connection.
    my $user          = $params{user};
    my $name          = $params{name};
    my $target        = ( $user ? $user.'@' : '' ).$params{host};
    my $description   = $name ? "$name ($target) SSH" : "$target SSH";

    # connect to SSH
    my $ssh;
    local $@;
    eval {
        local $SIG{__DIE__};
        $ssh = $self->ssh_connect( %params );
    };
    return {
        status => 'CRITICAL',
        info   => "Error for $description: $@",
    } if $@;

    # if there were no errors, it should've connected
    return {
        status => 'OK',
        info   => "Successful connection for $description",
    } unless $params{command};

    # run command if exists
    my %res = $self->run_command( $ssh, %params );
    return {
        status => 'CRITICAL',
        info   => "$description: $res{error}",
    } if $res{error};

    return {
        status => $res{exit_code} == 0 ? 'OK' : 'CRITICAL',
        info   => "$description <$params{command}> exit is $res{exit_code}",
        $params{return_output} ? ( data => \%res ) : (),
    };
}

sub ssh_connect {
    my ( $self, %params ) = @_;

    my $host       = $params{host};
    my $user       = $params{user};
    my $password   = $params{password};
    my %ssh_params = (
        protocol => 2,
        %{ $params{ssh_args} // {} },
    );

    my $ssh = Net::SSH::Perl->new( $host, %ssh_params );
    $ssh->login( $user, $password );

    return $ssh;
}

sub run_command {
    my ( $self, $ssh, %params ) = @_;
    my %res;

    local $@;
    eval {
        local $SIG{__DIE__};
        my ($stdout, $stderr, $exit_code) = $ssh->cmd(
            $params{command},
            $params{stdin} // '',
        );
        $res{ stdout }    = $stdout;
        $res{ stderr }    = $stderr;
        $res{ exit_code } = $exit_code;
    };
    $res{ error } = $@ if $@;

    return %res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HealthCheck::Diagnostic::SSH - Verify SSH connectivity to specified host.

=head1 VERSION

version v0.1.0

=head1 SYNOPSIS

Checks and verifies connection to SSH.
Can optionally run commands through the connection.

    my $health_check = HealthCheck->new( checks => [
        HealthCheck::Diagnostic::SSH->new(
            host => 'somehost.com',
            user => 'some_user,
        )
    ]);

    my $health_check = HealthCheck->new( checks => [
        HealthCheck::Diagnostic::SSH->new(
            host     => 'somehost.com',
            user     => 'some_user,
            ssh_args => {
                identity_files => [ '~/user/somepath/privatefile' ]
            },
            command       => 'echo "Hello World!"',
            return_output => 1,
        )
    ]);

=head1 DESCRIPTION

Determines if a SSH connection to a host is achievable. Sets the
C<status> to "OK" if the connection is successful and we can run the optional
C<command> parameter. The C<status> is set to "UNKNOWN" if required parameters
are missing. Otherwise, the C<status> is set to "CRITICAL".

=head2 host

The server name to connect to for the test.
This is required.

=head2 name

A descriptive name for the connection test.
This gets populated in the resulting C<info> tag.

=head2 user

Optional argument that can get passed into C<login> method of L<Net::SSH::Perl>.
Represents the authentication user credential for the host.

For more information, see L<Net::SSH::Perl/login>.

=head2 password

Optional argument that can get passed into C<login> method of L<Net::SSH::Perl>.
C<identity_files> in L<ssh_args> can be used to authenticate by default.
Represents the authentication password credential for the host.

=head2 ssh_args

Optional argument that can get passed into the L<Net::SSH::Perl> constructor.
Additional SSH connection parameters.
Only default parameter is the protocol set as 2.
C<identity_files> can be set in here to authenticate using the files by default.

For more information on the possible arguments, refer to L<Net::SSH::Perl>.

=head2 command

Optional argument that can get passed into C<cmd> method of L<Net::SSH::Perl>.
If provided, runs command and prints output into C<data> depending on the
value of L</display> input. An error output from running the command would
result in a non-zero value of C<data->exit_code> which is always provided.
If C<display> is enabled, output of the command is shown in C<data->stdout>
and an error message, if any, is stored in C<data->stderr>.

=head2 stdin

Optional argument that can get passed into C<cmd> method of L<Net::SSH::Perl>.
If provided, it's supplied to the L<command> on standard input.

=head2 return_output

Optional argument that determines whether output of L<Net::SSH::Perl>->C<cmd>
should be displayed. If provided a truthy value, (preferrably 1 for clarity)
the C<data> field of the output will be populated with C<stdout> and C<stderr>.
If ommitted, only the C<exit_code> will show by default as noted in L</command>.

=head1 INTERNALS

=head2 run_command

Used internally to run an ssh C<cmd> and assemble the result into
a C<data> structure to be used as as part of the Result.

=head2 ssh_connect

Used internally to instantiate a L<Net::SSH::Perl> instance

=head1 DEPENDENCIES

=over 4

=item *

L<HealthCheck::Diagnostic>

=item *

L<Net::SSH::Perl>

=back

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 - 2023 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
