package Git::Database::Actor;
$Git::Database::Actor::VERSION = '0.010';
use Moo;
use namespace::clean;

has name => (
    is       => 'ro',
    required => 1,
);

has email => (
    is       => 'ro',
    required => 1,
);

sub ident { $_[0]->name . ' <' . $_[0]->email . '>' }

1;

__END__

=pod

=head1 NAME

Git::Database::Actor - An actor in Git::Database

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use Git::Database::Actor;

    my $actor = Git::Database::Actor->new(
        name  => 'Philippe Bruhat (BooK)',
        email => 'book@cpan.org'
    );

    print $actor->ident;    # Philippe Bruhat (BooK) <book@cpan.org>

=head1 DESCRIPTION

L<Git::Database::Actor> represents a user in L<Git::Database>,
i.e. the combination of a name and an email.

=head1 ATTRIBUTES

=head2 name

The name of the actor.

=head2 email

The email of the actor.

=head1 METHODS

=head2 ident

The identity of the actor, build as:

    Name <email>

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2013-2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
