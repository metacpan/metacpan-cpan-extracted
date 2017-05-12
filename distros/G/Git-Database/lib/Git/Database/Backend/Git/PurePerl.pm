package Git::Database::Backend::Git::PurePerl;
$Git::Database::Backend::Git::PurePerl::VERSION = '0.009';
use Sub::Quote;

use Moo;
use namespace::clean;

with
  'Git::Database::Role::PurePerlBackend',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git::PurePerl object'
          if !eval { $_[0]->isa('Git::PurePerl') }
    } ),
);

# Git::Database::Role::PurePerlBackend
sub _store_packs { [ $_[0]->store->packs ] }

1;

__END__

=pod

=for Pod::Coverage
  hash_object
  get_object_attributes
  get_object_meta
  all_digests
  put_object
  refs

=head1 NAME

Git::Database::Backend::Git::PurePerl - A Git::Database backend based on Git::PurePerl

=head1 VERSION

version 0.009

=head1 SYNOPSIS

    # get a store
    my $r  = Git::PurePerl->new();

    # let Git::Database produce the backend
    my $db = Git::Database->new( store => $r );

=head1 DESCRIPTION

This backend reads data from a Git repository using the
L<Git::PurePerl> Git wrapper.

=head2 Git Database Roles

This backend does the following roles
(check their documentation for a list of supported methods):
L<Git::Database::Role::Backend>,
L<Git::Database::Role::ObjectReader>,
L<Git::Database::Role::ObjectWriter>,
L<Git::Database::Role::RefReader>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
