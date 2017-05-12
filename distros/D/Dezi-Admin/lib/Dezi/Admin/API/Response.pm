package Dezi::Admin::API::Response;
use strict;
use warnings;
use overload
    '""'     => sub { $_[0]->stringify; },
    'bool'   => sub {1},
    fallback => 1;
use JSON;
use Plack::Util::Accessor qw(
    total
    success
    results
    metaData
);

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = {
        success  => 1,
        metaData => {
            successProperty => 'success',
            totalProperty   => 'total',
            sortInfo        => {},
            fields          => [],
            idProperty      => 'id',
            root            => 'results',
            limit           => 50,
            start           => 0,
        },
        %args,
    };

    return bless $self, $class;
}

sub stringify {
    my $self = shift;
    return to_json( {%$self} );
}

1;

__END__

=head1 NAME

Dezi::Admin::API::Response - Dezi administration API response

=head1 SYNOPSIS

 use Dezi::Admin::API::Response;
 
 my $resp = Dezi::Admin::API::Response->new(
    total   => $total,
    results => $list,
 );
 print $resp;  # renders as JSON
        
=head1 DESCRIPTION

Dezi::Admin::API::Response represents a JSON response to an API call.

=head1 METHODS

=head2 new( I<args> )

Constructor. I<args> should include params I<total> and I<results>.

=head2 success

Get/set success boolean.

=head2 total

Get/set total integer.

=head2 results

Get/set array ref of results.

=head2 metaData

Get/set hash ref of meta data. Format is what ExtJS expects.

=head2 stringify

Returns JSON representation of Response. All stringification actions
are overloaded to call this method.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-admin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-Admin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Admin


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-Admin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-Admin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-Admin>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-Admin/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
