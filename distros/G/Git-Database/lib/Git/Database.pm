package Git::Database;
$Git::Database::VERSION = '0.009';
use strict;
use warnings;

use Module::Runtime qw( use_module );

use Moo::Object ();
use namespace::clean;

sub new {
    my $args = Moo::Object::BUILDARGS(@_);

    # store: an object that gives actual access to a git repo
    if ( my $store = delete $args->{store} ) {
        if ( !ref $store || -d $store ) {
            require Git::Database::Backend::Git::Sub;
            return Git::Database::Backend::Git::Sub->new( store => $store );
        }
        else {
            return use_module( "Git::Database::Backend::" . ref $store )
              ->new( store => $store );
        }
    }

    # some really basic default
    return use_module('Git::Database::Backend::None')->new;
}

1;

__END__

=pod

=head1 NAME

Git::Database - Provide access to the Git object database

=head1 VERSION

version 0.009

=head1 SYNOPSIS

    # get a store
    my $r  = Git::Repository->new();

    # build a backend to access the store
    my $db = Git::Database::Backend::Git::Repository->new( store => $r );

    # or let Git::Database figure it out by itself
    my $db = Git::Database->new( store => $r );

=head1 DESCRIPTION

Git::Database provides access from Perl to the object database stored
in a Git repository. It can use any supported Git wrapper to access
the Git object database maintained by Git.

Git::Database is actually a factory class: L</new> returns
L<backend|Git::Database::Tutorial/backend> instances.

=head1 METHODS

=head2 new

    my $r = Git::Repository->new;

    # $db is-a Git::Database::Backend::Git::Repository
    my $db = Git::Database->new( store => $r );

Return a L<backend|Git::Database::Tutorial/backend> object, based on
the class of the L<store|Git::Database::Tutorial/store> object.

=head1 BACKEND METHODS

The backend methods are split between several roles, and not all backends
do all the roles. Therefore not all backend objects support all the
following methods.

=head2 From L<Git::Database::Role::Backend>

This is the minimum required role to be a backend. Hence this method is
always available.

=over 4

=item L<hash_object|Git::Database::Role::Backend/hash_object>

=back

=head2 From L<Git::Database::Role::ObjectReader>

=over 4

=item L<has_object|Git::Database::Role::ObjectReader/has_object>

=item L<get_object_meta|Git::Database::Role::ObjectReader/get_object_meta>

=item L<get_object_attributes|Git::Database::Role::ObjectReader/get_object_attributes>

=item L<get_object|Git::Database::Role::ObjectReader/get_object>

=item L<all_digests|Git::Database::Role::ObjectReader/all_digests>

=back

=head2 From L<Git::Database::Role::ObjectWriter>

=over 4

=item L<put_object|Git::Database::Role::ObjectWriter/put_object>

=back

=head2 From L<Git::Database::Role::RefReader>

=over 4

=item L<refs|Git::Database::Role::RefReader/refs>

=item L<ref_names|Git::Database::Role::RefReader/ref_names>

=item L<ref_digest|Git::Database::Role::RefReader/ref_digest>

=back

=head2 From L<Git::Database::Role::RefWriter>

=over 4

=item L<put_ref|Git::Database::Role::RefWriter/put_ref>

=item L<delete_ref|Git::Database::Role::RefWriter/delete_ref>

=back

=head1 SEE ALSO

=over 4

=item Objects

L<Git::Database::Object::Blob>,
L<Git::Database::Object::Tree>,
L<Git::Database::Object::Commit>,
L<Git::Database::Object::Tag>.

=item Backend roles

L<Git::Database::Role::Backend>,
L<Git::Database::Role::ObjectReader>,
L<Git::Database::Role::ObjectWriter>,
L<Git::Database::Role::RefReader>,
L<Git::Database::Role::RefWriter>.

=item Backends

L<Git::Database::Backend::None>,
L<Git::Database::Backend::Git::Repository>,
L<Git::Database::Backend::Git::Sub>,
L<Git::Database::Backend::Git::PurePerl>,
L<Git::Database::Backend::Cogit>,
L<Git::Database::Backend::Git>,
L<Git::Database::Backend::Git::Wrapper>,
L<Git::Database::Backend::Git::Raw>.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Git::Database

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Git-Database>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Git-Database>

=item * Search CPAN

L<http://search.cpan.org/dist/Git-Database>

=item * MetaCPAN

L<http://metacpan.org/release/Git-Database>

=back

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2013-2017 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
