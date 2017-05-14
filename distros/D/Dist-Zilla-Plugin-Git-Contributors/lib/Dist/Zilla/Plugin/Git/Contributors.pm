use strict;
use warnings;
package Dist::Zilla::Plugin::Git::Contributors; # git description: v0.029-3-g7e1af87
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: Add contributor names from git to your distribution
# KEYWORDS: plugin distribution metadata git contributors authors commits

our $VERSION = '0.030';

use Moose;
with 'Dist::Zilla::Role::MetaProvider',
    'Dist::Zilla::Role::PrereqSource';

use List::Util 1.33 qw(none any);
use Git::Wrapper 0.035;
use Try::Tiny;
use Path::Tiny 0.048;
use Moose::Util::TypeConstraints 'enum';
use List::UtilsBy 0.04 'uniq_by';
use Unicode::Collate 0.53;
use version;
use namespace::autoclean;

sub mvp_multivalue_args { qw(paths remove) }
sub mvp_aliases { return { path => 'paths' } }

has include_authors => (
    is => 'ro', isa => 'Bool',
    default => 0,
);

has include_releaser => (
    is => 'ro', isa => 'Bool',
    default => 1,
);

has order_by => (
    is => 'ro', isa => enum([qw(name commits)]),
    default => 'name',
);

has paths => (
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub { [] },
    traits => ['Array'],
    handles => { paths => 'elements' },
);

has remove => (
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub { [] },
    traits => ['Array'],
    handles => { remove => 'elements' },
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    my $dist_root = path($self->zilla->root)->realpath;

    $config->{+__PACKAGE__} = {
        include_authors => $self->include_authors ? 1 : 0,
        include_releaser  => $self->include_releaser ? 1 : 0,
        order_by => $self->order_by,
        paths => [ sort map {
                     my $p = path($_)->realpath;
                     ($dist_root->subsumes($p) ? $p->relative($dist_root) : $p)->stringify
                   } $self->paths ],
        $self->remove ? ( remove => '...' ) : (),
        git_version => $self->_git('version'),
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };

    return $config;
};

sub metadata
{
    my $self = shift;

    my $contributors = $self->_contributors;
    return if not @$contributors;

    $self->_check_podweaver;
    +{ x_contributors => $contributors };
}

sub register_prereqs
{
    my $self = shift;

    return if none { /[^[:ascii:]]/ } @{ $self->_contributors };

    my $prereqs = $self->zilla->prereqs;
    my $all_prereqs = $prereqs->requirements_for(qw(runtime requires))
        ->clone
        ->add_requirements($prereqs->requirements_for(qw(configure requires)))
        ->add_requirements($prereqs->requirements_for(qw(build requires)))
        ->add_requirements($prereqs->requirements_for(qw(test requires)))
        ->as_string_hash;

    my $perl_prereq = $all_prereqs->{perl};

    $self->log_debug([ 'found non-ascii characters in contributor names; perl prereq so far is %s',
        defined $perl_prereq ? $perl_prereq : 'unknown' ]);
    $perl_prereq = 0 if not defined $perl_prereq;
    $perl_prereq = version->parse($perl_prereq)->numify;
    return if "$perl_prereq" >= '5.008006';

    # many Dist::Zilla-using distributions don't have an explicit minimum
    # perl, but we know that Dist::Zilla doesn't work until 5.8.7
    return if any { /^Dist::Zilla/ } keys %$all_prereqs;

    # if dynamic_config is set, the user gets another chance to read the file, via fallback code:
    # < haarg> eumm loads META, updates prereqs, and writes out MYMETA
    # < haarg> so in a working system, x_contributors will be included
    # < haarg> in a broken system, it will fail to load META, regenerate it from parameters including META_ADD/MERGE, then write it out
    # < haarg> so if there isn't any utf8 data in the parameters given to EUMM, it will produce a file that can be read by a "bad" JSON::PP
    return if $self->zilla->distmeta->{dynamic_config};

    # see https://github.com/makamaka/JSON-PP/pull/9 for for details
    $self->log('Warning: distribution has non-ascii characters in contributor names. META.json will be unparsable on perls <= 5.8.6 when JSON::PP is lower than 2.27300');

    $self->zilla->register_prereqs(
        {
            phase => 'configure',
            type  => 'suggests',
        },
        'JSON::PP' => '2.27300',
    );
}

# should not be called before the MetaProvider phase
has _contributors => (
    is => 'ro', isa => 'ArrayRef[Str]',
    lazy => 1,
    builder => '_build_contributors',
);

sub _build_contributors
{
    my $self = shift;

    # note that ->status does something different.
    return [] if not $self->_git(RUN => 'status');

    my @data = $self->_git(shortlog =>
        {
            email => 1,
            summary => 1,
            $self->order_by eq 'commits' ? ( numbered => 1 ) : (),
        },
        'HEAD', '--', $self->paths,
    );

    my @contributors = map { m/^\s*\d+\s*(.*)$/g; } @data;

    $self->log_debug([ 'extracted contributors from git: %s',
        sub { require Data::Dumper; Data::Dumper->new([ \@contributors ])->Indent(2)->Terse(1)->Dump } ]);

    my $fc = "$]" >= '5.016001'
        ? \&CORE::fc
        : do {
            $self->log_debug('case-folding not available; falling back to lower-cased comparisons');
            sub { lc $_[0] }    # not callable via \&CORE::lc
        };

    # remove duplicates by email address, keeping the latest associated name
    @contributors = uniq_by { $fc->((/(<[^>]+>)/g)[-1]) } @contributors;

    @contributors = Unicode::Collate->new(level => 1)->sort(@contributors) if $self->order_by eq 'name';

    if (not $self->include_authors)
    {
        my @author_emails = map { /(<[^>]+>)/g } @{ $self->zilla->authors };
        @contributors = grep {
            my $contributor = $_;
            none { $contributor =~ /\Q$_\E/i } @author_emails;
        } @contributors;
    }

    if (not $self->include_releaser and my $releaser = $self->_releaser)
    {
        @contributors = grep { $fc->($_) ne $fc->($releaser) } @contributors;
    }

    if ($self->remove)
    {
        @contributors = grep {
            my $contributor = $_; none { $contributor =~ /\Q$_\E/ } $self->remove
        } @contributors;
    }

    return \@contributors;
}

sub _releaser
{
    my $self = shift;

    my ($username, $email);
    try {
        ($username) = $self->_git(config => 'user.name');
        ($email)    = $self->_git(config => 'user.email');
    };
    if (not $username or not $email)
    {
        $self->log('could not extract user.name and user.email configs from git');
        return;
    }
    $username . ' <' . $email . '>';
}

sub _check_podweaver
{
    my $self = shift;

    # check if the module is loaded, not just that it is installed
    $self->log('WARNING! You appear to be using Pod::Weaver::Section::Contributors, but it is not new enough to take data directly from distmeta. Upgrade to version 0.008!')
        if eval { Pod::Weaver::Section::Contributors->VERSION(0); 1 }
            and not eval { Pod::Weaver::Section::Contributors->VERSION(0.007001); 1 };
}

has __git => (
    is => 'ro',
    isa => 'Git::Wrapper',
    lazy => 1,
    default => sub { Git::Wrapper->new(path(shift->zilla->root)->absolute->stringify) },
);

sub _git
{
    my ($self, $command, @args) = @_;

    die 'no command?!' if not $command;
    my $git = $self->__git;
    my @result = try {
        $git->$command(@args);
    } catch {
        $self->log(blessed($_) && $_->isa('Git::Wrapper::Exception') ? $_->error : $_);
        ();
    };
    my $err = $git->ERR;
    $self->log(@$err) if $err and @$err;

    # TODO Git::Wrapper should really be decoding this for us, via a new
    # (defaulting-to-false) utf8 flag
    utf8::decode($_) foreach @result;
    return @result;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git::Contributors - Add contributor names from git to your distribution

=head1 VERSION

version 0.030

=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::Contributors]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that extracts all names and email addresses
from git commits in your repository and adds them to the distribution metadata
under the C<x_contributors> key.  It takes a minimalist approach to this -- no
data is stuffed into other locations, including stashes -- if other plugins
wish to work with this information, they should extract it from the
distribution metadata.

=for stopwords unicode casefolding

=head1 RECOMMENDED PERL VERSION

This module uses unicode comparison routines as well as casefolding semantics
(when available); Perl 5.016 is recommended.

=head1 CONFIGURATION OPTIONS

=head2 C<include_authors>

When true, authors (as defined by the preamble section in your F<dist.ini>)
are added to the list of contributors. When false, authors
are filtered out of the list of contributors.  Defaults to false.

=head2 C<include_releaser>

Defaults to true; set to false to remove the current user (who is doing the
distribution release) from the contributors list. It is applied after
C<include_authors>, so you will be removed from the list even if you are (one
of the) distribution author(s) and C<include_authors = 1>.

You probably don't want this option -- it was added experimentally to change
how contributors are displayed on L<http://metacpan.org>, but it was decided
that this should be managed at a different layer than the metadata.

=head2 C<order_by>

When C<order_by = name>, contributors are sorted alphabetically
(ascending); when C<order_by = commits>, contributors are sorted by number of
commits made to the repository (descending). The default value is C<name>.

=head2 C<path>

Available since version 0.007.

Indicates a path, relative to the repository root, to search for commits in.
Technically: "Consider only commits that are enough to explain how the files that match the specified paths came to be."
Defaults to the repository root. Can be used more than once.
I<You should almost certainly not need this.>

=head2 C<remove>

Available since version 0.011.

Any contributor entry matching this regular expression is removed from inclusion.
Can be used more than once.

=for stopwords canonicalizing

=head1 CANONICALIZING NAMES AND ADDRESSES

If you or a contributor uses multiple names and/or email addresses to make
commits and would like them mapped to a canonical value (e.g. their
C<cpan.org> address), you can do this by
adding a F<.mailmap> file to your git repository, with entries formatted as
described in "MAPPING AUTHORS" in C<git help shortlog>
(L<https://www.kernel.org/pub/software/scm/git/docs/git-shortlog.html>).

Duplicate names that share the same email address will be removed
automatically (keeping the form associated with the latest commit).

=head1 ADDING CONTRIBUTORS TO POD DOCUMENTATION

You can add the contributor names to your module documentation by using
L<Pod::Weaver> in conjunction with L<Pod::Weaver::Section::Contributors>.

=head1 UNICODE SUPPORT

=for stopwords ascii

This module aims to properly handle non-ascii characters in contributor names.
However, on Windows you might need to do a bit more: see
L<https://github.com/msysgit/msysgit/wiki/Git-for-Windows-Unicode-Support> for
supported versions and extra configurations you may need to apply.

=head1 SEE ALSO

=over 4

=item *

L<How I'm using Dist::Zilla to give credit to contributors|http://www.dagolden.com/index.php/1921/how-im-using-distzilla-to-give-credit-to-contributors/>

=item *

L<Pod::Weaver::Section::Contributors> - weaves x_contributors data into a pod section

=item *

L<Dist::Zilla::Plugin::Meta::Contributors> - adds an explicit list of names to x_contributors

=item *

L<Dist::Zilla::Plugin::ContributorsFile> - takes a list of names from a file

=item *

L<Dist::Zilla::Plugin::ContributorsFromGit> - more dependencies, problematic tests, passes around a lot of extra data in stashes unnecessarily

=item *

L<Dist::Zilla::Plugin::ContributorsFromPod> - takes the list of contributors from pod

=item *

L<Module::Install::Contributors>

=back

=for Pod::Coverage mvp_multivalue_args mvp_aliases metadata register_prereqs

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Git-Contributors>
(or L<bug-Dist-Zilla-Plugin-Git-Contributors@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Git-Contributors@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Kent Fredric Klaus Eichner Matthew Horsfall Mohammad S Anwar

=over 4

=item *

Kent Fredric <kentnl@cpan.org>

=item *

Klaus Eichner <klaus03@gmail.com>

=item *

Matthew Horsfall <wolfsage@gmail.com>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
