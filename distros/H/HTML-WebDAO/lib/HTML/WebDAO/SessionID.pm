#$Id: SessionID.pm 97 2007-06-17 13:18:56Z zag $
package HTML::WebDAO::SessionID;
use HTML::WebDAO::Base;
use CGI;
use Data::Dumper;
use MIME::Base64;
use base qw( HTML::WebDAO::Sessionco);

use strict 'vars';

sub sess_servise_geturl{
    my $self = shift;
    my $str = $self->SUPER::sess_servise_geturl(@_);
    return "/sess_".$self->get_id.$str
}

sub get_id {
my $self=shift;
my $coo=U_id $self;
return $coo if ($coo);
($coo)=$self->Cgi_env->{path_info}=~m/sess_(\d{7})/;
$self->Cgi_env->{path_info}=~s/sess_(\d{7})//;
$coo ||= do {
	my $tmp=substr(time(),-7,7);
#	$self->Cgi_env->{path_info}.="sess_$tmp/";
	$tmp
	};
U_id $self $coo;
return $coo;
}
1;
__END__
