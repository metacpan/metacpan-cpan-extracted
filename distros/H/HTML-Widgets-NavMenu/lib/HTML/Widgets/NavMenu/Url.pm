package HTML::Widgets::NavMenu::Url;

use strict;
use warnings;

use base 'HTML::Widgets::NavMenu::Object';

__PACKAGE__->mk_acc_ref([qw(
    _url
    _is_dir
    _mode
    )]);

=head1 NAME

HTML::Widgets::NavMenu::Url - URL manipulation class.

=head1 SYNOPSIS

For internal use only.

=head1 METHODS
=cut

sub _init
{
    my $self = shift;

    my ($url, $is_dir, $mode) = @_;

    # TODO - extract a method.
    $self->_url(
        (ref($url) eq "ARRAY")
            ? [ @$url ]
            : [ split(/\//, $url) ]
    );

    $self->_is_dir($is_dir || 0);

    $self->_mode($mode || 'server');

    return 0;
}

sub _get_url
{
    my $self = shift;

    return [ @{$self->_url()} ];
}

sub _get_relative_url
{
    my $base = shift;

    my $url = $base->_get_url_worker(@_);

    return ( ($url eq "") ? "./" : $url);
}

sub _get_url_worker
{
    my $base = shift;
    my $to = shift;
    my $slash_terminated = shift;
    my $no_leading_dot = shift;

    my $prefix = ($no_leading_dot ? "" : "./");

    my @this_url = @{$base->_get_url()};
    my @other_url = @{$to->_get_url()};

    my $ret;

    my @this_url_bak = @this_url;
    my @other_url_bak = @other_url;

    while(
        scalar(@this_url) &&
        scalar(@other_url) &&
        ($this_url[0] eq $other_url[0])
    )
    {
        shift(@this_url);
        shift(@other_url);
    }

    if ((! @this_url) && (! @other_url))
    {
        if ((!$base->_is_dir() ) ne (!$to->_is_dir()))
        {
            die "Two identical URLs with non-matching _is_dir()'s";
        }
        if (! $base->_is_dir())
        {
            if (scalar(@this_url_bak))
            {
                return $prefix . $this_url_bak[-1];
            }
            else
            {
                die "Root URL is not a directory";
            }
        }
    }

    if (($base->_mode() eq "harddisk") && ($to->_is_dir()))
    {
        push @other_url, "index.html";
    }

    $ret = "";

    if ($slash_terminated)
    {
        if ((scalar(@this_url) == 0) && (scalar(@other_url) == 0))
        {
            $ret = $prefix;
        }
        else
        {
            if (! $base->_is_dir())
            {
                pop(@this_url);
            }
            $ret .= join("/", (map { ".." } @this_url), @other_url);
            if ($to->_is_dir() && ($base->_mode() ne "harddisk"))
            {
                $ret .= "/";
            }
        }
    }
    else
    {
        my @components = ((map { ".." } @this_url[1..$#this_url]), @other_url);
        $ret .= ($prefix . join("/", @components));
        if (($to->_is_dir()) && ($base->_mode() ne "harddisk") && scalar(@components))
        {
            $ret .= "/";
        }
    }

    #if (($to->_is_dir()) && (scalar(@other_url) || $slash_terminated))

    return $ret;
}

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;
