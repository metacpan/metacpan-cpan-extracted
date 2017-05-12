#$Id: Lobject.pm 97 2007-06-17 13:18:56Z zag $

package HTML::WebDAO::Lexer::Lobject;
use HTML::WebDAO::Lexer::Lbase;
use Data::Dumper;
use base qw( HTML::WebDAO::Lexer::Lbase );
use strict;

sub value {
    my $self = shift;
    my $eng = shift;
    my $par = $self->all;
    my @val = map { $_->value($eng) } @{ $self->childs } ;
    if ( $eng ) {
        my $object =  $eng->_createObj($par->{id},$par->{class}, @val);
        _log1 $self "create_obj fail for class: ".$par->{class}." ,id: ".$par->{id} unless $object;

    return $object
    }
    return {"Object ( ".( join ",",map {"$_ => ".$par->{$_}}  keys %{$par}).")"=>\@val}
}
1;

