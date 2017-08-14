package Hash::Merge::Extra;

use strict;
use warnings FATAL => 'all';

use Hash::Merge qw(_merge_hashes);

our $VERSION = '0.03'; # Don't forget to change in pod below

use constant L_ADDITIVE => {
    'SCALAR' => {
        'SCALAR' => sub { defined $_[0] ? $_[0] : $_[1] },
        'ARRAY'  => sub { defined $_[0] ? $_[0] : $_[1] },
        'HASH'   => sub { defined $_[0] ? $_[0] : $_[1] },
    },
    'ARRAY' => {
        'SCALAR' => sub { $_[0] },
        'ARRAY'  => sub { [ @{$_[0]}, @{$_[1]} ] },
        'HASH'   => sub { $_[0] },
    },
    'HASH' => {
        'SCALAR' => sub { $_[0] },
        'ARRAY'  => sub { $_[0] },
        'HASH'   => sub { _merge_hashes(@_) },
    },
};

use constant R_ADDITIVE => {
    'SCALAR' => {
        'SCALAR' => sub { defined $_[1] ? $_[1] : $_[0] },
        'ARRAY'  => sub { $_[1] },
        'HASH'   => sub { $_[1] },
    },
    'ARRAY' => {
        'SCALAR' => sub { defined $_[1] ? $_[1] : $_[0] },
        'ARRAY'  => sub { [ @{$_[1]}, @{$_[0]} ] },
        'HASH'   => sub { $_[1] },
    },
    'HASH' => {
        'SCALAR' => sub { defined $_[1] ? $_[1] : $_[0] },
        'ARRAY'  => sub { $_[1] },
        'HASH'   => sub { _merge_hashes(@_) },
    },
};

use constant L_OVERRIDE => {
    'SCALAR' => {
        'SCALAR' => sub { $_[0] },
        'ARRAY'  => sub { $_[0] },
        'HASH'   => sub { $_[0] },
    },
    'ARRAY' => {
        'SCALAR' => sub { $_[0] },
        'ARRAY'  => sub { $_[0] },
        'HASH'   => sub { $_[0] },
    },
    'HASH' => {
        'SCALAR' => sub { $_[0] },
        'ARRAY'  => sub { $_[0] },
        'HASH'   => sub { _merge_hashes(@_) },
    },
};

use constant R_OVERRIDE => {
    'SCALAR' => {
        'SCALAR' => sub { $_[1] },
        'ARRAY'  => sub { $_[1] },
        'HASH'   => sub { $_[1] },
    },
    'ARRAY' => {
        'SCALAR' => sub { $_[1] },
        'ARRAY'  => sub { $_[1] },
        'HASH'   => sub { $_[1] },
    },
    'HASH' => {
        'SCALAR' => sub { $_[1] },
        'ARRAY'  => sub { $_[1] },
        'HASH'   => sub { _merge_hashes(@_) },
    },
};

use constant L_REPLACE => {
    'SCALAR' => {
        'SCALAR' => sub { $_[0] },
        'ARRAY'  => sub { $_[0] },
        'HASH'   => sub { $_[0] },
    },
    'ARRAY' => {
        'SCALAR' => sub { $_[0] },
        'ARRAY'  => sub { $_[0] },
        'HASH'   => sub { $_[0] },
    },
    'HASH' => {
        'SCALAR' => sub { $_[0] },
        'ARRAY'  => sub { $_[0] },
        'HASH'   => sub { $_[0] },
    },
};

use constant R_REPLACE => {
    'SCALAR' => {
        'SCALAR' => sub { $_[1] },
        'ARRAY'  => sub { $_[1] },
        'HASH'   => sub { $_[1] },
    },
    'ARRAY' => {
        'SCALAR' => sub { $_[1] },
        'ARRAY'  => sub { $_[1] },
        'HASH'   => sub { $_[1] },
    },
    'HASH' => {
        'SCALAR' => sub { $_[1] },
        'ARRAY'  => sub { $_[1] },
        'HASH'   => sub { $_[1] },
    },
};

my %INDEX = (
    L_ADDITIVE      => L_ADDITIVE,
    L_OVERRIDE      => L_OVERRIDE,
    L_REPLACE       => L_REPLACE,

    R_ADDITIVE      => R_ADDITIVE,
    R_OVERRIDE      => R_OVERRIDE,
    R_REPLACE       => R_REPLACE,
);

sub import {
    shift; # throw off package name

    for (@_ ? @_ : keys %INDEX) {
        unless (exists $INDEX{$_}) {
            require Carp;
            Carp::croak "Unable to register $_ (no such behavior)";
        }
        Hash::Merge::specify_behavior($INDEX{$_}, $_);
    }
}

1;

__END__

=head1 NAME

Hash::Merge::Extra - Collection of extra behaviors for L<Hash::Merge>

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Hash::Merge qw(merge);
    use Hash::Merge::Extra;

    Hash::Merge::set_behavior('R_OVERRIDE');

    $result = merge($left, $right);

=head1 EXPORT

Nothing is exported.

All behaviors registered in L<Hash::Merge> if used as

    use Hash::Merge::Extra;

Nothing registered if passed empty list:

    use Hash::Merge::Extra qw();

Only specified behaviors registered if list defined:

    use Hash::Merge::Extra qw(L_OVERRIDE R_REPLACE);

=head1 BEHAVIORS

=over 4

=item B<L_ADDITIVE>, B<R_ADDITIVE>

Hashes merged, arrays joined, undefined scalars overrided. Left and right precedence.

=item B<L_OVERRIDE>, B<R_OVERRIDE>

Hashes merged, arrays and scalars overrided. Left and right precedence.

=item B<L_REPLACE>, B<R_REPLACE>

Nothing merged. One thing simply replaced by another. Left and right precedence.

=back

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/mr-mixas/Hash-Merge-Extra.pm/issues>

=head1 SEE ALSO

L<Hash::Merge>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
