package EWS::Calendar::Role::RetrieveWithinWindow;
BEGIN {
  $EWS::Calendar::Role::RetrieveWithinWindow::VERSION = '1.143070';
}
use Moose::Role;

use EWS::Calendar::ResultSet;
use Carp;

sub _list_messages {
    my ($self, $kind, $response) = @_;
    return @{ $response->{"${kind}Result"}
                       ->{ResponseMessages}
                       ->{cho_CreateItemResponseMessage} };
}

sub _check_for_errors {
    my ($self, $kind, $response, $opts) = @_;

    croak "Fault returned from Exchange Server: ($opts->{impersonate}) $response->{Fault}->{faultstring}\n"
        if ( exists $response->{Fault} );
    foreach my $msg ( $self->_list_messages($kind, $response) ) {
        my $code = $msg->{"${kind}ResponseMessage"}->{ResponseCode} || '';
        croak "Fault returned from Exchange Server: ($opts->{impersonate}) $code\n"
            if $code ne 'NoError';
    }
}

sub _list_calendaritems {
    my ($self, $kind, $response) = @_;

    return map { $_->{CalendarItem} }
           map { @{ $_->{Items}->{cho_Item} || [] } }
           map { exists $_->{RootFolder} ? $_->{RootFolder} : $_ } 
           map { $_->{"${kind}ResponseMessage"} }
               $self->_list_messages($kind, $response);
}

# Find list of items within the view, then Get details for each one
# (item:Body is only available this way, it's not returned by FindItem)
sub retrieve_within_window {
    my ($self, $opts) = @_;

    my $find_response = scalar $self->client->FindItem->(
        (exists $opts->{impersonate} ? (
            Impersonation => {
                ConnectingSID => {
                    PrimarySmtpAddress => $opts->{impersonate},
                }
            },
        ) : ()),
        RequestVersion => {
            Version => $self->client->server_version,
        },
        Traversal => 'Shallow',
        ItemShape => {
            BaseShape => 'IdOnly',
        },
        ParentFolderIds => {
            cho_FolderId => [
                { DistinguishedFolderId =>
                    {
                        Id => "calendar",
                        (exists $opts->{email} ? (
                            Mailbox => {
                                EmailAddress => $opts->{email},
                            },
                        ) : ()), # optional
                    },
                },
            ],
        },
        CalendarView => {
            StartDate => $opts->{window}->start->iso8601,
            EndDate   => $opts->{window}->end->iso8601,
        },
    );

    return EWS::Calendar::ResultSet->new({items => []})
        if !defined $find_response;

    $self->_check_for_errors('FindItem', $find_response, $opts);

    my @ids = map { $_->{ItemId}->{Id} }
                  $self->_list_calendaritems('FindItem', $find_response);

    my @items;

    # Exchange (at least versions 2007,2010) have a limit of 250 items for a
    # GetItem call. To be safe, we just pull 200 items at a time until we fetch
    # everything
    while (@ids) {
        my $get_response = scalar $self->client->GetItem->(
            (exists $opts->{impersonate} ? (
                Impersonation => {
                    ConnectingSID => {
                        PrimarySmtpAddress => $opts->{impersonate},
                    }
                },
            ) : ()),
            RequestVersion => {
                Version => $self->client->server_version,
            },
            ItemShape => {
                BaseShape => 'IdOnly',
                AdditionalProperties => {
                    cho_Path => [
                        map {{
                            FieldURI => {
                                FieldURI => $_, 
                            },  
                        }} qw/ 
                            calendar:Start
                            calendar:End
                            item:Subject
                            calendar:Location
                            calendar:CalendarItemType
                            calendar:Organizer
                            item:Sensitivity
                            item:DisplayTo
                            calendar:AppointmentState
                            calendar:IsAllDayEvent
                            calendar:LegacyFreeBusyStatus
                            item:IsDraft
                            item:Body
                            calendar:OptionalAttendees
                            calendar:RequiredAttendees
                            calendar:Duration
                            calendar:UID
                        /,
                    ],
                },
            },
            ItemIds => {
                cho_ItemId => [
                    map {{
                        ItemId => { Id => $_ },
                    }} splice(@ids, 0, 200)
                ],
            },
        );

        $self->_check_for_errors('GetItem', $get_response, $opts);
        push(@items, $self->_list_calendaritems('GetItem', $get_response));
    }

    return EWS::Calendar::ResultSet->new({ items => [ @items ] });
}

no Moose::Role;
1;

