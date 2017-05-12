package Dezi::Test::Doc;
use Moose;
with 'Dezi::Role';
use SWISH::3 qw( :constants );

# make accessor all built-ins
for my $attr ( keys %{ SWISH_DOC_PROP_MAP() } ) {
    has $attr => ( is => 'ro', isa => 'Str' );
}

# and any we use in our tests
my @attrs = qw( swishdefault swishtitle swishdescription );
for my $attr (@attrs) {
    has $attr => ( is => 'ro', isa => 'Str' );
}

sub uri { shift->swishdocpath }

sub property {
    my $self = shift;
    my $prop = shift or confess "property required";
    return $self->$prop;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Dezi::Test::Doc - test Document class for Dezi::Test::Result

=head1 SYNOPSIS

=head1 METHODS

=head2 SWISH_DOC_PROP_MAP

All attributes defined in L<SWISH::3> SWISH_DOC_PROP_MAP hash.

=head2 swishdefault

=head2 swishtitle

=head2 swishdescription

=head2 uri

Alias for swishdocpath.

=head2 property( I<attribute> )

Alias for calling I<attribute> directly as a method.

=head1 AUTHOR

Peter Karman, E<lt>karpet@dezi.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-app at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::App

You can also look for information at:

=over 4

=item * Website

L<http://dezi.org/>

=item * IRC

#dezisearch at freenode

=item * Mailing list

L<https://groups.google.com/forum/#!forum/dezi-search>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<https://metacpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2014 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL v2 or later.

=head1 SEE ALSO

L<http://dezi.org/>, L<http://swish-e.org/>, L<http://lucy.apache.org/>

