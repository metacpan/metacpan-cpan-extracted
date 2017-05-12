#
# This file is part of Dist-Zilla-Role-RegisterStash
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Role::RegisterStash;
BEGIN {
  $Dist::Zilla::Role::RegisterStash::AUTHORITY = 'cpan:RSRCHBOY';
}
# git description: 0.002-6-g7034f16
$Dist::Zilla::Role::RegisterStash::VERSION = '0.003';

# ABSTRACT: A plugin that can register stashes

use Moose::Role;
use namespace::autoclean;
use Class::Load;

use Dist::Zilla 4.3 ();


# so, we're a little sneaky here.  It's possible to register stashes w/o
# touching any "private" attributes or methods in the zilla object while it is
# being built from the configuration, but we don't always want to create them
# then.  (Think of it like a lazy attribute -- we don't want to build it until
# we need it, and it may be created further down in the configuration
# anyways.)
#
# instead we generate a coderef capturing our assembler, and stash that away.
# If we need to register a stash later, we'll be able to access the
# registration method as if we were during the build stage.

has _register_stash_method => (
    traits  => ['Code'],
    is      => 'ro',
    isa     => 'CodeRef',
    handles => {
        _register_stash => 'execute',
    },
);

before register_component => sub {
    my ($class, $name, $arg, $section) = @_;

    my $assembler = $section->sequence->assembler;
    $arg->{_register_stash_method} ||= sub {
        $assembler->register_stash(@_);
    };

    return;
};


sub _register_or_retrieve_stash {
    my ($self, $name) = @_;

    my $stash = $self->zilla->stash_named($name);
    return $stash
        if $stash;

    # TODO isn't there a better way?!
    (my $stash_pkg = $name) =~ s/^%/Dist::Zilla::Stash::/;

    ### $stash_pkg;
    Class::Load::load_class($stash_pkg);
    $stash = $stash_pkg->new();
    $self->_register_stash($name => $stash);
    return $stash;
}

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl zilla somesuch

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Dist::Zilla::Role::RegisterStash - A plugin that can register stashes

=head1 VERSION

This document describes version 0.003 of Dist::Zilla::Role::RegisterStash - released May 14, 2014 as part of Dist-Zilla-Role-RegisterStash.

=head1 SYNOPSIS

    # in your plugin...
    with 'Dist::Zilla::Role::RegisterStash';

    # and elsewhere...
    $self->_register_stash('%Foo' => $stash);

=head1 DESCRIPTION

Sometimes it's handy for a plugin to register a stash, and there's no easy way
to do that (without touching $self->zilla->_local_stashes or somesuch).

This role provides a _register_stash() method to your plugin, allowing you to
register stashes.  Yes, the leading underscore is intentional: the purpose of
this method is to allow the consuming plugin to register stashes, not anyone
else, so this method is private to the consumer.

=head1 METHODS

=head2 _register_stash($name => $stash_instance)

Given a name and a stash instance, register it with our zilla object.

=head2 _register_or_retrieve_stash

Given a stash name (e.g. C<%Store::Git>), return that stash.  If our C<dzil>
claims to not be aware of any such stash we register a new instance of the
stash in question and return it.

=head1 SOURCE

The development version is on github at L<http://https://github.com/RsrchBoy/Dist-Zilla-Role-RegisterStash>
and may be cloned from L<git://https://github.com/RsrchBoy/Dist-Zilla-Role-RegisterStash.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/Dist-Zilla-Role-RegisterStash/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://www.gittip.com/RsrchBoy/"><img src="https://raw.githubusercontent.com/gittip/www.gittip.com/master/www/assets/%25version/logo.png" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2FDist-Zilla-Role-RegisterStash&title=RsrchBoy's%20CPAN%20Dist-Zilla-Role-RegisterStash&tags=%22RsrchBoy's%20Dist-Zilla-Role-RegisterStash%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr this|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2FDist-Zilla-Role-RegisterStash&title=RsrchBoy's%20CPAN%20Dist-Zilla-Role-RegisterStash&tags=%22RsrchBoy's%20Dist-Zilla-Role-RegisterStash%20in%20the%20CPAN%22>,
L<gittip me|https://www.gittip.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
