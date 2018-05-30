package Mail::LMLM::Types::Egroups;
$Mail::LMLM::Types::Egroups::VERSION = '0.6805';
use strict;
use warnings;

use Mail::LMLM::Types::Ezmlm;

use vars qw(@ISA);

@ISA=qw(Mail::LMLM::Types::Ezmlm);

sub initialize
{
    my $self = shift;

    $self->SUPER::initialize(@_);

    if (! exists($self->{'hostname'}) )
    {
        $self->{'hostname'} = "yahoogroups.com";
    }
}

sub get_homepage_hostname
{
    my $self = shift;

    return "groups.yahoo.com";
}

sub get_homepage
{
    my $self = shift;

    if ( exists($self->{'homepage'}) )
    {
        return $self->{'homepage'};
    }
    else
    {
        return "http://" . $self->get_homepage_hostname() .
            "/group/" . $self->get_group_base() . "/";
    }
}

sub get_online_archive
{
    my $self = shift;

    if ( exists($self->{'online_archive'}) )
    {
        return $self->{'online_archive'};
    }
    else
    {
        return $self->get_homepage() . "messages/";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::LMLM::Types::Egroups - mailing list type for YahooGroups.

=head1 VERSION

version 0.6805

=head1 VERSION

version 0.6805

=head1 METHODS

=head2 get_homepage_hostname

Internal method.

=head2 initialize

Over-rides L<Mail::LMLM::Types::Base>'s method.

=head2 get_homepage

Calculates the homepage of the group.

=head2 get_online_archive

Over-rides the equivalent from L<Mail::LMLM::Types::Ezmlm>.

=head1 SEE ALSO

L<Mail::LMLM::Types::Ezmlm>

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 AUTHOR

unknown

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by unknown.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/mail-lmlm/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Mail::LMLM::Types::Egroups

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Mail-LMLM>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Mail-LMLM>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Mail-LMLM>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Mail-LMLM>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Mail-LMLM>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Mail-LMLM>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/M/Mail-LMLM>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Mail-LMLM>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Mail::LMLM>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-mail-lmlm at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Mail-LMLM>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/mail-lmlm>

  git clone http://bitbucket.org/shlomif/perl-mail-lmlm/overview

=cut
