package LucyX::Search::AnyTermQuery;
use strict;
use warnings;
use base qw( Lucy::Search::Query );
use Carp;
use Scalar::Util qw( blessed );
use LucyX::Search::AnyTermCompiler;

our $VERSION = '0.006';

=head1 NAME

LucyX::Search::AnyTermQuery - Lucy query extension for not NULL values

=head1 SYNOPSIS

 my $query = LucyX::Search::AnyTermQuery->new(
    field   => 'color',
 );
 my $hits = $searcher->hits( query => $query );
 # $hits == documents where the 'color' field is not empty

=head1 DESCRIPTION

LucyX::Search::AnyTermQuery extends the 
Lucy::QueryParser syntax to support NULL values.

=head1 METHODS

This class is a subclass of Lucy::Search::Query. Only new or overridden
methods are documented here.

=cut

# Inside-out member vars
my %field;

=head2 new( I<args> )

Create a new AnyTermQuery object. I<args> must contain key/value pair
for C<field>.

=cut

sub new {
    my ( $class, %args ) = @_;
    my $field = delete $args{field};
    my $self  = $class->SUPER::new(%args);
    confess("'field' param is required")
        unless defined $field;
    $field{$$self} = $field;
    return $self;
}

=head2 get_field

Retrieve the value set in new().

=cut

sub get_field { my $self = shift; return $field{$$self} }

sub DESTROY {
    my $self = shift;
    delete $field{$$self};
    $self->SUPER::DESTROY;
}

=head2 equals

Returns true (1) if the object represents the same kind of query
clause as another AnyTermQuery.

NOTE: Currently a AnyTermQuery and a NullTermQuery object will
evaluate as equal if they have the same field. This is a bug.

=cut

sub equals {
    my ( $self, $other ) = @_;
    return 0 unless blessed($other);
    return 0
        unless $other->isa( ref $self );
    return $self->get_field eq $other->get_field;
}

=head2 to_string

Returns the query clause the object represents.

=cut

sub to_string {
    my $self = shift;
    return sprintf( "(NOT %s:NULL)", $self->get_field );
}

=head2 make_compiler

Returns a LucyX::Search::NullCompiler object.

=cut

sub make_compiler {
    my $self = shift;
    my %args = @_;
    $args{parent} = $self;
    return LucyX::Search::AnyTermCompiler->new(%args);

    # TODO should our compiler call this in make_matcher() ?

    # unlike Search::Query synopsis, normalize()
    # is called internally in $compiler.
    # This should be fixed in a C re-write.
    #$compiler->normalize unless $subordinate;

    #return $compiler;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lucyx-search-wildcardquery at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LucyX-Search-NullTermQuery>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LucyX::Search::NullTermQuery


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LucyX-Search-NullTermQuery>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LucyX-Search-NullTermQuery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LucyX-Search-NullTermQuery>

=item * Search CPAN

L<http://search.cpan.org/dist/LucyX-Search-NullTermQuery/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
