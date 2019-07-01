package IO::Lambda::HTTP;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(http_request http_server);

use strict;
use warnings;
use IO::Lambda qw(:lambda);
use IO::Lambda::HTTP::Client;

sub http_request(&) 
{
#	Carp::carp "IO::Lambda::HTTP is deprecated, use IO::Lambda::HTTP::Client instead";
	IO::Lambda::HTTP::Client-> new(context)-> 
		condition(shift, \&http_request, 'http_request')
}

sub new {
	shift;
#	Carp::carp "IO::Lambda::HTTP is deprecated, use IO::Lambda::HTTP::Client instead";
	IO::Lambda::HTTP::Client->new(@_);
}
1;

__DATA__

=pod

=head1 NAME

IO::Lambda::HTTP - http requests lambda style

=head1 DESCRIPTION

The module exports a single condition C<http_request> that accepts a
C<HTTP::Request> object and set of options as parameters. The condition returns
either a C<HTTP::Response> on success, or an error string otherwise.

=head1 SYNOPSIS

   use HTTP::Request;
   use IO::Lambda qw(:all);
   use IO::Lambda::HTTP qw(http_request);

   lambda {
      context shift;
      http_request {
         my $result = shift;
         if ( ref($result)) {
            print "good: ", length($result-> content), " bytes\n";
         } else {
            print "bad: $result\n";
         }
      }
   }-> wait(
       HTTP::Request-> new( GET => "http://www.perl.com/")
   );

=head1 API

=over

=item http_request $HTTP::Request -> $HTTP::Response

C<http_request> is a lambda condition that accepts C<HTTP::Request> object in
the context. Returns either a C<HTTP::Response> object on success, or error
string otherwise.

=item new $HTTP::Request :: () -> $HTTP::Response

See L<IO::Lambda::HTTP::Client/new>

=back

=head1 BUGS

Non-blocking connects, and hence the module, don't work on win32 on perl5.8.X
due to under-implementation in ext/IO.xs.  They do work on 5.10 however. 

=head1 SEE ALSO

L<IO::Lambda::HTTP::Client>

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
