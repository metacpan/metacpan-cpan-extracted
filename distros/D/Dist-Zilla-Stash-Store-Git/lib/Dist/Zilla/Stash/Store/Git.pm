#
# This file is part of Dist-Zilla-Stash-Store-Git
#
# This software is Copyright (c) 2014 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Stash::Store::Git;
BEGIN {
  $Dist::Zilla::Stash::Store::Git::AUTHORITY = 'cpan:RSRCHBOY';
}
# git description: 0.000004-1-g398e665
$Dist::Zilla::Stash::Store::Git::VERSION = '0.000005';

# ABSTRACT: A common place to store and interface with git

use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts;
use MooseX::RelatedClasses;

use autobox::Core;
use version;

use Git::Wrapper;
use Version::Next;
use Hash::Merge::Simple 'merge';

with 'Dist::Zilla::Role::Store';


around stash_from_config => sub {
    my ($orig, $class) = (shift, shift);
    my ($name, $args, $section) = @_;

    $args = { _zilla => delete $args->{_zilla}, store_config => $args };
    return $class->$orig($name, $args, $section);
};


sub default_config {
    my $self = shift @_;

    return {
        'version.regexp' => '^v(.+)$',
        'version.first'  => '0.001',
        'version.next'   => $self->_default_next_version,
    };
}


has dynamic_config => (
    traits  => [ 'Hash' ],
    is      => 'lazy',
    isa     => 'HashRef',
    builder => sub {
        my $self = shift @_;

        my @config =
            map { $_->gitstore_config_provided }
            $self->_dzil->plugins_with('-GitStore::ConfigProvider')->flatten
            ;

        ### @config
        return \@config;
    },
    handles => {
        has_dynamic_config     => 'count',
        has_no_dynamic_config  => 'is_empty', # XXX ?
        has_dynamic_config_for => 'exists',
        # ...
    },
);


has store_config => (
    traits  => [ 'Hash' ],
    is      => 'lazy',
    isa     => 'HashRef',
    builder => sub { { } },
    handles => {
        has_store_config     => 'count',
        has_no_store_config  => 'is_empty', # XXX ?
        has_store_config_for => 'exists',
        # ...
    },
);


has config => (
    traits  => [ 'Hash' ],
    is      => 'lazy',
    isa     => 'HashRef',
    clearer => -1, # private

    handles => {
        has_config     => 'count',
        has_no_config  => 'is_empty',
        has_config_for => 'exists',
        get_config_for => 'get',
        # ...

        # stopgaps...
        has_version_regexp => [ exists => 'version.regexp' ],
        version_regexp     => [ get    => 'version.regexp' ],
        has_first_version  => [ exists => 'version.first'  ],
        first_version      => [ get    => 'version.first'  ],
    },

    builder => sub {
        my $self = shift @_;

        ### merge all our different config sources..
        my $config = merge
            $self->default_config,
            $self->dynamic_config,
            $self->store_config,
            ;

        return $config;
    },
);


related_class 'Git::Wrapper';

has repo_wrapper => (
    is              => 'lazy',
    isa_instance_of => 'Git::Wrapper',
    builder         => sub { $_[0]->git__wrapper_class->new($_[0]->repo_root) },
);


related_class 'Git::Raw::Repository';

has repo_raw => (
    is              => 'lazy',
    isa_instance_of => 'Git::Raw::Repository',
    builder         => sub { $_[0]->git__raw__repository_class->open($_[0]->repo_root) },
);


has repo_root => (is => 'lazy', builder => sub { '.' });


has tags => (
    is      => 'lazy',
    isa     => 'ArrayRef[Str]',
    # For win32, natch
    builder => sub { local $/ = "\n"; [ shift->repo_wrapper->tag ] },
);


has previous_versions => (

    traits  => ['Array'],
    is      => 'lazy',
    isa     => 'ArrayRef[Str]',

    handles => {

        has_previous_versions => 'count',
        earliest_version      => [ get =>  0 ],
        latest_version        => [ get => -1 ],
    },

    builder => sub {
        my $self = shift @_;

        my $regexp = $self->version_regexp;
        my @tags = map { /$regexp/ ? $1 : () } $self->tags->flatten;

        # find tagged versions; sort least to greatest
        my @versions =
            sort { version->parse($a) <=> version->parse($b) }
            grep { eval { version->parse($_) }  }
            @tags;

        return [ @versions ];
    },
);

# -- role implementation

# XXX should this be here as default logic?  or should we require that a
# plugin supply this information to us?

sub _default_next_version {
    my $self = shift @_;

    # override (or maybe needed to initialize)
    return $ENV{V}
        if defined $ENV{V};

    return $self->first_version
        unless $self->has_previous_versions;

    my $last_ver = $self->last_version;
    my $new_ver  = Version::Next::next_version($last_ver);
    $self->log("Bumping version from $last_ver to $new_ver");

    return "$new_ver";
}


__PACKAGE__->meta->make_immutable;
!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl versioning ATCHUNG

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Dist::Zilla::Stash::Store::Git - A common place to store and interface with git

=head1 VERSION

This document describes version 0.000005 of Dist::Zilla::Stash::Store::Git - released May 14, 2014 as part of Dist-Zilla-Stash-Store-Git.

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a L<Dist::Zilla Store|Dist::Zilla::Role::Store> providing a common place to
store, fetch and share configuration information as to your distribution's git repository,
as well as your own preferences (e.g. git tag versioning scheme).

=head1 ATTRIBUTES

=head2 dynamic_config

This attribute contains all the configuration information provided to the
store by the plugins performing the
L<Dist::Zilla::Role::GitStore::ConfigProvider|GitStore::ConfigProvider role>.
Any values specified herein override those in the L</default_config>, and
anything set by the store configuration (aka L</store_config>) similarly
overrides anything here.

=head2 store_config

This attribute contains all the information passed to the store via the
store's configuration, e.g. in the distribution's C<dist.ini>.  Any values
specified herein override those in the L</default_config>, and anything
returned by a plugin (aka L</dynamic_config>) similarly overrides anything
here.

This is a read-only accessor to the L</store_config> attribute.

=head2 config

This attribute contains a HashRef of all the known configuration values, from
all sources (default, stash and plugins aka dynamic).  It merges the
L</dynamic_config> into L</store_config>, and that result into
L</default_config>, each time giving the hash being merged precedence.

If you're looking for "The Right Place to Find Configuration Values", this is
it. :)

=head2 repo_wrapper

Contains a lazily-constructed L<Git::Wrapper> instance for our repository.

=head2 repo_raw

Contains a lazily-constructed L<Git::Raw::Repository> instance for our
repository.

=head2 repo_root

Stores the repository root; by default this is the current directory.

=head2 tags

An ArrayRef of all existing tags in the repository.

=head2 previous_versions

A sorted ArrayRef of all previous versions of this distribution, as derived
from the repository tags filtered through the regular expression given in the
C<version.regexp>.

=head1 METHODS

=head2 stash_from_config()

This method wraps L<Dist::Zilla::Role::Stash/stash_from_config> to capture our
L<Dist::Zilla> instance and funnel all our stash configuration options into
the L</store_config> attribute.

=head2 default_config

This method provides a HashRef of all the default settings we know about.  At the moment,
this is:

    version.regexp => '^v(.+)$'
    version.first  => '0.001'

You should never need to mess with this -- note that L</store_config> (values
passed to the store via configuration) and L</dynamic_config> (values returned
by the plugins performing the
L<Dist::Zilla::Role::GitStore::ConfigProvider|GitStore::ConfigProvider role>),
respectively, override this.

=head2 dynamic_config

This is a read-only accessor to the L</dynamic_config> attribute.

=head2 has_dynamic_config

True if we have been provided any configuration by plugins.

This is a read-only accessor to the L</dynamic_config> attribute.

=head2 has_dynamic_config_for

True if plugin configuration has been provided for a given key, e.g.

    do { ... } if $store->has_dynamic_config_for('version.first');

This is a read-only accessor to the L</dynamic_config> attribute.

=head2 store_config

A read-only accessor to the store_config attribute.

This is a read-only accessor to the L</store_config> attribute.

=head2 has_store_config

True if we have been provided any static configuration.

This is a read-only accessor to the L</store_config> attribute.

=head2 has_store_config_for

True if static configuration has been provided for a given key, e.g.

    do { ... } if $store->has_store_config_for('version.first');

This is a read-only accessor to the L</store_config> attribute.

=head2 config()

A read-only accessor returning the config HashRef.

This is a read-only accessor to the L</config> attribute.

=head2 has_config

True if we have any configuration stored; false if not.

This is a read-only accessor to the L</config> attribute.

=head2 has_no_config

The inverse of L</has_config>.

This is a read-only accessor to the L</config> attribute.

=head2 has_config_for($key)

Returns true if we have configuration information for a given key.

This is a read-only accessor to the L</config> attribute.

=head2 get_config_for($key)

Returns the value we have for a given key; returns C<undef> if we have no
configuration information for that key.

This is a read-only accessor to the L</config> attribute.

=head2 repo_wrapper()

This is a read-only accessor to the L</repo_wrapper> attribute.

=head2 repo_raw()

This is a read-only accessor to the L</repo_raw> attribute.

=head2 repo_root

Returns the path to the repository root; this may be a relative path.

This is a read-only accessor to the L</repo_root> attribute.

=head2 tags()

A read-only accessor to the L</tags> attribute.

=head2 previous_versions()

A read-only accessor to the L</previous_versions> attribute.

=head2 has_previous_versions

True if this distribution has any previous versions; that is, if any git tags
match the version regular expression.

This is a read-only accessor to the L</previous_versions> attribute.

=head2 earliest_version

Returns the earliest version known; C<undef> if no such version exists.

This is a read-only accessor to the L</previous_versions> attribute.

=head2 latest_version

Returns the latest version known; C<undef> if no such version exists.

This is a read-only accessor to the L</previous_versions> attribute.

=head1 ATCHUNG!

B<This is VERY EARLY CODE UNDER ACTIVE DEVELOPMENT!  It's being used by L<this
author's plugin bundle|Dist::Zilla::PluginBundle::RSRCHBOY>, and as such is
being released as a non-TRIAL / non-development (e.g. x.xxx_01) release to
make that easier.  The interface is likely to change.  Stability (as it is)
should be expected when this section is removed and the version >= 0.001 (aka
0.001000).

Contributions, issues and the like are welcome and encouraged.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::Role::Store|Dist::Zilla::Role::Store>

=item *

L<Dist::Zilla::Role::Stash|Dist::Zilla::Role::Stash>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/RsrchBoy/dist-zilla-stash-store-git>
and may be cloned from L<git://https://github.com/RsrchBoy/dist-zilla-stash-store-git.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/dist-zilla-stash-store-git/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://www.gittip.com/RsrchBoy/"><img src="https://raw.githubusercontent.com/gittip/www.gittip.com/master/www/assets/%25version/logo.png" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fdist-zilla-stash-store-git&title=RsrchBoy's%20CPAN%20Dist-Zilla-Stash-Store-Git&tags=%22RsrchBoy's%20Dist-Zilla-Stash-Store-Git%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr this|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fdist-zilla-stash-store-git&title=RsrchBoy's%20CPAN%20Dist-Zilla-Stash-Store-Git&tags=%22RsrchBoy's%20Dist-Zilla-Stash-Store-Git%20in%20the%20CPAN%22>,
L<gittip me|https://www.gittip.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
