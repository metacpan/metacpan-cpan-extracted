package InlineTest;
use strict;
use warnings;
use 5.010;

use JSON::PP;

sub constructor_args {
    return {
        url => 'http://localhost:8080',
        username => 'foo',
        password => 'foo',
    };
}

sub project_data {
    my $projav = 'http://localhost:8080/secure/projectavatar';
    my $projcat = 'http://localhost:8080/rest/api/latest/projectCategory';
    return ({
        avatarUrls => {
            "16x16" => "$projav?size=xsmall&pid=10003&avatarId=10204",
            "24x24" => "$projav?size=small&pid=10003&avatarId=10204",
            "32x32" => "$projav?size=medium&pid=10003&avatarId=10204",
            "48x48" => "$projav?pid=10003&avatarId=10204"
        },
        expand => "description,lead,url,projectKeys",
        id => 10003,
        key => "JRC",
        name => "JIRA::REST::Class",
        projectCategory => {
            description => "These are Packy's Perl projects",
            id => 10002,
            name => "Perl",
            self => "$projcat/10002"
        },
        projectTypeKey => "software",
        self => "http://localhost:8080/rest/api/2/project/10003"
    },
    {
        avatarUrls => {
            "16x16" => "$projav?size=xsmall&avatarId=10324",
            "24x24" => "$projav?size=small&avatarId=10324",
            "32x32" => "$projav?size=medium&avatarId=10324",
            "48x48" => "$projav?avatarId=10324"
        },
        expand => "description,lead,url,projectKeys",
        id => 10001,
        key => "KANBAN",
        name => "Kanban software development sample project",
        projectCategory => {
            description => "These are the demo projects that came with JIRA",
            id => 10000,
            name => "Demo",
            self => "$projcat/10000"
        },
        projectTypeKey => "software",
        self => "http://localhost:8080/rest/api/2/project/10001"
    },
    {
        avatarUrls => {
            "16x16" => "$projav?size=xsmall&pid=10004&avatarId=10001",
            "24x24" => "$projav?size=small&pid=10004&avatarId=10001",
            "32x32" => "$projav?size=medium&pid=10004&avatarId=10001",
            "48x48" => "$projav?pid=10004&avatarId=10001"
        },
        expand => "description,lead,url,projectKeys",
        id => 10004,
        key => "PACKAY",
        name => "PacKay Productions",
        projectCategory => {
            description => "These are projects for PacKay Productions",
            id => 10001,
            name => "Puppet",
            self => "$projcat/10001"
        },
        projectTypeKey => "business",
        self => "http://localhost:8080/rest/api/2/project/10004"
    },
    {
        avatarUrls => {
            "16x16" => "$projav?size=xsmall&pid=10000&avatarId=10327",
            "24x24" => "$projav?size=small&pid=10000&avatarId=10327",
            "32x32" => "$projav?size=medium&pid=10000&avatarId=10327",
            "48x48" => "$projav?pid=10000&avatarId=10327"
        },
        expand => "description,lead,url,projectKeys",
        id => 10000,
        key => "PM",
        name => "Project Management Sample Project",
        projectCategory => {
            description => "These are the demo projects that came with JIRA",
            id => 10000,
            name => "Demo",
            self => "$projcat/10000"
        },
        projectTypeKey => "business",
        self => "http://localhost:8080/rest/api/2/project/10000"
    },
    {
        avatarUrls => {
            "16x16" => "$projav?size=xsmall&pid=10002&avatarId=10325",
            "24x24" => "$projav?size=small&pid=10002&avatarId=10325",
            "32x32" => "$projav?size=medium&pid=10002&avatarId=10325",
            "48x48" => "$projav?pid=10002&avatarId=10325"
        },
        expand => "description,lead,url,projectKeys",
        id => 10002,
        key => "SCRUM",
        name => "Scrum Software Development Sample Project",
        projectCategory => {
            description => "These are the demo projects that came with JIRA",
            id => 10000,
            name => "Demo",
            self => "$projcat/10000"
        },
        projectTypeKey => "software",
        self => "http://localhost:8080/rest/api/2/project/10002"
    });
}

sub permissions_data {
    return {
        permissions => {
            ADD_COMMENTS => {
                description => "Ability to comment on issues.",
                havePermission => JSON::PP::true,
                id => 15,
                key => "ADD_COMMENTS",
                name => "Add Comments",
                type => "PROJECT"
            },
            ADMINISTER => {
                description => "Ability to perform most administration functions (excluding Import & Export, SMTP Configuration, etc.).",
                havePermission => JSON::PP::true,
                id => 0,
                key => "ADMINISTER",
                name => "JIRA Administrators",
                type => "GLOBAL"
            },
            ADMINISTER_PROJECTS => {
                description => "Ability to administer a project in JIRA.",
                havePermission => JSON::PP::true,
                id => 23,
                key => "ADMINISTER_PROJECTS",
                name => "Administer Projects",
                type => "PROJECT"
            },
            ASSIGNABLE_USER => {
                description => "Users with this permission may be assigned to issues.",
                havePermission => JSON::PP::true,
                id => 17,
                key => "ASSIGNABLE_USER",
                name => "Assignable User",
                type => "PROJECT"
            },
            ASSIGN_ISSUE => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to assign issues to other people.",
                havePermission => JSON::PP::true,
                id => 13,
                key => "ASSIGN_ISSUE",
                name => "Assign Issues",
                type => "PROJECT"
            },
            ASSIGN_ISSUES => {
                description => "Ability to assign issues to other people.",
                havePermission => JSON::PP::true,
                id => 13,
                key => "ASSIGN_ISSUES",
                name => "Assign Issues",
                type => "PROJECT"
            },
            ATTACHMENT_DELETE_ALL => {
                deprecatedKey => JSON::PP::true,
                description => "Users with this permission may delete all attachments.",
                havePermission => JSON::PP::true,
                id => 38,
                key => "ATTACHMENT_DELETE_ALL",
                name => "Delete All Attachments",
                type => "PROJECT"
            },
            ATTACHMENT_DELETE_OWN => {
                deprecatedKey => JSON::PP::true,
                description => "Users with this permission may delete own attachments.",
                havePermission => JSON::PP::true,
                id => 39,
                key => "ATTACHMENT_DELETE_OWN",
                name => "Delete Own Attachments",
                type => "PROJECT"
            },
            BROWSE => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to browse projects and the issues within them.",
                havePermission => JSON::PP::true,
                id => 10,
                key => "BROWSE",
                name => "Browse Projects",
                type => "PROJECT"
            },
            BROWSE_PROJECTS => {
                description => "Ability to browse projects and the issues within them.",
                havePermission => JSON::PP::true,
                id => 10,
                key => "BROWSE_PROJECTS",
                name => "Browse Projects",
                type => "PROJECT"
            },
            BULK_CHANGE => {
                description => "Ability to modify a collection of issues at once. For example, resolve multiple issues in one step.",
                havePermission => JSON::PP::true,
                id => 33,
                key => "BULK_CHANGE",
                name => "Bulk Change",
                type => "GLOBAL"
            },
            CLOSE_ISSUE => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to close issues. Often useful where your developers resolve issues, and a QA department closes them.",
                havePermission => JSON::PP::true,
                id => 18,
                key => "CLOSE_ISSUE",
                name => "Close Issues",
                type => "PROJECT"
            },
            CLOSE_ISSUES => {
                description => "Ability to close issues. Often useful where your developers resolve issues, and a QA department closes them.",
                havePermission => JSON::PP::true,
                id => 18,
                key => "CLOSE_ISSUES",
                name => "Close Issues",
                type => "PROJECT"
            },
            COMMENT_DELETE_ALL => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to delete all comments made on issues.",
                havePermission => JSON::PP::true,
                id => 36,
                key => "COMMENT_DELETE_ALL",
                name => "Delete All Comments",
                type => "PROJECT"
            },
            COMMENT_DELETE_OWN => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to delete own comments made on issues.",
                havePermission => JSON::PP::true,
                id => 37,
                key => "COMMENT_DELETE_OWN",
                name => "Delete Own Comments",
                type => "PROJECT"
            },
            COMMENT_EDIT_ALL => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to edit all comments made on issues.",
                havePermission => JSON::PP::true,
                id => 34,
                key => "COMMENT_EDIT_ALL",
                name => "Edit All Comments",
                type => "PROJECT"
            },
            COMMENT_EDIT_OWN => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to edit own comments made on issues.",
                havePermission => JSON::PP::true,
                id => 35,
                key => "COMMENT_EDIT_OWN",
                name => "Edit Own Comments",
                type => "PROJECT"
            },
            COMMENT_ISSUE => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to comment on issues.",
                havePermission => JSON::PP::true,
                id => 15,
                key => "COMMENT_ISSUE",
                name => "Add Comments",
                type => "PROJECT"
            },
            CREATE_ATTACHMENT => {
                deprecatedKey => JSON::PP::true,
                description => "Users with this permission may create attachments.",
                havePermission => JSON::PP::true,
                id => 19,
                key => "CREATE_ATTACHMENT",
                name => "Create Attachments",
                type => "PROJECT"
            },
            CREATE_ATTACHMENTS => {
                description => "Users with this permission may create attachments.",
                havePermission => JSON::PP::true,
                id => 19,
                key => "CREATE_ATTACHMENTS",
                name => "Create Attachments",
                type => "PROJECT"
            },
            CREATE_ISSUE => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to create issues.",
                havePermission => JSON::PP::true,
                id => 11,
                key => "CREATE_ISSUE",
                name => "Create Issues",
                type => "PROJECT"
            },
            CREATE_ISSUES => {
                description => "Ability to create issues.",
                havePermission => JSON::PP::true,
                id => 11,
                key => "CREATE_ISSUES",
                name => "Create Issues",
                type => "PROJECT"
            },
            CREATE_SHARED_OBJECTS => {
                description => "Ability to share dashboards and filters with other users, groups and roles.",
                havePermission => JSON::PP::true,
                id => 22,
                key => "CREATE_SHARED_OBJECTS",
                name => "Create Shared Objects",
                type => "GLOBAL"
            },
            DELETE_ALL_ATTACHMENTS => {
                description => "Users with this permission may delete all attachments.",
                havePermission => JSON::PP::true,
                id => 38,
                key => "DELETE_ALL_ATTACHMENTS",
                name => "Delete All Attachments",
                type => "PROJECT"
            },
            DELETE_ALL_COMMENTS => {
                description => "Ability to delete all comments made on issues.",
                havePermission => JSON::PP::true,
                id => 36,
                key => "DELETE_ALL_COMMENTS",
                name => "Delete All Comments",
                type => "PROJECT"
            },
            DELETE_ALL_WORKLOGS => {
                description => "Ability to delete all worklogs made on issues.",
                havePermission => JSON::PP::true,
                id => 43,
                key => "DELETE_ALL_WORKLOGS",
                name => "Delete All Worklogs",
                type => "PROJECT"
            },
            DELETE_ISSUE => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to delete issues.",
                havePermission => JSON::PP::true,
                id => 16,
                key => "DELETE_ISSUE",
                name => "Delete Issues",
                type => "PROJECT"
            },
            DELETE_ISSUES => {
                description => "Ability to delete issues.",
                havePermission => JSON::PP::true,
                id => 16,
                key => "DELETE_ISSUES",
                name => "Delete Issues",
                type => "PROJECT"
            },
            DELETE_OWN_ATTACHMENTS => {
                description => "Users with this permission may delete own attachments.",
                havePermission => JSON::PP::true,
                id => 39,
                key => "DELETE_OWN_ATTACHMENTS",
                name => "Delete Own Attachments",
                type => "PROJECT"
            },
            DELETE_OWN_COMMENTS => {
                description => "Ability to delete own comments made on issues.",
                havePermission => JSON::PP::true,
                id => 37,
                key => "DELETE_OWN_COMMENTS",
                name => "Delete Own Comments",
                type => "PROJECT"
            },
            DELETE_OWN_WORKLOGS => {
                description => "Ability to delete own worklogs made on issues.",
                havePermission => JSON::PP::true,
                id => 42,
                key => "DELETE_OWN_WORKLOGS",
                name => "Delete Own Worklogs",
                type => "PROJECT"
            },
            EDIT_ALL_COMMENTS => {
                description => "Ability to edit all comments made on issues.",
                havePermission => JSON::PP::true,
                id => 34,
                key => "EDIT_ALL_COMMENTS",
                name => "Edit All Comments",
                type => "PROJECT"
            },
            EDIT_ALL_WORKLOGS => {
                description => "Ability to edit all worklogs made on issues.",
                havePermission => JSON::PP::true,
                id => 41,
                key => "EDIT_ALL_WORKLOGS",
                name => "Edit All Worklogs",
                type => "PROJECT"
            },
            EDIT_ISSUE => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to edit issues.",
                havePermission => JSON::PP::true,
                id => 12,
                key => "EDIT_ISSUE",
                name => "Edit Issues",
                type => "PROJECT"
            },
            EDIT_ISSUES => {
                description => "Ability to edit issues.",
                havePermission => JSON::PP::true,
                id => 12,
                key => "EDIT_ISSUES",
                name => "Edit Issues",
                type => "PROJECT"
            },
            EDIT_OWN_COMMENTS => {
                description => "Ability to edit own comments made on issues.",
                havePermission => JSON::PP::true,
                id => 35,
                key => "EDIT_OWN_COMMENTS",
                name => "Edit Own Comments",
                type => "PROJECT"
            },
            EDIT_OWN_WORKLOGS => {
                description => "Ability to edit own worklogs made on issues.",
                havePermission => JSON::PP::true,
                id => 40,
                key => "EDIT_OWN_WORKLOGS",
                name => "Edit Own Worklogs",
                type => "PROJECT"
            },
            LINK_ISSUE => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to link issues together and create linked issues. Only useful if issue linking is turned on.",
                havePermission => JSON::PP::true,
                id => 21,
                key => "LINK_ISSUE",
                name => "Link Issues",
                type => "PROJECT"
            },
            LINK_ISSUES => {
                description => "Ability to link issues together and create linked issues. Only useful if issue linking is turned on.",
                havePermission => JSON::PP::true,
                id => 21,
                key => "LINK_ISSUES",
                name => "Link Issues",
                type => "PROJECT"
            },
            MANAGE_GROUP_FILTER_SUBSCRIPTIONS => {
                description => "Ability to manage (create and delete) group filter subscriptions.",
                havePermission => JSON::PP::true,
                id => 24,
                key => "MANAGE_GROUP_FILTER_SUBSCRIPTIONS",
                name => "Manage Group Filter Subscriptions",
                type => "GLOBAL"
            },
            MANAGE_SPRINTS_PERMISSION => {
                description => "Ability to manage sprints.",
                havePermission => JSON::PP::true,
                id => -1,
                key => "MANAGE_SPRINTS_PERMISSION",
                name => "Manage Sprints",
                type => "PROJECT"
            },
            MANAGE_WATCHERS => {
                description => "Ability to manage the watchers of an issue.",
                havePermission => JSON::PP::true,
                id => 32,
                key => "MANAGE_WATCHERS",
                name => "Manage Watchers",
                type => "PROJECT"
            },
            MANAGE_WATCHER_LIST => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to manage the watchers of an issue.",
                havePermission => JSON::PP::true,
                id => 32,
                key => "MANAGE_WATCHER_LIST",
                name => "Manage Watchers",
                type => "PROJECT"
            },
            MODIFY_REPORTER => {
                description => "Ability to modify the reporter when creating or editing an issue.",
                havePermission => JSON::PP::true,
                id => 30,
                key => "MODIFY_REPORTER",
                name => "Modify Reporter",
                type => "PROJECT"
            },
            MOVE_ISSUE => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to move issues between projects or between workflows of the same project (if applicable). Note the user can only move issues to a project he or she has the create permission for.",
                havePermission => JSON::PP::true,
                id => 25,
                key => "MOVE_ISSUE",
                name => "Move Issues",
                type => "PROJECT"
            },
            MOVE_ISSUES => {
                description => "Ability to move issues between projects or between workflows of the same project (if applicable). Note the user can only move issues to a project he or she has the create permission for.",
                havePermission => JSON::PP::true,
                id => 25,
                key => "MOVE_ISSUES",
                name => "Move Issues",
                type => "PROJECT"
            },
            PROJECT_ADMIN => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to administer a project in JIRA.",
                havePermission => JSON::PP::true,
                id => 23,
                key => "PROJECT_ADMIN",
                name => "Administer Projects",
                type => "PROJECT"
            },
            RESOLVE_ISSUE => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to resolve and reopen issues. This includes the ability to set a fix version.",
                havePermission => JSON::PP::true,
                id => 14,
                key => "RESOLVE_ISSUE",
                name => "Resolve Issues",
                type => "PROJECT"
            },
            RESOLVE_ISSUES => {
                description => "Ability to resolve and reopen issues. This includes the ability to set a fix version.",
                havePermission => JSON::PP::true,
                id => 14,
                key => "RESOLVE_ISSUES",
                name => "Resolve Issues",
                type => "PROJECT"
            },
            SCHEDULE_ISSUE => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to view or edit an issue's due date.",
                havePermission => JSON::PP::true,
                id => 28,
                key => "SCHEDULE_ISSUE",
                name => "Schedule Issues",
                type => "PROJECT"
            },
            SCHEDULE_ISSUES => {
                description => "Ability to view or edit an issue's due date.",
                havePermission => JSON::PP::true,
                id => 28,
                key => "SCHEDULE_ISSUES",
                name => "Schedule Issues",
                type => "PROJECT"
            },
            SET_ISSUE_SECURITY => {
                description => "Ability to set the level of security on an issue so that only people in that security level can see the issue.",
                havePermission => JSON::PP::false,
                id => 26,
                key => "SET_ISSUE_SECURITY",
                name => "Set Issue Security",
                type => "PROJECT"
            },
            SYSTEM_ADMIN => {
                description => "Ability to perform all administration functions. There must be at least one group with this permission.",
                havePermission => JSON::PP::true,
                id => 44,
                key => "SYSTEM_ADMIN",
                name => "JIRA System Administrators",
                type => "GLOBAL"
            },
            TRANSITION_ISSUE => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to transition issues.",
                havePermission => JSON::PP::true,
                id => 46,
                key => "TRANSITION_ISSUE",
                name => "Transition Issues",
                type => "PROJECT"
            },
            TRANSITION_ISSUES => {
                description => "Ability to transition issues.",
                havePermission => JSON::PP::true,
                id => 46,
                key => "TRANSITION_ISSUES",
                name => "Transition Issues",
                type => "PROJECT"
            },
            USER_PICKER => {
                description => "Ability to select a user or group from a popup window as well as the ability to use the 'share' issues feature. Users with this permission will also be able to see names of all users and groups in the system.",
                havePermission => JSON::PP::true,
                id => 27,
                key => "USER_PICKER",
                name => "Browse Users",
                type => "GLOBAL"
            },
            VIEW_DEV_TOOLS => {
                description => "Allows users in a software project to view development-related information on the issue, such as commits, reviews and build information.",
                havePermission => JSON::PP::true,
                id => 29,
                key => "VIEW_DEV_TOOLS",
                name => "View Development Tools",
                type => "PROJECT"
            },
            VIEW_READONLY_WORKFLOW => {
                description => "Users with this permission may view a read-only version of a workflow.",
                havePermission => JSON::PP::true,
                id => 45,
                key => "VIEW_READONLY_WORKFLOW",
                name => "View Read-Only Workflow",
                type => "PROJECT"
            },
            VIEW_VERSION_CONTROL => {
                deprecatedKey => JSON::PP::true,
                description => "Allows users to view development-related information on the view issue screen, like commits, reviews and build information.",
                havePermission => JSON::PP::true,
                id => 29,
                key => "VIEW_VERSION_CONTROL",
                name => "View Development Tools",
                type => "PROJECT"
            },
            VIEW_VOTERS_AND_WATCHERS => {
                description => "Ability to view the voters and watchers of an issue.",
                havePermission => JSON::PP::true,
                id => 31,
                key => "VIEW_VOTERS_AND_WATCHERS",
                name => "View Voters and Watchers",
                type => "PROJECT"
            },
            VIEW_WORKFLOW_READONLY => {
                deprecatedKey => JSON::PP::true,
                description => "admin.permissions.descriptions.VIEW_WORKFLOW_READONLY",
                havePermission => JSON::PP::true,
                id => 45,
                key => "VIEW_WORKFLOW_READONLY",
                name => "View Read-Only Workflow",
                type => "PROJECT"
            },
            WORKLOG_DELETE_ALL => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to delete all worklogs made on issues.",
                havePermission => JSON::PP::true,
                id => 43,
                key => "WORKLOG_DELETE_ALL",
                name => "Delete All Worklogs",
                type => "PROJECT"
            },
            WORKLOG_DELETE_OWN => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to delete own worklogs made on issues.",
                havePermission => JSON::PP::true,
                id => 42,
                key => "WORKLOG_DELETE_OWN",
                name => "Delete Own Worklogs",
                type => "PROJECT"
            },
            WORKLOG_EDIT_ALL => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to edit all worklogs made on issues.",
                havePermission => JSON::PP::true,
                id => 41,
                key => "WORKLOG_EDIT_ALL",
                name => "Edit All Worklogs",
                type => "PROJECT"
            },
            WORKLOG_EDIT_OWN => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to edit own worklogs made on issues.",
                havePermission => JSON::PP::true,
                id => 40,
                key => "WORKLOG_EDIT_OWN",
                name => "Edit Own Worklogs",
                type => "PROJECT"
            },
            WORK_ISSUE => {
                deprecatedKey => JSON::PP::true,
                description => "Ability to log work done against an issue. Only useful if Time Tracking is turned on.",
                havePermission => JSON::PP::true,
                id => 20,
                key => "WORK_ISSUE",
                name => "Work On Issues",
                type => "PROJECT"
            },
            WORK_ON_ISSUES => {
                description => "Ability to log work done against an issue. Only useful if Time Tracking is turned on.",
                havePermission => JSON::PP::true,
                id => 20,
                key => "WORK_ON_ISSUES",
                name => "Work On Issues",
                type => "PROJECT"
            }
        }
    };
}

1;
