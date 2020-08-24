use strict;
use warnings;
package MetaCPAN::Client::Favorite;
# ABSTRACT: A Favorite data object
$MetaCPAN::Client::Favorite::VERSION = '2.028000';
use Moo;

with 'MetaCPAN::Client::Role::Entity';

my %known_fields = (
    scalar   => [qw< date user release id author distribution >],
    arrayref => [],
    hashref  => []
);

my @known_fields =
    map { @{ $known_fields{$_} } } qw< scalar arrayref hashref >;

foreach my $field (@known_fields) {
    has $field => (
        is      => 'ro',
        lazy    => 1,
        default => sub {
            my $self = shift;
            return $self->data->{$field};
        },
    );
}

sub _known_fields { return \%known_fields }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaCPAN::Client::Favorite - A Favorite data object

=head1 VERSION

version 2.028000

=head1 SYNOPSIS

    # Query favorites for a given distribution:

    my $favorites = $mcpan->favorite( {
        distribution => 'Moose'
    } );


    # Total number of matches ("how many favorites does the dist have?"):

    print $favorites->total;


    # Iterate over the favorite matches

    while ( my $fav = $favorites->next ) { ... }

=head1 DESCRIPTION

A MetaCPAN favorite entity object.

=head1 ATTRIBUTES

=head2 date

An ISO8601 datetime string like C<2016-11-19T12:41:46> indicating when the
favorite was created.

=head2 user

The user ID (B<not> PAUSE ID) of the person who favorited the thing in
question.

=head2 release

The release that was favorited.

=head2 id

The favorite ID.

=head2 author

The PAUSE ID of the author whose release was favorited.

=head2 distribution

The distribution that was favorited.

=head1 AUTHORS

=over 4

=item *

Sawyer X <xsawyerx@cpan.org>

=item *

Mickey Nasriachi <mickey@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
