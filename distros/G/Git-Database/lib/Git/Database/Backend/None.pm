package Git::Database::Backend::None;
$Git::Database::Backend::None::VERSION = '0.010';
use Moo;
use namespace::clean;

with 'Git::Database::Role::Backend';

# we don't have a backend
has '+store' => (
    is        => 'ro',
    required  => 0,
    init_arg  => undef,
    predicate => 1,
);

1;

__END__

=head1 NAME

Git::Database::Backend::None - A minimal backend for Git::Database

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use Git::Database;
    use Git::Database::Backend::None;

    my $backend = Git::Database::Backend::None->new();

    # the empty tree
    my $tree = Git::Database::Object::Tree->new( content => '' );

    # 4b825dc642cb6eb9a060e54bf8d69288fbee4904
    my $digest = $backend->hash_object( $tree );

=head1 DESCRIPTION

C<Git::Database::Backend::None> is the minimal backend class for
L<Git::Database>.

It can't read or write from a L<store|Git::Database::Tutorial/store>,
because it doesn't have one.

=head2 Git Database Roles

This backend does the following roles
(check their documentation for a list of supported methods):
L<Git::Database::Role::Backend>.

Since it's not connected to a store, this class can't delegate the
L<digest|Git::Database::Role::Object/digest> computation to Git
itself. It therefore uses the default implementation provided by
L<Git::Database::Role::Backend>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
