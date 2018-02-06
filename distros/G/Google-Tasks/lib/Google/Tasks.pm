package Google::Tasks;
# ABSTRACT: Manipulate Google/GMail Tasks

use 5.014;
use strict;
use warnings;

use Moo;
use namespace::clean;
use LWP::UserAgent;
use HTML::Form;
use JSON;
use HTTP::Request::Common;
use Try::Tiny qw( try catch finally );
use Carp 'croak';

our $VERSION = '1.06'; # VERSION

has json => ( is => 'ro', default => sub { JSON->new } );
has ua   => (
    is      => 'ro',
    default => sub {
        my $ua = LWP::UserAgent->new(
            max_redirect => 24,
        );
        push( @{ $ua->requests_redirectable }, 'POST' );
        $ua->cookie_jar({});
        return $ua;
    },
);

has user        => ( is => 'rwp' );
has passwd      => ( is => 'rwp' );
has is_authed   => ( is => 'rwp', default => 0 );
has lists       => ( is => 'rwp' );
has tasks       => ( is => 'rwp' );
has active_list => ( is => 'rwp' );

sub BUILD {
    my ($self) = @_;
    $self->login( $self->user, $self->passwd ) if ( $self->user and $self->passwd );
}

sub login {
    my ( $self, $user, $passwd ) = @_;

    $self->_set_user($user)     if ($user);
    $self->_set_passwd($passwd) if ($passwd);

    croak('Must provide "user" and "passwd" values to login() or new()')
        unless ( $self->user and $self->passwd );

    my $form = ( HTML::Form->parse(
        $self->ua->request( HTTP::Request->new( 'GET', 'https://mail.google.com/tasks/ig' ) )
    ) )[0];
    $form->value( 'Email', $self->user );
    $form = ( HTML::Form->parse( $self->ua->request( $form->click ) ) )[0];
    $form->value( 'Passwd', $self->passwd );

    my $res = $self->ua->request( $form->click );

    croak('Authentication failed; check user and passwd values and that LWP::Protocol::https is installed')
        if ( $res->content =~ /<title>Sign in/ );

    $self->_set_is_authed(1);
    return $self->_parse_data(
        $self->json->decode(
            ( $res->content =~ /\{_setup\((.*)\)\}/ ) ? $1 : ''
        )->{'t'}
    );
}

sub _parse_data {
    my ( $self, $data ) = @_;

    $self->_set_lists( [ map { Google::Tasks::List->new( %{$_}, 'root' => $self ) } @{ $data->{'lists'} } ] );

    my %list_ids;

    $self->_set_tasks( [ map {
        $list_ids{$_}++ for ( @{ $_->{'list_id'} } );
        $_->{'list_id'} = $_->{'list_id'}[0];
        Google::Tasks::Task->new( %{$_}, 'root' => $self );
    } @{ $data->{'tasks'} } ] );

    my $most_common_list_id = (
        map { $_->[0] }
        sort { $b->[1] <=> $a->[1] }
        map { [ $_, $list_ids{$_} ] }
        keys %list_ids
    )[0];

    try {
        $self->_set_active_list(
            grep { $_->id eq $most_common_list_id } @{ $self->lists }
        );
    };

    return $self;
}

sub _call {
    my ( $self, $action ) = @_;
    croak('Must successfully authenticate with login() first') unless ( $self->is_authed );

    $action->{'action_id'} = int( rand(100) );

    my $res = $self->ua->request( HTTP::Request::Common::POST(
        'https://mail.google.com/tasks/r/ig',
        'AT'      => 1,
        'Content' => [ 'r' => encode_json( { 'action_list' => [$action] } ) ],
    ) );

    my $json;
    try {
        $json = $self->json->decode( $res->content );
    }
    catch {
        croak( $res->content );
    };

    return $json;
}

sub refresh {
    my ( $self, $list_name, $show_deleted ) = @_;

    my $list = $self->active_list;
    if ($list_name) {
        ($list) = ( grep { $_->name eq $list_name } @{ $self->data->lists } );

        croak('Either provide no list name or a valid list name of a list that has been loaded/saved')
            unless ( ref $list eq 'Google::Tasks::List' and $list->id );
    }

    my $action = {
        'action_type' => 'get_all',
        'get_deleted' => ($show_deleted) ? JSON::true : JSON::false,
    };

    $action->{'list_id'} = $list->id if ( ref $list eq 'Google::Tasks::List' and $list->id );
    return $self->_parse_data( $self->_call($action) );
}

package Google::Tasks::List {
    use Moo;
    use namespace::clean;

    has root => ( is => 'rwp', required => 1 );
    has id   => ( is => 'rwp' );
    has name => ( is => 'rw', default => '', coerce => sub { defined $_[0] ? $_[0] : '' } );

    sub save {
        my ($self) = @_;

        unless ( $self->id ) {
            my $rv = $self->root->_call( {
                'action_type'  => 'create',
                'index'        => scalar( @{ $self->root->lists } ),
                'entity_delta' => {
                    'name'        => $self->name,
                    'entity_type' => 'GROUP',
                },
            } );

            $self->_set_id( $rv->{'results'}[0]{'new_id'} );
            $self->root->_set_lists( [ @{ $self->root->lists }, $self ] );
            $self->root->_set_active_list($self);
        }
        else {
            $self->root->_call( {
                'action_type'  => 'update',
                'id'           => $self->id,
                'entity_delta' => {
                    'name' => $self->name,
                },
            } );
        }

        return $self;
    }

    sub drop {
        my ($self) = @_;

        $self->_call( {
            'action_type'  => 'update',
            'id'           => $self->id,
            'entity_delta' => {
                'deleted' => JSON::true,
            },
        } );

        $self->root->_set_lists( [ grep { $_->id ne $self->id } @{ $self->root->lists } ] );
        $self->root->_set_active_list(undef) if ( $self->root->active_list->id eq $self->id );

        return $self->root;
    }

    sub clear {
        my ($self) = @_;

        $self->_call( {
            'action_type'    => 'update_user',
            'clear_list_ids' => $self->id,
        } );

        $self->root->_set_tasks( [ grep { not $_->completed and not $_->deleted } @{ $self->root->tasks } ] );
        return $self;
    }
};

sub add_list {
    my ( $self, $list_name ) = @_;
    return Google::Tasks::List->new( name => $list_name, root => $self )->save;
}

sub drop_list {
    my ( $self, $list_name ) = @_;
    my ($list) = grep { $_->name eq $list_name } @{ $self->data->lists };

    croak('Must provide a valid list name of a list that has been loaded or saved')
        unless ( ref $list eq 'Google::Tasks::List' and $list->id );

    return $list->drop;
}

sub rename_list {
    my ( $self, $current_list_name, $new_list_name ) = @_;
    my ($list) = grep { $_->name eq $current_list_name } @{ $self->data->lists };

    croak('Must provide a valid list name of a list that has been loaded or saved')
        unless ( ref $list eq 'Google::Tasks::List' and $list->id );

    return $list->name($new_list_name)->save;
}

sub clear_list {
    my ( $self, $list_name ) = @_;
    my ($list) = grep { $_->name eq $list_name } @{ $self->data->lists };

    croak('Must provide a valid list name of a list that has been loaded or saved')
        unless ( ref $list eq 'Google::Tasks::List' and $list->id );

    return $list->clear;
}

package Google::Tasks::Task {
    use Moo;
    use namespace::clean;
    use Carp 'croak';
    use List::MoreUtils 'firstidx';
    use Date::Parse 'str2time';
    use DateTime;

    has root      => ( is => 'rwp', required => 1 );
    has list      => ( is => 'rwp' );
    has list_id   => ( is => 'rwp' );
    has id        => ( is => 'rwp' );
    has name      => ( is => 'rw', default => '', coerce => sub { defined $_[0] ? $_[0] : '' } );
    has notes     => ( is => 'rw', default => '', coerce => sub { defined $_[0] ? $_[0] : '' } );
    has completed => ( is => 'rw', default => 0, coerce => sub { $_[0] ? JSON::true : JSON::false } );
    has deleted   => ( is => 'rw', default => 0, coerce => sub { $_[0] ? JSON::true : JSON::false } );
    has task_date => ( is => 'rw', coerce => sub { DateTime->from_epoch( epoch => str2time( $_[0] ) ) } );
    has index     => ( is => 'rwp', default => 0 );

    sub BUILD {
        my ($self) = @_;
        local $Carp::CarpLevel = 2;

        if ( $self->list_id ) {
            my ($list) = grep { $self->list_id eq $_->id } @{ $self->root->lists };
            croak('If "list_id" is provided, it must be a valid list ID from a loaded list')
                if ( not $list );

            $self->_set_list($list);
        }
        elsif ( $self->list ) {
            croak('If "list" is provided, it must be a valid Google::Tasks::List object')
                if ( ref $self->list ne 'Google::Tasks::List' );

            $self->_set_list_id = $self->list->id;
        }
        else {
            $self->_set_list( $self->root->active_list );
            $self->_set_list_id( $self->root->active_list->id );
        }
    }

    sub save {
        my ($self) = @_;

        my %attr = map { $_ => $self->$_ } qw( name notes completed deleted );
        $attr{'task_date'} = $self->task_date->ymd('') if ( defined $self->task_date );

        unless ( $self->id ) {
            my %extra;
            $extra{'prior_sibling_id'} = $self->root->tasks->[ $self->index - 1 ]->id if ( $self->index );

            my $rv = $self->root->_call( {
                'action_type'      => 'create',
                'list_id'          => $self->list_id,
                'parent_id'        => $self->list_id,
                'dest_parent_type' => 'GROUP',
                'index'            => $self->index,
                'entity_delta'     => {
                    'entity_type' => 'TASK',
                    %attr,
                },
                %extra,
            } );

            $self->_set_id( $rv->{'results'}[0]{'new_id'} );
        }
        else {
            $self->root->_call( {
                'action_type'  => 'update',
                'id'           => $self->id,
                'entity_delta' => {
                    %attr,
                },
            } );
        }

        return $self;
    }

    sub move {
        my ( $self, $command ) = @_;
        croak('Must provide some command value for move()') unless ( defined $command );

        if ( $command =~ /^\d+$/ ) {
            croak("move() command seems to relocate task out of bounds of current list")
                if ( $command and not defined $self->root->tasks->[$command] );

            $self->root->_call( {
                'action_type' => 'move',
                'id'          => $self->id,
                'source_list' => $self->list_id,
                ($command) ? (
                    'dest_parent'      => $self->list_id,
                    'prior_sibling_id' => $self->root->tasks->[$command]->id,
                ) : (
                    'dest_parent'      => $self->list_id,
                ),
            } );

            my @tasks = grep { $_->id ne $self->id } @{ $self->root->tasks };
            splice( @tasks, $command, 0, $self );
            $self->root->_set_tasks(\@tasks);
        }
        elsif ( $command eq 'down' ) {
            $self->move( ( firstidx { $_->id eq $self->id } @{ $self->root->tasks } ) + 1 );
        }
        elsif ( $command eq 'up' ) {
            my $idx = ( firstidx { $_->id eq $self->id } @{ $self->root->tasks } ) - 1;

            croak("move() command seems to relocate task out of bounds of current list")
                if ( $idx < 0 );

            $self->move($idx);
        }
        elsif (
            ref $command eq 'Google::Tasks::Task' or
            ref $command eq 'Google::Tasks::List'
        ) {
            $self->root->_call( {
                'action_type' => 'move',
                'id'          => $self->id,
                'source_list' => $self->list_id,
                'dest_parent' => $command->id,
            } );
        }
        else {
            croak('Was unable to recognize command value provided');
        }

        return $self;
    }

    sub drop {
        my ($self) = @_;

        $self->_call( {
            'action_type'  => 'update',
            'id'           => $self->id,
            'entity_delta' => {
                'deleted' => JSON::true,
            },
        } );

        $self->root->_set_tasks( [ grep { $_->id ne $self->id } @{ $self->root->tasks } ] );
        return $self->root;
    }

};

sub add_task {
    my $self = shift;
    return Google::Tasks::Task->new( @_, root => $self )->save;
}

sub drop_task {
    my ( $self, $task_name ) = @_;
    return $self->task_by_name($task_name)->drop;
}

sub task_by_name {
    my ( $self, $task_name ) = @_;
    my ($task) = grep { $_->name ne $task_name } @{ $self->root->tasks };
    croak('Unable to find a task by the name provided') unless ( ref $task eq 'Google::Tasks::Task' );
    return $task;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Google::Tasks - Manipulate Google/GMail Tasks

=head1 VERSION

version 1.06

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/Google-Tasks.svg)](https://travis-ci.org/gryphonshafer/Google-Tasks)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/Google-Tasks/badge.png)](https://coveralls.io/r/gryphonshafer/Google-Tasks)

=head1 SYNOPSIS

    use Google::Tasks;

    my $google_tasks = Google::Tasks->new();
    $google_tasks->login( user => 'user', passwd => 'passwd' );

    my $gt = Google::Tasks->new( user => 'user', passwd => 'passwd' );

    my $list_object = $gt->lists->[0];
    my $active_list = $gt->active_list;

    $gt->refresh;                   # refresh the current list's data
    $gt->refresh('List Name');      # switch to a different list
    $gt->refresh( 'List Name', 1 );

    my $list = $gt->add_list('List Name');
    $gt->drop_list('List Name');

    my $list2 = $gt->rename_list( 'Current List Name', 'New List Name' );
    my $list3 = $gt->clear_list('List Name');

    $list->name('New List Name');
    $list->save;
    $list->drop;
    $list->clear;

    $gt->drop_task('Task Name');
    $gt->task_by_name('Task Name');

    my $task = $gt->add_task(
        name      => 'Task Name',
        notes     => 'Notes',
        completed => 0,             # defaults false
        deleted   => 0,             # defaults false
        task_date => DateTime->now, # defaults null
    );

    $task->move(2);
    $task->move('down');
    $task->move('up');
    $task->move( $gt->task_by_name('Other Task') );
    $task->move($list);

    $task->save;
    $task->drop;

=head1 DESCRIPTION

This module is an attempt to provide a simple means to manipulate the "Tasks"
functionality provided by Google's GMail. For more information, see:

    https://mail.google.com/tasks

That being said, I didn't use a Google API for this module. Instead, it
basically scrapes JSON off Google. I found this to be far easier than using
Google's API. I never intended this to be a real module, just something that I
could use quickly/easily myself. I'm only publishing this in case someone else
might find it useful as-is. It's not well-tested and probably never will be.
And Google could break this entire library by changing their JSON structure.
Consequently, this module should probably not be used by anyone, ever.

=head1 LIBRARY METHODS AND ATTRIBUTES

The following are methods and attributes of the core/parent library
(Google::Tasks) that pertain to core library functionality.

=head2 new

This instantiator is provided by L<Moo>. It can optionally accept a username
and password, and if so provided, it will call C<login()> automatically.

    my $gt  = Google::Tasks->new;
    my $gt2 = Google::Tasks->new( user => 'user', passwd => 'passwd' );

=head2 login

This method accepts a username and password for a valid/current GMail account,
then attempts to authenticate the user and start up a session with Google Tasks.

    $gt->login( user => 'user', passwd => 'passwd' );

The method returns a reference to the object from which the call was made. And
please note that the authentication takes place via a simple L<LWP::UserAgent>
scrape of a web form. For this to work, L<LWP::Protocol::https> must be
installed and SSL support must be available.

Following successful authentication, Google will return task lists data and
data for the tasks within the default/primary task list. This data gets parsed
into a series of attributes and sub-objects.

=head2 lists

Following login, this attribute will contain a reference to a list of Google
Tasks lists (as objects). Specifically, these are Google::Tasks::List objects.
(See below.)

    my @all_lists   = @{ $gt->lists };
    my $list_object = $gt->lists->[0];

=head2 tasks

Following login, this attribute will contain a reference to a list of Google
Tasks tasks (as objects). Specifically, these are Google::Tasks::Task objects.
(See below.) The tasks will only be from the current/active list, not all lists.
To switch lists, you'll need to C<refresh()> to a different list.

    my @all_tasks  = @{ $gt->lists };
    my $first_task = $gt->lists->[0];

=head2 active_list

This is a reference to the current/active list (as an object). Specifically,
this is a Google::Tasks::List object. (See below.)

    my $active_list = $gt->active_list;

=head2 refresh

Following a login, the tasks that get populated will only be from the
current/active list, not all lists. To switch lists, you'll need to C<refresh()>
to a different list.

    $gt->refresh;             # refresh the current list's data
    $gt->refresh('List Name'); # switch to a different list

The method returns a reference to the object from which the call was made.

By default, the refresh call populates tasks that are not deleted. However,
in the spirit of never really deleting anything ever, Google doesn't delete
deleted tasks. So if you provide an optional second parameter to C<refresh()>
that's boolean true, it will return tasks that are both deleted and undeleted.

    $gt->refresh( 'List Name', 1 );

=head1 LIST LIBRARY METHODS

The following are methods of the core/parent library (Google::Tasks) that
pertain to list functionality. These are helper/wrapper methods around methods
provided by Google::Tasks::List. (See below.)

=head2 add_list

This method creates a list and returns an object representing the list. The
object is an instantiation of Google::Tasks::List. The only value to supply,
which is required, is a text string representing the new list's name

    my $list = $gt->add_list('List Name');

=head2 drop_list

This method deletes a list based on a name match.

    $gt->drop_list('List Name');

Note that it is entirely possible to have multiple lists with the same name.
In those cases, only the first list with matching name is deleted. This method
returns a reference to the object from which it was called.

=head2 rename_list

This method renames a list based on a name search.

    my $list = $gt->rename_list( 'Current List Name', 'New List Name' );

Note that it is entirely possible to have multiple lists with the same name.
In those cases, only the first list with matching name is renamed.

=head2 clear_list

This method issues a call to "clear" a list, which basically means that any
task items on the list that are set as completed will be deleted off the list.

    my $list = $gt->clear_list($list_name);

=head1 LIST OBJECT METHODS

The following are methods of the list sub-library Google::Tasks::List.

=head2 new

This instantiator requires a text string representing the name of the new list
and a required "root" parameter, which is an instantiated Google::Tasks object.

    my $list = Google::Tasks::List->new( name =>, 'List Name', root => $gt );

You probably don't want to ever use this method directly; instead, use the
C<add_list()> method from Google::Tasks.

=head2 name

This is a simple L<Moo> get-er/set-er for the list's name. Changing the name
value itself won't really do anything useful until you envoke C<save()>.

    $list->name('New List Name');

=head2 save

This method saves changes made to the list metadata, which is really only the
list's name.

    $list->save;

The method returns a reference to the list.

=head2 drop

This method deletes a list.

    $list->drop;

=head2 clear

This method issues a call to "clear" a list, which basically means that any
task items on the list that are set as completed will be deleted off the list.

    $list->clear;

=head1 TASK HELPER METHODS

The following are helper methods of the core/parent library (Google::Tasks)
that pertain to tasks.

=head2 add_task

This method instantiates a Google::Tasks::Task object and adds it to the
current active list. It requires at minimum the task name. In addition, there
are quite a few other parameters you can pass in.

    my $task = $gt->add_task(
        name      => 'Task Name',
        notes     => 'Notes',
        completed => 0,             # defaults false
        deleted   => 0,             # defaults false
        task_date => DateTime->now, # defaults null
    );

Note that "task_date" is a DateTime object, but it's coerced into such when set.
So you can do stuff like this:

    $task->task_date('21/dec/93');
    $task->task_date->ymd; # returns "1993-12-21"

=head2 drop_task

This method drops a task based on the name of the task. It will look for the
first task in the current list that has a matching name and will delete it.

    $gt->drop_task('Task Name');

Note that you can have multiple tasks in a list with the same name. This
method will only delete the first match.

=head2 task_by_name

This method returns the task object from the current active list that matches
the name provided.

    $gt->task_by_name('Task Name');

Note that you can have multiple tasks in a list with the same name. This
method will only delete the first match.

=head1 TASK OBJECT METHODS

The following are methods of the list sub-library Google::Tasks::Task.

=head2 new

This method instantiates a Google::Tasks::Task object and requires at minimum
the task name, the "root" object, which is the instantiated Google::Tasks
object, and either the list object or list ID of the list the task belongs to.
In addition, there are quite a few other parameters you can pass in.

    my $task = Google::Tasks::Task->new(
        name      => 'Task Name',
        root      => $gt,
        list      => $list_obj,
        list_id   => $list_obj->id,
        notes     => 'Notes',
        completed => 0,             # defaults false
        deleted   => 0,             # defaults false
        task_date => DateTime->now, # defaults null
    );

Typically, you're not going to want to use this method directly. Instead, use
the C<add_task> helper method.

=head2 save

This method saves changes made to the task metadata.

    $task->save;

The method returns a reference to the list.

=head2 move

This method lets you move around tasks within a list, both in terms of relative
order, indenting (and outdenting), and moving tasks to other lists.

The simplest way to move tasks around on a list is to just change their order.
Assuming a flat set of tasks (no tasks are indented), you can select any task
on the list and tell C<move()> to change its order based on an integer that
represents the index of what the task should be. For example, let's say you have
a task list with 4 tasks: A, B, C, D. You want to move A between C and D. You'd
do this:

    $task->move(2);

You can accomplish similar changes by telling C<move()> to "up" or "down" a
task within a list.

    $task->move('down');
    $task->move('up');

And you can also pass C<move()> either a task object or a list object. If you
pass it a list object, it will move the task to be under (indented) to that
task. For example, if you have a list with tasks A, B, C, and D, and you want
to move A indented under C:

    $task->move( $gt->task_by_name('Other Task') );

If you pass a list object, the task (and any of its subordinate tasks if any)
will get moved under the new list.

    $task->move($list);

=head2 drop

This will delete the task.

    $task->drop;

=head1 SEE ALSO

L<Google::OAuth>, L<Google::API::Client>, L<Moo>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Google-Tasks>

=item *

L<CPAN|http://search.cpan.org/dist/Google-Tasks>

=item *

L<MetaCPAN|https://metacpan.org/pod/Google::Tasks>

=item *

L<AnnoCPAN|http://annocpan.org/dist/Google-Tasks>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/Google-Tasks>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/Google-Tasks>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Google-Tasks>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/G/Google-Tasks.html>

=back

=for Pod::Coverage BUILD is_authed json passwd ua user

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
