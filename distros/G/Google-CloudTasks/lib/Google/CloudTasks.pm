package Google::CloudTasks;
use 5.008001;
use strict;
use warnings;
use utf8;

use Google::CloudTasks::Client;

our $VERSION = "0.01";

sub client {
    my ($class, @args) = @_;

    my %args = @args;
    if ($args{version} and $args{version} ne 'v2') {
        die "Currently only version 'v2' of CloudTasks is suppoted.";
    }
    return Google::CloudTasks::Client->new(@args);
}

1;

__END__

=encoding utf-8

=head1 NAME

Google::CloudTasks - Perl client library for the Google CloudTasks API (I<unofficial>).

=head1 SYNOPSIS

    use Google::CloudTasks;

    my $client = Google::CloudTasks->client(
        version => 'v2',
        credentials_path => '/path/to/credentials.json',
    );

    #  Create task
    my $project_id = 'myproject';
    my $location_id = 'asia-northeast1';
    my $queue_id = 'myqueue';
    my $parent = "projects/$project_id/locations/$location_id/queues/$queue_id";

    my $task = {
        name => "$parent/tasks/mytask-01234567",
        appEngineHttpRequest => {
            relativeUri => '/do_task',
        },
    }
    my $ret = $client->create_task($parent, $task);


=head1 DESCRIPTION

Google::CloudTasks L<https://cloud.google.com/tasks/docs/reference/rest/>

This is a Perl client library for the Google CloudTasks API.

=head2 AUTHENTICATION

A service account with appropriate roles is required. You need to download JSON file and specify C<credentials_path>.
See also: L<https://cloud.google.com/docs/authentication/getting-started#creating_the_service_account>

=head1 METHODS

All methods handle raw hashref (or arrayref of hashref), rather than objects.

=head2 Create a client

    my $client = Google::CloudTasks->client(
        version => 'v2',
        credentials_path => '/path/to/credentials.json',
    );

C<version> is an API version. (Currently only C<v2> is available)
C<credentials_path> is a path to a service account JSON file.

=head2 Location

Refer the detailed representation of location at L<https://cloud.google.com/tasks/docs/reference/rest/Shared.Types/ListLocationsResponse#Location>

=head3 get_location

Gets information about a location.

    my $location = $client->get_location("projects/$PROJECT_ID/locations/$LOCATION_ID");

=head3 list_locations

Lists information about all locations under project.

    my $ret = $client->list_locations("projects/$PROJECT_ID");
    my $locations = $ret->{locations};

=head2 Queue

Refer the detailed representation of queue at L<https://cloud.google.com/tasks/docs/reference/rest/v2/projects.locations.queues#Queue>

=head3 create_queue

Creates a queue.

    my $queue = {
        name => 'queue-name',
    };
    my $created = $client->create_queue("projects/$PROJECT_ID/locations/$LOCATION_ID", $queue);

=head3 delete_queue

Deletes a queue.

    $client->delete_queue("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID")

=head3 get_queue

Gets information of a queue.

    my $queue = $client->get_queue("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID");

=head3 list_queues

Lists information of all queues.

    my $ret = $client->list_queues("projects/$PROJECT_ID/locations/$LOCATION_ID");
    my $queues = $ret->{queues};

=head3 patch_queue

Updates a queue.

    my $queue = {
        retryConfig => {
            maxAttempts => 5,
        },
    };
    my $update_mask = { updateMask => 'retryConfig.maxAttempts' };
    my $updated = $client->patch_queue(
        "projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID",
        $queue,
        $update_mask,   # optional
    );

=head3 pause_queue

Pauses a queue.

    my $queue = $client->pause_queue("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID");

=head3 resume_queue

Resumes a queue.

    my $queue = $client->resume_queue("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID");

=head3 get_iam_policy_queue

Gets the access control policy for a queue.

    my $policy = $client->get_iam_policy_queue("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID");

=head3 set_iam_policy_queue

Sets the access control policy for a queue.

    my $policy = {
        bindings => [
            +{
                role => 'roles/viewer',
                members => [
                    'serviceAccount:service-account-name@myproject.gserviceaccount.com',
                ],
            }
        ],
        etag => $etag,  # got via get_iam_policy_queue
    };
    $policy = $client->set_iam_policy_queue(
        "projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID",
        $policy,
    );

=head2 Task

Refer the detailed representation of task at L<https://cloud.google.com/tasks/docs/reference/rest/v2/projects.locations.queues.tasks#Task>

=head3 create_task

Creates a task. Note that a request body in C<appEngineHttpRequest> should be base64-encoded.

    use MIME::Base64;

    my $body = encode_base64('{"name": "TaskTest"}');
    chomp($body);

    my $task = {
        name => "projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID",
        appEngineHttpRequest => {
            relativeUri => '/path',
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => $body,
        },
    };
    my $created = $client->create_task(
        "projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID",
        $task
    );

=head3 delete_task

Deletes a task.

    $client->delete_task("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID/tasks/$TASK_ID");

=head3 get_task

Gets information of a task.

    my $task = $client->get_task("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID/tasks/$TASK_ID");

=head3 list_tasks

Lists information of all tasks.

    my $ret = $client->list_tasks("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID");
    my $tasks = $ret->{tasks};

=head3 run_task

Runs a task.

    my $ret = $client->run_task("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID/tasks/$TASK_ID");

=head1 TODO

The following methods has implemented, but not tested nor documented yet.

C<Queue.testIamPermissions>

=head1 LICENSE

Copyright (C) egawata.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

egawata (egawa dot takashi at gmail.com)

=cut
