package Dezi::Lucy::Result;
use Moose;
extends 'Dezi::Result';
use SWISH::3 ':constants';
use Carp;
use namespace::autoclean;

our $VERSION = '0.014';

has 'relevant_fields' => ( is => 'rw', isa => 'ArrayRef' );

=head1 NAME

Dezi::Lucy::Result - search result for Dezi::Lucy::Results

=head1 SYNOPSIS

 # see Dezi::Result

=head1 DESCRIPTION

Dezi::Lucy::Result is an Apache Lucy based Result
class for Dezi::App.

=head1 METHODS

Only new and overridden methods are documented here. See
the L<Dezi::Result> documentation.

=head2 relevant_fields

Returns an ARRAY ref of the field names in the result 
that matched the query. Will only be populated if
the Results object had find_relevant_fields() set to true.

=cut

=head2 uri

Returns the uri (unique term) for the result document.

=cut

sub uri { $_[0]->{doc}->{swishdocpath} }

=head2 title

Returns the title of the result document.

=cut

sub title { $_[0]->{doc}->{swishtitle} }

=head2 mtime

Returns the last modified time of the result document.

=cut

sub mtime { $_[0]->{doc}->{swishlastmodified} }

=head2 summary

Returns the swishdescription of the result document.

=cut

sub summary { $_[0]->{doc}->{swishdescription} }

=head2 get_property( I<PropertyName> )

Returns the value for I<PropertyName>.

=cut

sub get_property {
    my $self = shift;
    my $propname = shift or croak "PropertyName required";

    # if $propname is an alias, use the real property name (how it is stored)
    if ( exists $self->{property_map}->{$propname} ) {
        $propname = $self->{property_map}->{$propname};
    }

    if ( !exists $self->{doc}->{$propname} ) {
        croak "no such PropertyName: $propname";
    }
    return $self->{doc}->{$propname};
}

__PACKAGE__->meta->make_immutable;

1;

__END__

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

