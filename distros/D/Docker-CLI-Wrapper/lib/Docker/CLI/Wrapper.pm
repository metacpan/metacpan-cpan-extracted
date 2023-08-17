package Docker::CLI::Wrapper;
$Docker::CLI::Wrapper::VERSION = '0.0.7';
use strict;
use warnings;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Docker::CLI::Wrapper - a wrapper for the CLI of docker and compatible tools.

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

=head1 DESCRIPTION

These are Perl modules and OOP classes that wrap the docker's (or podman's) Command Line
Interface (CLI).

They were extracted from several programs I wrote that used Docker for
L<CI|https://github.com/shlomif/Freenode-programming-channel-FAQ/blob/master/FAQ_with_ToC__generated.md#what-do-continuous-integration-ci-services-such-as-travis-ci-jenkins-or-appveyor-provide>

It is possible that Dockerfiles provide similar functionality, but I was too
lazy to properly learn how to write them.

=head1 SEE ALSO

L<Docker::CLI::Wrapper::Container> .

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
