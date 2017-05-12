package Dezi::Bot::Cache;
use warnings;
use strict;
use CHI;

our $VERSION = '0.003';

=head1 NAME

Dezi::Bot::Cache - web crawler cache

=head1 SYNOPSIS

 use Dezi::Bot::Cache;

 my $cache = Dezi::Bot::Cache->new(%chi_params);
 $cache->add( foo => 'bar' );
 $cache->has( 'foo' );    # returns true
 $cache->get( 'foo' );    # returns 'bar'
 $cache->delete( 'foo' ); # removes 'foo' from cache and returns 1

=head1 DESCRIPTION

The Dezi::Bot::Cache module conforms to the SWISH::Prog::Cache
API but delegates all caching to CHI.

=head1 METHODS

=cut

=head2 new( I<chi_params> )

Returns instance of Dezi::Bot::Cache, initializing the internal
CHI object with I<chi_params>. 

If empty, I<chi_params> defaults to:

 %chi_params = (
   driver    => 'File',
   root_dir  => '/tmp/dezibot',
   namespace => 'dezibot',
 );

=cut

sub new {
    my $class      = shift;
    my %chi_params = @_;
    if ( !%chi_params ) {
        %chi_params = (
            driver    => 'File',
            root_dir  => '/tmp/dezibot',
            namespace => 'dezibot',
        );
    }
    my $chi = CHI->new(%chi_params);
    return bless { chi => $chi }, $class;
}

=head2 chi

Returns the internal CHI object.

=cut

sub chi {
    return shift->{chi};
}

=head2 add( I<key>, I<value> [, I<expires>] )

Add I<key> I<value> pair to cache, optional
I<expires> setting. See CHI for I<expires> 
documentation.

=cut

sub add {
    shift->chi->set(@_);
}

=head2 has( I<key> )

Returns true if I<key> is in the cache and has
not expired.

=cut

sub has {
    shift->chi->is_valid(@_);
}

=head2 get( I<key> )

Returns value for I<key> or undef if I<key>
is not present or has expired.

=cut

sub get {
    shift->chi->get(@_);
}

=head2 delete( I<key> )

Removes I<key> from the cache.

=cut

sub delete {
    shift->chi->remove(@_);
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-bot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-Bot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Bot


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-Bot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-Bot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-Bot>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-Bot/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

