package Git::Database::Role::RefWriter;
$Git::Database::Role::RefWriter::VERSION = '0.011';
use Moo::Role;

requires
  'put_ref',
  'delete_ref'
;

1;

__END__

=pod

=head1 NAME

Git::Database::Role::RefWriter - Abstract role for Git backends that write references

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    package MyGitBackend;

    use Moo;
    use namespace::clean;

    with
      'Git::Database::Role::Backend',
      'Git::Database::Role::RefWriter';

    # implement the required methods
    sub put_ref    { ... }
    sub delete_ref { ... }

=head1 DESCRIPTION

A L<backend|Git::Database::Role::Backend> doing the additional
Git::Database::Role::RefWriter role is capable of writing references
to a Git repository.

=head1 REQUIRED METHODS

=head2 put_ref

    $backend->put_ref( 'refs/heads/master', $digest );

Add or update the (fully qualified) refname to point to the given digest.

=head2 delete_ref

    $backend->delete_ref( 'refs/heads/master' );

Unconditionaly delete the given refname.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
