package Dezi::Cache;
use Moose;
with 'Dezi::Role';
use Carp;
use namespace::autoclean;

our $VERSION = '0.014';

has 'cache' => ( is => 'rw' );

no Moose;  # since we have our own 'has' method

=pod

=head1 NAME

Dezi::Cache - simple in-memory cache class

=head1 SYNOPSIS

 use Dezi::Cache;
 my $cache = Dezi::Cache->new;
 $cache->add( foo => 'bar' );
 $cache->has( 'foo' ); # returns true
 $cache->get( 'foo' ); # returns 'bar'
 $cache->delete( 'foo' ); # removes 'foo' from cache and returns 'bar'

=head1 DESCRIPTION

Dezi::Cache is a simple in-memory caching class. It's basically
just a Perl hash, but implemented as a class so that you can subclass it
and use different storage (e.g. Cache::* modules).

=cut

=head1 METHODS

See Dezi::Class. Only new or overridden methods are documented here.

=head2 BUILD

Initialize the cache. Called internally by new(). You should not need to
call this yourself.

=cut

sub BUILD {
    my $self = shift;
    $self->{cache} ||= {};
}

=head2 cache([ I<hash_ref> ])

Get/set the internal in-memory cache. The default is just a hash ref.
Subclasses are encouraged to implement their own storage.

=head2 has( I<key> )

Does I<key> exist in cache.

=cut

sub has {
    my $self = shift;
    my $key  = shift;
    defined($key) or croak "key required";
    return exists $self->{cache}->{$key};
}

=head2 get( I<key> )

Returns value for I<key>. Returns undef if has( I<key> ) is false.

=cut

sub get {
    my $self = shift;
    my $key  = shift;
    defined($key) or croak "key required";
    return exists $self->{cache}->{$key} ? $self->{cache}->{$key} : undef;
}

=head2 delete( I<key> )

Delete I<key> from cache.

=cut

sub delete {
    my $self = shift;
    my $key  = shift;
    defined($key) or croak "key required";
    delete $self->{cache}->{$key};
}

=head2 add( I<key> => I<value> )

Add I<key> to cache with value I<value>.

=cut

sub add {
    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    defined($key) or croak "key required";
    $self->{cache}->{$key} = $val;
}

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<http://swish-e.org/>
