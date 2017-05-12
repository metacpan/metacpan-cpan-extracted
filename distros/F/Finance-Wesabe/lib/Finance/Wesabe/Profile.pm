package Finance::Wesabe::Profile;

use Moose;
use Finance::Wesabe::Utils;

=head1 NAME

Finance::Wesabe::Profile - Class to represent your wesabe.com profile

=head1 SYNOPSIS

    my $profile = Finance::Wesabe::Profile->new(
        content => $c, parent => $p
    );

=head1 DESCRIPTION

This modules provides access to your profile information.

=head1 ACCESSORS

=over 4

=item * content - Hashref of data from the response

=item * parent - Parent object with acces to the user agent

=back

=cut

has content => ( is => 'ro', isa => 'HashRef' );

has parent => ( is => 'ro', isa => 'Object' );

=head1 PROFILE INFORMATION

=over 4

=item * name

=item * username

=item * postal_code

=item * email

=item * joined - A DateTime object

=item * country

=back

=cut

__PACKAGE__->mk_simple_field( qw( username name postal-code email ) );
__PACKAGE__->mk_deep_field( qw( country ) );
__PACKAGE__->mk_simple_date_field( qw( joined ) );

no Moose;

__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
