=head1 NAME

DynGig::RCE::Access - Process query for RCE server/client

=cut
package DynGig::RCE::Query;

use warnings;
use strict;
use Carp;

use YAML::XS;
use Compress::Zlib;

=head1 SYNOPSIS

 use DynGig::RCE::Query;

 my $query = DynGig::RCE::Query->new
 (
     client => \%client_information,
     query =>
     [ 
         query1 => { $code1, $param1 },
         query2 => { $code2, $param2 },
         ...
     ],
 );
 
 my $compressed_query = $query->zip();

 my $string = $query->serial();

 my @query = $query->query();

 my $uncompressed = DynGig::RCE::Query::unzip( $compressed_query );

=cut
sub new
{
    my ( $class, %param ) = @_;

    croak 'query not defined' unless my $query = $param{query};

    my $error = 'invalid definition for';
    $param{query} = [ $query ] if ref $query ne 'ARRAY';

    map { croak "$error query" unless ref $_ eq 'HASH' && defined $_->{code} }
        @{ $param{query} };

    bless \%param, ref $class || $class;
}

sub query
{
    my $this = shift;
    my $query = $this->{query};

    return wantarray ? @$query : $query;
}

sub serial
{
    my $this = shift;
    my $serial = $this->{client} ? YAML::XS::Dump $this->{client} : '';

    $serial .= YAML::XS::Dump @{ $this->{query} };
}

sub zip
{
    my ( $this, $nozip )  = @_;

    my $serial = YAML::XS::Dump $this;

    return $serial if $nozip;
    return Compress::Zlib::compress( $serial ) unless @_;
    return Compress::Zlib::compress( $serial, @_ );
}

sub unzip
{
    return undef unless my $unzip = Compress::Zlib::uncompress( $_[0] );
    return undef unless my $this = eval { YAML::XS::Load $unzip };
    return ref $this eq __PACKAGE__ ? $this : undef;
}

=head1 NOTE

See DynGig::RCE

=cut

1;

__END__
