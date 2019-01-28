package Git::Database::Role::ObjectWriter;
$Git::Database::Role::ObjectWriter::VERSION = '0.011';
use Moo::Role;

requires
  'put_object',
  ;

1;

__END__

=pod

=head1 NAME

Git::Database::Role::ObjectWriter - Abstract role for Git backends that write objects

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    package MyGitBackend;

    use Moo;
    use namespace::clean;

    with
      'Git::Database::Role::Backend',
      'Git::Database::Role::ObjectWriter';

    # implement the required methods
    sub put_object { ... }

=head1 DESCRIPTION

A L<backend|Git::Database::Role::Backend> doing the additional
Git::Database::Role::ObjectWriter role is capable of writing the
data from L<objects|Git::Database::Role::Object> to the attached Git
repository.

=head1 REQUIRED METHODS

=head2 put_object

    # a Git::Database::Object::Tree representing the empty tree
    my $tree = Git::Database::Object::Tree->new( content => '' );

    my $digest = $backend->put_object( $tree );

Given an L<object|Git::Database::Role::Object>, C<put_object> will write
the data for the object in the underlying repository database, and
return the digest for the object.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
