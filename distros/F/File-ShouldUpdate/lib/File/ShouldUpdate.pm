package File::ShouldUpdate;
$File::ShouldUpdate::VERSION = '0.2.0';
use strict;
use warnings;
use Time::HiRes qw/ stat /;

use parent 'Exporter';
use vars qw/ @EXPORT_OK /;
@EXPORT_OK = qw/ should_update should_update_multi /;

sub should_update_multi
{
    my ( $new_files, $syntax_sugar, $deps ) = @_;
    if ( $syntax_sugar ne ":" )
    {
        die qq#wrong syntax_sugar - not ":"!#;
    }
    my $min_dep;
    foreach my $filename2 (@$new_files)
    {
        my @stat2 = stat($filename2);
        if ( !@stat2 )
        {
            return 1;
        }
        my $new = $stat2[9];
        if ( ( !defined $min_dep ) or ( $min_dep > $new ) )
        {
            $min_dep = $new;
        }
    }
    foreach my $d (@$deps)
    {
        my @stat1 = stat($d);
        return 1 if ( $stat1[9] > $min_dep );
    }
    return 0;
}

sub should_update
{
    my ( $filename2, $syntax_sugar, @deps ) = @_;
    if ( $syntax_sugar ne ":" )
    {
        die qq#wrong syntax_sugar - not ":"!#;
    }
    return should_update_multi( [$filename2], $syntax_sugar, \@deps );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ShouldUpdate - should files be rebuilt?

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

    use File::ShouldUpdate qw/ should_update should_update_multi /;

    if (should_update("output.html", ":", "in.tt2", "data.sqlite"))
    {
        system("./my-gen-html");
    }

    if (should_update_multi(["output.html", "about.html", "contact.html"], ":", ["in.tt2", "data.sqlite"]))
    {
        system("./my-gen-html-multi");
    }

=head1 DESCRIPTION

This module provides should_update() which can be used to determine if files
should be updated based on the mtime timestamps of their dependencies. It avoids
confusing between target and dependencies by using syntactic sugar of the
familiar makefile rules ( L<https://en.wikipedia.org/wiki/Make_(software)> ).

=head1 FUNCTIONS

=head2 my $verdict = should_update($target, ":", @deps);

Should $target be updated if it doesn't exist or older than any of the deps.

=head2 my $verdict = should_update_multi([@targets], ":", [@deps]);

Should @targets be updated if some of them do not exist B<or> any of them are older than any of the deps.

Note that you must pass array references.

[Added in version 0.2.0.]

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/File-ShouldUpdate>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-ShouldUpdate>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/File-ShouldUpdate>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/F/File-ShouldUpdate>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=File-ShouldUpdate>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=File::ShouldUpdate>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-file-shouldupdate at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=File-ShouldUpdate>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-File-ShouldUpdate>

  git clone git://github.com/shlomif/perl-File-ShouldUpdate.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-File-ShouldUpdate/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
