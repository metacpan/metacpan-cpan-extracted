use strict;
use warnings;
package MetaCPAN::Client::Permission;
# ABSTRACT: A Permission data object
$MetaCPAN::Client::Permission::VERSION = '2.028000';
use Moo;

with 'MetaCPAN::Client::Role::Entity';

my %known_fields = (
    scalar   => [qw< module_name owner >],
    arrayref => [qw< co_maintainers >],
    hashref  => [],
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

MetaCPAN::Client::Permission - A Permission data object

=head1 VERSION

version 2.028000

=head1 SYNOPSIS

    my $permission = $mcpan->permission('MooseX::Types');

=head1 DESCRIPTION

A MetaCPAN permission entity object.

=head1 ATTRIBUTES

=head2 module_name

Returns the name of the module.

=head2 owner

The module owner (first-come permissions).

=head2 co_maintainers

Other maintainers with permissions to this module.

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
