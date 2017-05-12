# NAME

Kayako::RestAPI - Perl library for working with [Kayako REST API](https://kayako.atlassian.net/wiki/display/DEV/Kayako+REST+API)

# VERSION

version 0.01

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

## change\_ticket\_owner

$kayako\_api->change\_ticket\_owner($ticket\_id, $new\_owner\_id);

## make\_unassigned

$kayako\_api->make\_unassigned($ticket\_id);

equalent to $kayako\_api->change\_ticket\_owner($ticket\_id, 0);

## create\_ticket

Check a list of required arguments here: [https://kayako.atlassian.net/wiki/display/DEV/REST+-+Ticket#REST-Ticket-POST/Tickets/Ticket](https://kayako.atlassian.net/wiki/display/DEV/REST+-+Ticket#REST-Ticket-POST/Tickets/Ticket)

## filter\_fields

Private method. Filter fields of API request result

By default return only id, title and module fields

## get\_departements

$kayako\_api->get\_departements(); # return an arrayref

## get\_ticket\_statuses

$kayako\_api->get\_ticket\_statuses(); # return an arrayref

## get\_ticket\_priorities

$kayako\_api->get\_ticket\_priorities(); # return an arrayref

## get\_ticket\_types

$kayako\_api->get\_ticket\_types(); # return an arrayref

## get\_staff

$kayako\_api->get\_staff(); # return an arrayref

# AUTHOR

Pavel Serikov <pavelsr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
