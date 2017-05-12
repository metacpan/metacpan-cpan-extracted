package IDCHECKIO::Client;

#use strict;
use REST::Client;
use MIME::Base64;
use Cpanel::JSON::XS qw(encode_json);
use IDCHECKIO::ResponseIDCIO;
use JSON::Parse 'parse_json';


=head1 NAME

IDCHECKIO::Client - Client to use the IDCHECKIO API easily

=head1 SYNOPSIS

To complete

=head1 DESCRIPTION

...

=cut


our $VERSION = '0.04';

sub new {
  my $class = shift;
  my $self = {
    _user      => shift,
    _pwd       => shift,
    _language  => shift,
    _host      => shift,
    _protocol  => shift,
    _port      => shift,
    _verify    => shift,
  };
  $self->{_language} = "en" if !defined($self->{_language});
  $self->{_host} = "idcheck.io" if !defined($self->{_host});
  $self->{_protocol} = "https" if !defined($self->{_protocol});
  $self->{_port} = "443" if !defined($self->{_port});
  $self->{_verify} = "True" if !defined($self->{_verify});

  $self->{_client} = REST::Client->new();
  $self->{_client}->setHost("$self->{_protocol}://$self->{_host}:$self->{_port}");
  $self->{_client}->addHeader("Content-Type", "application/json");
  $self->{_client}->addHeader("Authorization", "");
  
  my $auth = encode_base64("$self->{_user}:$self->{_pwd}");
  $self->{_client}->addHeader("Content-Type", "application/json");
  $self->{_client}->addHeader("Authorization", "Basic $auth");
  $self->{_client}->addHeader("Accept-Language", "$self->{_language}");

  bless $self, $class;
  return $self;
}

sub analyse_mrz {
  my ( $self, $line1, $line2, $line3, $async ) = @_;
  $async = "False" if !defined($async);
  $line3 = "" if !defined($line3);  

  my $method = "/rest/v0/task/mrz";
  my $arguments = "?async=$async";
  my $url = "$method$arguments";

  my $data = {
    'line1' => $line1, 
    'line2' => $line2, 
    'line3' => $line3,
  };
  my $json_data = encode_json $data;

  my $result;
  $self->{_client}->POST($url, $json_data);
  my $json = parse_json($self->{_client}->responseContent());
  if( $self->{_client}->responseCode() eq '200' ){ 
    $result = IDCHECKIO::ResponseIDCIO->new($self->{_client}->responseCode(), $json->{uid}, $json);
  }
  else {
    $result = IDCHECKIO::ResponseIDCIO->new($self->{_client}->responseCode(), 0, $json);
  }
  return $result; 
}


sub analyse_image {
  my ( $self, $recto, $verso, $async, $base64 ) = @_;
  $async = "False" if !defined($async);
  $verso = "" if !defined($verso);
  $base64 = "False" if !defined($async);

  my $method = "/rest/v0/task/image";
  my $arguments = "?async=$async";
  my $url = "$method$arguments";
  
  my ( $frontImage, $backImage ) = ( "", "" );

  my $buffer;
  my $temp;
  my $encoded_recto = "";
  my $encoded_verso = "";
  if ( $base64 ){
    $encoded_recto = $recto;
    $encoded_verso = $verso;
  } else {
    seek($recto, 0, 0);
    binmode $recto;
    while ( read( $recto, $buffer, 4096 ) ) {
    #while ( read( INFILE, $buffer, 4096 ) ) {
      $temp = encode_base64($buffer, "");
      $encoded_recto = "$encoded_recto$temp";
    }
    if ( $verso != "" ){
      #open INFILE, '<', $verso or die "Unable to open file $verso";
      #binmode INFILE;
      seek($verso, 0, 0);
      binmode $verso;
      #while ( read( INFILE, $buffer, 4096 ) ) {
      while ( read( $verso, $buffer, 40096 ) ) {
        $temp = encode_base64($buffer, "");
        $encoded_verso = "$encoded_verso$temp";
      }
    }
  }
  my $data = {
    'frontImage' => $encoded_recto,
    'backImage'  => $encoded_verso,
  };
  my $json_data = encode_json $data;
  
  my $result;
  $self->{_client}->POST($url, $json_data);
  my $json = parse_json($self->{_client}->responseContent());
  if( $self->{_client}->responseCode() eq '200' ){
    $result = ResponseIDCIO->new($self->{_client}->responseCode(), $json->{uid}, $json); 
  }
  else {
    $result = ResponseIDCIO->new($self->{_client}->responseCode(), 0, $json);
  }
  return $result;
}


sub get_result {
  my ( $self, $uid, $rectoImageCropped, $faceImageCropped, $signatureImageCropped ) = @_;
  $rectoImageCropped = "False" if !defined($rectoImageCropped);
  $faceImageCropped = "False" if !defined($faceImageCropped);
  $signatureImageCropped = "False" if !defined($signatureImageCropped);

  my $method = "/rest/v0/result/";
  my $arguments = "?rectoImageCropped=$rectoImageCropped&faceImageCropped=$faceImageCropped&signatureImageCropped=$signatureImageCropped";
  my $url = "$method$uid/$arguments";

  my $result;
  $self->{_client}->GET($url);
  my $json = parse_json($self->{_client}->responseContent());
  if( $self->{_client}->responseCode() eq '200' ){
    $result = IDCHECKIO::ResponseIDCIO->new($self->{_client}->responseCode(), $json->{uid}, $json); 
  }
  else {
    $result = IDCHECKIO::ResponseIDCIO->new($self->{_client}->responseCode(), 0, $json);
  }
  return $result;
}

sub get_report {
  my ( $self, $uid, $path ) = @_;
  $path = "" if !defined($path);

  my $method = "/rest/v0/pdfreport/";
  my $arguments = "";
  my $url = "$method$uid$arguments";

  my $result;
  $self->{_client}->GET($url);
  my $json = parse_json($self->{_client}->responseContent());
  if( $self->{_client}->responseCode() eq '200' ){ 
    $result = IDCHECKIO::ResponseIDCIO->new($self->{_client}->responseCode(), $json->{uid}, $json);
  }
  else {
    $result = IDCHECKIO::ResponseIDCIO->new($self->{_client}->responseCode(), 0, $json);
  }
  return $result;
}

sub get_status {
  my ( $self, $uid, $wait ) = @_;
  $wait = 0 if !defined($wait);

  my $method = "/rest/v0/task/";
  my $arguments = "?wait=$wait";
  my $url = "$method$uid/$arguments";

  my $result;
  $self->{_client}->GET($url);
  my $json = parse_json($self->{_client}->responseContent());
  if( $self->{_client}->responseCode() eq '200' ){ 
    $result = IDCHECKIO::ResponseIDCIO->new($self->{_client}->responseCode(), $json->{uid}, $json);
  }
  else {
    $result = IDCHECKIO::ResponseIDCIO->new($self->{_client}->responseCode(), 0, $json);
  }
  return $result;
}

1;
