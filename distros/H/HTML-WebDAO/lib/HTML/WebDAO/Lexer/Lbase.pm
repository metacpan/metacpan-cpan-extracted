#$Id: Lbase.pm 106 2007-06-25 10:35:07Z zag $

package HTML::WebDAO::Lexer::Lbase;
use HTML::WebDAO::Base;
use Data::Dumper;
use base qw( HTML::WebDAO::Base );
use strict;
__PACKAGE__->attributes qw/ all  /;

sub _init() {
    my $self = shift;
    return $self->Init(@_);
}

sub Init {
    #Parametrs is realm
    my $self = shift;
    my %par  = @_;
    delete $par{context};
    $self->all( \%par );
    return %par;
}

sub get_self {
    return $_[0];
}

sub childs {
    my $self = shift;
    return $self->all->{childs} || [];
}

sub value {
    my $self = shift;
    my $eng  = shift;
    my $par  = $self->all;
    my $res;
    if ( exists $par->{value} ) {
        $res = $par->{value};
    }
    else {
        my @val = @{ $self->childs }
          ? do {
            map { $_->value($eng) } @{ $self->childs };
          }
          : ();
        $res = @val > 1 ? \@val : $val[0];
    }
    return ( $par->{name}, $res );
}

1;

