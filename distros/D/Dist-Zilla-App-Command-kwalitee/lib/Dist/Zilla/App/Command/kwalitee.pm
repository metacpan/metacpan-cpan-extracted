package Dist::Zilla::App::Command::kwalitee;
$Dist::Zilla::App::Command::kwalitee::VERSION = '0.04';
use 5.008003;
use strict;
use warnings;

use Dist::Zilla::App -command;

sub abstract { 'run CPANTS kwalitee check on your dist' }

sub opt_spec {

    [
        'core|c', 'core kwalitee tests only',
        { default => 0 }
    ],

    [
        'experimental|e', 'include experimental metrics',
        { default => 0 },
    ],

    [
        'verbose|v', 'request verbose output',
        { default => 0 }
    ],

}

sub execute {
    my ($self, $opt, $arg) = @_;

    require App::CPANTS::Lint;
    App::CPANTS::Lint->VERSION('0.03');

    my $tgz = $self->zilla->build_archive;
    my $linter = App::CPANTS::Lint->new(experimental => $opt->experimental);
    $linter->lint($tgz);
    $linter->output_report;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::kwalitee - calculate CPANTS kwalitee score for your dist

=head1 SYNOPSIS

 dzil kwalitee [ --core | -c ] [ --experimental | -e ]
               [ --verbose | -v ]

=head1 DESCRIPTION

This command is a thin wrapper around the functionality in
L<App::CPANTS::Lint>, which is itself a wrapper around functionality in
L<Module::CPANTS::Analyse>.

From within the top directory of your distribution you can run:

 % dzil kwalitee

Which saves you from having to run:

 % dzil build
 % cpants_lint.pl <tarball>

You might argue that if you're "doing Dist::Zilla right",
then you shouldn't need to run `cpants_lint.pl`,
but when I'm adopting distributions and switching them to Dist::Zilla
I find myself running the two commands above.

=head1 SEE ALSO

L<App::CPANTS::Lint> does the actual work of this command.
It is the core of the L<cpants_lint.pl> script.

L<Module::CPANTS::Analyse> is the module behind L<App::CPANTS::Lint>,
which actually does the analysis.

L<Dist::Zilla::Plugin::Test::Kwalitee> is a plugin that generates a
release test using L<Test::Kwalitee>.

L<CPANTS|http://cpants.cpanauthors.org> is the website where you
can see the Kwalitee score for all distributions on CPAN.
As a CPAN author you can see a dashboard for all your dists.
For example, my PAUSE id is NEILB, so my dashboard is at:

 http://cpants.cpanauthors.org/author/NEILB

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

