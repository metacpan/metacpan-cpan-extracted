#$Id: CVapache2.pm 97 2007-06-17 13:18:56Z zag $

package HTML::WebDAO::CVapache2;
use HTML::WebDAO::Base;
use CGI;
use Data::Dumper;
use strict;
use warnings;

use base qw( HTML::WebDAO::Base );
#__PACKAGE__->
attributes qw ( _req _cgi );

my %met2sub =(
        url =>sub { return 'http://site.zag'},
#        path_info =>sub { $r->uri},
    );
sub _init {
    my $self = shift;
    my $r = shift || return;
    _req $self  $r;
    _cgi $self new CGI::;
    return 1;
}
#path_info param url header
sub path_info {
    my $self = shift;
    return $self->_req->uri
}
sub param {
    my $self = shift;
    return $self->_cgi->param(@_)
}
sub response {
    my $self = shift;
    my $res = shift || return;
#    $self->_log1(Dumper(\$res));
#    $self->_log1($r);
    my $r = $self->_req;
#    $self->_log1($r);
    while ( my ($key,$val) = each %{$res->{headers}}) {
        for ($key) {
            /-TYPE/ && do { 
                #$r->headers_out->add('Content-Type', 'text/html' );
#                $self->_log1("type".$val);
                $r->content_type($val) 
                }
                ||
            /-COOKIE/ && do { 
               $r->headers_out->add( 'Set-Cookie', $val->as_string )
            } ||
            /Last-Modified/i && do {
                $r->headers_out->add( $key, $val )
            }
        }
    }
#    $r->content_type($res->{type});
    if ($res->{file}) {
        $r->sendfile($res->{file})
    } else {
        print $res->{data};
    }
}
sub print {
    my $self = shift;
    print @_;
}

sub get_cookie {
    my $self = shift;
    return $self->_cgi->cookie(@_)
}

sub header {
    my $self = shift;
    return $self->_cgi->header(@_)
}
sub AUTOLOAD { 
    my $self = shift;
    return if $HTML::WebDAO::CVapache2::AUTOLOAD =~ /::DESTROY$/;
    ( my $auto_sub ) = $HTML::WebDAO::CVapache2::AUTOLOAD =~ /.*::(.*)/;
#    print STDERR  "$self do $auto_sub ";
    $self->_log2("sub $auto_sub not handle in ".__PACKAGE__."called from\n".Dumper([map {[caller($_)]} (1..6)])) unless my $sub = $met2sub{$auto_sub};
    return  $sub->(@_)
#    die "errrr"
}
1;
