#$Id: SessionSH.pm 97 2007-06-17 13:18:56Z zag $

package HTML::WebDAO::SessionSH;
use strict;
use warnings;
use HTML::WebDAO::Base;
use HTML::WebDAO::Session;
use Data::Dumper;
use base qw( HTML::WebDAO::Session );

#Need to be forever called from over classes;
sub Init {
    my $self = shift;
    my %args = @_;
    $self->SUPER::Init(@_);
    delete $args{store};
    Params $self ( \%args );
}

#Can be overlap if you choose another
#alghoritm generate unique session ID (i.e cookie,http_auth)
sub ___get_id {
    die "aaa";
    return rand(100);
}

sub print_header() {
    return ''
}

sub sess_servise {
    my $self= shift;
    return $self->SUPER::sess_servise(@_)

}

sub ExecEngine() {
    my ( $self, $eng_ref ) = @_;
    $eng_ref->RegEvent( $self, "_sess_servise", \&sess_servise );

    #print $self->print_header();
#    $eng_ref->Work($self);

    #print @{$eng_ref->Fetch()};
#    $self->store_session($eng_ref);
#    $eng_ref->_destroy;
}

1;
