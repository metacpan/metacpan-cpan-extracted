package HTML::Latemp::NavLinks::GenHtml;

use warnings;
use strict;

use 5.008;

use parent 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(
    nav_links_obj
    root
    ));


our $VERSION = '0.2.6';


sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_init(@_);
    return $self;
}

sub _init
{
    my $self = shift;
    my (%args) = @_;

    $self->root($args{root});
    $self->nav_links_obj($args{nav_links_obj});

    return $self;
}


sub _get_buttons
{
    my $self = shift;

    my @buttons =
    (
        {
            'dir' => "prev",
            'button' => "left",
            'title' => "Previous Page",
        },
        {
            'dir' => "up",
            'button' => "up",
            'title' => "Up in the Site",
        },
        {
            'dir' => "next",
            'button' => "right",
            'title' => "Next Page",
        },
    );

    foreach my $button (@buttons)
    {
        my $dir = $button->{'dir'};
        if ($button->{'exists'} = exists($self->nav_links_obj->{$dir}))
        {
            $button->{'link_obj'} = $self->nav_links_obj->{$dir};
        }
    }

    return \@buttons;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Latemp::NavLinks::GenHtml - A module to generate the HTML of the
navigation links.

=head1 VERSION

version 0.2.6

=head1 SYNOPSIS

    package MyNavLinks;

    use base 'HTML::Latemp::NavLinks::GenHtml::ArrowImages';

=head1 METHODS

=head2 $specialised_class->new('param1' => $value1, 'param2' => $value2)

Initialises the object.

=head2 $obj->get_total_html()

Calculates the HTML and returns it.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-latemp-navlinks-genhtml@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Latemp-NavLinks-GenHtml>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shlomi Fish, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the MIT X11 license.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Latemp-NavLinks-GenHtml or by
email to bug-html-latemp-navlinks-genhtml@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc HTML::Latemp::NavLinks::GenHtml

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/HTML-Latemp-NavLinks-GenHtml>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/HTML-Latemp-NavLinks-GenHtml>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Latemp-NavLinks-GenHtml>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/HTML-Latemp-NavLinks-GenHtml>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/HTML-Latemp-NavLinks-GenHtml>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/HTML-Latemp-NavLinks-GenHtml>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/HTML-Latemp-NavLinks-GenHtml>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/H/HTML-Latemp-NavLinks-GenHtml>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=HTML-Latemp-NavLinks-GenHtml>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=HTML::Latemp::NavLinks::GenHtml>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-html-latemp-navlinks-genhtml at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=HTML-Latemp-NavLinks-GenHtml>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://bitbucket.org/shlomif/latemp>

  hg clone ssh://hg@bitbucket.org/shlomif/latemp

=cut
