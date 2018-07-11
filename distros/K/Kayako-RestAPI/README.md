# NAME

Kayako::RestAPI - Perl library for working with [Kayako REST API](https://kayako.atlassian.net/wiki/display/DEV/Kayako+REST+API). Tested with

# VERSION

version 0.04

# SYNOPSIS

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

You can test you controller with [API Test Controller](https://kayako.atlassian.net/wiki/display/DEV/API+Test+Controller)

# METHODS

## xml2obj

Convert xml API response to hash using XML::XML2JSON::xml2obj method

    my $xml = $kayako_api->get('/Some/Endpoint');
    my $hash = $kayako_api->xml2obj($xml);

Can potentially crash is returned xml isn't valid (when XML::XML2JSON dies)

## get\_hash

Wrapper under abstract GET API query, return hash

    $kayako_api->get_hash('/Some/API/Endpoint');

Can potentially crash is returned xml isn't valid (when XML::XML2JSON dies)

## get\_ticket\_xml

Get info about ticket in native XML

    $kayako_api->get_ticket_xml($ticket_id);

## get\_ticket\_hash

    $kayako_api->get_ticket_hash($ticket_id);

## change\_ticket\_owner

    $kayako_api->change_ticket_owner($ticket_id, $new_owner_id);

## make\_unassigned

    $kayako_api->make_unassigned($ticket_id);

equalent to 

    $kayako_api->change_ticket_owner($ticket_id, 0);

## create\_ticket

Check a list of required arguments here: [https://kayako.atlassian.net/wiki/display/DEV/REST+-+Ticket#REST-Ticket-POST/Tickets/Ticket](https://kayako.atlassian.net/wiki/display/DEV/REST+-+Ticket#REST-Ticket-POST/Tickets/Ticket)

## filter\_fields

Filter fields of API request result and trim content\_key

By default leave only id, title and module fields

    my $arrayref = $kayako_api->get_hash('/Some/API/Endpoint');
    $kayako_api->filter_fields($arrayref); 

## get\_departements

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

## get\_ticket\_statuses

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

## get\_ticket\_priorities

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

## get\_ticket\_types

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

## get\_staff

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
            'isenabled' => { 'text' => '1' }6,
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

# AUTHOR

Pavel Serikov <pavelsr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
