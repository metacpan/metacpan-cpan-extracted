package MetaStore::Response;

#$Id$

use Data::Dumper;
use WebDAO::Response;
use JSON;
use WebDAO;
use base qw( WebDAO::Response );
mk_attr ( __json=>undef, __html=>undef, __xml=>undef);
our $VERSION = '0.1';

use strict;

=head1 NAME

MetaStore::Response - Response class

=head1 SYNOPSIS

  use MetaStore::Response;

=head1 DESCRIPTION

Class for set response headers. Add functionality to return context.

=head1 METHODS

=cut

=head2 json 

=cut

sub json : lvalue {
    my $self = shift;
    $self->{__json};
}


sub raw : lvalue {
    my $self = shift;
    $self->{__raw};
}

sub html : lvalue {
    my $self = shift;
    $self->{__html};
}

sub xml : lvalue {
    my $self = shift;
    $self->{__xml};
}

sub js : lvalue {
    my $self = shift;
    $self->{__jscript};
}

sub _print_dep_on_context {
    my ( $self, $session ) = @_;
    my $accept = $self->get_request->accept;
    my $res ;
    if ( exists $accept->{'application/javascript'} ) {
        $res = $self->json;
        $res = to_json($res) unless  ref($res) eq 'CODE';
    } else {
        $res = $self->html
    }
    #print if defined result
    $self->print( ref($res) eq 'CODE' ? $res->() : $res ) if defined $res;
}

sub _destroy {
    my $self = shift;
    $self->{__js} = undef;
    $self->{__json} = undef;
    $self->{__html} = undef;
    $self->{__xml} = undef;
    $self->{__raw}= undef; 
#    $self->auto( [] );
}
1;
__END__

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=cut

