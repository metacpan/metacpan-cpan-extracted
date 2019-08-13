# NAME

Google::CloudTasks - Perl client library for the Google CloudTasks API (_unofficial_).

# SYNOPSIS

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

# DESCRIPTION

Google::CloudTasks [https://cloud.google.com/tasks/docs/reference/rest/](https://cloud.google.com/tasks/docs/reference/rest/)

This is a Perl client library for the Google CloudTasks API.

## AUTHENTICATION

A service account with appropriate roles is required. You need to download JSON file and specify `credentials_path`.
See also: [https://cloud.google.com/docs/authentication/getting-started#creating\_the\_service\_account](https://cloud.google.com/docs/authentication/getting-started#creating_the_service_account)

# METHODS

All methods handle raw hashref (or arrayref of hashref), rather than objects.

## Create a client

    my $client = Google::CloudTasks->client(
        version => 'v2',
        credentials_path => '/path/to/credentials.json',
    );

`version` is an API version. (Currently only `v2` is available)
`credentials_path` is a path to a service account JSON file.

## Location

Refer the detailed representation of location at [https://cloud.google.com/tasks/docs/reference/rest/Shared.Types/ListLocationsResponse#Location](https://cloud.google.com/tasks/docs/reference/rest/Shared.Types/ListLocationsResponse#Location)

### get\_location

Gets information about a location.

    my $location = $client->get_location("projects/$PROJECT_ID/locations/$LOCATION_ID");

### list\_locations

Lists information about all locations under project.

    my $ret = $client->list_locations("projects/$PROJECT_ID");
    my $locations = $ret->{locations};

## Queue

Refer the detailed representation of queue at [https://cloud.google.com/tasks/docs/reference/rest/v2/projects.locations.queues#Queue](https://cloud.google.com/tasks/docs/reference/rest/v2/projects.locations.queues#Queue)

### create\_queue

Creates a queue.

    my $queue = {
        name => 'queue-name',
    };
    my $created = $client->create_queue("projects/$PROJECT_ID/locations/$LOCATION_ID", $queue);

### delete\_queue

Deletes a queue.

    $client->delete_queue("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID")

### get\_queue

Gets information of a queue.

    my $queue = $client->get_queue("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID");

### list\_queues

Lists information of all queues.

    my $ret = $client->list_queues("projects/$PROJECT_ID/locations/$LOCATION_ID");
    my $queues = $ret->{queues};

### patch\_queue

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

### pause\_queue

Pauses a queue.

    my $queue = $client->pause_queue("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID");

### resume\_queue

Resumes a queue.

    my $queue = $client->resume_queue("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID");

### get\_iam\_policy\_queue

Gets the access control policy for a queue.

    my $policy = $client->get_iam_policy_queue("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID");

### set\_iam\_policy\_queue

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

## Task

Refer the detailed representation of task at [https://cloud.google.com/tasks/docs/reference/rest/v2/projects.locations.queues.tasks#Task](https://cloud.google.com/tasks/docs/reference/rest/v2/projects.locations.queues.tasks#Task)

### create\_task

Creates a task. Note that a request body in `appEngineHttpRequest` should be base64-encoded.

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

### delete\_task

Deletes a task.

    $client->delete_task("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID/tasks/$TASK_ID");

### get\_task

Gets information of a task.

    my $task = $client->get_task("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID/tasks/$TASK_ID");

### list\_tasks

Lists information of all tasks.

    my $ret = $client->list_tasks("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID");
    my $tasks = $ret->{tasks};

### run\_task

Runs a task.

    my $ret = $client->run_task("projects/$PROJECT_ID/locations/$LOCATION_ID/queues/$QUEUE_ID/tasks/$TASK_ID");

# TODO

The following methods has implemented, but not tested nor documented yet.

`Queue.testIamPermissions`

# LICENSE

Copyright (C) egawata.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

egawata (egawa dot takashi at gmail.com)
