package Business::FedEx::ShipRequest;

use LWP::Simple;

use Business::FedEx;
use Business::FedEx::Constants qw(:all);

our @ISA = qw(Business::FedEx);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.01';

our $errstr = "";
our $err = 0;


#--/-INIT ARGS-/-------------------------------------------------------#
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;  
  my %args = (transaction_id => '32826482',              #--/-REQUIRED - Any number you want - used for error tracking
	      account_number => '',                      #--/-REQUIRED - Your 9 digit FedEx Account number
	      weight => '',                              #--/-REQUIRED
	      weight_units =>'LBS',
	      service => '1',
	      special_services => '',
	      ship_date => '',
	      declared_value => '',
	      cod_flag => 'N',
	      cod_amount => '',
	      cod_cashiers_check => '',
	      special_services => 'NNNNNNNNNNNNN',
	      dry_ice_weight => '',
	      meter_number => '',                        #--/-REQUIRED - Your 7 digit FedEx meter number
	      gif_label => '400',
	      tracking_num => '',

	      shipper_name => '',                        #--/-REQUIRED - 
	      shipper_company => '',                      #--/-REQUIRED - 
	      shipper_address1 => '',                    #--/-REQUIRED - 
	      shipper_address2 => '',
	      shipper_city => '',                        #--/-REQUIRED - 
	      shipper_zip_code => '',                    #--/-REQUIRED - 
	      shipper_state => '',                       #--/-REQUIRED - 
	      shipper_phone => '',                       #--/-REQUIRED - 
	      
	      dest_company => '',                        #--/-REQUIRED - 
	      dest_address1 => '',                       #--/-REQUIRED - 
	      dest_address2 => '',
	      dest_city => '',                           #--/-REQUIRED - 
	      dest_zip_code => '',                       #--/-REQUIRED - 
	      dest_state => '',                          #--/-REQUIRED - 
	      dest_phone => '',                           #--/-REQUIRED - 
	      recipient_department => '',                
	      payor_account_number => '',                #--/-REQUIRED - 10 digit fedex account # of payor
	      payment_code => '1',                       #--/-REQUIRED - 
	      reference_info => '',
	      signature_release_flag => 'N',
	      #
	      hal_station_address1 => '',
	      hal_city => '',
	      hal_state => '',
	      hal_zip_code => '',
	      pkg_height => '',
	      pkg_width => '', 
	      pkg_length => '',
	      dim_units => '',
	      future_day_ship => '',
	      dest_country_code => 'US',
	      ult_dest_country_code => 'US',
	      shipper_country_code => 'US',
	      #INTERNATIONAL ONLY-----
	      duties_pay_type => '',
	      duties_account_num => '',
	      pkg_description => '',
	      manufacture_country_code => '',
	      currency_type => '',
	      carriage_value => '',
	      unit_weight1 => '',
	      unit_value1 => '',
	      quantity1 => '',
	      unit_measure1 => '',
	      #local_ship_time => '',
	      customs_value => '',
	      ein_num => '',
	      commercial_invoice_flag => '',
	      hal_phone => '',
	      @_);
  my $self = $class->SUPER::new(%args);
  return $self;
}

sub DESTROY {
  #  warn "DESTROYING: ", ref(shift), "\n";
}

{

  #--/-REQUEST A SHIPMENT-/--------------------------------------#
  sub ship{    
    my $self = shift;
    my ($username, $password, $url, $trans_type) = @_;
    my $response;
    my $gif_data;
    my %types = (domestic=>'0,"1"',international=>'0,"51"');
    my $buf = ($types{$trans_type} || '0,"1"');
    my $field;
    my $response;
    my $value;
    my $gif;
    my $data;
    my $finish_data;
    my $tmp_hex = '';
    my $count = 0;
    my @fedex_response;
    my @field_data;
    my $tmpbuf = 'abc';

    my @Keys = keys(%$self);
    foreach(@Keys){
      $field = join(',',eval(uc($_)),'"'.$self->{$_}.'"');
      $buf = $buf.$field;
    }
    
    #--/-SEND OUT REQUEST TO FEDEX THROUGH SHIPAPI OR VIA PROXY (fedex.pl)-/-----------------#
    $response = $self->_send_buf($url, $buf, $username, $password);#get($args);
    
    $response =~ m/(.*188,)(.*)(99.*)/;
    #@fedex_response = split(/\"\w+,\"/,$response);
    @fedex_response = split(//,$response);
    foreach(@fedex_response){
      #Grab Buffer Before GIF data
      if(! ($data =~ /188,\"/i)){
	if((! ($_ =~ / /))&&(! ($_ =~ /\n/))){
	  $data = $data.$_;
	  $field_data[$count] = $field_data[$count].$_;
	  if($field_data[$count] =~ /\d+,\"\w*\"/){
	    $count++;
	  }
	}
      }else{
	#Grab Buffer After GIF data
	if($_ =~ /\"/){$finish_data = 1;}
	if(($finish_data == 1)&&($_ ne ' ')){
	  $data = $data.$_;
	  $field_data[$count] = $field_data[$count].$_;
	  if($field_data[$count] =~ /\d+,\"\w*\"/){
	    $count++;
	  }
	}else{
	  $raw_gif = $raw_gif.$_;
	  #Parse GIF Buffer (Escape seq = '%'), Refer to FedEx API for limmited details.
	  #The following is VERY touchy. Please backup before editing!
	  if($_ eq '%'){
	    $tmp_hex = '0x';
	  }else{
	    if($tmp_hex eq '0x'){
	      $tmp_hex = $tmp_hex.$_;
	    }else{
	      if($tmp_hex =~ /0x\w/){
		$tmp_hex = $tmp_hex.$_;
		if(chr(hex($tmp_hex)) eq '"'){
		  #print '"';
		  $gif_data = $gif_data.'"';
		}else{
		  if(chr(hex($tmp_hex)) eq ' '){
		    #print '%00';
		    $gif_data = $gif_data.'%00';
		  }else{
		    if(chr(hex($tmp_hex)) eq '%'){
		      #print '%';
		      $gif_data = $gif_data.'%';
		    }else{
		      #print chr(hex($tmp_hex));
		      $gif_data = $gif_data.chr(hex($tmp_hex));
		    }
		  }
		}
		$tmp_hex = '';
	      }else{
		if($_ eq ' '){
		  #print $_;
		  $gif_data = $gif_data.$_
		}else{
		  if($_ eq '%'){
		    #print '%25';
		    $gif_data = $gif_data.'%25';
		  }else{
		    #print $_;
		    $gif_data = $gif_data.$_;
		  }
		}
	      }
	    }
	  }
	}
      }
    }
    $self->{'gif_data'} = $gif_data;
    $self->{'raw_gif'} = $raw_gif;
    #--Set The Private Variables--#
    foreach(@field_data){
      ($field,$value) = split(/\,/,$_);
      if(eval('FE'."$field")){
	$value =~ s/\"//g;
	$self->{eval('FE'."$field")} = $value;
      }
    }
    #$self->_set_data($response);
  }

  #--/-GET A SHIPPING RATE-/--------------------------------------#
  sub rate{
    my $self = shift;
    my ($username, $password, $url, $transaction_type) = @_;
    my $response;
    my %types = (domestic=>'0,"2"',international=>'0,"52"');
    my $field;
    my $value;
    my $count = 0;
    #Transaction type: Request Rate
    my $buf = ($types{$transaction_type} || '0,"2"');
    my @fedex_response;
    my @field_data;
    my @Keys = keys(%$self);
    my $tmp;
    my $args;
    my $response;

    foreach(@Keys){
      $field = join(',',eval(uc($_)),'"'.$self->{$_}.'"');
      $buf = $buf.$field;
    } 
    $response = $self->_send_buf($url,$buf,$username,$password);
    #$response =~ s/\ //g;   
    #Group the buffer in a 'logical' sense (logical according to FedEx!)
    #Store the data in Private Vars
    $self->_set_data($response);

  }

  #--/-TRACK A FEDEX PACKAGE-/-----------------------------------#
  sub track{
    my $self = shift;
    my ($username, $password, $url, $tracking_num) = @_;
    my $buf = '0,"402"';
    my $field;
    my @fedex_response;
    my @field_data;
    my $count;
    my $response;

    $self->{tracking_num} = $tracking_num;
    my @Keys = keys(%$self);
    foreach(@Keys){
      $field = join(',',eval(uc($_)),'"'.$self->{$_}.'"');
      $buf = $buf.$field;
    } 
    $response = $self->_send_buf($url,$buf,$username,$password);        
    #Store the data in Private Vars
    $self->_set_data($response);
  }


  #--/-SEND BUFFER TO FEDEX-/------------------------------------#
  sub _send_buf{
    my $self = shift;
    my ($url,$buf,$username,$password) = @_;
    my $response;
    if(($url eq '')||($url eq 'localhost')){
      eval('use Business::FedEx::ShipAPI');
      my $fedex = Business::FedEx::ShipAPI->new(username=>$username, password=>$password);
      $buf = $buf.'99,""';
      $fedex->connect();
      $response = $fedex->transaction($buf);
      $fedex->disconnect();
      $fedex = undef;
    }else{
      $response = get("$url\?buf=\'$buf\'");
    }
    return $response;
  }  

  #--/-SET VALUES-/---------------------------------------------#
  sub _set_data{
    my $self = shift;
    my ($response) = @_;
    my @fedex_response;
    my @field_data;
    my $count;

    @fedex_response = split(//,$response);
    foreach(@fedex_response){
      $field_data[$count] = $field_data[$count].$_;
      if($field_data[$count] =~ /\d+,\".*\"$/){
	$count++;
      }
    }
    foreach(@field_data){
      ($field,$value) = split(/\,/,$_);
      if(eval('FE'."$field")){
	$value =~ s/\"//g;
	$self->{eval('FE'."$field")} = $value;
      }
    }
  }

  #--Helper function that formats the rate.
  sub _format_rate{
    (my $rate) = @_;
    my $dollars = substr($rate,0,-2);
    my $cents = substr($rate,-2);
    if(! $dollars){ 
      $dollars = 0;
    }
    $rate = join('.',$dollars,$cents);
    return $rate;
  }

  #--/-RETURN STORED VALUES-/------------------------------------#
  sub get_data{
    my $self = shift;
    my ($field) = @_;
    if($self->{$field}){
      if($field =~ /charge/){
	return _format_rate($self->{$field});
      }else{
	return $self->{$field};
      }
    }else{
      return $self->{'error_mesg'};
    }
  }


}

1;
__END__

=head1 NAME

Business::FedEx::ShipRequest - Shipping/Tracking Interface to FedEx

=head1 SYNOPSIS
 

ShipRequest gives you the ability to track, rate, and ship international and domestic packages via FedEx.


=head1 API

=head1 DESCRIPTION

Two ways to use ShipRequest.  If you are on a Win32 system, you can use ShipRequest directly (w/o using the proxy interface).  However, If you plan on using ShipRequest on any other platform, you MUST use the proxy interface.  Read 'USE PROXY' below for instructions.  

=head2 CREATE A SHIPPING OBJECT:

Refer to Business::FedEx::Constants or the FedEx ShipAPI documentation for the required fields.

     use Business::FedEx::ShipRequest;
     $s = Business::FedEx::ShipRequest->new(constant_name=>'value',constant_name2=>'value',etc...);


=head2 SHIP A PACKAGE:

     $s->ship('username','secret','localhost','domestic');
     $s->ship('username','secret','localhost','international');

=head2 RATE A PACKAGE:

     $s->rate('username','secret','localhost','domestic');
     $s->rate('username','secret','localhost','international');

=head2 TRACK A PACKAGE:

     $s->track('username','secret','localhost','123456789098');

=head2 USE PROXY:

In order to use fedex.pl (proxy interface), you must install Business::FedEx on a Win32 web server and put the fedex.pl script in Win32's cgi-bin.  You can then make a ShipRequest from any box just by including the url in the method call (instead of 'localhost').

     $s->ship('username','secret','http://www.hostname.com/cgi-bin/fedex.pl','domestic');

=head2 GET REPLY INFO:

Refer to Business::FedEx::Constants for constant_name information or refer to the FedEx ShipAPI documentation.

$data = $s->get_data('constant_name');


=head2 EXPORT

None by default.

=head1 AUTHOR

Patrick Tully, ptully@avatartech.com

=head1 SEE ALSO

Business::FedEx

Business::FedEx::Constants

Business::FedEx::ShipAPI

=cut
