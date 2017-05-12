package Games::Perlwar::Cell;

use strict;
use warnings;
use Carp;

our $VERSION = '0.03';
use Class::Std;

use Games::Perlwar::AgentEval;

my %owner_of          : ATTR( :name<owner> :default<undef> );
my %facade_of         : ATTR( :set<facade> :init_arg<facade> :default<undef>);
my %code_of           : ATTR( :get<code> :init_arg<code> :default<undef> );
my %operational_of    : ATTR( :name<operational> :default<1> );

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub run {
    my ( $self, $vars ) = @_;
    my %vars;
    %vars = %$vars if $vars;

    return Games::Perlwar::AgentEval->new({
        code => $self->get_code,
        vars => { 
            %vars,
            '$o' => $self->get_facade,
            '$O' => $self->get_owner,
        }
    });

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_code {
    my ( $self, $code ) = @_;
    my $id = ident $self;

    $code = '' if !$code or $code =~ /^\s*$/;

    $code_of{ $id } = $code;

    unless( $code ) {
        $self->set_owner( undef );
        $self->set_facade( undef );
    }

    return $self;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_facade {
    my $self = shift;
    my $id = ident $self;

    return $facade_of{ $id } || $owner_of{ $id };
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub set {
    my( $self, $ref_args ) = @_;
    my $id = ident $self;

    my %args = %$ref_args;

    $self->set_owner( $args{owner} ) if $args{owner};
    $self->set_facade( $args{apparent_owner} ) if $args{apparent_owner};
    $self->set_code( $args{code} ) if $args{code};
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub is_empty {
    my $self = shift;
    my $id = ident $self;

    return !$code_of{ $id };
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub delete {
    my ( $self ) = @_;
    $self->set_code( undef );
}

sub clear { $_[0]->delete; }

sub insert {
    my ( $self, $ref_args ) = @_;
    my $id = ident $self;

    $self->set_owner( $ref_args->{ owner } );
    $self->set_facade( $ref_args->{ apparent_owner } );
    $self->set_code( $ref_args->{ code } );
}

sub copy {
    my ( $self, $original ) = @_;
    my $id = ident $self;

    $self->set_owner( $original->get_owner );
    $self->set_facade( $original->get_facade );
    $self->set_code( $original->get_code );
}

sub save_as_xml {
    die "obsolete";
    my( $self, $writer ) = @_;
    my $id = ident $self;

    $writer->dataElement( owner => $self->get_owner );
    $writer->dataElement( facade => $self->get_facade );
    $writer->dataElement( code => $self->get_code );
}




1;
