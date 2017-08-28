package Dist::Zilla::App::Command::externaldeps; ## no critic (Capitalization)

# ABSTRACT: print external libraries and binaries prerequisites

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)

our $VERSION = '1.008';     # VERSION
use utf8;

#pod =for test_synopsis
#pod BEGIN { die "SKIP: this is command line, not perl\n" }
#pod
#pod =head1 SYNOPSIS
#pod
#pod On the command line:
#pod
#pod     % dzil externaldeps
#pod     man
#pod     sqlite3
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a command plugin for L<Dist::Zilla|Dist::Zilla>. It provides the
#pod C<externaldeps> command, which prints external prerequisites declared
#pod with
#pod L<Dist::Zilla::Plugin::RequiresExternal|Dist::Zilla::Plugin::RequiresExternal>.
#pod
#pod =cut

use Dist::Zilla::App -command;    ## no critic (ProhibitCallsToUndeclaredSubs)
use English '-no_match_vars';

sub opt_spec { }

sub execute {
    my $self   = shift;
    my $plugin = $self->zilla->plugin_named('RequiresExternal');
    local $LIST_SEPARATOR = "\n";
    say "@{ $plugin->_requires }";
    return;
}

## no critic (NamingConventions::ProhibitAmbiguousNames)
sub abstract { return 'print external libraries and binaries prerequisites' }

1;

__END__

=pod

=encoding utf8

=for :stopwords Mark Gardner Joenio Costa GSI Commerce and cpan testmatrix url annocpan
anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders
metacpan

=head1 NAME

Dist::Zilla::App::Command::externaldeps - print external libraries and binaries prerequisites

=head1 VERSION

version 1.008

=for test_synopsis BEGIN { die "SKIP: this is command line, not perl\n" }

=head1 SYNOPSIS

On the command line:

    % dzil externaldeps
    man
    sqlite3

=head1 DESCRIPTION

This is a command plugin for L<Dist::Zilla|Dist::Zilla>. It provides the
C<externaldeps> command, which prints external prerequisites declared
with
L<Dist::Zilla::Plugin::RequiresExternal|Dist::Zilla::Plugin::RequiresExternal>.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Plugin::RequiresExternal

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-RequiresExternal>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Dist-Zilla-Plugin-RequiresExternal>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-RequiresExternal>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-RequiresExternal>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-RequiresExternal>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-RequiresExternal>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::RequiresExternal>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at L<https://github.com/mjgardner/Dist-Zilla-Plugin-RequiresExternal/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/Dist-Zilla-Plugin-RequiresExternal>

  git clone git://github.com/mjgardner/Dist-Zilla-Plugin-RequiresExternal.git

=head1 AUTHORS

=over 4

=item *

Mark Gardner <mjgardner@cpan.org>

=item *

Joenio Costa <joenio@joenio.me>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by GSI Commerce and Joenio Costa.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
