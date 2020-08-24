use strict;
use warnings;
package MetaCPAN::Client::Distribution;
# ABSTRACT: A Distribution data object
$MetaCPAN::Client::Distribution::VERSION = '2.028000';
use Moo;

with 'MetaCPAN::Client::Role::Entity';

my %known_fields = (
    scalar   => [qw< name >],
    arrayref => [],
    hashref  => [qw< bugs river >]
);

my %__known_fields_ex = (
    map { my $k = $_; $k => +{ map { $_ => 1 } @{ $known_fields{$k} } } }
    keys %known_fields
);

my @known_fields = map { @{ $known_fields{$_} } } keys %known_fields;

foreach my $field ( @known_fields ) {
    has $field => (
        is      => 'ro',
        lazy    => 1,
        default => sub {
            my $self = shift;
            return (
                exists $self->data->{$field}                ? $self->data->{$field} :
                exists $__known_fields_ex{hashref}{$field}  ? {} :
                exists $__known_fields_ex{arrayref}{$field} ? [] :
                exists $__known_fields_ex{scalar}{$field}   ? '' :
                undef
            );
        },
    );
}

sub _known_fields { return \%known_fields }

sub rt     { $_[0]->bugs->{rt}     || {} }
sub github { $_[0]->bugs->{github} || {} }

sub metacpan_url { "https://metacpan.org/release/" . $_[0]->name }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaCPAN::Client::Distribution - A Distribution data object

=head1 VERSION

version 2.028000

=head1 SYNOPSIS

    my $dist = $mcpan->distribution('MetaCPAN-Client');

=head1 DESCRIPTION

A MetaCPAN distribution entity object.

=head1 ATTRIBUTES

=head2 name

The distribution's name.

=head2 bugs

A hashref containing information about bugs reported in various issue
trackers. The top-level keys are issue tracker names like C<rt> or
C<github>. Each value is itself a hashref containing information about the
bugs in that tracker. The keys vary between trackers, but this will always
contain a C<source> key, which is a URL for the tracker. There may also be
keys containing counts such as C<active>, C<closed>, etc.

=head2 river

A hashref containing L<"CPAN
River"|http://neilb.org/2015/04/20/river-of-cpan.html> information about the
distro. The hashref contains the following keys:

=over 4

=item * bucket

A positive or zero integer. The higher the number the farther upstream this
distribution is.

=item * immediate

The number of distributions that directly depend on this one.

=item * total

The number of distributions that depend on this one, directly or indirectly.

=back

=head1 METHODS

=head2 rt

Returns the hashref of data for the rt bug tracker. This defaults to an empty
hashref.

=head2 github

Returns the hashref of data for the github bug tracker. This defaults to an
empty hashref.

=head2 metacpan_url

Returns a link to the distribution page on MetaCPAN.

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
