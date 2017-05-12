#$Id: Lmethod.pm 97 2007-06-17 13:18:56Z zag $

package HTML::WebDAO::Lexer::Lmethod;
use HTML::WebDAO::Lexer::Lobject;
use Data::Dumper;
use base qw( HTML::WebDAO::Lexer::Lobject );
use strict;

sub Init {
    my $self = shift;
    my %pars = @_;
    unless ( exists( $pars{path} ) ) {
        _log1 $self "tag method need attribute 'path'!";
        return;
    }
    return $self->SUPER::Init( @_, id => "none", class => "_method_call" );
}

sub value {
    my $self = shift;
    my $eng  = shift;
    my $par  = $self->all;
    my @val  = map { $_->value($eng) } @{ $self->childs };
    if ($eng) {
        my $object =
          $eng->_createObj( "none", "_method_call", $par->{path}, @val );
        _log1 $self "create_obj fail for class: "
          . $par->{class}
          . " ,id: "
          . $par->{id}
          unless $object;
        return $object;
    }
    return {"Object ( "
          . ( join ",", map { "$_ => " . $par->{$_} } keys %{$par} )
          . ")" => \@val };
}

1;

