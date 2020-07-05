package HTML::Widgets::NavMenu::Url;
$HTML::Widgets::NavMenu::Url::VERSION = '1.0801';
use strict;
use warnings;

use parent 'HTML::Widgets::NavMenu::Object';

__PACKAGE__->mk_acc_ref(
    [
        qw(
            _url
            _is_dir
            _mode
            )
    ]
);


sub _init
{
    my $self = shift;

    my ( $url, $is_dir, $mode ) = @_;

    # TODO - extract a method.
    $self->_url(
          ( ref($url) eq "ARRAY" )
        ? [@$url]
        : [ split( /\//, $url ) ]
    );

    $self->_is_dir( $is_dir || 0 );

    $self->_mode( $mode || 'server' );

    return 0;
}

sub _get_url
{
    my $self = shift;

    return [ @{ $self->_url() } ];
}

sub _get_relative_url
{
    my $base = shift;

    my $url = $base->_get_url_worker(@_);

    return ( ( $url eq "" ) ? "./" : $url );
}

sub _get_url_worker
{
    my $base             = shift;
    my $to               = shift;
    my $slash_terminated = shift;
    my $no_leading_dot   = shift;

    my $prefix = ( $no_leading_dot ? "" : "./" );

    my @this_url  = @{ $base->_get_url() };
    my @other_url = @{ $to->_get_url() };

    my $ret;

    my @this_url_bak  = @this_url;
    my @other_url_bak = @other_url;

    while (scalar(@this_url)
        && scalar(@other_url)
        && ( $this_url[0] eq $other_url[0] ) )
    {
        shift(@this_url);
        shift(@other_url);
    }

    if ( ( !@this_url ) && ( !@other_url ) )
    {
        if ( ( !$base->_is_dir() ) ne ( !$to->_is_dir() ) )
        {
            die "Two identical URLs with non-matching _is_dir()'s";
        }
        if ( !$base->_is_dir() )
        {
            if ( scalar(@this_url_bak) )
            {
                return $prefix . $this_url_bak[-1];
            }
            else
            {
                die "Root URL is not a directory";
            }
        }
    }

    if ( ( $base->_mode() eq "harddisk" ) && ( $to->_is_dir() ) )
    {
        push @other_url, "index.html";
    }

    $ret = "";

    if ($slash_terminated)
    {
        if ( ( scalar(@this_url) == 0 ) && ( scalar(@other_url) == 0 ) )
        {
            $ret = $prefix;
        }
        else
        {
            if ( !$base->_is_dir() )
            {
                pop(@this_url);
            }
            $ret .= join( "/", ( map { ".." } @this_url ), @other_url );
            if ( $to->_is_dir() && ( $base->_mode() ne "harddisk" ) )
            {
                $ret .= "/";
            }
        }
    }
    else
    {
        my @components =
            ( ( map { ".." } @this_url[ 1 .. $#this_url ] ), @other_url );
        $ret .= ( $prefix . join( "/", @components ) );
        if (   ( $to->_is_dir() )
            && ( $base->_mode() ne "harddisk" )
            && scalar(@components) )
        {
            $ret .= "/";
        }
    }

    #if (($to->_is_dir()) && (scalar(@other_url) || $slash_terminated))

    return $ret;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widgets::NavMenu::Url - URL manipulation class.

=head1 VERSION

version 1.0801

=head1 SYNOPSIS

For internal use only.

=head1 METHODS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/HTML-Widgets-NavMenu>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Widgets-NavMenu>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/HTML-Widgets-NavMenu>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/H/HTML-Widgets-NavMenu>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=HTML-Widgets-NavMenu>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=HTML::Widgets::NavMenu>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-html-widgets-navmenu at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=HTML-Widgets-NavMenu>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-HTML-Widgets-NavMenu>

  git clone git://github.com/shlomif/perl-HTML-Widgets-NavMenu.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-HTML-Widgets-NavMenu/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
