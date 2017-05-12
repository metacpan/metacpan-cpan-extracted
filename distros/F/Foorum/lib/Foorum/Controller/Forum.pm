package Foorum::Controller::Forum;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';
use Foorum::Utils qw/get_page_from_url/;
use Foorum::Formatter qw/filter_format/;

sub board : Path {
    my ( $self, $c ) = @_;

    my @forums = $c->model('DBIC')->resultset('Forum')->search(
        {   forum_type => 'classical',
            status     => { '!=', 'banned' },
        },
        { order_by => 'me.forum_id', }
    )->all;

    # get last_post and the author
    foreach (@forums) {
        next unless $_->last_post_id;
        $_->{last_post} = $c->model('DBIC::Topic')->get( $_->last_post_id );
        next unless $_->{last_post};
        $_->{last_post}->{updator} = $c->model('DBIC::User')
            ->get( { user_id => $_->{last_post}->{last_updator_id} } );
    }

    $c->cache_page('300');

    # get all moderators
    my @forum_ids;
    push @forum_ids, $_->forum_id foreach (@forums);
    if ( scalar @forum_ids ) {
        my $roles = $c->model('DBIC::UserForum')
            ->get_forum_moderators( \@forum_ids );
        $c->stash->{forum_roles} = $roles;
    }

    $c->stash->{whos_view_this_page} = 1;
    $c->stash->{forums}              = \@forums;
    $c->stash->{template}            = 'forum/board.html';
}

sub forum : PathPart('forum') Chained('/') CaptureArgs(1) {
    my ( $self, $c, $forum_code ) = @_;

    my $forum = $c->controller('Get')->forum( $c, $forum_code );
}

sub forum_list : Regex('^forum/(\w+)$') {
    my ( $self, $c ) = @_;

    my $is_elite = ( $c->req->path =~ /\/elite(\/|$)/ ) ? 1 : 0;
    my $page     = get_page_from_url( $c->req->path );
    my $rss      = ( $c->req->path =~ /\/rss(\/|$)/ ) ? 1 : 0;  # /forum/1/rss

    # get the forum information
    my $forum_code = $c->req->snippets->[0];
    my $forum      = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id   = $forum->{forum_id};
    $forum_code = $forum->{forum_code};

    my @extra_cols = ($is_elite) ? ( 'elite', 1 ) : ();
    my $rows
        = ($rss)
        ? 10
        : $c->config->{per_page}->{forum};    # 10 for RSS is enough
    my $it = $c->model('DBIC')->resultset('Topic')->search(
        {   forum_id    => $forum_id,
            'me.status' => { '!=', 'banned' },
            @extra_cols,
        },
        {   order_by => \'sticky DESC, last_update_date DESC',
            rows     => $rows,
            page     => $page,
            prefetch => [ 'author', 'last_updator' ],
        }
    );
    my @topics = $it->all;

    if ($rss) {
        foreach (@topics) {
            my $rs = $c->model('DBIC::Comment')->find(
                {   object_type => 'topic',
                    object_id   => $_->topic_id,
                },
                {   order_by => 'post_on',
                    rows     => 1,
                    page     => 1,
                    columns  => [ 'text', 'formatter' ],
                }
            );
            next unless ($rs);
            $_->{text} = $rs->text;

            # filter format by Foorum::Filter
            $_->{text} = $c->model('DBIC::FilterWord')
                ->convert_offensive_word( $_->{text} );
            $_->{text}
                = filter_format( $_->{text}, { format => $rs->formatter } );
        }
        $c->stash->{topics}   = \@topics;
        $c->stash->{template} = 'forum/forum.rss.html';
        $c->cache_page('600');
        return;
    }

    # above is for RSS, left is for HTML

    # get all moderators
    $c->stash->{forum_roles}
        = $c->model('DBIC::UserForum')->get_forum_moderators($forum_id);

    # for page 1 and normal mode
    if ( $page == 1 and not $is_elite ) {

        # for private forum
        if ( $forum->{policy} eq 'private' ) {
            my $pending_count = $c->model('DBIC::UserForum')->count(
                {   forum_id => $forum_id,
                    status   => 'pending',
                }
            );
            $c->stash( { pending_count => $pending_count, } );
        }

        # check announcement
        $c->stash->{announcement}
            = $c->model('DBIC::Forum')->get_announcement($forum);
    }

    $c->cache_page('300');

    if ( $c->user_exists ) {
        my @all_topic_ids = map { $_->topic_id } @topics;
        $c->stash->{is_visited}
            = $c->model('DBIC::Visit')
            ->is_visited( 'topic', \@all_topic_ids, $c->user->user_id )
            if ( scalar @all_topic_ids );
    }

    # Pager
    my $pager = $it->pager;

    # For Tabs
    $c->stash->{poll_count} = $c->model('DBIC')->resultset('Poll')->count(
        {   forum_id => $forum_id,
            duration => { '>', time() },
        }
    );

    # Forum Links
    my @links = $c->model('DBIC::ForumSettings')->get_forum_links($forum_id);
    $c->stash->{forum_links} = \@links;

    $c->stash->{whos_view_this_page} = 1;
    $c->stash->{pager}               = $pager;
    $c->stash->{topics}              = \@topics;
    $c->stash->{template}            = 'forum/forum.html';
}

sub join : Chained('forum') Arg(0) {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    my $forum      = $c->stash->{forum};
    my $forum_id   = $forum->{forum_id};
    my $forum_code = $forum->{forum_code};

    if ( $forum->{policy} eq 'private' ) {

        # check if already requested
        if ( $c->req->method eq 'POST' ) {
            my $rs = $c->model('DBIC::UserForum')->search(
                {   user_id  => $c->user->user_id,
                    forum_id => $forum_id,
                },
                { columns => ['status'], }
            )->first;
            if ($rs) {
                if (   $rs->status eq 'user'
                    or $rs->status eq 'moderator'
                    or $rs->status eq 'admin' ) {
                    return $c->res->redirect( $forum->{forum_url} );
                } elsif ( $rs->status eq 'blocked'
                    or $rs->status eq 'pending'
                    or $rs->status eq 'rejected' ) {
                    my $status = uc( $rs->status );
                    $c->detach( '/print_error', ["ERROR_USER_$status"] );
                }
            } else {
                $c->model('DBIC::UserForum')->create_user_forum(
                    {   user_id  => $c->user->user_id,
                        forum_id => $forum_id,
                        status   => 'pending',
                    }
                );

                my $forum_admin = $c->model('DBIC::UserForum')
                    ->get_forum_admin($forum_id);
                my $requestor = $c->model('DBIC::User')
                    ->get( { user_id => $c->user->user_id } );

                my $forum;
                if (    $c->stash->{forum}
                    and $c->stash->{forum}->{forum_id} == $forum_id ) {
                    $forum = $c->stash->{forum};
                } else {
                    $forum = $c->model('DBIC::Forum')->get($forum_id);
                }

                # Send Notification Email
                $c->model('DBIC::ScheduledEmail')->create_email(
                    {   template => 'forum_pending_request',
                        to       => $forum_admin->{email},
                        lang     => $c->stash->{lang},
                        stash    => {
                            rept  => $forum_admin,
                            from  => $requestor,
                            forum => $forum,
                        }
                    }
                );

                $c->detach(
                    '/print_message',
                    [   'Successfully Requested. You need wait for admin\'s approval'
                    ]
                );
            }
        } else {
            $c->stash(
                {   simple_wrapper => 1,
                    template       => 'forum/join_us.html',
                }
            );
        }
    } else {
        $c->model('DBIC::UserForum')->create_user_forum(
            {   user_id  => $c->user->user_id,
                forum_id => $forum_id,
                status   => 'user',
            }
        );
        $c->res->redirect( $forum->{forum_url} );
    }
}

sub members : Chained('forum') Args {
    my ( $self, $c, $member_type ) = @_;

    my $forum      = $c->stash->{forum};
    my $forum_id   = $forum->{forum_id};
    my $forum_code = $forum->{forum_code};

    $member_type ||= 'user';
    if (    'pending' ne $member_type
        and 'blocked'  ne $member_type
        and 'rejected' ne $member_type ) {
        $member_type = 'user';
    }

    my $page = get_page_from_url( $c->req->path );

    my ( @query_cols, @attr_cols );
    if ( 'user' eq $member_type ) {
        @query_cols = ( 'status', [ 'admin', 'moderator', 'user' ] );
        @attr_cols = ( 'order_by' => 'status ASC' );
    } else {
        @query_cols = ( 'status', $member_type );
    }
    my $rs = $c->model('DBIC::UserForum')->search(
        { @query_cols, forum_id => $forum_id, },
        {   @attr_cols,
            rows => 20,
            page => $page,
        }
    );
    my @user_roles = $rs->all;
    my @all_user_ids = map { $_->user_id } @user_roles;

    my @members;
    my %members;
    if ( scalar @all_user_ids ) {
        @members = $c->model('DBIC::User')->search(
            { user_id => { 'IN', \@all_user_ids }, },
            {   columns => [
                    'user_id',  'username',
                    'nickname', 'gender',
                    'register_time'
                ],
            }
        )->all;
        %members = map { $_->user_id => $_ } @members;
    }

    $c->stash(
        {   template            => 'forum/members.html',
            member_type         => $member_type,
            pager               => $rs->pager,
            user_roles          => \@user_roles,
            whos_view_this_page => 1,
            members             => \%members,
        }
    );
}

sub action_log : Chained('forum') Args(0) {
    my ( $self, $c ) = @_;

    my $forum      = $c->stash->{forum};
    my $forum_id   = $forum->{forum_id};
    my $forum_code = $forum->{forum_code};

    my $page = get_page_from_url( $c->req->path );
    my $rs   = $c->model('DBIC')->resultset('LogAction')->search(
        { forum_id => $forum_id, },
        {   order_by => \'time DESC',
            page     => $page,
            rows     => 20,
        }
    );

    my @actions = $rs->all;

    my @all_user_ids;
    my %unique_user_ids;
    foreach (@actions) {
        next if ( $unique_user_ids{ $_->user_id } );
        push @all_user_ids, $_->user_id;
        $unique_user_ids{ $_->user_id } = 1;
    }
    if ( scalar @all_user_ids ) {
        my $authors
            = $c->model('DBIC::User')->get_multi( 'user_id', \@all_user_ids );
        foreach (@actions) {
            $_->{operator} = $authors->{ $_->user_id };
        }
    }

    $c->stash(
        {   template => 'forum/action_log.html',
            pager    => $rs->pager,
            logs     => \@actions,
        }
    );
}

sub create : Local {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    my $is_admin = $c->model('Policy')->is_admin( $c, 'site' );

    # if function_on.create_forum is off, check is admin
    if ( not $c->config->{function_on}->{create_forum} and not $is_admin ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

    $c->stash( { template => 'forum/create.html' } );

    return unless ( $c->req->method eq 'POST' );

    $c->form(
        name        => [ qw/NOT_BLANK/, [qw/LENGTH 1 40/] ],
        description => [ qw/NOT_BLANK/, [qw/LENGTH 1 200/] ],
    );
    return if ( $c->form->has_error );

    # check forum_code
    my $forum_code = $c->req->param('forum_code');
    my $err = $c->model('DBIC::Forum')->validate_forum_code($forum_code);
    if ($err) {
        $c->set_invalid_form( forum_code => $err );
        return;
    }

    my $name        = $c->req->param('name');
    my $description = $c->req->param('description');
    my $moderators  = $c->req->param('moderators');
    my $private     = $c->req->param('private');

    # validate the admin for roles.site.admin
    my $admin_user;
    if ($is_admin) {
        my $admin = $c->req->param('admin');
        $admin_user = $c->model('DBIC::User')->get( { username => $admin } );
        unless ($admin_user) {
            return $c->set_invalid_form( admin => 'ADMIN_NONEXISTENCE' );
        }
    } else {
        $admin_user = $c->user;
    }

    # validate the moderators
    my $total_members = 1;
    my @moderators = split( /\s*\,\s*/, $moderators );
    my @moderator_users;
    foreach (@moderators) {
        next if ( $_ eq $admin_user->{username} );    # avoid the same man
        last
            if ( scalar @moderator_users > 2 )
            ;    # only allow 3 moderators at most
        my $moderator_user
            = $c->model('DBIC::User')->get( { username => $_ } );
        unless ($moderator_user) {
            $c->stash->{non_existence_user} = $_;
            return $c->set_invalid_form( moderators => 'ADMIN_NONEXISTENCE' );
        }
        $total_members++;
        push @moderator_users, $moderator_user;
    }

    # insert data into table.
    my $policy = ( $private and $private == 1 ) ? 'private' : 'public';
    my $forum = $c->model('DBIC::Forum')->create(
        {   name          => $name,
            forum_code    => $forum_code,
            description   => $description,
            forum_type    => 'classical',
            policy        => $policy,
            total_members => $total_members,
        }
    );
    $c->model('DBIC::UserForum')->create_user_forum(
        {   user_id  => $admin_user->{user_id},
            status   => 'admin',
            forum_id => $forum->forum_id,
        }
    );
    foreach (@moderator_users) {
        $c->model('DBIC::UserForum')->create_user_forum(
            {   user_id  => $_->{user_id},
                status   => 'moderator',
                forum_id => $forum->forum_id,
            }
        );
    }

    # create time
    $c->model('DBIC')->resultset('ForumSettings')->create(
        {   forum_id => $forum->forum_id,
            type     => 'created_time',
            value    => time(),
        }
    );
    $c->model('DBIC')->resultset('ForumSettings')
        ->clear_cache( $forum->forum_id );

    $c->res->redirect("/forum/$forum_code");
}

sub about : Chained('forum') Args(0) {
    my ( $self, $c ) = @_;

    my $forum      = $c->stash->{forum};
    my $forum_id   = $forum->{forum_id};
    my $forum_code = $forum->{forum_code};

    # get all settings, so that we have created_time
    $c->stash->{settings} = $c->model('DBIC')->resultset('ForumSettings')
        ->get_all( $forum->{forum_id} );

    # get all moderators
    $c->stash->{forum_roles}
        = $c->model('DBIC::UserForum')->get_forum_moderators($forum_id);

    $c->stash->{template} = 'forum/about.html';
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
