#
# This file is part of Dist-Zilla-Stash-PAUSE-Encrypted
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Stash::PAUSE::Encrypted;
{
  $Dist::Zilla::Stash::PAUSE::Encrypted::VERSION = '0.003';
}

# ABSTRACT: Keep your PAUSE bits safely encrypted!

use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts;

use Config::Identity::PAUSE;

extends 'Dist::Zilla::Stash::PAUSE';

has "+$_" => (traits => [Shortcuts], lazy => 1, builder => 1, required => 0)
    for qw{ username password };

has identity => (
    traits  => ['Hash'],
    is      => 'lazy',
    isa     => 'HashRef',
    handles => {
        _build_username => [ get => 'username' ],
        _build_password => [ get => 'password' ],
    },
);

sub _build_identity { my %id = Config::Identity::PAUSE->load; \%id }

__PACKAGE__->meta->make_immutable;
!!42;


=pod

=encoding utf-8

=for :stopwords Chris Weyl magicky

=head1 NAME

Dist::Zilla::Stash::PAUSE::Encrypted - Keep your PAUSE bits safely encrypted!

=head1 VERSION

This document describes version 0.003 of Dist::Zilla::Stash::PAUSE::Encrypted - released July 13, 2012 as part of Dist-Zilla-Stash-PAUSE-Encrypted.

=head1 SYNOPSIS

    # ...do the GPG magicky things described by Config::Identity, then:

    # in your ~/.dzil/config.ini
    [%PAUSE::Encrypted / %PAUSE]

=head1 DESCRIPTION

This is a simple extension of L<Dist::Zilla::Stash::PAUSE> to use
L<Config::Identity> to store and access an encrypted version of your PAUSE
user id and password.

=for Pod::Coverage BUILD

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Config::Identity>

=item *

L<Dist::Zilla::Stash::PAUSE>

=item *

L<Dist::Zilla::Plugin::UploadToCPAN>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/RsrchBoy/dist-zilla-stash-pause-encrypted>
and may be cloned from L<git://github.com/RsrchBoy/dist-zilla-stash-pause-encrypted.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/dist-zilla-stash-pause-encrypted/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut


__END__

