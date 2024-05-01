package t::TestAuditLogger;
use base 'Test::Builder::Module';

our $VERSION = '2.0.19';

sub new {

    my $obj = { _logs => [] };
    return bless $obj, shift;
}

sub log {
    my ( $self, $req, %fields ) = @_;

    $fields{req}->{id} = $req->request_id;

    push @{ $self->{_logs} }, {%fields};
}

sub loggrep {
    my ( $object, %matches ) = @_;
    while ( my ( $key, $value ) = each(%matches) ) {
        if ( $object->{$key} ne $value ) {
            return 0;
        }
    }
    return 1;
}

sub contains {
    my ( $self, %matches ) = @_;
    my $found = 0;
    my $str_matches =
      join( ', ', map { "$_=$matches{$_}" } sort keys %matches );
    $self->builder->ok(
        scalar grep( { loggrep( $_, %matches ) } @{ $self->{_logs} } ),
        "Found $str_matches in audit logs" );
}

sub logs {
    my ($self) = @_;
    return $self->{_logs};
}

1;
