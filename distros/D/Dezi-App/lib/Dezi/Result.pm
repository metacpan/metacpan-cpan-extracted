package Dezi::Result;
use Moose;
use MooseX::StrictConstructor;
with 'Dezi::Role';
use Carp;
use namespace::autoclean;

our $VERSION = '0.014';

has 'doc'          => ( is => 'ro', isa => 'Object',  required => 1, );
has 'score'        => ( is => 'ro', isa => 'Num',     required => 1 );
has 'property_map' => ( is => 'ro', isa => 'HashRef', required => 1 );

=head1 NAME

Dezi::Result - abstract result class

=head1 SYNOPSIS
                
 my $results = $searcher->search( 'foo bar' );
 while (my $result = $results->next) {
     printf("%4d %s\n", $result->score, $result->uri);
 }

=head1 DESCRIPTION

Dezi::Result is a abstract class. It defines
the APIs that all Dezi engines adhere to in
returning results from a Dezi::InvIndex.

=head1 METHODS

The following methods are all accessors (getters) only.

=head2 doc

Returns an object for the backend engine.

=head2 score

Returns the ranking score for the Result.

=head2 uri

=head2 mtime

=head2 title

=head2 summary

=head2 swishdocpath

Alias for uri().

=head2 swishlastmodified

Alias for mtime().

=head2 swishtitle

Alias for title().

=head2 swishdescription

Alias for summary().

=head2 swishrank

Alias for score().

=cut

sub uri     { shift->doc->swishdocpath }
sub mtime   { shift->doc->swishlastmodified }
sub summary { shift->doc->swishdescription }
sub title   { shift->doc->swishtitle }

# version 2 names for the faithful
sub swishdocpath      { shift->uri }
sub swishlastmodified { shift->mtime }
sub swishtitle        { shift->title }
sub swishdescription  { shift->summary }
sub swishrank         { shift->score }

=head2 get_property( I<property> )

Returns the stored value for I<property> for this Result.

The default behavior is to simply call a method called I<property>
on the internal doc() object. Subclasses should implement per-engine
behavior.

=cut

sub get_property {
    my $self = shift;
    my $propname = shift or croak "propname required";

    # if $propname is an alias, use the real property name (how it is stored)
    if ( exists $self->property_map->{$propname} ) {
        $propname = $self->property_map->{$propname};
    }

    if ( $self->can($propname) ) {
        return $self->$propname;
    }
    return $self->doc->property($propname);
}

=head2 get_property_array( I<property> )

Returns the stored value for I<property> for the Result. Unlike
get_property(), the value is always an arrayref, split
on the libswish3 multi-value character.

Example:

 my $val    = $result->get_property('foo');       # "green\003blue"
 my $arrval = $result->get_property_array('foo'); # ['green', 'blue']

Note that return value will *always* be an arrayref, even if
the original value does not contain a multi-value character.

=cut

sub get_property_array {
    my $self = shift;
    my $val  = $self->get_property(@_);
    return [ split( /\003/, $val ) ];
}

=head2 property_map

Set by the parent Results, a hashref of property aliases to real names.
Used by get_property().

=cut

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

    perldoc Dezi::Result

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

