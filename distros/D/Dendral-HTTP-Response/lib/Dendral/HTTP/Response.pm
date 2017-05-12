package Dendral::HTTP::Response;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.1.0';

require XSLoader;
XSLoader::load('Dendral::HTTP::Response', $VERSION);

sub new 
{ 
	my $class = shift;
	my $r     = shift;

	my $self  = {r => $r};

	bless $self, $class;

return $self;
}


1;
__END__

=head1 NAME

Dendral::HTTP::Response - Perl interface for Apache response variables


=head1 SYNOPSIS

  # Mod_perl handler
  use Dendral::HTTP::Response;

  sub handler
  {
      my $r = shift;
      my $res = new Dendral::HTTP::Response($r);
      
      #Add cookie to response header
      $res -> add_cookie(name => 'Cooker', 
                         value => {qwe => 'Test',asd => '3'},
                         domain => 'www.Rambler.ru,
                         path => '/123',
                         secure => 1, 
                         expires => '+1M');
                        
      #Set response header 
      $res -> set_header('X-Message' => 'Hello');
      
      #Delete Response header by name
      $res -> delete_header('Set-Cookie');
      
      #Merge header
      $res -> merge_header('X-Temp','123');
      
      #Clear all response header
      $res -> clear_headers();
      
      #Send response headers (Apache 1.x)
      $res -> send_http_header();
      
      #Send file to client
      $res -> send_file('/etc/passwd');
  }

=head1 DESCRIPTION

Dendral::HTTP::Response is a part of Dendral - fast, reliable and lightweight MVC framework.


=head1 METHODS

=head2 new - Constructor

    Create a new Dendral::HTTP::Response object with an Apache request_rec object:

    my $res = new Dendral::HTTP::Response($r);

=head2 add_cookie - Add Set-Cookie header to response

  $res -> add_cookie(name => 'Cooker1', 
                     value => 123,
                     domain => 'www.rambler.ru,
                     path => '/123');

  $res -> add_cookie(name => 'Cooker2', 
                     value => {qwe => 'Test',asd => '3'},
                     domain => 'www.Rambler.ru,
                     path => '/1234',
                     expires => '+1M',
                     secure => 1, 
                     httponly => 1);

=head2 set_http_code - Set HTTP response code

  $res -> set_http_code(404);

=head2 get_http_code - Get HTTP response code

  my $code = $res -> get_http_code();

=head2 send_http_header - Send HTTP response headers

  $res -> send_http_header();

=head2 redirect - Redirect to uri (Set 

  $res -> redirect('/index.html');

=head2 redirect_permanent - Permanent redirect to uri.

  $res -> redirect_permanent('/index.html');

=head2 set_header - Set Response header 

  $res -> set_header('X-Message' => 'Hello');

=head2 get_header - Get Response header 

  $msg = $res -> get_header('X-Message');
  #Get hashref of all Headers
  $headers = $res -> get_header();

=head2 set_content_type - Set Response 'Content-type' header

  $res -> set_content_type('text/plain');

=head2 get_content_type - Get Response 'Content-type' header

  my $content_type = $res -> get_content_type();

=head2 delete_header - Delete Response header 

  $res -> delete_header('X-Message');

=head2 merge_header - Merge Response header 

  $res -> merge_header('X-Message', 'Test');

=head2 clear_headers - Clear all Response headers

  $res -> clear_headers();

=head2 send_file -  Send file to client

  $res -> send_file('/etc/passwd');


=head1 SEE ALSO

perl(1), Apache(3), Dendral::HTTP::Request(1)

=cut
