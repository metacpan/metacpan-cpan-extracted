package EWS::Folder::Role::Reader;
BEGIN {
  $EWS::Folder::Role::Reader::VERSION = '1.143070';
}

use Moose::Role;
use EWS::Folder::ResultSet;
use Carp;

sub _list_messages {
    my ($self, $kind, $response) = @_;
    if ( $response->{Fault} ) {
        my $msg;
        $msg->{"${kind}ResponseMessage"}->{ResponseCode} = $response->{Fault}->{faultstring};
        return $msg;
    }
    else {
        return @{ $response->{"${kind}Result"}
                           ->{ResponseMessages}
                           ->{"cho_CreateItemResponseMessage"} };
    }
}

sub _check_for_errors {
    my ($self, $kind, $response) = @_;

    foreach my $msg ( $self->_list_messages($kind, $response) ) {
        my $code = $msg->{"${kind}ResponseMessage"}->{ResponseCode} || '';
        croak "Fault returned from Exchange Server: $code\n"
            if $code ne 'NoError';
    }
}

sub _PagingOffset {
    my ($self, $kind, $response) = @_;

    foreach my $msg ( $self->_list_messages($kind, $response) ) {
        if ( exists $msg->{"${kind}ResponseMessage"}->{RootFolder} ) {
            if ( ! $msg->{"${kind}ResponseMessage"}->{RootFolder}->{IncludesLastItemInRange} ) {
                    return $msg->{"${kind}ResponseMessage"}->{RootFolder}->{IndexedPagingOffset};
            }
        }
    }
    return 0;
}

sub _list_folderitems {
    my ($self, $kind, $response) = @_;

        return  map { exists $_->{Folder} ? $_->{Folder} : $_ }
                map { exists $_->{TasksFolder} ? $_->{TasksFolder} : $_ } 
                map { exists $_->{ContactsFolder} ? $_->{ContactsFolder} : $_ } 
                map { exists $_->{CalendarFolder} ? $_->{CalendarFolder} : $_ } 
                map { @{ $_->{Folders}->{cho_Folder} || [] } }
                map { exists $_->{RootFolder} ? $_->{RootFolder} : $_ } 
                map { $_->{"${kind}ResponseMessage"} }
                $self->_list_messages($kind, $response);
}

# Find list of items within the view, then Get details for each one
# (item:Body is only available this way, it's not returned by FindItem)
sub retrieve{
    my ($self, $opts) = @_;

    my @items;
    my $IndexedPagingOffset = 0;
    do {
        # Find all folders underneath the 'Top of Information Store'
        my $find_response = scalar $self->client->FindFolder->(
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
        Traversal => 'Deep',
        FolderShape => {
            BaseShape => 'IdOnly',
            AdditionalProperties => {
                cho_Path => [
                {ExtendedFieldURI => {
                    PropertyTag => '3592',
                    PropertyType => 'Integer',
                }},
                    map {{
                        FieldURI => {
                            FieldURI => $_, 
                        },  
                    }} qw/ 
                        folder:DisplayName
                        folder:FolderClass
                        folder:ChildFolderCount
                        folder:TotalCount
                        folder:ManagedFolderInformation
                        folder:ParentFolderId
                    /,
                ],
            },
        },
        IndexedPageFolderView => {
                MaxEntriesReturned => '100',
                Offset => $IndexedPagingOffset,
                BasePoint => 'Beginning',
        },
        ParentFolderIds => {
            cho_FolderId => [
                {
                    DistinguishedFolderId => {
                        (exists $opts->{folderId} ? (
                                Id => $self->FolderId,
                        ) : Id => "msgfolderroot",)
                    },
                },
            ],
        },
        );

        $self->_check_for_errors('FindFolder', $find_response);

        push( @items, $self->_list_folderitems('FindFolder', $find_response));

        $IndexedPagingOffset = $self->_PagingOffset('FindFolder', $find_response);
    } while ( $IndexedPagingOffset > 0 );

    return return EWS::Folder::ResultSet->new({items => []})
        if scalar @items == 0;

        # Now add to that the details for the actual 'Top of Information Store' folder.
    my $get_response = scalar $self->client->GetFolder->(
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
        FolderShape => {
            BaseShape => 'IdOnly',
            AdditionalProperties => {
                cho_Path => [
                {ExtendedFieldURI => {
                    PropertyTag => '3592',
                    PropertyType => 'Integer',
                }},
                    map {{
                        FieldURI => {
                            FieldURI => $_, 
                        },  
                    }} qw/ 
                        folder:DisplayName
                        folder:FolderClass
                        folder:ChildFolderCount
                        folder:ManagedFolderInformation
                        folder:ParentFolderId
                    /,
                ],
            },
        },
        FolderIds => {
            cho_FolderId => [
                    {DistinguishedFolderId => {
                        (exists $opts->{folderId} ? (
                                Id => $self->FolderId,
                        ) : Id => "msgfolderroot",)
                    }},
            ],
        },
    );

    $self->_check_for_errors('GetFolder', $get_response);

        push( @items, $self->_list_folderitems('GetFolder', $get_response));

    return EWS::Folder::ResultSet->new({
        items => [ @items ]
    });
}

no Moose::Role;
1;

