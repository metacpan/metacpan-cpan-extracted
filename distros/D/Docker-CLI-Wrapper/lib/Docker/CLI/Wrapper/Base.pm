package Docker::CLI::Wrapper::Base;
$Docker::CLI::Wrapper::Base::VERSION = '0.0.7';
use strict;
use warnings;
use 5.014;
use autodie;

use Moo;
use Path::Tiny qw/ path /;

has 'docker_cmd_line_prefix' =>
    ( is => 'ro', lazy => 1, builder => 'calc_docker_cmd_line_prefix' );

sub do_system
{
    my ( $self, $args ) = @_;

    my $cmd = $args->{cmd};
    print "Running [@$cmd]\n";
    if ( system(@$cmd) )
    {
        die "Running [@$cmd] failed!";
    }

    return;
}

sub calc_docker_cmd_line_prefix
{
    my $self = shift;

    {
        my $fh = path("/etc/fedora-release");

        if ( -e $fh )
        {
            if ( my ($fedora_ver) =
                $fh->slurp_utf8() =~ /^Fedora release ([0-9]+)/ )
            {
                if ( $fedora_ver >= 31 )
                {
                    # return ['podman'];
                    return [ 'systemd-run', '--scope', '--user', 'podman' ];
                }
            }
        }
    }
    return ['docker'];
}

sub calc_docker_cmd
{
    my ( $self, $args ) = @_;

    my $cmd = $args->{cmd};
    return { docker_cmd => [ @{ $self->docker_cmd_line_prefix }, @$cmd, ], };
}

sub docker
{
    my ( $self, $args ) = @_;

    my $cmd = $args->{cmd};
    return $self->do_system(
        { %$args, cmd => $self->calc_docker_cmd( $args, )->{'docker_cmd'}, } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Docker::CLI::Wrapper::Base - base class.

=head1 VERSION

version 0.0.7

=head1 SYNOPSIS

    use Docker::CLI::Wrapper::Base;

    my $obj = Docker::CLI::Wrapper::Base->new();

    $obj->do_system(
        {
            cmd => [
                qw/ls -l/,
            ],
        }
    );

=head1 METHODS

=head2 $obj->do_system({ cmd => [@CMD]});

Sugar for system(@CMD) - prints and dies on error.

=head2 $obj->docker({ cmd => [@CMD]});

Runs docker using the args in @CMD, using do_system.

=head2 $obj->calc_docker_cmd({ cmd => [@CMD]});

Calculates the docker command and returns it (without executing it).

[Added in version 0.0.7.]

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
