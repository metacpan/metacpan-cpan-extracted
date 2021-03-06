package HTML::Latemp::NavLinks::GenHtml::Text;
$HTML::Latemp::NavLinks::GenHtml::Text::VERSION = '0.2.9';
use strict;
use warnings;

use parent 'HTML::Latemp::NavLinks::GenHtml';


__PACKAGE__->mk_accessors(
    qw(
        nav_links
        )
);

use Template;

# load Template::Stash to make method tables visible
use Template::Stash;

# Define a method to return a substring.
$Template::Stash::SCALAR_OPS->{'substr'} = sub {
    return substr( $_[0], $_[1], $_[2] );
};

sub _get_nav_buttons_html
{
    my $self = shift;

    my (%args) = (@_);

    my $with_accesskey = $args{'with_accesskey'};

    my $root = $self->root();

    my $template = Template->new(
        {
            'POST_CHOMP' => 1,
        }
    );

    my $vars = {
        'buttons'        => $self->_get_buttons(),
        'root'           => $root,
        'with_accesskey' => $with_accesskey,
    };

    my $nav_links_template = <<'EOF';
[% USE HTML %]
[% FOREACH b = buttons %]
[% SET key = b.dir.substr(0, 1) %]
<li>[
[% IF b.exists %]
<a href="[% HTML.escape(b.link_obj.direct_url()) %]" title="[% b.title %] (Alt+[% key FILTER upper %])"
[% IF with_accesskey %]
accesskey="[% key %]"
[% END %]
>[% END %] [% b.dir %] [% IF b.exists %]</a>
[% END %]
]</li>
[% END %]
EOF

    my $nav_buttons_html = "";

    $template->process( \$nav_links_template, $vars, \$nav_buttons_html );
    return $nav_buttons_html;
}

sub get_total_html
{
    my $self = shift;

    return
          "<ul class=\"nav_links\">\n"
        . $self->_get_nav_buttons_html(@_)
        . "\n</ul>";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Latemp::NavLinks::GenHtml::Text - A class to generate the text HTML of
the navigation links.

=head1 VERSION

version 0.2.9

=head1 SYNOPSIS

    my $obj = HTML::Latemp::NavLinks::GenHtml::Text->new(
        root => $path_to_root,
        nav_links_obj => $links,
        );

=head1 DESCRIPTION

This module generates text navigation links. C<root> is the relative path to
the site's root directory. C<nav_links> are the navigation links' objects
hash as returned by L<HTML::Widgets::NavMenu> or something similar.

=head1 METHODS

=head2 $obj->get_total_html()

Calculates and returns the final HTML.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/HTML-Latemp-NavLinks-GenHtml>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Latemp-NavLinks-GenHtml>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/HTML-Latemp-NavLinks-GenHtml>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

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

L<https://github.com/thewml/latemp>

  git clone https://github.com/thewml/latemp

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/html-latemp-navlinks-genhtml/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
