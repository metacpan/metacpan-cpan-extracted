package MasonX::Request::HTMLTemplate::WithApacheSession;

use MasonX::Request::WithApacheSession;
use MasonX::Request::HTMLTemplate;
use Data::Dumper;
use base qw(MasonX::Request::HTMLTemplate MasonX::Request::WithApacheSession);

$MasonX::Request::HTMLTemplate::WithApacheSession::VERSION	= '0.04';


sub _alter_superclass() { 
	# overload static parent method
    return     $MasonX::Request::WithApacheSession::VERSION 
               ? 'MasonX::Request::WithApacheSession' 
               :   $HTML::Mason::ApacheHandler::VERSION
                    ? 'HTML::Mason::Request::ApacheHandler'
                    : $HTML::Mason::CGIHandler::VERSION 
                        ? 'HTML::Mason::Request::CGI'
                        : 'HTML::Mason::Request';
}

sub items {
	# overload parent method to add session variables
	my $self 		= shift;
	my $ret		= {};
	my $sessionStruct;
	if ($self->can('session')) {
		# Running under MasonX::Request::WithApacheSession
		if (defined $self->session) {
			# clone hashref by val
			my $session = { %{$self->session} };
			# remove hidden MasonX::Request::WithApacheSession variables
			delete $$session{'___force_a_write___'};
			delete $$session{'_session_id'};
			&_convStructToHash($session,\$sessionStruct,'');
		}
	}
	return $self->SUPER::items($sessionStruct);
}

sub _convStructToHash {
  # convert a struct
  # { keya = {
  #               keyb => {
  #                   keyc => value, ...
  # in
  # { keya_keyb_keyc => value
  my $hashOrig        = shift;
  my $hashDest        = shift;
  my $parentKey       = shift;
  while (my($key,$value) = each(%{$hashOrig})) {
    my $gkey = $parentKey eq '' ? $key :  $parentKey . '_' . $key ;
    #print $gkey . " " . (Data::Dumper::Dumper($value));
    if (ref($value) eq "HASH") {
			&_convStructToHash($value,$hashDest,$gkey);
    } else {
			$$hashDest->{$gkey} = $value;
    }
  }
}


1;
