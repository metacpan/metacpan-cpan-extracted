#
# This file is part of Dist-Zilla-Plugin-ContributorsFromGit
#
# This software is Copyright (c) 2017, 2015, 2014, 2013, 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Plugin::ContributorsFromGit;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.017-9-ge7df715
$Dist::Zilla::Plugin::ContributorsFromGit::VERSION = '0.018';

# ABSTRACT: Populate your 'CONTRIBUTORS' POD from the list of git authors

use utf8;
use v5.10;

use Moose;
use MooseX::AttributeShortcuts;
use MooseX::Types::Moose ':all';
use Encode qw(decode_utf8);
use autobox::Core;
use autobox::Junctions;
use File::Which 'which';
use List::AllUtils qw{ max uniq };
use File::ShareDir qw/ dist_dir /;
use YAML::Tiny;
use Path::Class;

use autodie 'system';
use IPC::System::Simple ( ); # explict dep for autodie system

use aliased 'Dist::Zilla::Stash::PodWeaver';

with
    'Dist::Zilla::Role::BeforeBuild',
    'Dist::Zilla::Role::RegisterStash',
    'Dist::Zilla::Role::MetaProvider',
    ;

has _contributor_list => (
    is      => 'lazy',
    isa     => 'ArrayRef[Str]',
    builder => sub {
        my $self = shift @_;
        my @authors = $self->zilla->authors->flatten;

        ### and get our list from git, filtering: "@authors"
        my @contributors = uniq
            map  { $self->_contributor_emails->{$_} // $_ }
            grep { $_ ne 'Your Name <you@example.com>'   }
            grep { [ map { lc } @authors ]->none eq lc   }
            map  { decode_utf8($_)                       }
            map  { chomp; s/^\s*\d+\s*//; $_             }
            `git shortlog -s -e HEAD`
            ;

        return [ sort @contributors ];
    },
);

has _contributor_emails => (
    is       => 'lazy',
    isa      => HashRef[Str],
    init_arg => undef,

    builder => sub {

        my $mapping = YAML::Tiny
            ->read(
                file(
                    dist_dir('Dist-Zilla-Plugin-ContributorsFromGit'),
                    'author-emails.yaml',
                ),
            )
            ->[0]
            ;

        my $_map_it = sub {
            my ($canonical, @alternates) = @_;
            return ( map { $_ => $canonical } @alternates );
        };

        return {
            map { $_map_it->($_ => $mapping->{$_}->flatten) }
            $mapping->keys->flatten
        };
    },
);

has _stopwords => (
    is => 'lazy',
    isa => ArrayRef[Str],
    init_arg => undef,

    builder => sub {
        my $self = shift @_;

        # break contributor names into a stopwords-suitable list
        my @stopwords =
            map { (split / /)      }
            map { /^(.*) <.*$/; $1 }
            $self->_contributor_list->flatten
            ;

        return [ uniq sort @stopwords ];
    },
);

sub before_build {
    my $self = shift @_;

    # skip if we can't find git
    unless (which 'git') {
        $self->log('The "git" executable has not been found');
        return;
    }

    # XXX we should also check here that we're in a git repo, but I'm going to
    # leave that for the git stash (when it's not vaporware)

    ### get our stash...
    my $stash   = $self->zilla->stash_named('%PodWeaver');
    do { $stash = PodWeaver->new; $self->_register_stash('%PodWeaver', $stash) }
        unless defined $stash;

    ### ...and config...
    my $config = $stash->_config;

    # helper sub to keep us from clobbering existing values, until (and if):
    # https://github.com/rwstauner/Dist-Zilla-Role-Stash-Plugins/pull/1
    my $_append = sub {
        my ($key, @values) = @_;

        my $i = -1;
        do { $i++ } while exists $config->{$key."[$i]"};
        do { $config->{$key."[$i]"} = $_; $i++ }
            for @values;

        return;
    };

    $_append->('Contributors.contributors' => $self->_contributor_list->flatten);
    $_append->('-StopWords.include'        => $self->_stopwords->flatten);

    ### $config
    return;
}

sub metadata {
    my $self = shift @_;
    my $list = $self->_contributor_list;
    return @$list ? { 'x_contributors' => $list } : {};
}

__PACKAGE__->meta->make_immutable;
!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Brendan Randy Stauner Tatsuhiko Yanick Byrd Champoux David
Golden Graham Greb Knop Mike Miyagawa zilla BeforeBuild metacpan shortlog
committer mailmap

=head1 NAME

Dist::Zilla::Plugin::ContributorsFromGit - Populate your 'CONTRIBUTORS' POD from the list of git authors

=head1 VERSION

This document describes version 0.018 of Dist::Zilla::Plugin::ContributorsFromGit - released August 13, 2017 as part of Dist-Zilla-Plugin-ContributorsFromGit.

=head1 SYNOPSIS

    ; in your dist.ini
    [ContributorsFromGit]

    ; in your weaver.ini
    [Contributors]

=head1 DESCRIPTION

This plugin makes it easy to acknowledge the contributions of others by
populating a L<%PodWeaver|Dist::Zilla::Stash::PodWeaver> stash with the unique
list of all git commit authors reachable from the current HEAD.

=head1 OVERVIEW

On collecting the unique list of reachable commit authors from git, we search
and remove any git authors from the list of authors L<Dist::Zilla> knows
about.  We then look for a stash named C<%PodWeaver>; if we don't find one
then we create an instance of L<Dist::Zilla::Stash::PodWeaver> and register it
with our zilla instance.  Then we add the list of contributors (the filtered
git authors list) to the stash in such a way that
L<Pod::Weaver::Section::Contributors> can find them.

Note that you do not need to have the C<%PodWeaver> stash created; it will be
added if it is not found.  However, your L<Pod::Weaver> config (aka
C<weaver.ini>) must include the
L<Contributors|Pod::Weaver::Section::Contributors> section plugin.

=head2 Dist::Zilla Phase

This plugin runs during the L<BeforeBuild|Dist::Zilla::Role::BeforeBuild>
phase.

=head2 Metadata Keys

The list of contributors is also added to distribution metadata under the custom
C<x_contributors> key.  (e.g. in C<META.yml>, C<META.json>, etc)

If you have duplicate contributors because of differences in committer name
or email you can use a C<.mailmap> file to canonicalize contributor names
and emails.  See L<git help shortlog|git-shortlog(1)> for details.

=head2 Pod::Weaver::Section::Contributors is OPTIONAL

Note that using the L<Pod::Weaver::Section::Contributors> section is in no way
mandated or necessitated by this package; if you wish to use it you must
include the Contributors section in your L<Pod::Weaver> configuration in the
traditional fashion.

=for Pod::Coverage before_build metadata

=head1 METACPAN CONTRIBUTOR MATCHING

L<MetaCPAN|http://metacpan.org> will attempt to match a contributor address
back to a PAUSE account.  However, it (currently) can only do that if the
contributor's email address is their C<PAUSEID@cpan.org> address.  There are
two mechanisms for helping to resolve this, if your commits are not using this
address.

Both of these approaches have pros and cons that have been discussed at
levels nearing the heat brought to any discussion of religion, homosexuality,
or Chief O'Brien's actual rank at any ST:TNG convention.  However, they both
have the advantage of *working*, and through different modes of action.  You
are free to use one, both or neither.  These are only important if you're not
committing with your C<@cpan.org> email address B<and> want the MetaCPAN to
link to your author page from the page of the package you contributed to.

=head2 Using a .mailmap file

See C<git help shortlog> for help on how to use this.  A C<.mailmap> file must
be maintained in each repository using it.

=head2 Globally, via the authors mapping

This package contains a YAML file containing a mapping of C<@cpan.org> author
addresses; this list is consulted while building the contributors list, and
can be used to replace a non-cpan.org address with one.

To add to or modify this mapping, fork, add your alternate email addresses to
C<share/author-emails.yaml>, and submit a pull-request for inclusion.  It'll
be merged and released; as various authors update their set of installed
modules and cut new releases, the mapping will appear.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Weaver::Section::Contributors>

=item *

L<Dist::Zilla::Stash::PodWeaver>

=item *

L<http://www.dagolden.com/index.php/1921/how-im-using-distzilla-to-give-credit-to-contributors/>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/RsrchBoy/Dist-Zilla-Plugin-ContributorsFromGit/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 CONTRIBUTORS

=for stopwords Brendan Byrd David Golden Graham Knop Mike Greb Randy Stauner Tatsuhiko Miyagawa Yanick Champoux

=over 4

=item *

Brendan Byrd <Perl@ResonatorSoft.org>

=item *

David Golden <dagolden@cpan.org>

=item *

Graham Knop <haarg@haarg.org>

=item *

Mike Greb <mikegrb@cpan.org>

=item *

Randy Stauner <randy@magnificent-tears.com>

=item *

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017, 2015, 2014, 2013, 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
