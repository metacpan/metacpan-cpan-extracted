package Git::Database::Object::Raw;
$Git::Database::Object::Raw::VERSION = '0.011';
use Moo;

has kind => (
    is        => 'ro',
    required  => 1,
);

with 'Git::Database::Role::Object';

*sha1 = \&digest;

sub raw { $_[0]->kind . ' ' . $_[0]->size . "\0" . $_[0]->content }

sub BUILDARGS {
    return @_ == 2 && eval { $_[1]->does('Git::Database::Role::Object') }
      ? { kind => $_[1]->kind, content => $_[1]->content }
      : Moo::Object::BUILDARGS(@_);
}

1;

__END__

=pod

=for Pod::Coverage
  BUILDARGS
  kind

=head1 NAME

Git::Database::Object::Raw - Raw Git::Database objects

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    # $object is-a Git::Database::Object (Blob, Tree, Commit, Tag)
    my $raw  = Git::Database::Object::Raw->new( $object );

=head1 DESCRIPTION

This tiny class adds the L</sha1> and L</raw> methods to those offered
by L<Git::Database::Role::Object>. Git::Database::Object::Raw objects
can be handed to L<Git::PurePerl::Loose> or L<Cogit::Loose> for saving
in the Git object database.

=head1 METHODS

=head2 sha1

Alias for L<digest|Git::Database::Role::Object/digest>.

=head2 raw

Return the raw data, as used by L<Git::PurePerl::Loose> and
L<Cogit::Loose> to save an object in the Git object database.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
