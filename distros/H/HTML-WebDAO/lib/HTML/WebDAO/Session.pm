#$Id: Session.pm 292 2008-06-15 08:24:28Z zag $

package HTML::WebDAO::Session;
use HTML::WebDAO::Base;
use HTML::WebDAO::CVcgi;
use HTML::WebDAO::Store::Abstract;
use HTML::WebDAO::Response;
use Data::Dumper;
use base qw( HTML::WebDAO::Base );
use Encode qw(encode decode is_utf8);
use strict;
__PACKAGE__->attributes
  qw( Cgi_obj Cgi_env U_id Header Params  _store_obj _response_obj _is_absolute_url);

sub _init() {
    my $self = shift;
    $self->Init(@_);
    return 1;
}

#Need to be forever called from over classes;
sub Init {

    #Parametrs is realm
    my $self = shift;
    my %args = @_;
    Header $self ( {} );
    U_id $self undef;
    Cgi_obj $self $args{cv}
      || new HTML::WebDAO::CVcgi::;    #create default controller
    my $cv = $self->Cgi_obj;           # Store Cgi_obj in local var
                                       #create response object
    $self->_response_obj(
        new HTML::WebDAO::Response::
          session => $self,
        cv => $cv
    );
    _store_obj $self ( $args{store} || new HTML::WebDAO::Store::Abstract:: );

    #workaround for CGI.pm: http://rt.cpan.org/Ticket/Display.html?id=36435
    my %accept = ();
    if ( $cv->http('accept') ) {
        %accept = map { $_ => $cv->Accept($_) } $cv->Accept();
    }
    Cgi_env $self (
        {
            url => $cv->url( -base => 1 ),    #http://eng.zag
            path_info         => $cv->url( -absolute => 1, -path_info => 1 ),
            path_info_elments => [],
            file              => "",
            base_url     => $cv->url( -base => 1 ),    #http://base.com
            query_string => $cv->query_string,
            referer      => $cv->referer(),
            accept       => \%accept
        }
    );

    #fix CGI.pm bug http://rt.cpan.org/Ticket/Display.html?id=25908
    $self->Cgi_env->{path_info} =~ s/\?.*//s;
    $self->get_id;
    Params $self ( $self->_get_params() );
    $self->Cgi_env->{path_info_elments} =
      [ grep { defined $_ } split( /\//, $self->Cgi_env->{path_info} ) ];

}

#Can be overlap if you choose another
#alghoritm generate unique session ID (i.e cookie,http_auth)
sub get_id {
    my $self = shift;
    my $coo  = U_id $self;
    return $coo if ($coo);
    return rand(100);
}

=head2 call_path [$url]

Return ref to array of element from $url or from CGI ENV

=cut

sub call_path {
    my $self = shift;
    my $url = shift || return $self->Cgi_env->{path_info_elments};
    $url =~ s%^/%%;
    $url =~ s%/$%%;
    return [ grep { defined $_ } split( /\//, $url ) ];

}

=head2  set_absolute_url 1|0

Set flag for build absolute pathes. Return previus value.

=cut

sub set_absolute_url {
    my $self       = shift;
    my $value      = shift;
    my $prev_value = $self->_is_absolute_url;
    $self->_is_absolute_url($value) if defined $value;
    return $prev_value;
}

sub _load_attributes_by_path {
    my $self = shift;
    $self->_store_obj->_load_attributes( $self->get_id(), @_ );
}

sub _store_attributes_by_path {
    my $self = shift;
    $self->_store_obj->_store_attributes( $self->get_id(), @_ );
}

sub flush_session {
    my $self = shift;
    $self->_store_obj->flush( $self->get_id() );
}

sub response_obj {
    my $self = shift;
    return $self->_response_obj;
}

#Session interface to device(HTTP protocol) specific function
#$self->SendEvent("_sess_servise",{
#		funct 	=> geturl,
#		par	=> $ref,
#		result	=> \$res
#});

sub sess_servise {
    my ( $self, $event_name, $par ) = @_;
    my %service = (
        geturl  => sub { $self->sess_servise_geturl(@_) },
        getenv  => sub { $self->sess_servise_getenv(@_) },
        getsess => sub { return $self },
    );
    if ( exists( $service{ $par->{funct} } ) ) {
        ${ $par->{result} } = $service{ $par->{funct} }->( $par->{par} );
    }
    else {
        logmsgs $self "not exist request funct !" . $par->{funct};
    }
}

#
#{variable=>{
#			name=>Par,
#			value=>"10"},
#event	=>{
#			name=>"_info_on",
#			value=>"10"
#			}})
sub sess_servise_geturl {
    my ( $self, $par ) = @_;
    my $str;
    $str = $par->{path} || '';
    if ( exists( $par->{event} ) ) {
        $str .= "ev/evn_"
          . $par->{event}->{name} . "/"
          . $par->{event}->{value} . "/";
    }
    if ( exists( $par->{variable} ) ) {
        $par->{variable}->{name} =~ s/\./\//g;
        $str .= "par/"
          . $par->{variable}->{name} . "/"
          . $par->{variable}->{value} . "/";
    }
    $str .= ( exists( $par->{file} ) ) ? $par->{file} : $self->Cgi_env->{file};
    if ( ref( $par->{pars} ) eq 'HASH' ) {
        my @pars;
        while ( my ( $key, $val ) = each %{ $par->{pars} } ) {
            push @pars, "$key=$val";
        }
        $str .= "?" . join "&" => @pars;
    }

    #set absolute path
    $str = $self->Cgi_env->{base_url} . $str if $self->set_absolute_url;
    return $str;
}

#get current session enviro-ent
sub sess_servise_getenv {
    my ($self) = @_;
    return $self->Cgi_env;
}

sub response {
    my $self = shift;
    my $res  = shift;

    #    unless $res->type
    return if $res->{cleared};
    my $headers = $self->Header();
    $headers->{-TYPE} = $res->{type} if $res->{type};
    while ( my ( $key, $val ) = each %$headers ) {
        my $UKey = uc $key;
        $res->{headers}->{$UKey} = $headers->{$UKey}
          unless exists $res->{headers}->{$UKey};
    }

    #    $res->{headers} = $headers;
    $self->Cgi_obj->response($res);
}

sub print {
    my $self = shift;
    $self->Cgi_obj->print(@_);
}

sub ExecEngine() {
    my ( $self, $eng_ref ) = @_;

    #print $self->print_header();
    $eng_ref->RegEvent( $self, "_sess_servise", \&sess_servise );
    $eng_ref->Work($self);
    $eng_ref->SendEvent("_sess_ended");

    #print @{$eng_ref->Fetch()};
    $eng_ref->_destroy;
    $self->flush_session();

}

#for setup Output headers
sub set_header {
    my $self     = shift;
    my $response = $self->response_obj;
    return $self->response_obj->set_header(@_)

}

#Get cgi params;
sub _get_params {
    my $self = shift;
    my $_cgi = $self->Cgi_obj();
    my %params;
    foreach my $i ( $_cgi->param() ) {
        my @all = $_cgi->param($i);
        foreach my $value (@all) {
            next if ref $value;
            $value = decode( 'utf8', $value ) unless is_utf8($value);
        }
        $params{$i} = scalar @all > 1 ? \@all : $all[0];
    }
    return \%params;
}

sub print_header() {
    my ($self) = @_;
    my $_cgi   = $self->Cgi_obj();
    my $ref    = $self->Header();
    return $self->response( { data => '', } );
    return $_cgi->header( map { $_ => $ref->{$_} } keys %{ $self->Header() } );
}

sub destroy {
    my $self = shift;
    $self->_response_obj(undef);
}
1;
