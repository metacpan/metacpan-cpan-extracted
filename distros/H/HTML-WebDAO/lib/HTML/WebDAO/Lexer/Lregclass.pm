#$Id: Lregclass.pm 106 2007-06-25 10:35:07Z zag $

package HTML::WebDAO::Lexer::Lregclass;
use HTML::WebDAO::Lexer::Lbase;
use Data::Dumper;
use base qw( HTML::WebDAO::Lexer::Lobject );
use strict;

sub Init {
    my $self = shift;
    my %par  = @_;
    if ( my $context = $par{context} ) {
        push @{ $context->auto }, $self;
    }
    $self->SUPER::Init(@_);
}

sub get_self {
    return undef;
}

sub value {
    my $self = shift;
    my $eng  = shift;
    my $par  = $self->all;
    my ( $class, $alias ) = @$par{qw/class alias/};
    unless ( $class && $alias ) {
        _log1 $self "Syntax error: regclass - not initialized class or alias";
        return;
    }
    if ( my $error_str = $eng->register_class( $class => $alias ) ) {
        _log1 $self $error_str;
    }

}

1;
