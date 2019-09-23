use strict;
use warnings;
package Dist::Zilla::Plugin::CheckIssues; # git description: v0.010-8-gf6e9be7
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: Retrieve count of outstanding RT and github issues for your distribution
# KEYWORDS: plugin bugs issues rt github

our $VERSION = '0.011';

use Moose;
with 'Dist::Zilla::Role::BeforeRelease';
use List::Util 1.33 'any';
use Term::ANSIColor 3.00 'colored';
use Encode ();
use namespace::autoclean;

has [qw(rt github colour)] => (
    is => 'ro', isa => 'Bool',
    default => 1,
);

has repo_url => (
    is => 'rw', isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;

        my $url;
        if ($self->zilla->built_in)
        {
            # we've already done a build, so distmeta is available
            my $distmeta = $self->zilla->distmeta;
            $url = (($distmeta->{resources} || {})->{repository} || {})->{url} || '';
        }
        else
        {
            # no build (we're probably running the command): we cannot simply
            # call ->distmeta because various plugins will cause side-effects
            # with invalid assumptions (no files have been gathered, etc) --
            # so we just query a short list of plugins that we know can
            # provide repository resource metadata
            my @plugins = grep {
                my $plugin = $_;
                any { $plugin->isa('Dist::Zilla::Plugin::' . $_) }
                    qw(MetaResources AutoMetaResources GithubMeta GitHub::Meta Repository)
            } @{ $self->zilla->plugins_with(-MetaProvider) };

            $self->log('Cannot find any resource metadata-providing plugins to run!')
                if not @plugins;

            foreach my $plugin (@plugins)
            {
                $self->log_debug([ 'calling metadata for %s', $plugin->plugin_name ]);
                my $plugin_meta = $plugin->metadata;
                $url = (($plugin_meta->{resources} || {})->{repository} || {})->{url} || '';
                last if $url;
            }
        }
        $url;
    },
);

# owner_name, repo_name
has _github_owner_repo => (
    isa => 'ArrayRef[Str]',
    init_arg => undef,
    lazy => 1,
    default => sub {
        my $self = shift;

        if (my $url = $self->repo_url)
        {
            $self->log_debug([ 'getting issue data for %s...', $url ]);
            my ($owner_name, $repo_name) = $url =~ m{github\.com[:/]([^/]+)/([^/]+?)(?:/|\.git|$)};
            return [ $owner_name, $repo_name ] if $owner_name and $repo_name;
        }

        $self->log('failed to find a github repo in metadata');
        [];
    },
    traits => ['Array'],
    handles => { _github_owner_repo => 'elements' },
);

sub mvp_aliases { +{ color => 'colour' } }

# metaconfig is unimportant for this distribution since it does not alter the
# built distribution in any way
around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    my $data = {
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };
    $config->{+__PACKAGE__} = $data if keys %$data;

    return $config;
};

sub get_issues
{
    my $self = shift;

    my $dist_name = $self->zilla->name;

    my @issues;

    if ($self->rt)
    {
        my %rt_data = $self->_rt_data_for_dist($dist_name);
        if (defined $rt_data{open} and defined $rt_data{stalled}) {
            my $colour = $rt_data{open} ? 'bright_red'
                : $rt_data{stalled} ? 'yellow'
                : 'green';

            my @text = (
                'Issues on RT (https://rt.cpan.org/Public/Dist/Display.html?Name=' . $dist_name . '):',
                '  open: ' .  ($rt_data{open} || 0) . '   stalled: ' . ($rt_data{stalled} || 0),
            );

            @text = map colored($_, $colour), @text if $self->colour;
            push @issues, @text;
        }
    }

    if ($self->github
        and my ($owner_name, $repo_name) = $self->_github_owner_repo)
    {
        my $issue_count = $self->_github_issue_count($owner_name, $repo_name);
        if (defined $issue_count)
        {
            my $colour = $issue_count ? 'bright_red' : 'green';

            my $url = 'https://github.com/'.$owner_name.'/'.$repo_name;
            my @text = (
                'Issues and/or pull requests on github ('.$url.'/issues and '.$url.'/pulls):',
                '  open: ' . $issue_count,
            );

            @text = map colored($_, $colour), @text if $self->colour;
            push @issues, @text;
        }
    }

    return @issues;
}

sub before_release
{
    my $self = shift;

    $self->log($_) foreach $self->get_issues;
}

sub _rt_data_for_dist
{
    my ($self, $dist_name) = @_;

    my $json = $self->_rt_data_raw;
    return if not $json;

    require JSON::MaybeXS; JSON::MaybeXS->VERSION('1.001000');
    my $all_data = JSON::MaybeXS->new(utf8 => 0)->decode($json);
    return if not $all_data->{$dist_name};

    my %rt_data;
    $rt_data{open} = $all_data->{$dist_name}{counts}{active}
                   - $all_data->{$dist_name}{counts}{stalled};
    $rt_data{stalled} = $all_data->{$dist_name}{counts}{stalled};
    return %rt_data;
}

sub _rt_data_raw
{
    my $self = shift;

    $self->log_debug('fetching RT bug data...');
    my $data = $self->_fetch('https://rt.cpan.org/Public/bugs-per-dist.json');
    return if not $data;
    return $data;
}

sub _github_issue_count
{
    my ($self, $owner_name, $repo_name) = @_;

    $self->log_debug('fetching github issues data...');

    my $json = $self->_fetch('https://api.github.com/repos/' . $owner_name . '/' . $repo_name);
    return if not $json;

    require JSON::MaybeXS; JSON::MaybeXS->VERSION('1.001000');
    my $data = JSON::MaybeXS->new(utf8 => 0)->decode($json);
    $data->{open_issues_count};
}

sub _fetch
{
    my ($self, $url) = @_;

    require HTTP::Tiny;
    my $res = HTTP::Tiny->new->get($url);
    if (not $res->{success}) {
        $self->log('could not fetch from '.$url.': got '
            .($res->{status} && $res->{content} ? $res->{status}.' '.$res->{content} : 'unknown'));
        return;
    }

    my $data = $res->{content};

    require HTTP::Headers;
    if (my $charset = HTTP::Headers->new(%{ $res->{headers} })->content_type_charset)
    {
        $data = Encode::decode($charset, $data, Encode::FB_CROAK);
    }

    return $data;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CheckIssues - Retrieve count of outstanding RT and github issues for your distribution

=head1 VERSION

version 0.011

=head1 SYNOPSIS

In your F<dist.ini>:

    [CheckIssues]
    rt = 1              ; default
    github = 1          ; default
    colour = 1          ; default

    [ConfirmRelease]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that retrieves the RT and/or github issue
and pull request counts for your distribution before release.  Place it immediately before
C<[ConfirmRelease]> in your F<dist.ini> to give you an opportunity to abort the
release if you forgot to fix a bug or merge a pull request.

=for Pod::Coverage mvp_aliases before_release get_issues

=head1 CONFIGURATION OPTIONS

=head2 C<rt>

Checks your distribution's queue at L<https://rt.cpan.org/>. Defaults to true.
(You should leave this enabled even if you have your main issue list on github,
as sometimes tickets still end up on RT.)

=head2 C<github>

Checks the issue list on L<github|https://github.com> for your distribution; does
nothing if your distribution is not hosted on L<github|https://github.com>, as
listed in your distribution's metadata.  Defaults to true.

=head2 C<colour> or C<color>

Uses L<Term::ANSIColor> to colour-code the results according to severity.
Defaults to true.

=head2 C<repo_url>

The URL of the github repository.  This is fetched from the C<resources> field
in metadata, so it should not normally be specified manually.

=head1 FUTURE FEATURES, MAYBE

If I can find the right APIs to call, it would be nice to have a C<verbose>
option which fetches the actual titles of the open issues. Advice or patches welcome!

Possibly other issue trackers? Does anyone even use any other issue trackers
anymore? :)

=head1 ACKNOWLEDGEMENTS

=for stopwords Ricardo Signes codereview

Some code was liberally stolen from Ricardo Signes's
L<codereview tool|https://github.com/rjbs/misc/blob/master/code-review>.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::MetaResources> - manually add resource information (such as git repository) to metadata

=item *

L<Dist::Zilla::Plugin::GithubMeta> - automatically detect and add github repository information to metadata

=item *

L<Dist::Zilla::Plugin::AutoMetaResources> - configuration-based resource metadata provider

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-CheckIssues>
(or L<bug-Dist-Zilla-Plugin-CheckIssues@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-CheckIssues@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
