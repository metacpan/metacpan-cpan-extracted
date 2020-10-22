package Dist::Zilla::Plugin::TestRun;

use 5.014;

use Moose;

with( 'Dist::Zilla::Role::TestRunner', );

sub test
{
    my ( $self, $target ) = @_;

    my $cmd     = 'runtest';
    my @testing = $self->zilla->logger->get_debug ? '--verbose' : ();

    system $^X, 'Build', $cmd, @testing
        and die "error running $^X Build $cmd\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::TestRun - run ./Build runtest on the build distribution

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

1. In the dist.ini:

    [ModuleBuild]
    mb_class = Test::Run::Builder
    [TestRun]

2. Put C<inc/Test/Run/Builder.pm> in the repository.

3. From the command line

    $ dzil test
    $ dzil test --release

Will run using "./Build runtest" as well.

=head1 SUBROUTINES/METHODS

=head2 test()

Needed by L<Dist::Zilla> .

=head1 THANKS

Thanks to rwstauner and cjm on #distzilla on irc.perl.org for providing
some help and insights.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Dist-Zilla-Plugin-TestRun>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-TestRun>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-TestRun>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-TestRun>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-TestRun>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::TestRun>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-plugin-testrun at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Dist-Zilla-Plugin-TestRun>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/shlomif/perl-Dist-Zilla-Plugin-TestRun>

  git clone git://github.com/shlomif/perl-Dist-Zilla-Plugin-TestRun.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-TestRun> or by
email to
L<bug-dist-zilla-plugin-testrun@rt.cpan.org|mailto:bug-dist-zilla-plugin-testrun@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
