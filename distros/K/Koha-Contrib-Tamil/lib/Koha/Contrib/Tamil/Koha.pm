package Koha::Contrib::Tamil::Koha;
#ABSTRACT: Class exposing info about a Koha instance.
$Koha::Contrib::Tamil::Koha::VERSION = '0.069';
use Moose;

use Modern::Perl;
use Carp;
use XML::Simple;
use DBI;
use ZOOM;
use MARC::Record;
use MARC::File::XML;
use YAML;
use C4::Biblio qw/ GetMarcBiblio /;
use Search::Elasticsearch;



has conf_file => ( is => 'rw', isa => 'Str' );



has dbh => ( is => 'rw' );



has conf => ( is => 'rw' );


has _zconn => ( is => 'rw', isa => 'HashRef' );

has es => ( is => 'rw' );

has es_index => ( is=> 'rw' );

has _old_marc_biblio_sub => ( is => 'rw', isa => 'Bool', default => 0 );


sub BUILD {
    my $self = shift;

    # Use KOHA_CONF environment variable by default
    $self->conf_file( $ENV{KOHA_CONF} )  unless $self->conf_file;

    $self->conf( XMLin( $self->conf_file, 
        keyattr => ['id'], forcearray => ['listen', 'server', 'serverinfo'],
        suppressempty => '     ') );

    # Database Handler
    my $c = $self->conf->{config};
    $self->dbh( DBI->connect(
        "DBI:"     . $c->{db_scheme} .
        ":dbname=" . $c->{database} .
        ";host="   . $c->{hostname} .
        ";port="   . $c->{port},
        $c->{user}, $c->{pass} )
    ) or carp $DBI::errstr;
    if ( $c->{db_scheme} eq 'mysql' ) {
        # Force utf8 communication between MySQL and koha
        $self->dbh->{ mysql_enable_utf8 } = 1;
        $self->dbh->do( "set NAMES 'utf8'" );
        $self->dbh->{ mysql_auto_reconnect } = 1;
        my $tz = $ENV{TZ};
        ($tz) and $self->dbh->do( qq(SET time_zone = "$tz") );
    }

    # Zebra connections 
    $self->_zconn( { biblio => undef, auth => undef } );

    # ElasticSearch
    if ( my $param = $c->{elasticsearch} ) {
        my $es = Search::Elasticsearch->new( nodes => $param->{server} );
        $self->es( $es );
        $self->es_index( {
            biblios     => $param->{index_name} . '_biblios',
            authorities => $param->{index_name} . '_authorities',
        } );
    }

    my $version = C4::Context->preference('Version');
    if ( $version =~ /^([0-9]{2})\.([0-9]{2})/ ) {
        $version = "$1.$2";
        $version += 0;
        $self->_old_marc_biblio_sub(1) if $version <= 17.05;
    }
    else {
        $self->_old_marc_biblio_sub(1);
    }

}



sub zconn_reset {
    my $self = shift;
    my $zcs = $self->_zconn;
    for my $server ( keys %$zcs ) {
        my $zc = $zcs->{$server};
        $zc->destroy() if $zc;
        undef $zcs->{$server};
    }
}



sub zconn {
    my ($self, $server) = @_;

    my $zc = $self->_zconn->{$server};
    #return $zc  if $zc && $zc->errcode() == 0 && $zc->_check();
    return $zc  if $zc;

    #FIXME: à réactiver pour s'assurer que de nouvelles connexion ne sont
    # créées inutilement.
    #print "zconn: nouvelle connexion\n";
    my $c        = $self->conf;
    my $name     = $server eq 'biblio' ? 'biblioserver' : 'authorityserver';
    my $syntax   = $c->{server}->{$name}->{retrievalinfo}->{retrieval};
    $syntax = [ grep { $_->{name} && $_->{name} eq 'F' && $_->{syntax} ne 'xml' } @$syntax ];
    $syntax = $syntax->[0]->{syntax};
    my $host     = $c->{listen}->{$name}->{content};
    my $user     = $c->{serverinfo}->{$name}->{user};
    my $password = $c->{serverinfo}->{$name}->{password};
    my $auth     = $user && $password;

    # set options
    my $o = new ZOOM::Options();
    if ( $user && $password ) {
        $o->option( user     => $user );
        $o->option( password => $password );
    }
    #$o->option(async => 1) if $async;
    #$o->option(count => $piggyback) if $piggyback;
    $o->option( cqlfile => $c->{server}->{$name}->{cql2rpn} );
    $o->option( cclfile => $c->{serverinfo}->{$name}->{ccl2rpn} );
    $o->option( preferredRecordSyntax => $syntax );
    $o->option( elementSetName => "F"); # F for 'full' as opposed to B for 'brief'
    $o->option( databaseName => $server eq 'biblio' ? "biblios" : "authorities");

    $zc = create ZOOM::Connection( $o );
    $zc->connect($host, 0);
    carp "something wrong with the connection: ". $zc->errmsg()
        if $zc->errcode;

    $self->_zconn->{$server} = $zc;
    return $zc;
}



sub zbiblio {
    shift->zconn( 'biblio' );
}



sub zauth {
    shift->zconn( 'auth' );
}



sub get_biblio_marc {
    my ( $self, $id ) = @_; 
    my $sth = $self->dbh->prepare(
        "SELECT metadata FROM biblio_metadata WHERE biblionumber=? ");
    $sth->execute( $id );
    my ($marcxml) = $sth->fetchrow;
    return unless $marcxml;
    $marcxml =~
s/[^\x09\x0A\x0D\x{0020}-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]//g;
    #MARC::File::XML->default_record_format(
    #C4::Context->preference('marcflavour') );
    my $record = MARC::Record->new();
    if ($marcxml) {
        $record = eval { 
            MARC::Record::new_from_xml( $marcxml, "utf8" ) };
        if ($@) { warn " problem with: $id : $@ \n$marcxml"; }
        return $record;
    }   
    return;
}



sub get_biblio {
    my ( $self, $id ) = @_; 

    my $record = $self->_old_marc_biblio_sub
        ? GetMarcBiblio($id)
        : GetMarcBiblio({biblionumber => $id});
    return unless $record;
    return MARC::Moose::Record::new_from($record, 'Legacy');
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::Koha - Class exposing info about a Koha instance.

=head1 VERSION

version 0.069

=head1 ATTRIBUTES

=head2 conf_file

Name of Koha configuration file. If not supplied, the configuration file is
taken in KOHA_CONF environment variable.

=head2 dbh

Handle to Koha database defined in Koha configuration file.

=head2 conf

Koha XML configuration file.

=head1 METHODS

=head2 zconn_reset

Reset both Zebra connections, biblio/authority server.

=head2 zconn($type)

Return a connection to biblio or authority Zebra server. Example:

  my $zc = $koha->zconn('biblio');
  my $zc = $koha->zconn('authority');

=head2 zbiblio

Returns a L<ZOOM::connection> to Koha bibliographic records Zebra server.

=head2 zauth

Returns a L<ZOOM::connection> to Koha authority records Zebra server.

=head2 get_biblio_marc($biblionumber)

Return a MARC::Record from its biblionumber

=head2 get_biblio($biblionumber)

Return a MARC::Moose::Record from its biblionumber. It's a wrapper around GetMarcBiblio()

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
