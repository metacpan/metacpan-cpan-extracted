use strict;
package DigitalOcean::Action;
use Mouse;
use DigitalOcean::Types;

#ABSTRACT: Represents an Action object in the DigitalOcean API

has DigitalOcean => (
    is => 'rw',
    isa => 'DigitalOcean',
);


has id => ( 
    is => 'ro',
    isa => 'Num',
);


has status => ( 
    is => 'rw',
    isa => 'Str',
);


has type => ( 
    is => 'ro',
    isa => 'Str',
);


has started_at => ( 
    is => 'ro',
    isa => 'Str',
);


has completed_at => ( 
    is => 'rw',
    isa => 'Str|Undef',
);


has resource_id => ( 
    is => 'ro',
    isa => 'Num|Undef',
);


has resource_type => ( 
    is => 'ro',
    isa => 'Str',
);


has region => ( 
    is => 'rw',
    isa => 'Coerced::DigitalOcean::Region|Undef',
    coerce => 1,
);


has region_slug => ( 
    is => 'ro',
    isa => 'Undef|Str',
);

 
sub complete { shift->status eq 'completed' }
 
 
sub wait { 
    my ($self) = @_;
    my $action = $self;
 
    print "going to wait\n";
    until($action->complete) { 
        print "waiting\n";
        sleep($self->DigitalOcean->time_between_requests);
        $action = $self->DigitalOcean->action($action->id);       
    }
    print "complete\n";
 
    $self->status($action->status);
    $self->completed_at($action->completed_at);
}


__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::Action - Represents an Action object in the DigitalOcean API

=head1 VERSION

version 0.17

=head1 SYNOPSIS

    FILL ME IN   

=head1 DESCRIPTION

FILL ME IN

=head1 METHODS

=head2 id

A unique numeric ID that can be used to identify and reference an action.

=head2 status

The current status of the action. This can be "in-progress", "completed", or "errored".

=head2 type

This is the type of action that the object represents. For example, this could be "transfer" to represent the state of an image transfer action.

=head2 started_at

A time value given in ISO8601 combined date and time format that represents when the action was initiated.

=head2 completed_at

A time value given in ISO8601 combined date and time format that represents when the action was completed.

=head2 resource_id

A unique identifier for the resource that the action is associated with.

=head2 resource_type

The type of resource that the action is associated with.

=head2 region

Returns a L<DigitalOcean::Region> object.

=head2 region_slug

A slug representing the region where the action occurred.

=head2 complete

This method returns true if the action is complete, false if it is not.

    if($action->complete) { 
        #do something
    }

=head2 wait

This method will wait for an action to complete and will not return until
the action has completed. It is recommended to not use this directly, but
rather to let L<DigitalOcean> call this for you (see L<WAITING ON EVENTS|DigitalOcean/"WAITING ON EVENTS">).

    $action->wait;
 
    #do stuff now that event is done.

This method works by making requests to Digital Ocean's API to see if the action
is complete yet. See L<TIME BETWEEN REQUESTS|DigitalOcean/"time_between_requests">.

=head2 id

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
