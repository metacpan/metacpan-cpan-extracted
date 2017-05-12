package Memcached::Server::Default;

use warnings;
use strict;

use Memcached::Server;

=head1 NAME

Memcached::Server::Default - A pure perl Memcached server

=head1 VERSION

Version 0.04

=cut

sub new {
    shift;
    my $data = {};
    return Memcached::Server->new(
	cmd => {
	    set => sub {
		my($cb, $key, $flag, $expire) = @_;
		$data->{$key} = $_[4];
		$cb->(1);
	    },
	    get => sub {
		my($cb, $key) = @_;
		if( exists $data->{$key} ) {
		    $cb->(1, $data->{$key});
		}
		else {
		    $cb->(0);
		}
	    },
	    _find => sub {
		my($cb, $key) = @_;
		$cb->( exists $data->{$key} );
	    },
	    delete => sub {
		my($cb, $key) = @_;
		if( exists $data->{$key} ) {
		    delete $data->{$key};
		    $cb->(1);
		}
		else {
		    $cb->(0);
		}
	    },
	    flush_all => sub {
		my($cb) = @_;
		$data = {};
		$cb->();
	    },
	},
	@_
    );
}

=head1 SYNOPSIS

    use Memcached::Server::Default;
    use AE;

    Memcached::Server::Default->new(
	open => [[0, 8888]]
    );

    AE::cv->recv;

=head1 DESCRIPTION

This module is a simple but complete example for using L<Memcached::Server>.
It works like a normal Memcached server, but not good at efficiency as the
real one. It is just a example.

=head1 SEE ALSO

L<Memcached::Server>, L<AnyEvent>, L<AnyEvent::Socket>

=head1 AUTHOR

Cindy Wang (CindyLinz)

=head1 BUGS

Please report any bugs or feature requests to C<bug-memcached-server at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Memcached-Server>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Memcached::Server::Default


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Memcached-Server>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Memcached-Server>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Memcached-Server>

=item * Search CPAN

L<http://search.cpan.org/dist/Memcached-Server/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Cindy Wang (CindyLinz).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
