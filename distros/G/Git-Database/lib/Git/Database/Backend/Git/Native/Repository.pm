package Git::Database::Backend::Git::Native::Repository;
$Git::Database::Backend::Git::Native::Repository::VERSION = '0.013';
use Cwd qw( cwd );
use Git::Native;
use Sub::Quote;

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  #'Git::Database::Role::ObjectReader',
  #'Git::Database::Role::ObjectWriter',
  #'Git::Database::Role::RefReader',
  #'Git::Database::Role::RefWriter',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git::Native::Repository object'
          if !eval { $_[0]->isa('Git::Native::Repository') }
        # die version check
    } ),
    default => sub { Git::Native->open( cwd() ) },
);

1;

__END__

=pod

=for Pod::Coverage
  hash_object

=head1 NAME

Git::Database::Backend::Git::Native::Repository - A Git::Database backend based on Git::Native

=head1 VERSION

version 0.013

=head1 SYNOPSIS

    # get a store
    my $r = Git::Native->open('.');

    # let Git::Database produce the backend
    my $db = Git::Database->new( store => $r );

=head1 DESCRIPTION

This backend reads data from a Git repository using the L<Git::Native>
bindings to the L<libgit2|http://libgit2.github.com> library.

=head2 Git Database Roles

This backend does the following roles
(check their documentation for a list of supported methods):
L<Git::Database::Role::Backend>.

=head1 AUTHORS

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2026 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
