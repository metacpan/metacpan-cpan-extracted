package HTTP::DAV::Response;

use strict;
use vars qw(@ISA $VERSION);

$VERSION = '0.14';

require HTTP::Response;
@ISA = qw(HTTP::Response);

my %dav_status_codes = (
   102 => "Processing. Server has accepted the request, but has not yet completed it",
   204 => "No Content",
   207 => "Multistatus",
   422 => "Unprocessable Entity. Bad client XML sent?",
   423 => "Locked. The source or destination resource is locked",
   424 => "Failed Dependency",
   507 => "Insufficient Storage. The server is unable to store the request",
);

# PROTECTED METHODS

sub clone_http_resp {
   my ($class,$http_resp) = @_;
   my %clone = %{$http_resp};
   my $self = \%clone;
   bless $self, (ref($class) || $class); 
}

# This routine resets the base
# message in the 
# object based on the 
# code and the status_codes above.
# set_message('207');
sub set_message {
   my ($self,$code) = @_;

   # Set the status code
   if ( defined $dav_status_codes{$code} ) {
      $self->message( $dav_status_codes{$code} );
   }
}

sub set_responsedescription {
   $_[0]->{'_dav_responsedescription'} = $_[1] if $_[1];
}

sub get_responsedescription { $_[0]->{'_dav_responsedescription'}; }

sub add_status_line {
   my($self,$message,$responsedescription,$handle,$url) = @_;
   
   # Parse "status-line". See section 6.1 of RFC 2068
   # Status-Line= HTTP-Version SP Status-Code SP Reason-Phrase CRLF
   if (defined $message && $message =~ /^(.*?)\s(.*?)\s(.*?)$/ ) {
      my ($http_version,$status_code,$reason_phrase) = ($1,$2,$3);

      push ( @{$self->{_dav_multistatus}},
               {
                  'handle' => $handle,
                  'url' => $url,
                  'HTTP Version' => $http_version,
                  'code' => $status_code,
                  'message' => $reason_phrase,
                  'description' => $responsedescription,
               }
           );
      return 1;

   } else {
      return 0;
   }
}

# PUBLIC METHODS

sub is_multistatus {
    return ($_[0]->code eq "207" )? 1:0; 
}

sub messages {
   my ($self) = @_;

   my @messages = ();
   if ($self->is_multistatus() ) {
      foreach my $num ( 0 .. $self->response_count()) {
         push(@messages, $self->message_bynum($num));
      }
   } else {
      push(@messages,$self->message());
   }

   return wantarray ? @messages : join("\n",@messages);
}

sub codes {
   my ($self) = @_;

   my @codes = ();
   if ($self->is_multistatus() ) {
      foreach my $num ( 0 .. $self->response_count()) {
         push(@codes, $self->code_bynum($num));
      }
   } else {
      push(@codes,$self->code());
   }

   return \@codes;
}

sub response_count { 
   return -1 unless exists $_[0]->{_dav_multistatus};
   return -1 unless ref($_[0]->{_dav_multistatus}) =~ /ARRAY/;
   return  $#{$_[0]->{_dav_multistatus}}; 
}

sub message_bynum { $_[0]->{_dav_multistatus}[$_[1]]{'message'}; }
sub    code_bynum { $_[0]->{_dav_multistatus}[$_[1]]{'code'}; }
sub     url_bynum { $_[0]->{_dav_multistatus}[$_[1]]{'url'}; }
sub description_bynum { $_[0]->{_dav_multistatus}[$_[1]]{'description'}; }

sub response_bynum {
   my ($self,$number) = @_;

   if (defined $number && $number>=0 ) {
      return (
         $self->code_bynum($number),
         $self->message_bynum($number),
         $self->url_bynum($number),
         $self->description_bynum($number),
      );
   }
}

sub is_success {
   my ($self) = @_;

   if ($self->is_multistatus() ) {
      foreach my $code ( @{ $self->codes() } ) {
         return 0 if ( HTTP::Status::is_error($code) );
      }
   } else {
      return ($self->SUPER::is_success() || 0);
   }

   return 1;
}

sub as_string {
   my ($self) = @_;
   my ($ms, $returnstr) = "";

#   use Data::Dumper;
#   print Data::Dumper->Dump( [\$self] , [ '$self' ] );
   foreach my $num ( 0 .. $self->response_count() ) {
      my %h = %{$self->{_dav_multistatus}[$num]};
      $ms .= "Error number $num ($h{handle}):\n";
      $ms .= "   Href:       $h{url}\n"                 if defined $h{url};
      $ms .= "   Mesg(code): $h{message} ($h{code})\n"  if defined $h{code};
      $ms .= "   Desc:       $h{'description'}\n"       if defined $h{'description'};
      $ms .= "\n";
   }

   my $rd = $self->get_responsedescription() || "";

   $returnstr .= "Multistatus lines:\n$ms\n" if $ms;
   $returnstr .= "Overall responsedescription: \"$rd\"\n" if $rd;
   $returnstr .= $self->SUPER::as_string;
   $returnstr;
}

=head1 NAME

HTTP::DAV::Response - represents a WebDAV HTTP Response (ala HTTP::Response)

=head1 SYNOPSIS

require HTTP::DAV::Response;

=head1 DESCRIPTION

The HTTP::DAV::Response class encapsulates HTTP style responses.  A response consists of a response line, some headers, and (potentially empty) content. 

HTTP::DAV::Response is a subclass of C<HTTP::Response> and therefore inherits its methods.  (HTTP::Response in turn inherits it's methods from C<HTTP::Message>).

Therefore, this class actually inherits a rich library of functions. You are more likely wanting to read the C<HTTP::Response> class as opposed to this class.

Instances of this class are usually created by a C<HTTP::DAV::Resource> object after it has performed some request (such as get, lock, delete, etc). You use the object to analyse the success or otherwise of the request.

HTTP::DAV::Response was created to handle two extra functions that normal HTTP Responses don't require:

 - WebDAV responses have 6 extra error codes: 102, 207, 422, 423, 424 and 507. Older versions of the LWP's C<HTTP::Status> class did not have these extra codes. These were added.

 - WebDAV responses can actually contain more than one response (and often DO contain more than one) in the form of a "Multistatus". These multistatus responses come in the form of an XML document. HTTP::DAV::Response can accurately parse these XML responses and emulate the normal of the C<HTTP::Response>.

HTTP::DAV::Response transparently implements these extra features without the user having to be aware, so you really should be reading the C<HTTP::Response> documentation for most of the things you want to do (have I already said that?).

There are only a handful of custom functions that HTTP::DAV::Response returns and those are to handle multistatus requests, C<messages()> and C<codes()>.

The six extra status codes that DAV servers can be returned in an HTTP Response are:
  102 => "Processing. Server has accepted the request, but has not yet completed it",
  207 => "Multistatus",
  422 => "Unprocessable Entity. Bad client XML sent?",
  423 => "Locked. The source or destination resource is locked",
  424 => "Failed Dependency",
  507 => "Insufficient Storage. The server is unable to store the request",

See C<HTTP::Status> for the rest.

=head1 HANDLING A MULTISTATUS 

So, many DAV requests may return a multistatus ("207 multistatus") instead of, say, "200 OK" or "403 Forbidden".

The HTTP::DAV::Response object stores each "response" sent back in the multistatus. You access them by array number.

The following code snippet shows what you will normally want to do:

...
$response = $resource->lock();

if ( $response->is_multistatus() ) {

   foreach $num ( 0 .. $response->response_count() ) {
      ($err_code,$mesg,$url,$desc) = 
         $response->response_bynum($num);
      print "$mesg ($err_code) for $url\n";
   }
}

Would produce something like this:
   Failed Dependency (424) for /test/directory
   Locked (423) for /test/directory/file3

This says that we couldn't lock /test/directory 
because file3 which exists inside is already locked by somebody else.

=head1 METHODS

=over 4 

=item B<is_multistatus>

This function takes no arguments and returns a 1 or a 0.

For example: if ($response->is_multistatus() ) { }

If the HTTP reply had "207 Multistatus" in the header then that indicates that there are multiple status messages in the XML content that was returned.

In this event, you may be interested in knowing what the individual messages were. To do this you would then use C<messages>. 

=item B<response_count>

Takes no arguments and returns "the number of error responses -1" that we got.
Why -1? Because usually you will want to use this like an array operator:

foreach $num ( 0 .. $response->response_count() ) { 
   print $response->message_bynum();
}

=item B<response_bynum>

Takes one argument, the "response number" that you're interested in. And returns an array of details:

   ($code,$message,$url,$description) = response_bynum(2);

where 
   $code - is the HTTP error code (e.g. 403, 423, etc).
   $message - is the associated message for that error code.
   $url - is the url that this error applies to (recall that there can be multiple responses within one response and they all relate to one URL)
   $description - is server's attempt at an english description of what happened.

=item B<code_bynum>

Takes one argument, the "response number" that you're interested in, and returns it's code. E.g:

  $code = $response->code_bynum(1);

See C<response_bynum()>

=item B<message_bynum>

Takes one argument, the "response number" that you're interested in, and returns it's message. E.g:

  $code = $response->message_bynum(1);

See C<response_bynum()>

=item B<url_bynum>

Takes one argument, the "response number" that you're interested in, and returns it's url. E.g:

  $code = $response->message_bynum(1);

See C<response_bynum()>

=item B<description_bynum>

Takes one argument, the "response number" that you're interested in, and returns it's description. E.g:

  $code = $response->message_description(1);

See C<response_bynum()>

=item B<messages>

Takes no arguments and returns all of the messages returned in a multistatus response. If called in a scalar context then all of the messages will be returned joined together by newlines. If called in an array context the messages will be returned as an array.

$messages = $response->messages();
e.g. $messages eq "Forbidden\nLocked";

@messages = $response->messages();
e.g. @messages eq ["Forbidden", "Locked"];

This routine is a variant on the standard C<HTTP::Response> C<message()>. 

=back

=cut

