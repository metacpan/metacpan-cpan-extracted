use strict;
use warnings;
package MetaCPAN::Client::Cover;
# ABSTRACT: A Cover data object
$MetaCPAN::Client::Cover::VERSION = '2.028000';
use Moo;

with 'MetaCPAN::Client::Role::Entity';

my %known_fields = (
    scalar   => [qw< distribution release version >],
    arrayref => [],
    hashref  => [qw< criteria >],
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

MetaCPAN::Client::Cover - A Cover data object

=head1 VERSION

version 2.028000

=head1 SYNOPSIS

    my $cover = $mcpan->cover('Moose-2.2007');

=head1 DESCRIPTION

A MetaCPAN cover entity object.

=head1 ATTRIBUTES

=head2 distribution

Returns the name of the distribution.

=head2 release

Returns the name of the release.

=head2 version

Returns the version of the release.

=head2 criteria

Returns a hashref with the coverage stats for the release.
Will contain one or more of the following keys:
'branch', 'condition', 'statement', 'subroutine', 'total'

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
