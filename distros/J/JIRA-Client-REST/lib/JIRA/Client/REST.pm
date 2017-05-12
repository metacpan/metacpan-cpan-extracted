package JIRA::Client::REST;
{
  $JIRA::Client::REST::VERSION = '0.06';
}
use Moose;

# ABSTRACT: JIRA REST Client

use JSON qw(decode_json encode_json);
use Net::HTTP::Spore;


has '_client' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;

        my $client = Net::HTTP::Spore->new_from_string(
            '{
                "name": "JIRA",
                "authority": "GITHUB:gphat",
                "version": "1.0",
                "methods": {
                    "get_issue": {
                        "path": "/rest/api/latest/issue/:id",
                        "required_params": [
                            "id"
                        ],
                        "optional_params": [
                            "expand"
                        ],
                        "method": "GET",
                        "authentication": true
                    },
                    "get_issue_transitions": {
                        "path": "/rest/api/latest/issue/:id/transitions",
                        "required_params": [
                            "id"
                        ],
                        "optional_params": [
                            "expand"
                        ],
                        "method": "GET",
                        "authentication": true
                    },
                    "get_issue_votes": {
                        "path": "/rest/api/latest/issue/:id/votes",
                        "required_params": [
                            "id"
                        ],
                        "optional_params": [
                            "expand"
                        ],
                        "method": "GET",
                        "authentication": true
                    },
                    "get_issue_watchers": {
                        "path": "/rest/api/latest/issue/:id/watchers",
                        "required_params": [
                            "id"
                        ],
                        "optional_params": [
                            "expand"
                        ],
                        "method": "GET",
                        "authentication": true
                    },
                    "get_project": {
                        "path": "/rest/api/latest/project/:key",
                        "required_params": [
                            "key"
                        ],
                        "method": "GET",
                        "authentication": true
                    },
                    "get_project_versions": {
                        "path": "/rest/api/latest/project/:key/versions",
                        "required_params": [
                            "key"
                        ],
                        "method": "GET",
                        "authentication": true
                    },
                    "get_version": {
                        "path": "/rest/api/latest/version/:id",
                        "required_params": [
                            "id"
                        ],
                        "method": "GET",
                        "authentication": true
                    },
                    "unvote_for_issue": {
                        "path": "/rest/api/latest/issue/:id/votes",
                        "required_params": [
                            "id"
                        ],
                        "method": "DELETE",
                        "authentication": true
                    },
                    "unwatch_issue": {
                        "path": "/rest/api/latest/issue/:id/watchers",
                        "required_params": [
                            "id",
                            "username"
                        ],
                        "method": "DELETE",
                        "authentication": true
                    },
                    "vote_for_issue": {
                        "path": "/rest/api/latest/issue/:id/votes",
                        "required_params": [
                            "id"
                        ],
                        "method": "POST",
                        "authentication": true
                    },
                    "watch_issue": {
                        "path": "/rest/api/latest/issue/:id/watchers",
                        "required_params": [
                            "id",
                            "username"
                        ],
                        "method": "POST",
                        "authentication": true
                    }
                }
            }',
            base_url => $self->url,
            trace => $self->debug,
        );
        $client->enable('Format::JSON');
        $client->enable('Auth::Basic', username => $self->username, password => $self->password);
        return $client;
    }
);

has 'debug' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);


has 'password' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);


has 'url' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);


has 'username' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);


sub get_issue {
    my ($self, $id, $expand) = @_;

    return $self->_client->get_issue(id => $id, expand => $expand);
}


sub get_issue_transitions {
    my ($self, $id, $expand) = @_;

    return $self->_client->get_issue_transitions(id => $id, expand => $expand);
}


sub get_issue_votes {
    my ($self, $id, $expand) = @_;

    return $self->_client->get_issue_votes(id => $id, expand => $expand);
}


sub get_issue_watchers {
    my ($self, $id, $expand) = @_;

    return $self->_client->get_issue_watchers(id => $id, expand => $expand);
}


sub get_project {
    my ($self, $key) = @_;
    
    return $self->_client->get_project(key => $key);
}


sub get_project_versions {
    my ($self, $key) = @_;
    
    return $self->_client->get_project_versions(key => $key);
}


sub get_version {
    my ($self, $id) = @_;
    
    return $self->_client->get_version(id => $id);
}


sub unvote_for_issue {
    my ($self, $id) = @_;

    return $self->_client->unvote_for_issue(id => $id);
}


sub unwatch_issue {
    my ($self, $id, $username) = @_;

    return $self->_client->unwatch_issue(id => $id, username => $username);
}


sub vote_for_issue {
    my ($self, $id) = @_;

    return $self->_client->vote_for_issue(id => $id);
}


sub watch_issue {
    my ($self, $id, $username) = @_;

    return $self->_client->watch_issue(id => $id, username => $username);
}

1;

__END__
=pod

=head1 NAME

JIRA::Client::REST - JIRA REST Client

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use JIRA::Client::REST;

    my $client = JIRA::Client::REST->new(
        username => 'username',
        password => 'password',
        url => 'http://jira.mycompany.com',
    );
    my $issue = $client->get_issue('TICKET-12');
    print $issue->{fields}->{priority}->{value}->{name}."\n";

=head1 DESCRIPTION

JIRA::Client::REST is a wrapper for the L<JIRA REST API|http://docs.atlassian.com/jira/REST/latest/>.
It is a thin wrapper, returning decoded version of the JSON without any munging
or mangling.

=head1 HEADS UP

This module is under development and some of the REST API hasn't been implemented
yet.

=head1 ATTRIBUTES

=head2 password

Set/Get the password to use when connecting to JIRA.

=head2 url

Set/Get the URL for the JIRA instance.

=head2 username

Set/Get the username to use when connecting to JIRA.

=head1 METHODS

=head2 get_issue($id, $expand)

Get the issue with the supplied id.  Returns a HashRef of data.

=head2 get_issue_transitions($id, $expand)

Get the transitions possible for this issue by the current user.

=head2 get_issue_votes($id, $expand)

Get voters on the issue.

=head2 get_issue_watchers($id, $expand)

Get watchers on the issue.

=head2 get_project($key)

Get the project for the specifed key.

=head2 get_project_versions($key)

Get the versions for the project with the specified key.

=head2 get_version($id)

Get the version with the specified id.

=head2 unvote_for_issue($id)

Remove your vote from an issue.

=head2 unwatch_issue($id, $username)

Remove a watcher from an issue.

=head2 vote_for_issue($id)

Cast your vote in favor of an issue.

=head2 watch_issue($id, $username)

Watch an issue. (Or have someone else watch it.)

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

