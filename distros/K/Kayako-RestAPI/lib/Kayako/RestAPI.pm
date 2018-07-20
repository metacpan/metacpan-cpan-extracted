package Kayako::RestAPI;
$Kayako::RestAPI::VERSION = '0.06';

# ABSTRACT: Perl library for working with L<Kayako REST API|https://kayako.atlassian.net/wiki/display/DEV/Kayako+REST+API>. Tested with


use common::sense;
use Mojo::UserAgent;
use Digest::SHA qw(hmac_sha256_base64);
use File::Slurp;
use XML::LibXML::Simple;
use utf8;
use Data::Dumper;

my $xs = XML::LibXML::Simple->new();

sub new {
    my $class = shift;
    my $o     = {};
    $o->{auth_hash}        = shift;
    $o->{xml2json_options} = shift;
    $o->{xml2json_options} =
      { content_key => 'text', pretty => 1, attribute_prefix => 'attr_' }
      if not defined $o->{xml2json_options};
    $o->{ua} = Mojo::UserAgent->new;
    bless $o, $class;
    return $o;
}

sub _prepare_request {
    my $self     = shift;
    my @alphabet = ( ( 'a' .. 'z' ), ( 'A' .. 'Z' ), 0 .. 9 );
    my $len      = 10;
    my $salt     = join '', map { $alphabet[ rand(@alphabet) ] } 1 .. $len;
    my $digest =
      hmac_sha256_base64( $salt, $self->{auth_hash}{secret_key} ) . '=';
    my $hash = {
        "apikey"    => $self->{auth_hash}{api_key},
        "salt"      => $salt,
        "signature" => $digest
    };
    return $hash;
}


sub xml2obj {
    my ( $self, $xml ) = @_;
    $xs->XMLin($xml);
}

# abstract api GET/POST/PUT/DELETE _query. return plain xml
sub _query {
    my ( $self, $method, $route, $params ) = @_;
    $params->{e} = $route;
    my %hash = ( %{ $self->_prepare_request }, %$params );
    my $xml =
      $self->{ua}->$method( $self->{auth_hash}{api_url} => form => \%hash )
      ->res->body;
    $xml =~ s/([\x00-\x09]+)|([\x0B-\x1F]+)//g;
    return $xml;
}

sub get {
    my ( $self, $route, $params ) = @_;
    $self->_query( 'get', $route, $params );
}

sub put {
    my ( $self, $route, $params ) = @_;
    $self->_query( 'put', $route, $params );
}

sub post {
    my ( $self, $route, $params ) = @_;
    $self->_query( 'post', $route, $params );
}

sub delete {
    my ( $self, $route, $params ) = @_;
    $self->_query( 'delete', $route, $params );
}


sub get_hash {
    my ( $self, $route, $params ) = @_;
    my $xml = $self->get( $route, $params );
    return $self->xml2obj($xml);
}


sub get_ticket_xml {
    my ( $self, $ticket_id, $params ) = @_;
    return $self->get( "/Tickets/Ticket/" . $ticket_id . "/", $params );
}


sub get_ticket_hash {
    my ( $self, $ticket_id ) = @_;
    my $xml  = $self->get_ticket_xml($ticket_id);
    my $hash = {};
    if ( $xml eq 'Ticket not Found' || $xml eq '' ) {
        die "Ticket not Found";

        # $hash->{'ticket_id'} = $ticket_id;
        # $hash->{'is_found'} = 0;
    }
    else {
        $hash = $self->xml2obj($xml)->{ticket};
    }
    return $hash;
}


sub change_ticket_owner {
    my ( $self, $ticket_id, $new_owner_id ) = @_;
    my $content_key = $self->{xml2json_options}{content_key};
    my $old_data    = $self->get_ticket_hash($ticket_id);
    $self->put(
        "/Tickets/Ticket/" . $ticket_id . "/",
        { ownerstaffid => $new_owner_id }
    );
    my $new_data = $self->get_ticket_hash($ticket_id);
    my $res      = {
        old => {
            ownerstaffid   => $old_data->{ownerstaffid}{$content_key},
            ownerstaffname => $old_data->{ownerstaffname}{$content_key}
        },
        new => {
            ownerstaffid   => $new_data->{ownerstaffid}{$content_key},
            ownerstaffname => $new_data->{ownerstaffname}{$content_key}
        }
    };
    return $res;
}


sub make_unassigned {
    my ( $self, $ticket_id ) = @_;
    $self->change_ticket_owner( $ticket_id, 0 );
}


sub create_ticket {
    my ( $self, $params ) = @_;
    my $xml = $self->post( '/Tickets/Ticket/', $params );
    $self->xml2obj($xml);
}


sub filter_fields {
    my ( $self, $a ) = @_;    # array of hashes
    my $key = $self->{xml2json_options}{content_key};
    for my $j (@$a) {
        $j = { map { $_ => $j->{$_}{$key} }
              grep { exists $j->{$_} } qw/id title module/ };
    }
    return $a;
}

# Convert nested hash with id keys into array of hashes. For compatibility with old API
# Usage is same as filter_fields
sub _postprocess_libxml {
    my ( $self, $hash ) = @_;    # array of hashes
    my @res;
    for my $k ( sort keys %$hash ) {

# my $j = { map { $_ => $hash->{$k} } grep { exists $hash->{$k} } qw/id title module fullname/ };
# warn "Element:".Dumper $j;
        my $j = {
            id     => $k,
            title  => $hash->{$k}{title},
            module => $hash->{$k}{module}
        };
        push @res, $j;

        # push @res, $j;
    }
    return \@res;
}


sub get_departements {
    my $self = shift;
    my $xml  = $self->get('/Base/Department/');
    $self->xml2obj($xml)->{department};
}

sub get_departements_old {
    my $self = shift;
    $self->_postprocess_libxml( $self->get_departements );
}


sub get_ticket_statuses {
    my $self = shift;
    my $xml  = $self->get('/Tickets/TicketStatus/');
    $self->xml2obj($xml)->{ticketstatus};
}

sub get_ticket_statuses_old {
    my $self = shift;
    $self->_postprocess_libxml( $self->get_ticket_statuses );
}


sub get_ticket_priorities {
    my $self = shift;
    my $xml  = $self->get('/Tickets/TicketPriority/');
    $self->xml2obj($xml)->{ticketpriority};
}

sub get_ticket_priorities_old {
    my $self = shift;
    $self->_postprocess_libxml( $self->get_ticket_priorities );
}


sub get_ticket_types {
    my $self = shift;
    my $xml  = $self->get('/Tickets/TicketType/');
    $self->xml2obj($xml)->{tickettype};    # array
}

sub get_ticket_types_old {
    my $self = shift;
    $self->_postprocess_libxml( $self->get_ticket_types );
}


sub get_staff {
    my $self = shift;
    my $xml  = $self->get('/Base/Staff/');
    $self->xml2obj($xml)->{staff};    # array
}

sub get_staff_old {
    my $self = shift;
    $self->_postprocess_libxml( $self->get_staff );
}

# HTTP mocks
# perl -Ilib -MData::Dumper -MKayako::RestAPI -E 'print Dumper Kayako::RestAPI::_samples();'
sub _samples {
    return [
        {
            method      => 'get',
            route       => '/Tickets/Ticket/1000/',
            sample_file => 'ticket.xml',
            params      => {}
        },
        {
            method      => 'get',
            route       => '/Base/Department/',
            sample_file => 'departments.xml'
        },
        {
            method      => 'get',
            route       => '/Tickets/TicketStatus/',
            sample_file => 'ticket_status.xml'
        },
        {
            method      => 'get',
            route       => '/Tickets/TicketPriority/',
            sample_file => 'ticket_priority.xml'
        },
        {
            method      => 'get',
            route       => '/Tickets/TicketType/',
            sample_file => 'ticket_type.xml'
        },
        {
            method      => 'get',
            route       => '/Base/Staff/',
            sample_file => 'staff.xml'
        }
    ];
}

# generate ethalon data to t/lib/Kayako/samples
# perl -Ilib -MData::Dumper -MKayako::RestAPI -E 'print Dumper Kayako::RestAPI::_generate_t_samples();'
sub _generate_t_samples {
    my @samples = @{ __PACKAGE__->_samples };
    my $k       = Kayako::RestAPI->new(
        {
            api_url    => '',
            api_key    => '',
            secret_key => ''
        }
    );

    for my $s (@samples) {
        my $data = $k->_query( $s->{method}, $s->{route} );
        write_file( 't/lib/Kayako/samples/' . $s->{sample_file},
            { binmode => ':raw' }, $data );
    }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kayako::RestAPI - Perl library for working with L<Kayako REST API|https://kayako.atlassian.net/wiki/display/DEV/Kayako+REST+API>. Tested with

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use Kayako::RestAPI;

    my $kayako_api = Kayako::RestAPI->new({ 
      "api_url" => '',
      "api_key" => '',
      "secret_key" => ''
    }, { 
      content_key => 'text', 
      pretty => 1, 
      attribute_prefix => 'attr_' 
    });

    $kayako_api->get($route, $params); # $params is optional hashref
    $kayako_api->post($route, $params);
    $kayako_api->put($route, $params);
    $kayako_api->delete($route, $params);

    $kayako_api->get('/Base/Department'); # list of all departements
  
    my $ticket_id = 1000;
    $kayako_api->get_ticket_xml($ticket_id);
    $kayako_api->get_ticket_hash($ticket_id);

    $kayako_api->create_ticket({
      subject => 'Test ticket',
      fullname => 'Pavel Serikov',
      email => 'someuser@gmail.com',
      contents => 'Hello, world!',
      departmentid => 5,
      ticketstatusid => 4,
      ticketpriorityid => 1,
      tickettypeid => 5,
      autouserid => 1
    });

You can test you controller with L<API Test Controller|https://kayako.atlassian.net/wiki/display/DEV/API+Test+Controller>

Attention: since version 0.06 (migration from XML::XML2JSON to XML::LibXML::Simple) response structure of following methods was changed from array to hash

    get_ticket_hash
    get_departements
    get_ticket_statuses
    get_ticket_priorities
    get_ticket_types

If you need to use old structure please add _old suffix to method ;)

WORK UNDER THIS MODULE IS IN PROGRESS, HELP WANTED, ESPECIALLY FOR WRITING DOCS

=head1 METHODS

=head2 xml2obj

Convert xml API response to hash using XML::XML2JSON::xml2obj method

    my $xml = $kayako_api->get('/Some/Endpoint');
    my $hash = $kayako_api->xml2obj($xml);

Can potentially crash is returned xml isn't valid (when XML::XML2JSON dies)

=head2 get_hash

Wrapper under abstract GET API query, return hash

    $kayako_api->get_hash('/Some/API/Endpoint');

Can potentially crash is returned xml isn't valid (when XML::XML2JSON dies)

=head2 get_ticket_xml

Get info about ticket in native XML

    $kayako_api->get_ticket_xml($ticket_id);

=head2 get_ticket_hash

    $kayako_api->get_ticket_hash($ticket_id);

=head2 change_ticket_owner

    $kayako_api->change_ticket_owner($ticket_id, $new_owner_id);

=head2 make_unassigned

    $kayako_api->make_unassigned($ticket_id);

equalent to 

    $kayako_api->change_ticket_owner($ticket_id, 0);

=head2 create_ticket

Check a list of required arguments here: L<https://kayako.atlassian.net/wiki/display/DEV/REST+-+Ticket#REST-Ticket-POST/Tickets/Ticket>

=head2 filter_fields

THIS METHOD LEFT HERE FOR COMPATIBILITY AND WILL BE REMOVED IN FUTURE RELEASES

Filter fields of API request result and trim content_key added by XML::XML2JSON

By default leave only id, title and module fields

    my $arrayref = $kayako_api->get_hash('/Some/API/Endpoint');
    $kayako_api->filter_fields($arrayref); 

=head2 get_departements_old

    $kayako_api->get_departements();

Return an arrayref of hashes with title, module and id keys like

    [
        {
            'module' => 'tickets',
            'title' => 'Hard drives department',
            'id' => '5'
        },
        {
            'id' => '6',
            'module' => 'tickets',
            'title' => 'Flash drives department'
        }
    ]

API endpoint is /Base/Department/

=head2 get_ticket_statuses_old

    $kayako_api->get_ticket_statuses(); 

Return an arrayref of hashes with title and id keys like

    [
        {
            'title' => 'In progress',
            'id' => '1'
        },
        {
            'title' => 'Closed',
            'id' => '3'
        },
        {
            'id' => '4',
            'title' => 'New'
        }
    ]

API endpoint is /Tickets/TicketStatus/

=head2 get_ticket_priorities_old

        $kayako_api->get_ticket_priorities();

Return an arrayref of hashes with title and id keys like

    [
        {
            'title' => 'Normal',
            'id' => '1'
        },
        {
            'id' => '3',
            'title' => 'Urgent'
        },
    ]

API endpoint is /Tickets/TicketPriority/

=head2 get_ticket_types_old

    $kayako_api->get_ticket_types();

Return an arrayref of hashes with title and id keys like

    [
        {
            'id' => '1',
            'title' => 'Case'
        },
        {
            'id' => '3',
            'title' => 'Bug'
        },
        {
            'id' => '5',
            'title' => 'Feedback'
        }
    ];

API endpoint is /Tickets/TicketType/

=head2 get_staff_old

    $kayako_api->get_staff();

Return an arrayref of hashes with keys like firstname, lastname, username etc.

E.g.

    [ 
        { ... },
        {
            'id' => { 'text' => '12' },
            'firstname' => { 'text' => 'Pavel' },
            'email' => { 'text' => 'pavelsr@cpan.org' },
            'lastname' => { 'text' => 'Serikov' },
            'enabledst' => { 'text' => '0'},
            'username' => { 'text' => 'pavelsr' },
            'isenabled' => { 'text' => '1' },
            'staffgroupid' => { 'text' => '4' },
            'greeting' => {},
            'timezone' => {},
            'designation' => { 'text' => 'TS' },
            'mobilenumber' => {},
            'signature' => {},
            'fullname' => { 'text' => 'Pavel Serikov' }
        }
    ]

API endpoint is /Base/Staff/

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
