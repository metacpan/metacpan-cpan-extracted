package Docker::CLI::Wrapper::Container;
$Docker::CLI::Wrapper::Container::VERSION = '0.0.7';
use strict;
use warnings;
use 5.014;
use autodie;

use Moo;

extends('Docker::CLI::Wrapper::Base');

has 'container' => ( is => 'ro', required => 1, );
has 'sys'       => ( is => 'ro', required => 1, );

sub clean_up
{
    my ($self) = @_;

    eval { $self->docker( { cmd => [ 'stop', $self->container(), ] } ); };

    eval { $self->docker( { cmd => [ 'rm', $self->container(), ] } ); };

    return;
}

sub run_docker
{
    my ($self) = @_;

    $self->docker( { cmd => [ 'pull', $self->sys() ] } );
    $self->docker(
        {
            cmd => [
                'run',              "-t",
                "-d",               "--name",
                $self->container(), $self->sys(),
            ]
        }
    );

    return;
}

sub exe
{
    my ( $self, $args ) = @_;

    my @user;
    if ( exists $args->{user} )
    {
        push @user, ( '--user', $args->{user} );
    }

    return $self->docker(
        { cmd => [ 'exec', @user, $self->container(), @{ $args->{cmd} } ] } );
}

sub exe_bash_code
{
    my ( $self, $args ) = @_;

    return $self->exe(
        {
            %$args, cmd => [ 'bash', '-c', $args->{code}, ],
        }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Docker::CLI::Wrapper::Container - manage a container.

=head1 VERSION

version 0.0.7

=head1 SYNOPSIS

    use Docker::CLI::Wrapper::Container ();

    my $obj = Docker::CLI::Wrapper::Container->new(
        {
            container => "my-docker-container",
            sys => 'debian:sid',
        }
    );
    $obj->clean_up();
    $obj->run_docker();
    $obj->exe_bash_code(
        {
            code => qq#set -e -x; printf "%s\\n" "Hello world!"# ,
        }
    );
    $obj->clean_up();

=head1 METHODS

=head2 $obj->sys()

The desired operating system / docker image to use for the container.
A string.

=head2 $obj->container()

The container name / ID.

A string.

=head2 $obj->run_docker()

Get the container to run (after pulling its system).

[Added in version 0.0.3.]

=head2 $obj->clean_up()

Stops and deletes the container.

=head2 $obj->exe({ cmd => [@CMD], })

"docker exec"s the @CMD on the container: one can specify
an optional 'user' username.

[Added in version 0.0.4.]

=head2 $obj->exe_bash_code({code => $CODE})

Runs $CODE using C<'bash -c'> inside the container.

[Added in version 0.0.4.]

=head2 $obj->do_system({ cmd => [@CMD]});

Sugar for system(@CMD) - prints and dies on error.

=head2 $obj->docker({ cmd => [@CMD]});

Runs docker using the args in @CMD, using do_system.

=head2 $obj->calc_docker_cmd_line_prefix()

Calculates the prefix for running docker at the attributes' init time.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Docker-CLI-Wrapper>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Docker-CLI-Wrapper>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Docker-CLI-Wrapper>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Docker-CLI-Wrapper>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Docker-CLI-Wrapper>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Docker::CLI::Wrapper>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-docker-cli-wrapper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Docker-CLI-Wrapper>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Docker-CLI-Wrapper>

  git clone https://github.com/shlomif/Docker-CLI-Wrapper.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/Docker-CLI-Wrapper/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
