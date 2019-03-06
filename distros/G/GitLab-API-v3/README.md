# NAME

GitLab::API::v3 - A complete GitLab API v3 client. (DEPRECATED)

# SYNOPSIS

    use GitLab::API::v3;
    
    my $api = GitLab::API::v3->new(
        url   => $v3_api_url,
        token => $token,
    );
    
    my $branches = $api->branches( $project_id );

## DEPRECATED

This module is at the end of it's life as the latest GitLab no longer supports
the v3 API.  Instead, use [GitLab::API::v4](https://metacpan.org/pod/GitLab::API::v4).

# DESCRIPTION

This module provides a one-to-one interface with the GitLab
API v3.  Much is not documented here as it would just be duplicating
GitLab's own [API Documentation](http://doc.gitlab.com/ce/api/README.html).

Note that this distribution also includes the [gitlab-api-v3](https://metacpan.org/pod/gitlab-api-v3) command-line
interface (CLI).

# CREDENTIALS

Authentication credentials may be defined by setting either the ["token"](#token),
the ["login"](#login) and ["password"](#password), or the ["email"](#email) and ["password"](#password) arguments.

When the object is constructed the ["login"](#login), ["email"](#email), and ["password"](#password)
arguments are used to call ["session"](#session) to generate a token.  The token is
saved in the ["token"](#token) attribute, and the login/email/password arguments
are discarded.

If no credentials are supplied then the client will be anonymous and greatly
limited in what it can do with the API.

## CONSTANTS

Several values in the GitLab API require looking up the numeric value
for a meaning (such as `access_level` and `visibility_level`).
Instead of doing that, you can use [GitLab::API::v3::Constants](https://metacpan.org/pod/GitLab::API::v3::Constants).

## EXCEPTIONS

The API methods will all throw (hopefully) a useful exception if
an unsuccessful response is received from the API.  That is except for
`GET` requests that return a `404` response - these will return `undef`
for methods that return a value.

If you'd like to catch and handle these exceptions consider using
[Try::Tiny](https://metacpan.org/pod/Try::Tiny).

## LOGGING

This module uses [Log::Any](https://metacpan.org/pod/Log::Any) and produces some debug messages here
and there, but the most useful bits are the info messages produced
just before each API call.

## PROJECT ID

Note that many API calls require a `$project_id`.  This can be
specified as either a numeric project `ID`, or as a
`NAMESPACE_PATH/PROJECT_PATH` in many cases.  Perhaps even
all cases, but the GitLab documentation on this point is vague.

## RETURN VALUES

Many of this module's methods should return a value but do not
currently.  This is due to the fact that this module was built
as a strict representation of GitLab's own documentation which
is often inconsistent.

If you find a method that should provide a return value, but
doesn't currently, please verify that GitLab actually does
return a value and then submit a pull request or open an issue.
See ["CONTRIBUTING"](#contributing) for more info.

# REQUIRED ARGUMENTS

## url

The URL to your v3 API endpoint.  Typically this will be something
like `http://git.example.com/api/v3`.

# OPTIONAL ARGUMENTS

## token

A GitLab API token.
If set then neither ["login"](#login) or ["email"](#email) may be set.
Read more in ["CREDENTIALS"](#credentials).

## login

A GitLab user login name.
If set then ["password"](#password) must be set.
Read more in ["CREDENTIALS"](#credentials).

## email

A GitLab user email.
If set then ["password"](#password) must be set.
Read more in ["CREDENTIALS"](#credentials).

## password

A GitLab user password.
This must be set if either ["login"](#login) or ["email"](#email) are set.
Read more in ["CREDENTIALS"](#credentials).

## rest\_client

An instance of [GitLab::API::v3::RESTClient](https://metacpan.org/pod/GitLab::API::v3::RESTClient).  Typically you will not
be setting this as it defaults to a new instance and customization
should not be necessary.

## retries

The number of times the request should be retried in case it does not succeed.
Defaults to 0, meaning that a failed request will not be retried.

# UTILITY METHODS

## paginator

    my $paginator = $api->paginator( $method, @method_args );
    
    my $members = $api->paginator('group_members', $group_id);
    while (my $member = $members->next()) {
        ...
    }
    
    my $users_pager = $api->paginator('users');
    while (my $users = $users_pager->next_page()) {
        ...
    }
    
    my $all_open_issues = $api->paginator(
        'issues',
        $project_id,
        { state=>'opened' },
    )->all();

Given a method who supports the `page` and `per_page` parameters,
and returns an array ref, this will return a [GitLab::API::v3::Paginator](https://metacpan.org/pod/GitLab::API::v3::Paginator)
object that will allow you to walk the records one page or one record
at a time.

# AWARD EMOJI METHODS

See [http://docs.gitlab.com/ce/api/award\_emoji.html](http://docs.gitlab.com/ce/api/award_emoji.html).

## issue\_award\_emojis

    my $award_emojis = $api->issue_award_emojis(
        $id,
        $issue_id,
    );

Sends a `GET` request to `/projects/:id/issues/:issue_id/award_emoji` and returns the decoded/deserialized response body.

## merge\_request\_award\_emojis

    my $award_emojis = $api->merge_request_award_emojis(
        $id,
        $merge_request_id,
    );

Sends a `GET` request to `/projects/:id/merge_requests/:merge_request_id/award_emoji` and returns the decoded/deserialized response body.

## issue\_award\_emoji

    my $award_emoji = $api->issue_award_emoji(
        $id,
        $issue_id,
        $award_id,
    );

Sends a `GET` request to `/projects/:id/issues/:issue_id/award_emoji/:award_id` and returns the decoded/deserialized response body.

## merge\_request\_award\_emoji

    my $award_emoji = $api->merge_request_award_emoji(
        $id,
        $merge_request_id,
        $award_id,
    );

Sends a `GET` request to `/projects/:id/merge_requests/:merge_request_id/award_emoji/:award_id` and returns the decoded/deserialized response body.

## create\_issue\_award\_emoji

    my $award_emoji = $api->create_issue_award_emoji(
        $id,
        $issue_id,
        \%params,
    );

Sends a `POST` request to `/projects/:id/issues/:issue_id/award_emoji` and returns the decoded/deserialized response body.

## create\_merge\_request\_award\_emoji

    my $award_emoji = $api->create_merge_request_award_emoji(
        $id,
        $merge_request_id,
        \%params,
    );

Sends a `POST` request to `/projects/:id/merge_requests/:merge_request_id/award_emoji` and returns the decoded/deserialized response body.

## delete\_issue\_award\_emoji

    my $award_emoji = $api->delete_issue_award_emoji(
        $id,
        $issue_id,
        $award_id,
    );

Sends a `DELETE` request to `/projects/:id/issues/:issue_id/award_emoji/:award_id` and returns the decoded/deserialized response body.

## delete\_merge\_request\_award\_emoji

    my $award_emoji = $api->delete_merge_request_award_emoji(
        $id,
        $merge_request_id,
        $award_id,
    );

Sends a `DELETE` request to `/projects/:id/merge_requests/:merge_request_id/award_emoji/:award_id` and returns the decoded/deserialized response body.

## issue\_note\_award\_emojis

    my $award_emojis = $api->issue_note_award_emojis(
        $id,
        $issue_id,
        $note_id,
    );

Sends a `GET` request to `/projects/:id/issues/:issue_id/notes/:note_id/award_emoji` and returns the decoded/deserialized response body.

## issue\_note\_award\_emoji

    my $award_emoji = $api->issue_note_award_emoji(
        $id,
        $issue_id,
        $note_id,
        $award_id,
    );

Sends a `GET` request to `/projects/:id/issues/:issue_id/notes/:note_id/award_emoji/:award_id` and returns the decoded/deserialized response body.

## create\_issue\_note\_award\_emoji

    my $award_emoji = $api->create_issue_note_award_emoji(
        $id,
        $issue_id,
        $note_id,
        \%params,
    );

Sends a `POST` request to `/projects/:id/issues/:issue_id/notes/:note_id/award_emoji` and returns the decoded/deserialized response body.

## delete\_issue\_note\_award\_emoji

    my $award_emoji = $api->delete_issue_note_award_emoji(
        $id,
        $issue_id,
        $note_id,
        $award_id,
    );

Sends a `DELETE` request to `/projects/:id/issues/:issue_id/notes/:note_id/award_emoji/:award_id` and returns the decoded/deserialized response body.

## merge\_request\_note\_award\_emojis

    my $award_emojis = $api->merge_request_note_award_emojis(
        $id,
        $merge_request_id,
        $note_id,
    );

Sends a `GET` request to `/projects/:id/merge_requests/:merge_request_id/notes/:note_id/award_emoji` and returns the decoded/deserialized response body.

## merge\_request\_note\_award\_emoji

    my $award_emoji = $api->merge_request_note_award_emoji(
        $id,
        $merge_request_id,
        $note_id,
        $award_id,
    );

Sends a `GET` request to `/projects/:id/merge_requests/:merge_request_id/notes/:note_id/award_emoji/:award_id` and returns the decoded/deserialized response body.

## create\_merge\_request\_note\_award\_emoji

    my $award_emoji = $api->create_merge_request_note_award_emoji(
        $id,
        $merge_request_id,
        $note_id,
        \%params,
    );

Sends a `POST` request to `/projects/:id/merge_requests/:merge_request_id/notes/:note_id/award_emoji` and returns the decoded/deserialized response body.

## delete\_merge\_request\_note\_award\_emoji

    my $award_emoji = $api->delete_merge_request_note_award_emoji(
        $id,
        $merge_request_id,
        $note_id,
        $award_id,
    );

Sends a `DELETE` request to `/projects/:id/merge_requests/:merge_request_id/notes/:note_id/award_emoji/:award_id` and returns the decoded/deserialized response body.

# BRANCH METHODS

See [http://doc.gitlab.com/ce/api/branches.html](http://doc.gitlab.com/ce/api/branches.html).

## branches

    my $branches = $api->branches(
        $project_id,
    );

Sends a `GET` request to `/projects/:project_id/repository/branches` and returns the decoded/deserialized response body.

## branch

    my $branch = $api->branch(
        $project_id,
        $branch_name,
    );

Sends a `GET` request to `/projects/:project_id/repository/branches/:branch_name` and returns the decoded/deserialized response body.

## protect\_branch

    $api->protect_branch(
        $project_id,
        $branch_name,
        \%params,
    );

Sends a `PUT` request to `/projects/:project_id/repository/branches/:branch_name/protect`.

## unprotect\_branch

    $api->unprotect_branch(
        $project_id,
        $branch_name,
    );

Sends a `PUT` request to `/projects/:project_id/repository/branches/:branch_name/unprotect`.

## create\_branch

    my $branch = $api->create_branch(
        $project_id,
        \%params,
    );

Sends a `POST` request to `/projects/:project_id/repository/branches` and returns the decoded/deserialized response body.

## delete\_branch

    $api->delete_branch(
        $project_id,
        $branch_name,
    );

Sends a `DELETE` request to `/projects/:project_id/repository/branches/:branch_name`.

# BUILD METHODS

See [http://docs.gitlab.com/ce/api/builds.html](http://docs.gitlab.com/ce/api/builds.html).

## builds

    my $builds = $api->builds(
        $id,
        \%params,
    );

Sends a `GET` request to `/projects/:id/builds` and returns the decoded/deserialized response body.

## commit\_builds

    my $builds = $api->commit_builds(
        $id,
        $sha,
        \%params,
    );

Sends a `GET` request to `/projects/:id/repository/commits/:sha/builds` and returns the decoded/deserialized response body.

## build

    my $build = $api->build(
        $id,
        $build_id,
    );

Sends a `GET` request to `/projects/:id/builds/:build_id` and returns the decoded/deserialized response body.

## build\_artifacts

    my $artifacts = $api->build_artifacts(
        $id,
        $build_id,
    );

Sends a `GET` request to `/projects/:id/builds/:build_id/artifacts` and returns the decoded/deserialized response body.

## build\_trace

    my $trace = $api->build_trace(
        $id,
        $build_id,
    );

Sends a `GET` request to `/projects/:id/builds/:build_id/trace` and returns the decoded/deserialized response body.

## cancel\_build

    my $build = $api->cancel_build(
        $id,
        $build_id,
    );

Sends a `POST` request to `/projects/:id/builds/:build_id/cancel` and returns the decoded/deserialized response body.

## retry\_build

    my $build = $api->retry_build(
        $id,
        $build_id,
    );

Sends a `POST` request to `/projects/:id/builds/:build_id/retry` and returns the decoded/deserialized response body.

## erase\_build

    my $build = $api->erase_build(
        $id,
        $build_id,
    );

Sends a `POST` request to `/projects/:id/builds/:build_id/erase` and returns the decoded/deserialized response body.

## keep\_build\_artifacts

    my $build = $api->keep_build_artifacts(
        $id,
        $build_id,
    );

Sends a `POST` request to `/projects/:id/builds/:build_id/artifacts/keep` and returns the decoded/deserialized response body.

# BUILD TRIGGER METHODS

See [http://docs.gitlab.com/ce/api/build\_triggers.html](http://docs.gitlab.com/ce/api/build_triggers.html).

## triggers

    my $triggers = $api->triggers(
        $id,
    );

Sends a `GET` request to `/projects/:id/triggers` and returns the decoded/deserialized response body.

## trigger

    my $trigger = $api->trigger(
        $id,
        $token,
    );

Sends a `GET` request to `/projects/:id/triggers/:token` and returns the decoded/deserialized response body.

## create\_trigger

    my $trigger = $api->create_trigger(
        $id,
    );

Sends a `POST` request to `/projects/:id/triggers` and returns the decoded/deserialized response body.

## delete\_trigger

    my $trigger = $api->delete_trigger(
        $id,
        $token,
    );

Sends a `DELETE` request to `/projects/:id/triggers/:token` and returns the decoded/deserialized response body.

# BUILD VARIABLE METHODS

See [http://docs.gitlab.com/ce/api/build\_variables.html](http://docs.gitlab.com/ce/api/build_variables.html).

## variables

    my $variables = $api->variables(
        $id,
    );

Sends a `GET` request to `/projects/:id/variables` and returns the decoded/deserialized response body.

## variable

    my $variable = $api->variable(
        $id,
        $key,
    );

Sends a `GET` request to `/projects/:id/variables/:key` and returns the decoded/deserialized response body.

## create\_variable

    my $variable = $api->create_variable(
        $id,
        \%params,
    );

Sends a `POST` request to `/projects/:id/variables` and returns the decoded/deserialized response body.

## update\_variable

    my $variable = $api->update_variable(
        $id,
        $key,
        \%params,
    );

Sends a `PUT` request to `/projects/:id/variables/:key` and returns the decoded/deserialized response body.

## delete\_variable

    my $variable = $api->delete_variable(
        $id,
        $key,
    );

Sends a `DELETE` request to `/projects/:id/variables/:key` and returns the decoded/deserialized response body.

# COMMIT METHODS

See [http://doc.gitlab.com/ce/api/commits.html](http://doc.gitlab.com/ce/api/commits.html).

## commits

    my $commits = $api->commits(
        $project_id,
        \%params,
    );

Sends a `GET` request to `/projects/:project_id/repository/commits` and returns the decoded/deserialized response body.

## commit

    my $commit = $api->commit(
        $project_id,
        $commit_sha,
    );

Sends a `GET` request to `/projects/:project_id/repository/commits/:commit_sha` and returns the decoded/deserialized response body.

## commit\_diff

    my $diff = $api->commit_diff(
        $project_id,
        $commit_sha,
    );

Sends a `GET` request to `/projects/:project_id/repository/commits/:commit_sha/diff` and returns the decoded/deserialized response body.

## commit\_comments

    my $comments = $api->commit_comments(
        $project_id,
        $commit_sha,
    );

Sends a `GET` request to `/projects/:project_id/repository/commits/:commit_sha/comments` and returns the decoded/deserialized response body.

## add\_commit\_comment

    $api->add_commit_comment(
        $project_id,
        $commit_sha,
        \%params,
    );

Sends a `POST` request to `/projects/:project_id/repository/commits/:commit_sha/comments`.

# DEPLOY KEY METHODS

See [http://doc.gitlab.com/ce/api/deploy\_keys.html](http://doc.gitlab.com/ce/api/deploy_keys.html).

## deploy\_keys

    my $keys = $api->deploy_keys(
        $project_id,
    );

Sends a `GET` request to `/projects/:project_id/keys` and returns the decoded/deserialized response body.

## deploy\_key

    my $key = $api->deploy_key(
        $project_id,
        $key_id,
    );

Sends a `GET` request to `/projects/:project_id/keys/:key_id` and returns the decoded/deserialized response body.

## create\_deploy\_key

    $api->create_deploy_key(
        $project_id,
        \%params,
    );

Sends a `POST` request to `/projects/:project_id/keys`.

## delete\_deploy\_key

    $api->delete_deploy_key(
        $project_id,
        $key_id,
    );

Sends a `DELETE` request to `/projects/:project_id/keys/:key_id`.

# GROUP METHODS

See [http://doc.gitlab.com/ce/api/groups.html](http://doc.gitlab.com/ce/api/groups.html).

## groups

    my $groups = $api->groups();

Sends a `GET` request to `/groups` and returns the decoded/deserialized response body.

## group

    my $group = $api->group(
        $group_id,
    );

Sends a `GET` request to `/groups/:group_id` and returns the decoded/deserialized response body.

## create\_group

    $api->create_group(
        \%params,
    );

Sends a `POST` request to `/groups`.

## transfer\_project

    $api->transfer_project(
        $group_id,
        $project_id,
    );

Sends a `POST` request to `/groups/:group_id/projects/:project_id`.

## delete\_group

    $api->delete_group(
        $group_id,
    );

Sends a `DELETE` request to `/groups/:group_id`.

## search\_groups

    my $groups = $api->search_groups(
        \%params,
    );

Sends a `GET` request to `/groups` and returns the decoded/deserialized response body.

## group\_members

    my $members = $api->group_members(
        $group_id,
    );

Sends a `GET` request to `/groups/:group_id/members` and returns the decoded/deserialized response body.

## group\_projects

    my $projects = $api->group_projects(
        $group_id,
        \%params,
    );

Sends a `GET` request to `/groups/:group_id/projects` and returns the decoded/deserialized response body.

## add\_group\_member

    $api->add_group_member(
        $group_id,
        \%params,
    );

Sends a `POST` request to `/groups/:group_id/members`.

## edit\_group\_member

    $api->edit_group_member(
        $group_id,
        $user_id,
        \%params,
    );

Sends a `PUT` request to `/groups/:group_id/members/:user_id`.

## remove\_group\_member

    $api->remove_group_member(
        $group_id,
        $user_id,
    );

Sends a `DELETE` request to `/groups/:group_id/members/:user_id`.

# ISSUE METHODS

See [http://doc.gitlab.com/ce/api/issues.html](http://doc.gitlab.com/ce/api/issues.html).

## all\_issues

    my $issues = $api->all_issues(
        \%params,
    );

Sends a `GET` request to `/issues` and returns the decoded/deserialized response body.

## issues

    my $issues = $api->issues(
        $project_id,
        \%params,
    );

Sends a `GET` request to `/projects/:project_id/issues` and returns the decoded/deserialized response body.

## issue

    my $issue = $api->issue(
        $project_id,
        $issue_id,
    );

Sends a `GET` request to `/projects/:project_id/issues/:issue_id` and returns the decoded/deserialized response body.

## create\_issue

    my $issue = $api->create_issue(
        $project_id,
        \%params,
    );

Sends a `POST` request to `/projects/:project_id/issues` and returns the decoded/deserialized response body.

## edit\_issue

    my $issue = $api->edit_issue(
        $project_id,
        $issue_id,
        \%params,
    );

Sends a `PUT` request to `/projects/:project_id/issues/:issue_id` and returns the decoded/deserialized response body.

# KEY METHODS

See [http://docs.gitlab.com/ce/api/keys.html](http://docs.gitlab.com/ce/api/keys.html).

## key

    my $key = $api->key(
        $key_id,
    );

Sends a `GET` request to `/keys/:key_id` and returns the decoded/deserialized response body.

# LABEL METHODS

See [http://doc.gitlab.com/ce/api/labels.html](http://doc.gitlab.com/ce/api/labels.html).

## labels

    my $labels = $api->labels(
        $project_id,
    );

Sends a `GET` request to `/projects/:project_id/labels` and returns the decoded/deserialized response body.

## create\_label

    my $label = $api->create_label(
        $project_id,
        \%params,
    );

Sends a `POST` request to `/projects/:project_id/labels` and returns the decoded/deserialized response body.

## delete\_label

    $api->delete_label(
        $project_id,
        \%params,
    );

Sends a `DELETE` request to `/projects/:project_id/labels`.

## edit\_label

    my $label = $api->edit_label(
        $project_id,
        \%params,
    );

Sends a `PUT` request to `/projects/:project_id/labels` and returns the decoded/deserialized response body.

# MERGE REQUEST METHODS

See [http://doc.gitlab.com/ce/api/merge\_requests.html](http://doc.gitlab.com/ce/api/merge_requests.html).

## merge\_requests

    my $merge_requests = $api->merge_requests(
        $project_id,
        \%params,
    );

Sends a `GET` request to `/projects/:project_id/merge_requests` and returns the decoded/deserialized response body.

## merge\_request

    my $merge_request = $api->merge_request(
        $project_id,
        $merge_request_id,
    );

Sends a `GET` request to `/projects/:project_id/merge_request/:merge_request_id` and returns the decoded/deserialized response body.

## create\_merge\_request

    my $merge_request = $api->create_merge_request(
        $project_id,
        \%params,
    );

Sends a `POST` request to `/projects/:project_id/merge_requests` and returns the decoded/deserialized response body.

## edit\_merge\_request

    my $merge_request = $api->edit_merge_request(
        $project_id,
        $merge_request_id,
        \%params,
    );

Sends a `PUT` request to `/projects/:project_id/merge_requests/:merge_request_id` and returns the decoded/deserialized response body.

## accept\_merge\_request

    $api->accept_merge_request(
        $project_id,
        $merge_request_id,
        \%params,
    );

Sends a `PUT` request to `/projects/:project_id/merge_requests/:merge_request_id/merge`.

## add\_merge\_request\_comment

    $api->add_merge_request_comment(
        $project_id,
        $merge_request_id,
        \%params,
    );

Sends a `POST` request to `/projects/:project_id/merge_requests/:merge_request_id/comments`.

## merge\_request\_comments

    my $comments = $api->merge_request_comments(
        $project_id,
        $merge_request_id,
    );

Sends a `GET` request to `/projects/:project_id/merge_requests/:merge_request_id/comments` and returns the decoded/deserialized response body.

# MILESTONE METHODS

See [http://doc.gitlab.com/ce/api/milestones.html](http://doc.gitlab.com/ce/api/milestones.html).

## milestones

    my $milestones = $api->milestones(
        $project_id,
        \%params,
    );

Sends a `GET` request to `/projects/:project_id/milestones` and returns the decoded/deserialized response body.

## milestone

    my $milestone = $api->milestone(
        $project_id,
        $milestone_id,
    );

Sends a `GET` request to `/projects/:project_id/milestones/:milestone_id` and returns the decoded/deserialized response body.

## create\_milestone

    $api->create_milestone(
        $project_id,
        \%params,
    );

Sends a `POST` request to `/projects/:project_id/milestones`.

## edit\_milestone

    $api->edit_milestone(
        $project_id,
        $milestone_id,
        \%params,
    );

Sends a `PUT` request to `/projects/:project_id/milestones/:milestone_id`.

## milestone\_issues

    my $issues = $api->milestone_issues(
        $project_id,
        $milestone_id,
    );

Sends a `GET` request to `/projects/:project_id/milestones/:milestone_id/issues` and returns the decoded/deserialized response body.

# OPEN SOURCE LICENSES METHODS

See [http://docs.gitlab.com/ce/api/licenses.html](http://docs.gitlab.com/ce/api/licenses.html).

## licenses

    my $licenses = $api->licenses(
        \%params,
    );

Sends a `GET` request to `/licenses` and returns the decoded/deserialized response body.

## license

    my $license = $api->license(
        $license_key,
        \%params,
    );

Sends a `GET` request to `/licenses/:license_key` and returns the decoded/deserialized response body.

# NAMESPACE METHODS

See [http://docs.gitlab.com/ce/api/namespaces.html](http://docs.gitlab.com/ce/api/namespaces.html).

## namespaces

    my $namespaces = $api->namespaces(
        \%params,
    );

Sends a `GET` request to `/namespaces` and returns the decoded/deserialized response body.

# NOTE METHODS

See [http://doc.gitlab.com/ce/api/notes.html](http://doc.gitlab.com/ce/api/notes.html).

## notes

    my $notes = $api->notes(
        $project_id,
        $thing_type,
        $thing_id,
    );

Sends a `GET` request to `/projects/:project_id/:thing_type/:thing_id/notes` and returns the decoded/deserialized response body.

## note

    my $note = $api->note(
        $project_id,
        $thing_type,
        $thing_id,
        $note_id,
    );

Sends a `GET` request to `/projects/:project_id/:thing_type/:thing_id/notes/:note_id` and returns the decoded/deserialized response body.

## create\_note

    $api->create_note(
        $project_id,
        $thing_type,
        $thing_id,
        \%params,
    );

Sends a `POST` request to `/projects/:project_id/:thing_type/:thing_id/notes`.

## edit\_note

    $api->edit_note(
        $project_id,
        $thing_type,
        $thing_id,
        $note_id,
        \%params,
    );

Sends a `PUT` request to `/projects/:project_id/:thing_type/:thing_id/notes/:note_id`.

# PROJECT METHODS

See [http://doc.gitlab.com/ce/api/projects.html](http://doc.gitlab.com/ce/api/projects.html).

## projects

    my $projects = $api->projects(
        \%params,
    );

Sends a `GET` request to `/projects` and returns the decoded/deserialized response body.

## owned\_projects

    my $projects = $api->owned_projects(
        \%params,
    );

Sends a `GET` request to `/projects/owned` and returns the decoded/deserialized response body.

## all\_projects

    my $projects = $api->all_projects(
        \%params,
    );

Sends a `GET` request to `/projects/all` and returns the decoded/deserialized response body.

## project

    my $project = $api->project(
        $project_id,
    );

Sends a `GET` request to `/projects/:project_id` and returns the decoded/deserialized response body.

## project\_events

    my $events = $api->project_events(
        $project_id,
    );

Sends a `GET` request to `/projects/:project_id/events` and returns the decoded/deserialized response body.

## create\_project

    my $project = $api->create_project(
        \%params,
    );

Sends a `POST` request to `/projects` and returns the decoded/deserialized response body.

## create\_project\_for\_user

    $api->create_project_for_user(
        $user_id,
        \%params,
    );

Sends a `POST` request to `/projects/user/:user_id`.

## edit\_project

    my $project = $api->edit_project(
        $project_id,
        \%params,
    );

Sends a `PUT` request to `/projects/:project_id` and returns the decoded/deserialized response body.

## fork\_project

    $api->fork_project(
        $project_id,
    );

Sends a `POST` request to `/pojects/fork/:project_id`.

## delete\_project

    $api->delete_project(
        $project_id,
    );

Sends a `DELETE` request to `/projects/:project_id`.

## project\_members

    my $members = $api->project_members(
        $project_id,
        \%params,
    );

Sends a `GET` request to `/projects/:project_id/members` and returns the decoded/deserialized response body.

## project\_member

    my $member = $api->project_member(
        $project_id,
        $user_id,
    );

Sends a `GET` request to `/project/:project_id/members/:user_id` and returns the decoded/deserialized response body.

## add\_project\_member

    $api->add_project_member(
        $project_id,
        \%params,
    );

Sends a `POST` request to `/projects/:project_id/members`.

## edit\_project\_member

    $api->edit_project_member(
        $project_id,
        $user_id,
        \%params,
    );

Sends a `PUT` request to `/projects/:project_id/members/:user_id`.

## remove\_project\_member

    $api->remove_project_member(
        $project_id,
        $user_id,
    );

Sends a `DELETE` request to `/projects/:project_id/members/:user_id`.

## share\_project\_with\_group

    $api->share_project_with_group(
        $id,
        \%params,
    );

Sends a `POST` request to `/projects/:id/share`.

## delete\_shared\_project\_link\_within\_group

    $api->delete_shared_project_link_within_group(
        $id,
        $group_id,
    );

Sends a `DELETE` request to `/projects/:id/share/:group_id`.

## project\_hooks

    my $hooks = $api->project_hooks(
        $project_id,
    );

Sends a `GET` request to `/projects/:project_id/hooks` and returns the decoded/deserialized response body.

## project\_hook

    my $hook = $api->project_hook(
        $project_id,
        $hook_id,
    );

Sends a `GET` request to `/project/:project_id/hooks/:hook_id` and returns the decoded/deserialized response body.

## create\_project\_hook

    $api->create_project_hook(
        $project_id,
        \%params,
    );

Sends a `POST` request to `/projects/:project_id/hooks`.

## edit\_project\_hook

    $api->edit_project_hook(
        $project_id,
        $hook_id,
        \%params,
    );

Sends a `PUT` request to `/projects/:project_id/hooks/:hook_id`.

## delete\_project\_hook

    my $hook = $api->delete_project_hook(
        $project_id,
        $hook_id,
    );

Sends a `DELETE` request to `/projects/:project_id/hooks/:hook_id` and returns the decoded/deserialized response body.

## set\_project\_fork

    $api->set_project_fork(
        $project_id,
        $forked_from_id,
    );

Sends a `POST` request to `/projects/:project_id/fork/:forked_from_id`.

## clear\_project\_fork

    $api->clear_project_fork(
        $project_id,
    );

Sends a `DELETE` request to `/projects/:project_id/fork`.

## search\_projects\_by\_name

    my $projects = $api->search_projects_by_name(
        $query,
        \%params,
    );

Sends a `GET` request to `/projects/search/:query` and returns the decoded/deserialized response body.

# PROJECT SNIPPET METHODS

See [http://doc.gitlab.com/ce/api/project\_snippets.html](http://doc.gitlab.com/ce/api/project_snippets.html).

## snippets

    my $snippets = $api->snippets(
        $project_id,
    );

Sends a `GET` request to `/projects/:project_id/snippets` and returns the decoded/deserialized response body.

## snippet

    my $snippet = $api->snippet(
        $project_id,
        $snippet_id,
    );

Sends a `GET` request to `/projects/:project_id/snippets/:snippet_id` and returns the decoded/deserialized response body.

## create\_snippet

    $api->create_snippet(
        $project_id,
        \%params,
    );

Sends a `POST` request to `/projects/:project_id/snippets`.

## edit\_snippet

    $api->edit_snippet(
        $project_id,
        $snippet_id,
        \%params,
    );

Sends a `PUT` request to `/projects/:project_id/snippets/:snippet_id`.

## delete\_snippet

    $api->delete_snippet(
        $project_id,
        $snippet_id,
    );

Sends a `DELETE` request to `/projects/:project_id/snippets/:snippet_id`.

## snippet\_content

    my $content = $api->snippet_content(
        $project_id,
        $snippet_id,
    );

Sends a `GET` request to `/projects/:project_id/snippets/:snippet_id/raw` and returns the decoded/deserialized response body.

# REPOSITORY METHODS

See [http://doc.gitlab.com/ce/api/repositories.html](http://doc.gitlab.com/ce/api/repositories.html).

## tree

    my $tree = $api->tree(
        $project_id,
        \%params,
    );

Sends a `GET` request to `/projects/:project_id/repository/tree` and returns the decoded/deserialized response body.

## blob

    my $blob = $api->blob(
        $project_id,
        $ref,
        \%params,
    );

Sends a `GET` request to `/projects/:project_id/repository/blobs/:ref` and returns the decoded/deserialized response body.

## raw\_blob

    my $raw_blob = $api->raw_blob(
        $project_id,
        $blob_sha,
    );

Sends a `GET` request to `/projects/:project_id/repository/raw_blobs/:blob_sha` and returns the decoded/deserialized response body.

## archive

    my $archive = $api->archive(
        $project_id,
        \%params,
    );

Sends a `GET` request to `/projects/:project_id/repository/archive` and returns the decoded/deserialized response body.

## compare

    my $comparison = $api->compare(
        $project_id,
        \%params,
    );

Sends a `GET` request to `/projects/:project_id/repository/compare` and returns the decoded/deserialized response body.

## contributors

    my $contributors = $api->contributors(
        $project_id,
    );

Sends a `GET` request to `/projects/:project_id/repository/contributors` and returns the decoded/deserialized response body.

# FILE METHODS

See [http://doc.gitlab.com/ce/api/repository\_files.html](http://doc.gitlab.com/ce/api/repository_files.html).

## file

    my $file = $api->file(
        $project_id,
        \%params,
    );

Sends a `GET` request to `/projects/:project_id/repository/files` and returns the decoded/deserialized response body.

## create\_file

    $api->create_file(
        $project_id,
        \%params,
    );

Sends a `POST` request to `/projects/:project_id/repository/files`.

## edit\_file

    $api->edit_file(
        $project_id,
        \%params,
    );

Sends a `PUT` request to `/projects/:project_id/repository/files`.

## delete\_file

    $api->delete_file(
        $project_id,
        \%params,
    );

Sends a `DELETE` request to `/projects/:project_id/repository/files`.

# RUNNER METHODS

See [http://docs.gitlab.com/ce/api/runners.html](http://docs.gitlab.com/ce/api/runners.html).

## runners

    my $runners = $api->runners(
        \%params,
    );

Sends a `GET` request to `/runners` and returns the decoded/deserialized response body.

## all\_runners

    my $runners = $api->all_runners(
        \%params,
    );

Sends a `GET` request to `/runners/all` and returns the decoded/deserialized response body.

## runner

    my $runner = $api->runner(
        $id,
    );

Sends a `GET` request to `/runners/:id` and returns the decoded/deserialized response body.

## update\_runner

    my $runner = $api->update_runner(
        $id,
        \%params,
    );

Sends a `PUT` request to `/runners/:id` and returns the decoded/deserialized response body.

## delete\_runner

    my $runner = $api->delete_runner(
        $id,
    );

Sends a `DELETE` request to `/runners/:id` and returns the decoded/deserialized response body.

## project\_runners

    my $runners = $api->project_runners(
        $id,
    );

Sends a `GET` request to `/projects/:id/runners` and returns the decoded/deserialized response body.

## enable\_project\_runner

    my $runner = $api->enable_project_runner(
        $id,
        \%params,
    );

Sends a `POST` request to `/projects/:id/runners` and returns the decoded/deserialized response body.

## disable\_project\_runner

    my $runner = $api->disable_project_runner(
        $id,
        $runner_id,
    );

Sends a `DELETE` request to `/projects/:id/runners/:runner_id` and returns the decoded/deserialized response body.

# SERVICE METHODS

See [http://doc.gitlab.com/ce/api/services.html](http://doc.gitlab.com/ce/api/services.html).

## edit\_project\_service

    $api->edit_project_service(
        $project_id,
        $service_name,
        \%params,
    );

Sends a `PUT` request to `/projects/:project_id/services/:service_name`.

## delete\_project\_service

    $api->delete_project_service(
        $project_id,
        $service_name,
    );

Sends a `DELETE` request to `/projects/:project_id/services/:service_name`.

# SESSION METHODS

See [http://doc.gitlab.com/ce/api/session.html](http://doc.gitlab.com/ce/api/session.html).

## session

    my $session = $api->session(
        \%params,
    );

Sends a `POST` request to `/session` and returns the decoded/deserialized response body.

# SETTINGS METHODS

See [http://docs.gitlab.com/ce/api/settings.html](http://docs.gitlab.com/ce/api/settings.html).

## settings

    my $settings = $api->settings();

Sends a `GET` request to `/application/settings` and returns the decoded/deserialized response body.

## update\_settings

    my $settings = $api->update_settings(
        \%params,
    );

Sends a `PUT` request to `/application/settings` and returns the decoded/deserialized response body.

# SIDEKIQ METHODS

See [http://docs.gitlab.com/ce/api/sidekiq\_metrics.html](http://docs.gitlab.com/ce/api/sidekiq_metrics.html).

## queue\_metrics

    my $metrics = $api->queue_metrics();

Sends a `GET` request to `/sidekiq/queue_metrics` and returns the decoded/deserialized response body.

## process\_metrics

    my $metrics = $api->process_metrics();

Sends a `GET` request to `/sidekiq/process_metrics` and returns the decoded/deserialized response body.

## job\_stats

    my $stats = $api->job_stats();

Sends a `GET` request to `/sidekiq/job_stats` and returns the decoded/deserialized response body.

## compound\_metrics

    my $metrics = $api->compound_metrics();

Sends a `GET` request to `/sidekiq/compound_metrics` and returns the decoded/deserialized response body.

# USER SNIPPET METHODS

See [http://docs.gitlab.com/ce/api/snippets.html](http://docs.gitlab.com/ce/api/snippets.html).

## user\_snippets

    my $snippets = $api->user_snippets();

Sends a `GET` request to `/snippets` and returns the decoded/deserialized response body.

## user\_snippet

    my $snippet = $api->user_snippet(
        $snippet_id,
    );

Sends a `GET` request to `/snippets/:snippet_id` and returns the decoded/deserialized response body.

## create\_user\_snippet

    $api->create_user_snippet(
        \%params,
    );

Sends a `POST` request to `/snippets`.

## edit\_user\_snippet

    $api->edit_user_snippet(
        $snippet_id,
        \%params,
    );

Sends a `PUT` request to `/snippets/:snippet_id`.

## delete\_user\_snippet

    $api->delete_user_snippet(
        $snippet_id,
    );

Sends a `DELETE` request to `/snippets/:snippet_id`.

## public\_snippets

    my $snippets = $api->public_snippets();

Sends a `GET` request to `/snippets/public` and returns the decoded/deserialized response body.

# SYSTEM HOOK METHODS

See [http://doc.gitlab.com/ce/api/system\_hooks.html](http://doc.gitlab.com/ce/api/system_hooks.html).

## hooks

    my $hooks = $api->hooks();

Sends a `GET` request to `/hooks` and returns the decoded/deserialized response body.

## create\_hook

    $api->create_hook(
        \%params,
    );

Sends a `POST` request to `/hooks`.

## test\_hook

    my $hook = $api->test_hook(
        $hook_id,
    );

Sends a `GET` request to `/hooks/:hook_id` and returns the decoded/deserialized response body.

## delete\_hook

    $api->delete_hook(
        $hook_id,
    );

Sends a `DELETE` request to `/hooks/:hook_id`.

# TAG METHODS

See [http://docs.gitlab.com/ce/api/tags.html](http://docs.gitlab.com/ce/api/tags.html).

## tags

    my $tags = $api->tags(
        $project_id,
    );

Sends a `GET` request to `/projects/:project_id/repository/tags` and returns the decoded/deserialized response body.

## tag

    my $tag = $api->tag(
        $project_id,
        $tag_name,
    );

Sends a `GET` request to `/projects/:project_id/repository/tags/:tag_name` and returns the decoded/deserialized response body.

## create\_tag

    my $tag = $api->create_tag(
        $project_id,
        \%params,
    );

Sends a `POST` request to `/projects/:project_id/repository/tags` and returns the decoded/deserialized response body.

## delete\_tag

    $api->delete_tag(
        $project_id,
        $tag_name,
    );

Sends a `DELETE` request to `/projects/:project_id/repository/tags/:tag_name`.

## create\_release

    $api->create_release(
        $project_id,
        $tag_name,
        \%params,
    );

Sends a `POST` request to `/projects/:project_id/repository/tags/:tag_name/release`.

## update\_release

    $api->update_release(
        $project_id,
        $tag_name,
        \%params,
    );

Sends a `PUT` request to `/projects/:project_id/repository/tags/:tag_name/release`.

# USER METHODS

See [http://doc.gitlab.com/ce/api/users.html](http://doc.gitlab.com/ce/api/users.html).

## users

    my $users = $api->users(
        \%params,
    );

Sends a `GET` request to `/users` and returns the decoded/deserialized response body.

## user

    my $user = $api->user(
        $user_id,
    );

Sends a `GET` request to `/users/:user_id` and returns the decoded/deserialized response body.

## create\_user

    $api->create_user(
        \%params,
    );

Sends a `POST` request to `/users`.

## edit\_user

    $api->edit_user(
        $user_id,
        \%params,
    );

Sends a `PUT` request to `/users/:user_id`.

## delete\_user

    my $user = $api->delete_user(
        $user_id,
    );

Sends a `DELETE` request to `/users/:user_id` and returns the decoded/deserialized response body.

## current\_user

    my $user = $api->current_user();

Sends a `GET` request to `/user` and returns the decoded/deserialized response body.

## current\_user\_ssh\_keys

    my $keys = $api->current_user_ssh_keys();

Sends a `GET` request to `/user/keys` and returns the decoded/deserialized response body.

## user\_ssh\_keys

    my $keys = $api->user_ssh_keys(
        $user_id,
    );

Sends a `GET` request to `/users/:user_id/keys` and returns the decoded/deserialized response body.

## user\_ssh\_key

    my $key = $api->user_ssh_key(
        $key_id,
    );

Sends a `GET` request to `/user/keys/:key_id` and returns the decoded/deserialized response body.

## create\_current\_user\_ssh\_key

    $api->create_current_user_ssh_key(
        \%params,
    );

Sends a `POST` request to `/user/keys`.

## create\_user\_ssh\_key

    $api->create_user_ssh_key(
        $user_id,
        \%params,
    );

Sends a `POST` request to `/users/:user_id/keys`.

## delete\_current\_user\_ssh\_key

    $api->delete_current_user_ssh_key(
        $key_id,
    );

Sends a `DELETE` request to `/user/keys/:key_id`.

## delete\_user\_ssh\_key

    $api->delete_user_ssh_key(
        $user_id,
        $key_id,
    );

Sends a `DELETE` request to `/users/:user_id/keys/:key_id`.

# SEE ALSO

[Net::Gitlab](https://metacpan.org/pod/Net::Gitlab) purports to provide an interface to the GitLab API, but
it is hard to tell due to a complete lack of documentation via either
POD or unit tests.

# CONTRIBUTING

This module is auto-generated from a set of YAML files defining the
interface of GitLab's API.  If you'd like to contribute to this module
then please feel free to make a
[fork on GitHub](https://github.com/bluefeet/GitLab-API-v3)
and submit a pull request, just make sure you edit the files in the
`authors/` directory instead of `lib/GitLab/API/v3.pm` directly.

Please see
[https://github.com/bluefeet/GitLab-API-v3/blob/master/author/README.pod](https://github.com/bluefeet/GitLab-API-v3/blob/master/author/README.pod)
for more information.

Alternatively, you can
[open a ticket](https://github.com/bluefeet/GitLab-API-v3/issues).

# AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>
    Dotan Dimet <dotan@corky.net>
    Nigel Gregoire <nigelgregoire@gmail.com>
    trunov-ms <trunov.ms@gmail.com>
    Marek R. Sotola <Marek.R.Sotola@nasa.gov>
    José Joaquín Atria <jjatria@gmail.com>
    Dave Webb <github@d5ve.com>

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
