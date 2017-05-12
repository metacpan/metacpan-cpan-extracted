package Foorum::Controller::ForumAdmin;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';

#use File::Slurp;
use Foorum::Utils qw/is_color encodeHTML/;

sub forum_for_admin : PathPart('forumadmin') Chained('/') CaptureArgs(1) {
    my ( $self, $c, $forum_code ) = @_;

    my $forum = $c->controller('Get')->forum( $c, $forum_code );

    unless ( $c->model('Policy')->is_admin( $c, $forum->{forum_id} ) ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

}

sub home : PathPart('') Chained('forum_for_admin') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'forumadmin/index.html';
}

sub basic : Chained('forum_for_admin') Args(0) {
    my ( $self, $c ) = @_;

    my $forum    = $c->stash->{forum};
    my $forum_id = $forum->{forum_id};

    $c->stash( { template => 'forumadmin/basic.html', } );

    $c->stash->{is_site_admin} = $c->model('Policy')->is_admin( $c, 'site' );

    my $role = $c->model('DBIC::UserForum')->get_forum_moderators($forum_id);
    unless ( $c->req->method eq 'POST' ) {

        # get all moderators
        my $e_moderators = $role->{$forum_id}->{moderator};
        if ($e_moderators) {
            my @e_moderators = @{$e_moderators};
            my @moderator_username;
            push @moderator_username, $_->{username} foreach (@e_moderators);
            $c->stash->{moderators} = join( ',', @moderator_username );
        }
        $c->stash->{private} = ( $forum->{policy} eq 'private' ) ? 1 : 0;
        return;
    }

    # validate
    $c->form(
        name => [ qw/NOT_BLANK/, [qw/LENGTH 1 40/] ],

        #        description  => [qw/NOT_BLANK/ ],
    );
    return if ( $c->form->has_error );

    # check forum_code
    my $forum_code = $c->req->param('forum_code');
    if ( $forum_code and $forum_code ne $forum->{forum_code} ) {
        my $err = $c->model('DBIC::Forum')->validate_forum_code($forum_code);
        $c->set_invalid_form( forum_code => $err );
        return;
    }

    my $name        = $c->req->param('name');
    my $description = $c->req->param('description');
    my $moderators  = $c->req->param('moderators');
    my $private     = $c->req->param('private');

    # get forum admin
    my $admin = $role->{$forum_id}->{admin};
    my $admin_username = ($admin) ? $admin->{username} : '';

    my @moderators = split( /\s*\,\s*/, $moderators );
    my @moderator_users;
    foreach (@moderators) {
        next if ( $_ eq $admin_username );    # avoid the same man
        last
            if ( scalar @moderator_users > 2 )
            ;    # only allow 3 moderators at most
        my $moderator_user
            = $c->model('DBIC::User')->get( { username => $_ } );
        unless ($moderator_user) {
            $c->stash->{non_existence_user} = $_;
            return $c->set_invalid_form( moderators => 'ADMIN_NONEXISTENCE' );
        }
        push @moderator_users, $moderator_user;
    }

    # escape html for name and description
    $name        = encodeHTML($name);
    $description = encodeHTML($description);

    # insert data into table.

    # 1, forum settings
    my @all_types = qw/can_post_threads can_post_replies can_post_polls/;

    # delete before create
    $c->model('DBIC')->resultset('ForumSettings')->search(
        {   forum_id => $forum_id,
            type     => { 'IN', \@all_types },
        }
    )->delete;
    foreach my $type (@all_types) {
        my $value = $c->req->params->{$type};
        $value = 'Y' unless ( 'N' eq $value );
        if ( 'N' eq $value ) {    # don't store 'Y' because it's default
            $c->model('DBIC')->resultset('ForumSettings')->create(
                {   forum_id => $forum_id,
                    type     => $type,
                    value    => 'N',
                }
            );
        }
    }
    $c->model('DBIC')->resultset('ForumSettings')->clear_cache($forum_id);

    # 2, forum table
    my $policy = ( $private == 1 ) ? 'private' : 'public';
    my @extra_update;
    push @extra_update, ( forum_code => $forum_code )
        if ( $c->stash->{is_site_admin} );
    $c->model('DBIC::Forum')->update_forum(
        $forum_id,
        {   name        => $name,
            description => $description,

            #        type => 'classical',
            policy => $policy,
            @extra_update,
        }
    );

    # 3, user_role
    # delete before create
    $c->model('DBIC::UserForum')->search(
        {   status   => 'moderator',
            forum_id => $forum->{forum_id},
        }
    )->delete;
    foreach (@moderator_users) {
        $c->model('DBIC::UserForum')->create_user_forum(
            {   user_id  => $_->{user_id},
                status   => 'moderator',
                forum_id => $forum->{forum_id},
            }
        );
    }

    my $forum_url = $c->model('DBIC::Forum')->get_forum_url($forum);
    $c->res->redirect($forum_url);
}

sub announcement : Chained('forum_for_admin') Args(0) {
    my ( $self, $c ) = @_;

    my $forum    = $c->stash->{forum};
    my $forum_id = $forum->{forum_id};

    my $announce = $c->model('DBIC::Comment')->find(
        {   object_id   => $forum_id,
            object_type => 'announcement',
        },
        { columns => [ 'title', 'text', 'formatter' ] }
    );

    unless ( $c->req->method eq 'POST' ) {
        $c->stash(
            {   template => 'forumadmin/announcement.html',
                announce => $announce,
            }
        );
        return;
    }

    my $title     = $c->req->param('title');
    my $text      = $c->req->param('text');
    my $formatter = $c->req->param('formatter');

    # if no text is typed, delete the record.
    # or else, save it.
    if ( length($text) and length($title) ) {
        if ($announce) {
            $title = encodeHTML($title);
            $c->model('DBIC')->resultset('Comment')->search(
                {   object_id   => $forum_id,
                    object_type => 'announcement',
                }
                )->update(
                {   text      => $text,
                    update_on => time(),
                    author_id => $c->user->user_id,
                    title     => $title,
                    formatter => $formatter,
                }
                );
        } else {
            $c->model('DBIC::Comment')->create_comment(
                {   object_type => 'announcement',
                    object_id   => $forum_id,
                    forum_id    => $forum_id,
                    title       => $title,
                    text        => $text,
                    formatter   => $formatter,
                    user_id     => $c->user->user_id,
                    post_ip     => $c->req->address,
                    lang        => $c->stash->{lang},
                }
            );
        }
    } else {
        $c->model('DBIC::Comment')->search(
            {   object_id   => $forum_id,
                object_type => 'announcement',
            }
        )->delete;
    }

    $c->cache->remove("forum|announcement|forum_id=$forum_id");

    $c->res->redirect( $forum->{forum_url} );
}

sub links : Chained('forum_for_admin') Args(0) {
    my ( $self, $c ) = @_;

    my $forum     = $c->stash->{forum};
    my $forum_id  = $forum->{forum_id};
    my $max_count = 9;
    $c->stash->{max_count} = $max_count;

    $c->stash( { template => 'forumadmin/links.html' } );

    if ( $c->req->method eq 'POST' ) {

        # validate
        my $error;
        foreach my $i ( 0 .. $max_count ) {
            my $url  = $c->req->params->{"url$i"};
            my $text = $c->req->params->{"text$i"};
            next unless ( $url and $text );
            $error->{url}->{$i}  = 'LENGTH' if ( length($url) > 99 );
            $error->{text}->{$i} = 'LENGTH' if ( length($text) > 99 );
        }

        if ( keys %$error ) {
            return $c->stash->{error} = $error;
        }

        # delete before create
        my @all_types = map {"forum_link$_"} ( 0 .. $max_count );
        $c->model('DBIC')->resultset('ForumSettings')->search(
            {   forum_id => $forum_id,
                type     => { 'IN', \@all_types },
            }
        )->delete;
        foreach my $i ( 0 .. $max_count ) {
            my $url  = $c->req->params->{"url$i"};
            my $text = $c->req->params->{"text$i"};
            next unless ( $url and $text );
            $c->model('DBIC')->resultset('ForumSettings')->create(
                {   forum_id => $forum_id,
                    type     => "forum_link$i",
                    value    => "$url $text",
                }
            );
        }
        $c->model('DBIC')->resultset('ForumSettings')->clear_cache($forum_id);
        $c->res->redirect( $forum->{forum_url} );
    } else {

        # fulfill for FillInForm
        my @links
            = $c->model('DBIC::ForumSettings')->get_forum_links($forum_id);
        my $filldata;
        foreach my $i ( 0 .. $#links ) {
            $filldata->{"url$i"}  = $links[$i]->{url};
            $filldata->{"text$i"} = $links[$i]->{text};
        }
        $c->stash->{filldata} = $filldata;
    }
}

# it's an ajax request
sub change_membership : Chained('forum_for_admin') Args(0) {
    my ( $self, $c ) = @_;

    my $forum    = $c->stash->{forum};
    my $forum_id = $forum->{forum_id};

    # get params;
    my $from    = $c->req->param('from');
    my $to      = $c->req->param('to');
    my $user_id = $c->req->param('user_id');

    unless ( grep { $from eq $_ } ( 'user', 'rejected', 'blocked', 'pending' )
            and grep { $to eq $_ } ( 'user', 'rejected', 'blocked' )
            and $user_id =~ /^\d+$/ ) {
        return $c->res->body('Illegal request');
    }

    my $rs = $c->model('DBIC::UserForum')->count(
        {   forum_id => $forum_id,
            user_id  => $user_id,
            status   => $from,
        }
    );
    return $c->res->body('no record available') unless ($rs);

    if ( 'user' eq $from and ( 'rejected' eq $to or 'blocked' eq $to ) ) {
        $c->model('DBIC::Forum')
            ->update_forum( $forum_id,
            { total_members => \'total_members - 1' } );
    } elsif (
        ( 'rejected' eq $from or 'blocked' eq $from or 'pending' eq $from )
        and 'user' eq $to ) {
        $c->model('DBIC::Forum')
            ->update_forum( $forum_id,
            { total_members => \'total_members + 1' } );
    }

    my $where = {
        forum_id => $forum_id,
        user_id  => $user_id,
        status   => $from,
    };
    $c->model('DBIC::UserForum')->search($where)->update( { status => $to } );
    $c->model('DBIC::UserForum')->clear_cached_policy($where);

    $c->res->body('OK');
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
