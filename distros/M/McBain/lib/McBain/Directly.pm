package McBain::Directly;

use warnings;
use strict;

use Carp;

=head1 NAME
 
McBain::Directly - Use a McBain API directly from Perl code.

=head1 SYNOPSIS

	# if the API is object oriented
	use MyAPI;

	my $api = MyAPI->new;

	$two_times_five = $api->call('GET:/math/multiply', { one => 2, two => 5 });

	# if the API is not object oriented
	use MyAPI;

	$two_times_five = MyAPI->call('GET:/math/multiply', { one => 2, two => 5 });

=head1 DESCRIPTION

The C<McBain::Directly> module is the default, and simplest L<McBain runner|McBain/"MCBAIN RUNNERS">
available. It allows using APIs written with L<McBain> directly from Perl code.

When used directly, C<McBain> APIs behave like so:

=over

=item * Return values from the API's methods are returned to the caller as is, with no
formatting or processing whatsoever.

=item * Exceptions are returned as is as well, in C<McBain>'s L<standard exception hash-ref|McBain/"EXCEPTIONS">
format. This means the C<call()> method C<die>s when errors are encountered, so
you should check for exceptions with C<eval>, or use something like L<Try::Tiny>.

=back

=head1 METHODS EXPORTED TO YOUR API

None.

=head1 METHODS REQUIRED BY MCBAIN

This runner module implements the following methods required by C<McBain>:

=head2 init( )

Does nothing here.

=cut

sub init { 1 }

=head2 generate_env( $namespace, $payload )

Accepts the arguments to the C<call()> method and creates C<McBain>'s
standard C<$env> hash-ref.

=cut

sub generate_env {
	my $class = shift;

	confess { code => 400, error => "Namespace must match <METHOD>:<ROUTE> where METHOD is one of GET, POST, PUT, DELETE or OPTIONS" }
		unless $_[0] =~ m/^(GET|POST|PUT|DELETE|OPTIONS):[^:]+$/;

	my ($method, $route) = split(/:/, $_[0]);

	return {
		METHOD	=> $method,
		ROUTE		=> $route,
		PAYLOAD	=> $_[1]
	};
}

=head2 generate_res( $env, $res )

Simply returns the results as-is.

=cut

sub generate_res {
	my ($class, $env, $res) = @_;

	return $res;
}

=head2 handle_exception( $err )

Simply rethrows the exception.

=cut

sub handle_exception {
	my ($class, $err) = @_;

	confess $err;
}

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-McBain@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=McBain>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc McBain::Directly

You can also look for information at:

=over 4
 
=item * RT: CPAN's request tracker
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=McBain>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/McBain>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/McBain>
 
=item * Search CPAN
 
L<http://search.cpan.org/dist/McBain/>
 
=back
 
=head1 AUTHOR
 
Ido Perlmuter <ido@ido50.net>
 
=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2013-2014, Ido Perlmuter C<< ido@ido50.net >>.
 
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic>
and L<perlgpl|perlgpl>.
 
The full text of the license can be found in the
LICENSE file included with this module.
 
=head1 DISCLAIMER OF WARRANTY
 
BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.
 
IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
 
=cut

1;
__END__

