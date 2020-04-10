# vim:set sw=4 ts=4 sts=4 ft=perl expandtab:
package Etherpad;
# ABSTRACT: interact with Etherpad API

use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json);
use Mojo::IOLoop;
use Data::Dumper;
use Carp qw(carp);

has 'url';
has 'apikey';
has 'user';
has 'password';
has 'proxy';
has 'ua' => sub { Mojo::UserAgent->new; };

our $VERSION = '1.2.14.0';


sub _execute {
    my $c    = shift;
    my $args = shift;

    if (defined $c->proxy) {
        if ($c->proxy->{detect}) {
            $c->ua->proxy->detect;
        } else {
            $c->ua->proxy->http($c->proxy->{http})  if defined $c->proxy->{http};
            $c->ua->proxy->http($c->proxy->{https}) if defined $c->proxy->{https};
        }
    }

    my $url = Mojo::URL->new($c->url);
    $url->userinfo($c->user.':'.$c->password) if defined $c->user && defined $c->password;

    my $path = $url->path;
    $path =~ s#/$##;
    $url->path($path.'/api/'.$args->{api}.'/'.$args->{method});

    $args->{args}->{apikey} = $c->apikey;

    my $res = $c->ua->get($url => form => $args->{args})->result;
    if ($res->is_success) {
        # Can’t use $res->json when json is too large
        my $json = decode_json($res->body);
        if ($json->{code} == 0) {
            return 1 if $args->{boolean};
            my $data;
            if (defined $args->{key}) {
                $data = (ref($json->{data}) eq 'HASH') ? $json->{data}->{$args->{key}} : $json->{data};
            } else {
                $data = $json->{data};
            }

            return (wantarray) ? @{$data}: $data if ref($data) eq 'ARRAY';
            return $data;
        } else {
            carp $json->{message};
            return undef;
        }
    } else {
        carp Dumper $res->message;
        return undef;
    }
}


#################################################################
#################################################################

#################### subroutine header begin ####################


#################### subroutine header end ####################


sub create_group {
    my $c = shift;

    return $c->_execute({
        api    => 1,
        method => 'createGroup',
        key    => 'groupID'
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub create_group_if_not_exists_for {
    my $c            = shift;
    my $group_mapper = shift;

    unless (defined($group_mapper)) {
        carp 'Please provide a group id';
        return undef;
    }

    my $args = {
        groupMapper => $group_mapper
    };

    return $c->_execute({
        api    => 1,
        method => 'createGroupIfNotExistsFor',
        key    => 'groupID',
        args   => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub delete_group {
    my $c        = shift;
    my $group_id = shift;

    unless (defined($group_id)) {
        carp 'Please provide a group id';
        return undef;
    }

    my $args = {
        groupID => $group_id
    };

    return $c->_execute({
        api     => 1,
        method  => 'deleteGroup',
        boolean => 1,
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub list_pads {
    my $c        = shift;
    my $group_id = shift;

    unless (defined($group_id)) {
        carp 'Please provide a group id';
        return undef;
    }

    my $args = {
        groupID => $group_id
    };

    return $c->_execute({
        api     => 1,
        method  => 'listPads',
        key     => 'padIDs',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub create_group_pad {
    my $c        = shift;
    my $group_id = shift;
    my $pad_name = shift;
    my $text     = shift;

    unless (defined($pad_name)) {
        carp 'Please provide at least 2 arguments : the group id and the pad name';
        return undef
    }

    my $args = {
        groupID => $group_id,
        padName => $pad_name
    };
    $args->{text} = $text if defined $text;

    return $c->_execute({
        api     => 1,
        method  => 'createGroupPad',
        boolean => 1,
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub list_all_groups {
    my $c = shift;

    return $c->_execute({
        api     => '1.1',
        method  => 'listAllGroups',
        key     => 'groupIDs'
    });
}


#################################################################
#################################################################

#################### subroutine header begin ####################


#################### subroutine header end ####################


sub create_author {
    my $c    = shift;
    my $name = shift;

    my $args = {};
    $args->{name} = $name if defined $name;

    return $c->_execute({
        api     => 1,
        method  => 'createAuthor',
        key     => 'authorID',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub create_author_if_not_exists_for {
    my $c             = shift;
    my $author_mapper = shift;
    my $name          = shift;

    unless (defined($author_mapper)) {
        carp 'Please provide your application author id';
        return undef;
    }

    my $args = {
        authorMapper => $author_mapper
    };
    $args->{name} = $name if defined $name;

    return $c->_execute({
        api     => 1,
        method  => 'createAuthorIfNotExistsFor',
        key     => 'authorID',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub list_pads_of_author {
    my $c         = shift;
    my $author_id = shift;

    unless (defined($author_id)) {
        carp 'Please provide an author id';
        return undef;
    }

    my $args = {
        authorID => $author_id
    };

    return $c->_execute({
        api     => 1,
        method  => 'listPadsOfAuthor',
        key     => 'padIDs',
        args    => $args
    });
}


#################### subroutine header end ####################


sub get_author_name {
    my $c         = shift;
    my $author_id = shift;

    unless (defined($author_id)) {
        carp 'Please provide an author id';
        return undef;
    }

    my $args = {
        authorID => $author_id
    };

    return $c->_execute({
        api     => '1.1',
        method  => 'getAuthorName',
        key     => 'authorName',
        args    => $args
    });
}


#################################################################
#################################################################

#################### subroutine header begin ####################


#################### subroutine header end ####################


sub create_session {
    my $c           = shift;
    my $group_id    = shift;
    my $author_id   = shift;
    my $valid_until = shift;

    unless (defined($valid_until)) {
        carp 'Please provide 3 arguments : the group id, the author id and a valid unix timestamp';
        return undef;
    }
    unless ($valid_until =~ m/\d+/) {
        carp 'Please provide a *valid* unix timestamp as third argument';
        return undef;
    }

    my $args = {
        groupID    => $group_id,
        authorID   => $author_id,
        validUntil => $valid_until
    };

    return $c->_execute({
        api     => 1,
        method  => 'createSession',
        key     => 'sessionID',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub delete_session {
    my $c          = shift;
    my $session_id = shift;

    unless (defined($session_id)) {
        carp 'Please provide a session id';
        return undef;
    }

    my $args = {
        sessionID => $session_id
    };

    return $c->_execute({
        api     => 1,
        method  => 'deleteSession',
        boolean => 1,
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub get_session_info {
    my $c          = shift;
    my $session_id = shift;

    unless (defined($session_id)) {
        carp 'Please provide a session id';
        return undef;
    }

    my $args = {
        sessionID => $session_id
    };

    return $c->_execute({
        api     => 1,
        method  => 'getSessionInfo',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub list_sessions_of_group {
    my $c        = shift;
    my $group_id = shift;

    unless (defined($group_id)) {
        carp 'Please provide a group id';
        return undef;
    }

    my $args = {
        groupID => $group_id
    };

    return $c->_execute({
        api     => 1,
        method  => 'listSessionsOfGroup',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub list_sessions_of_author {
    my $c         = shift;
    my $author_id = shift;

    unless (defined($author_id)) {
        carp 'Please provide an author id';
        return undef;
    }

    my $args = {
        authorID => $author_id
    };

    return $c->_execute({
        api     => 1,
        method  => 'listSessionsOfAuthor',
        args    => $args
    });
}


#################################################################
#################################################################

#################### subroutine header begin ####################


#################### subroutine header end ####################


sub get_text {
    my $c      = shift;
    my $pad_id = shift;
    my $rev    = shift;

    unless (defined($pad_id)) {
        carp 'Please provide at least a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };
    $args->{rev} = $rev if defined $rev;

    my $result = $c->_execute({
        api     => 1,
        method  => 'getText',
        key     => 'text',
        args    => $args
    });

    return $result->{text} if (ref $result eq 'HASH');
    return $result;
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub set_text {
    my $c      = shift;
    my $pad_id = shift;
    my $text   = shift;

    unless (defined($text)) {
        carp 'Please provide 2 arguments : a pad id and a text';
        return undef;
    }

    my $args = {
        padID => $pad_id,
        text  => $text
    };

    return $c->_execute({
        api     => 1,
        method  => 'setText',
        boolean => 1,
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub append_text {
    my $c      = shift;
    my $pad_id = shift;
    my $text   = shift;

    unless (defined($text)) {
        carp 'Please provide 2 arguments : a pad id and a text';
        return undef;
    }

    my $args = {
        padID => $pad_id,
        text  => $text
    };

    return $c->_execute({
        api     => '1.2.13',
        method  => 'appendText',
        boolean => 1,
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub get_html {
    my $c      = shift;
    my $pad_id = shift;
    my $rev    = shift;

    unless (defined($pad_id)) {
        carp 'Please provide at least a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };
    $args->{rev} = $rev if defined $rev;

    return $c->_execute({
        api     => 1,
        method  => 'getHTML',
        key     => 'html',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub set_html {
    my $c      = shift;
    my $pad_id = shift;
    my $html   = shift;

    unless (defined($html)) {
        carp 'Please provide 2 arguments : a pad id and a HTML code';
        return undef;
    }

    my $args = {
        padID => $pad_id,
        html  => $html
    };

    return $c->_execute({
        api     => 1,
        method  => 'setHTML',
        boolean => 1,
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub get_attribute_pool {
    my $c      = shift;
    my $pad_id = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };

    return $c->_execute({
        api     => '1.2.8',
        method  => 'getAttributePool',
        key     => 'pool',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub get_revision_changeset {
    my $c      = shift;
    my $pad_id = shift;
    my $rev    = shift;

    unless (defined($pad_id)) {
        carp 'Please provide at least a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };
    $args->{rev} = $rev if defined $rev;

    return $c->_execute({
        api     => '1.2.8',
        method  => 'getRevisionChangeset',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub create_diff_html {
    my $c         = shift;
    my $pad_id    = shift;
    my $start_rev = shift;
    my $end_rev   = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id, a start_rev and an end_rev';
        return undef;
    }

    unless (defined($start_rev)) {
        carp 'Please provide a start_rev and an end_rev';
        return undef;
    }

    unless (defined($end_rev)) {
        carp 'Please provide an end_rev';
        return undef;
    }

    my $args = {
        padID    => $pad_id,
        startRev => $start_rev,
        endRev   => $end_rev
    };

    return $c->_execute({
        api     => '1.2.7',
        method  => 'createDiffHTML',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub restore_revision {
    my $c      = shift;
    my $pad_id = shift;
    my $rev    = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id, a start_rev and an end_rev';
        return undef;
    }

    unless (defined($rev)) {
        carp 'Please provide a revision number';
        return undef;
    }

    my $args = {
        padID => $pad_id,
        rev   => $rev
    };

    return $c->_execute({
        api     => '1.2.11',
        method  => 'restoreRevision',
        boolean => 1,
        args    => $args
    });
}


#################################################################
#################################################################

#################### subroutine header begin ####################


#################### subroutine header end ####################


sub get_chat_history {
    my $c      = shift;
    my $pad_id = shift;
    my $start  = shift;
    my $end    = shift;

    unless (defined($pad_id)) {
        carp 'Please provide at least a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };
    $args->{start} = $start if defined $start;
    $args->{end}   = $end   if defined $end;

    return $c->_execute({
        api     => '1.2.7',
        method  => 'getChatHistory',
        key     => 'messages',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub get_chat_head {
    my $c      = shift;
    my $pad_id = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };

    return $c->_execute({
        api     => '1.2.7',
        method  => 'getChatHead',
        key     => 'chatHead',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub append_chat_message {
    my $c         = shift;
    my $pad_id    = shift;
    my $text      = shift;
    my $author_id = shift;
    my $timestamp = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id, a text, an authorID and a timestamp';
        return undef;
    }

    unless (defined($text)) {
        carp 'Please provide a text, an authorID and a timestamp';
        return undef;
    }

    unless (defined($author_id)) {
        carp 'Please provide an authorID and a timestamp';
        return undef;
    }

    unless (defined($timestamp)) {
        carp 'Please provide a timestamp';
        return undef;
    }

    my $args = {
        padID     => $pad_id,
        text      => $text,
        authorID  => $author_id,
        time      => $timestamp
    };

    return $c->_execute({
        api     => '1.2.12',
        method  => 'appendChatMessage',
        boolean => 1,
        args    => $args
    });
}


#################################################################
#################################################################

#################### subroutine header begin ####################


#################### subroutine header end ####################


sub create_pad {
    my $c      = shift;
    my $pad_id = shift;
    my $text   = shift;

    unless (defined($pad_id)) {
        carp 'Please provide at least a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };
    $args->{text} = $text if defined $text;

    return $c->_execute({
        api     => 1,
        method  => 'createPad',
        boolean => 1,
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub get_revisions_count {
    my $c      = shift;
    my $pad_id = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };

    return $c->_execute({
        api     => 1,
        method  => 'getRevisionsCount',
        key     => 'revisions',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub get_saved_revisions_count {
    my $c      = shift;
    my $pad_id = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };

    return $c->_execute({
        api     => '1.2.11',
        method  => 'getSavedRevisionsCount',
        key     => 'savedRevisions',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub list_saved_revisions {
    my $c      = shift;
    my $pad_id = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };

    return $c->_execute({
        api     => '1.2.11',
        method  => 'listSavedRevisions',
        key     => 'savedRevisions',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub save_revision {
    my $c      = shift;
    my $pad_id = shift;
    my $rev    = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };
    $args->{rev} = $rev if defined $rev;

    return $c->_execute({
        api     => '1.2.11',
        method  => 'saveRevision',
        boolean => 1,
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub get_users_count {
    my $c      = shift;
    my $pad_id = shift;

    return $c->pad_users_count($pad_id);
}

sub pad_users_count {
    my $c      = shift;
    my $pad_id = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };

    return $c->_execute({
        api     => 1,
        method  => 'padUsersCount',
        key     => 'padUsersCount',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub pad_users {
    my $c      = shift;
    my $pad_id = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };

    return $c->_execute({
        api     => '1.1',
        method  => 'padUsers',
        key     => 'padUsers',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub delete_pad {
    my $c      = shift;
    my $pad_id = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };

    return $c->_execute({
        api     => 1,
        method  => 'deletePad',
        boolean => 1,
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub copy_pad {
    my $c              = shift;
    my $source_id      = shift;
    my $destination_id = shift;
    my $force          = shift;

    unless (defined($source_id)) {
        carp 'Please provide a source pad id and a destination pad id';
        return undef;
    }

    unless (defined($destination_id)) {
        carp 'Please provide a destination pad id';
        return undef;
    }

    $source_id      =~ s/ /_/g;
    $destination_id =~ s/ /_/g;

    my $args = {
        sourceID      => $source_id,
        destinationID => $destination_id,
    };
    $args->{force} = ($force) ? 'true' : 'false' if defined $force;

    return $c->_execute({
        api     => '1.2.9',
        method  => 'copyPad',
        boolean => 1,
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub move_pad {
    my $c              = shift;
    my $source_id      = shift;
    my $destination_id = shift;
    my $force          = shift;

    unless (defined($source_id)) {
        carp 'Please provide a source pad id and a destination pad id';
        return undef;
    }

    unless (defined($destination_id)) {
        carp 'Please provide a destination pad id';
        return undef;
    }

    $source_id      =~ s/ /_/g;
    $destination_id =~ s/ /_/g;

    my $args = {
        sourceID      => $source_id,
        destinationID => $destination_id,
    };
    $args->{force} = ($force) ? 'true' : 'false' if defined $force;

    return $c->_execute({
        api     => '1.2.9',
        method  => 'movePad',
        boolean => 1,
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub get_read_only_id {
    my $c      = shift;
    my $pad_id = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };

    return $c->_execute({
        api     => 1,
        method  => 'getReadOnlyID',
        key     => 'readOnlyID',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub get_pad_id {
    my $c            = shift;
    my $read_only_id = shift;

    unless (defined($read_only_id)) {
        carp 'Please provide a read only id';
        return undef;
    }

    my $args = {
        padID => $read_only_id
    };

    return $c->_execute({
        api     => '1.2.10',
        method  => 'getPadID',
        key     => 'padID',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub set_public_status {
    my $c             = shift;
    my $pad_id        = shift;
    my $public_status = shift;

    unless (defined($public_status)) {
        carp 'Please provide 2 arguments : a pad id and a public status (1 or 0)';
        return undef;
    }

    my $args = {
        padID        => $pad_id,
        publicStatus => ($public_status) ? 'true' : 'false'
    };

    return $c->_execute({
        api     => 1,
        method  => 'setPublicStatus',
        boolean => 1,
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub get_public_status {
    my $c      = shift;
    my $pad_id = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };

    return $c->_execute({
        api     => 1,
        method  => 'getPublicStatus',
        key     => 'publicStatus',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub set_password {
    my $c        = shift;
    my $pad_id   = shift;
    my $password = shift;

    unless (defined($password)) {
        carp 'Please provide 2 arguments : a pad id and a password';
        return undef;
    }

    my $args = {
        padID    => $pad_id,
        password => $password
    };

    return $c->_execute({
        api     => 1,
        method  => 'setPassword',
        boolean => 1,
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub is_password_protected {
    my $c      = shift;
    my $pad_id = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };

    return $c->_execute({
        api     => 1,
        method  => 'isPasswordProtected',
        key     => 'isPasswordProtected',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub list_authors_of_pad {
    my $c      = shift;
    my $pad_id = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };

    return $c->_execute({
        api     => 1,
        method  => 'listAuthorsOfPad',
        key     => 'authorIDs',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub list_names_of_authors_of_pad {
    my $c      = shift;
    my $pad_id = shift;

    unless (defined($pad_id)) {
        carp 'Please provide a pad id';
        return undef;
    }

    my @names;
    my $anonymous = 0;

    my @authors = $c->list_authors_of_pad($pad_id);
    for my $author (@authors) {
        my $name = $c->get_author_name($author);
        if (defined($name)) {
            push @names, $name;
        } else {
            $anonymous++;
        }
    }
    @names = sort(@names);
    push @names, $anonymous . ' anonymous' if ($anonymous);

    return (wantarray) ? @names : \@names;
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub get_last_edited {
    my $c   = shift;
    my $pad_id = shift;

    unless (defined($pad_id)) {
        carp 'Please provide at least a pad id';
        return undef;
    }

    my $args = {
        padID => $pad_id
    };

    return $c->_execute({
        api     => 1,
        method  => 'getLastEdited',
        key     => 'lastEdited',
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub send_clients_message {
    my $c   = shift;
    my $pad_id = shift;
    my $msg    = shift;

    unless (defined($msg)) {
        carp "Please provide 2 arguments : the pad id and a message";
        return undef;
    }

    my $args = {
        padID => $pad_id,
        msg   => $msg
    };

    return $c->_execute({
        api     => '1.1',
        method  => 'sendClientsMessage',
        boolean => 1,
        args    => $args
    });
}


#################### subroutine header begin ####################


#################### subroutine header end ####################


sub check_token {
    my $c = shift;

    my $args = {};

    return $c->_execute({
        api     => '1.2',
        method  => 'checkToken',
        boolean => 1,
        args    => $args
    });
}


#################################################################
#################################################################

#################### subroutine header begin ####################



sub list_all_pads {
    my $c = shift;

    my $args = {};

    return $c->_execute({
        api     => '1.2.1',
        method  => 'listAllPads',
        key     => 'padIDs',
        args    => $args
    });
}

#################################################################
#################################################################

#################### subroutine header begin ####################



sub get_stats {
    my $c = shift;

    my $args = {};

    return $c->_execute({
        api     => '1.2.14',
        method  => 'getStats',
        args    => $args
    });
}

#################### footer pod documentation begin ###################
#################### footer pod documentation end ###################

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Etherpad - interact with Etherpad API

=head1 VERSION

version 1.2.14.0

=head1 SYNOPSIS

  use Etherpad;
  my $ec = Etherpad->new(
    url      => 'http://pad.example.org',
    apikey   => 'secret_etherpad_API_key',
    user     => 'http_user',
    password => 'http_password',
    proxy    => {
        http  => 'http://proxy.example.org',
        https => 'http://proxy.example.org'
    }
  );

  $ec->create_pad('new_pad_name');

=head1 DESCRIPTION

Client module for the Etherpad HTTP API.

The Etherpad API currently supported is the 1.2.13 (Etherpad version: 1.6.0)

This module aims to replace L<Etherpad::API>

=head1 ATTRIBUTES

L<Etherpad> implements the following attributes.

=head2 url

  my $url = $ec->url;
  $ec     = $ec->url('http://pad.example.org');

MANDATORY. The Etherpad URL, no default.

=head2 apikey

  my $apikey = $ec->apikey;
  $ec        = $ec->apikey('secret_etherpad_API_key');

MANDATORY. Secret API key, located in the APIKEY.txt file of your Etherpad installation directory, no default.

=head2 ua

  my $ua = $ec->ua;
  $ec    = $ec->ua(Mojo::UserAgent->new);

OPTIONAL. User agent, default to a Mojo::UserAgent. Please, don't use anything other than a Mojo::Useragent.

=head2 user

  my $user = $ec->user;
  $ec      = $ec->user('bender');

OPTIONAL. HTTP user, use it if your Etherpad is protected by a HTTP authentication, no default.

=head2 password

  my $password = $ec->password;
  $ec          = $ec->password('beer');

OPTIONAL. HTTP password, use it if your Etherpad is protected by a HTTP authentication, no default.

=head2 proxy

  my $proxy = $ec->proxy;
  $ec       = $ec->proxy({
    http  => 'http://proxy.example.org',
    https => 'http://proxy.example.org'
  });

OPTIONAL. Proxy settings. If set to { detect => 1 }, Etherpad will check environment variables HTTP_PROXY, http_proxy, HTTPS_PROXY, https_proxy, NO_PROXY and no_proxy for proxy information. No default.

=head1 METHODS

Etherpad inherits all methods from Mojo::Base and implements the following new ones.

=head2 Groups

Pads can belong to a group. The padID of grouppads is starting with a groupID like g.asdfasdfasdfasdf$test

See L<https://etherpad.org/doc/v1.6.0/#index_groups>

=head3 create_group

 Usage     : $ec->create_group();
 Purpose   : Creates a new group
 Returns   : The new group ID
 Argument  : None
 See       : https://etherpad.org/doc/v1.6.0/#index_creategroup

=head3 create_group_if_not_exists_for

 Usage     : $ec->create_group_if_not_exists_for('groupMapper');
 Purpose   : This functions helps you to map your application group ids to epl group ids
 Returns   : The epl group id
 Argument  : Your application group id
 See       : https://etherpad.org/doc/v1.6.0/#index_creategroupifnotexistsfor_groupmapper

=head3 delete_group

 Usage     : $ec->delete_group('groupId');
 Purpose   : Deletes a group
 Returns   : 1 if it succeeds
 Argument  : The id of the group you want to delete
 See       : https://etherpad.org/doc/v1.6.0/#index_deletegroup_groupid

=head3 list_pads

 Usage     : $ec->list_pads('groupId');
 Purpose   : Returns all pads of this group
 Returns   : An array or an array reference (depending on the context) which contains the pad ids
 Argument  : The id of the group from which you want the pads
 See       : https://etherpad.org/doc/v1.6.0/#index_listpads_groupid

=head3 create_group_pad

 Usage     : $ec->create_group_pad('groupID', 'padName' [, 'text'])
 Purpose   : Creates a new pad in this group
 Returns   : 1 if it succeeds
 Argument  : The group id, the pad name, optionally takes the pad's initial text
 See       : https://etherpad.org/doc/v1.6.0/#index_creategrouppad_groupid_padname_text

=head3 list_all_groups

 Usage     : $ec->list_all_groups()
 Purpose   : Lists all existing groups
 Returns   : An array or an array reference (depending on the context) which contains the groups ids
 Argument  : None
 See       : https://etherpad.org/doc/v1.6.0/#index_listallgroups

=head2 Author

These authors are bound to the attributes the users choose (color and name).

See L<https://etherpad.org/doc/v1.6.0/#index_author>

=head3 create_author

 Usage     : $ec->create_author(['name'])
 Purpose   : Creates a new author
 Returns   : The new author ID
 Argument  : Optionally takes a string as argument : the new author's name
 See       : https://etherpad.org/doc/v1.6.0/#index_createauthor_name

=head3 create_author_if_not_exists_for

 Usage     : $ec->create_author_if_not_exists_for(authorMapper [, name])
 Purpose   : This functions helps you to map your application author ids to epl author ids
 Returns   : The epl author ID
 Argument  : Your application author ID (mandatory) and optionally the epl author name
 See       : https://etherpad.org/doc/v1.6.0/#index_createauthorifnotexistsfor_authormapper_name

=head3 list_pads_of_author

 Usage     : $ec->list_pads_of_author('authorID')
 Purpose   : Returns an array of all pads this author contributed to
 Returns   : An array or an array reference depending on the context, containing the pads names
 Argument  : An epl author ID
 See       : https://etherpad.org/doc/v1.6.0/#index_listpadsofauthor_authorid

=head3 get_author_name

 Usage     : $ec->get_author_name('authorID')
 Purpose   : Returns the Author Name of the author
 Returns   : The author name
 Argument  : The epl author ID
 See       : https://etherpad.org/doc/v1.6.0/#index_getauthorname_authorid

=head2 Session

Sessions can be created between a group and an author. This allows an author to access more than one group. The sessionID will be set as a cookie to the client and is valid until a certain date. The session cookie can also contain multiple comma-seperated sessionIDs, allowing a user to edit pads in different groups at the same time. Only users with a valid session for this group, can access group pads. You can create a session after you authenticated the user at your web application, to give them access to the pads. You should save the sessionID of this session and delete it after the user logged out.

See L<https://etherpad.org/doc/v1.6.0/#index_session>

=head3 create_session

 Usage     : $ec->create_session('groupID', 'authorID', 'validUntil')
 Purpose   : Creates a new session. validUntil is an unix timestamp in seconds
 Returns   : The epl session ID
 Argument  : An epl group ID, an epl author ID and an valid unix timestamp (the session validity end date)
 See       : https://etherpad.org/doc/v1.6.0/#index_createsession_groupid_authorid_validuntil

=head3 delete_session

 Usage     : $ec->delete_session('sessionID')
 Purpose   : Deletes a session
 Returns   : 1 if it succeeds
 Argument  : An epl session ID
 See       : https://etherpad.org/doc/v1.6.0/#index_deletesession_sessionid

=head3 get_session_info

 Usage     : $ec->get_session_info('sessionID')
 Purpose   : Returns informations about a session
 Returns   : A hash reference, containing 3 keys : authorID, groupID and validUntil
 Argument  : An epl session ID
 See       : https://etherpad.org/doc/v1.6.0/#index_getsessioninfo_sessionid

=head3 list_sessions_of_group

 Usage     : $ec->list_sessions_of_group('groupID')
 Purpose   : Returns all sessions of a group
 Returns   : Returns a hash reference, which keys are sessions ID and values are sessions infos (see get_session_info)
 Argument  : An epl group ID
 See       : https://etherpad.org/doc/v1.6.0/#index_listsessionsofgroup_groupid

=head3 list_sessions_of_author

 Usage     : $ec->list_sessions_of_author('authorID')
 Purpose   : Returns all sessions of an author
 Returns   : Returns a hash reference, which keys are sessions ID and values are sessions infos (see get_session_info)
 Argument  : An epl group ID
 See       : https://etherpad.org/doc/v1.6.0/#index_listsessionsofauthor_authorid

=head2 Pad Content

Pad content can be updated and retrieved through the API.

See L<https://etherpad.org/doc/v1.6.0/#index_pad_content>

=head3 get_text

 Usage     : $ec->get_text('padID', ['rev'])
 Purpose   : Returns the text of a pad
 Returns   : A string, containing the text of the pad
 Argument  : Takes a pad ID (mandatory) and optionally a revision number
 See       : https://etherpad.org/doc/v1.6.0/#index_gettext_padid_rev

=head3 set_text

 Usage     : $ec->set_text('padID', 'text')
 Purpose   : Sets the text of a pad
 Returns   : 1 if it succeeds
 Argument  : Takes a pad ID and the text you want to set (both mandatory)
 See       : https://etherpad.org/doc/v1.6.0/#index_settext_padid_text

=head3 append_text

 Usage     : $ec->append_text('padID', 'text')
 Purpose   : Appends text to a pad
 Returns   : 1 if it succeeds
 Argument  : Takes a pad ID and the text you want to append (both mandatory)
 See       : https://etherpad.org/doc/v1.6.0/#index_appendtext_padid_text

=head3 get_html

 Usage     : $ec->get_html('padID', ['rev'])
 Purpose   : Returns the text of a pad formatted as html
 Returns   : A string, containing the text of the pad formatted as html
 Argument  : Takes a pad ID (mandatory) and optionally a revision number
 See       : https://etherpad.org/doc/v1.6.0/#index_gethtml_padid_rev

=head3 set_html

 Usage     : $ec->set_html('padID', 'html')
 Purpose   : Sets the text of a pad based on HTML, HTML must be well formed.
 Returns   : 1 if it succeeds
 Argument  : Takes a pad ID and the HTML code you want to set (both mandatory)
 See       : https://etherpad.org/doc/v1.6.0/#index_sethtml_padid_html

=head3 get_attribute_pool

 Usage     : $ec->get_attribute_pool('padID')
 Purpose   : Returns the attribute pool of a pad
 Returns   : A hash reference, containing 3 keys
             * numToAttrib, containing a hash reference, which keys are integers and contents are array references
             * attribToNum, containing a hash reference, which keys are string and contents are integers
             * nextNum, which content is an integer
 Argument  : Takes a pad ID (mandatory)
 See       : https://etherpad.org/doc/v1.6.0/#index_getattributepool_padid

=head3 get_revision_changeset

 Usage     : $ec->get_revision_changeset('padID' [, rev])
 Purpose   : Get the changeset at a given revision, or last revision if 'rev' is not defined
 Returns   : A string, representing an etherpad changeset
 Argument  : Takes a pad ID (mandatory) and optionally a revision number
 See       : https://etherpad.org/doc/v1.6.0/#index_getrevisionchangeset_padid_rev

=head3 create_diff_html

 Usage     : $ec->create_diff_html('padId', rev1, rev2)
 Purpose   : Returns an object of diffs from 2 points in a pad
 Returns   : A hash reference which keys are
             * html, which content is a string representing the diff between the two revisions
             * authors, which content is an array reference of authors
 Argument  : Takes a pad ID, a revision number to start and a revision number to end. All arguments are mandatory
 See       : https://etherpad.org/doc/v1.6.0/#index_creatediffhtml_padid_startrev_endrev

=head3 restore_revision

 Usage     : $ec->restore_revision('padId', rev)
 Purpose   : Restores revision from past as new changeset
 Returns   : 1 if it succeeds
 Argument  : Takes a pad ID, a revision number to restore. All arguments are mandatory
 See       : https://etherpad.org/doc/v1.7.0/#index_restorerevision_padid_rev

=head2 Chat

See L<https://etherpad.org/doc/v1.6.0/#index_chat>

=head3 get_chat_history

 Usage     : $ec->get_chat_history('padID' [, start, end])
 Purpose   : Returns
              - a part of the chat history, when start and end are given
              - the whole chat history, when no extra parameters are given
 Returns   : An array or an array reference, depending of the context, containing hash references with 4 keys :
              - text     => text of the message
              - userId   => epl user id
              - time     => unix timestamp of the message
              - userName => epl user name
 Argument  : Takes a pad ID (mandatory) and optionally the start and the end numbers of the messages you want.
             The start number can't be higher than or equal to the current chatHead. The first chat message is number 0.
             If you specify a start but not an end, all messages will be returned.
 See       : https://etherpad.org/doc/v1.6.0/#index_getchathistory_padid_start_end

=head3 get_chat_head

 Usage     : $ec->get_chat_head('padID')
 Purpose   : Returns the chatHead (last number of the last chat-message) of the pad
 Returns   : The last chat-message number. -1 if there is no chat message
 Argument  : A pad ID
 See       : https://etherpad.org/doc/v1.6.0/#index_getchathead_padid

=head3 append_chat_message

 Usage     : $ec->append_chat_message('padID', 'text', 'authorID', 'timestamp')
 Purpose   : Add a message to chat
 Returns   : 1 if it succeeds
 Argument  : Takes a pad ID (mandatory), a text (mandatory), an author ID (mandatory) and a timestamp (mantdatory)
 See       : Undocumented yet

=head2 Pad

Group pads are normal pads, but with the name schema GROUPID$PADNAME. A security manager controls access of them and its forbidden for normal pads to include a $ in the name.

See L<https://etherpad.org/doc/v1.6.0/#index_pad>

=head3 create_pad

 Usage     : $ec->create_pad('padID' [, 'text'])
 Purpose   : Creates a new (non-group) pad. Note that if you need to create a group Pad, you should call create_group_pad.
 Returns   : 1 if it succeeds
 Argument  : Takes a pad ID (mandatory) and optionally a text to fill the pad
 See       : https://etherpad.org/doc/v1.6.0/#index_createpad_padid_text

=head3 get_revisions_count

 Usage     : $ec->get_revisions_count('padID')
 Purpose   : Returns the number of revisions of this pad
 Returns   : The number of revisions
 Argument  : A pad ID
 See       : https://etherpad.org/doc/v1.6.0/#index_getrevisionscount_padid

=head3 get_saved_revisions_count

 Usage     : $ec->get_saved_revisions_count('padID')
 Purpose   : Returns the number of saved revisions of this pad
 Returns   : The number of saved revisions
 Argument  : A pad ID
 See       : https://etherpad.org/doc/v1.6.0/#index_getsavedrevisionscount_padid

=head3 list_saved_revisions

 Usage     : $ec->list_saved_revisions('padID')
 Purpose   : Returns the list of saved revisions of this pad
 Returns   : An array or an array reference, depending of the context, containing the saved revisions numbers
 Argument  : A pad ID
 See       : https://etherpad.org/doc/v1.6.0/#index_listsavedrevisions_padid

=head3 save_revision

 Usage     : $ec->save_revision('padID', ['rev'])
 Purpose   : Saves a revision
 Returns   : 1 if it succeeds
 Argument  : Takes a pad ID (mandatory) and optionally a revision number
 See       : https://etherpad.org/doc/v1.6.0/#index_saverevision_padid_rev

=head3 get_users_count

 Alias for pad_users_count (see below)

=head3 pad_users_count

 Usage     : $ec->pad_users_count('padID')
 Purpose   : Returns the number of user that are currently editing this pad
 Returns   : The number of users
 Argument  : A pad ID
 See       : https://etherpad.org/doc/v1.6.0/#index_paduserscount_padid

=head3 pad_users

 Usage     : $ec->pad_users('padID')
 Purpose   : Returns the list of users that are currently editing this pad
 Returns   : An array or an array reference, depending of the context, containing hash references with 3 keys : colorId, name and timestamp
 Argument  : A pad ID
 See       : https://etherpad.org/doc/v1.6.0/#index_padusers_padid

=head3 delete_pad

 Usage     : $ec->delete_pad('padID')
 Purpose   : Deletes a pad
 Returns   : 1 if it succeeds
 Argument  : A pad ID
 See       : https://etherpad.org/doc/v1.6.0/#index_deletepad_padid

=head3 copy_pad

 Usage     : $ec->copy_pad('sourceID', 'destinationID' [, 1])
 Purpose   : Copies a pad with full history and chat. If force is true and the destination pad exists, it will be overwritten
 Returns   : 1 if it succeeds
 Argument  : A source pad ID
             A destination pad ID
             A force flag : a value which is true or false, in perl interpretation (for example; 0 and '' are false, 1, 2 and 'foo' are true)
 See       : https://etherpad.org/doc/v1.6.0/#index_copypad_sourceid_destinationid_force_false

=head3 move_pad

 Usage     : $ec->move_pad('sourceID', 'destinationID' [, 1])
 Purpose   : Moves a pad. If force is true and the destination pad exists, it will be overwritten
 Returns   : 1 if it succeeds
 Argument  : A source pad ID
             A destination pad ID
             A force flag : a value which is true or false, in perl interpretation (for example; 0 and '' are false, 1, 2 and 'foo' are true)
 See       : https://etherpad.org/doc/v1.6.0/#index_movepad_sourceid_destinationid_force_false

=head3 get_read_only_id

 Usage     : $ec->get_read_only_id('padID')
 Purpose   : Returns the read only link of a pad
 Returns   : A string
 Argument  : A pad ID
 See       : https://etherpad.org/doc/v1.6.0/#index_getreadonlyid_padid

=head3 get_pad_id

 Usage     : $ec->get_pad_id('readOnlyID')
 Purpose   : Returns the id of a pad which is assigned to the readOnlyID
 Returns   : A string
 Argument  : A read only ID
 See       : https://etherpad.org/doc/v1.6.0/#index_getpadid_readonlyid

=head3 set_public_status

 Usage     : $ec->set_public_status('padID', 'publicStatus')
 Purpose   : Sets a boolean for the public status of a pad
 Returns   : 1 if it succeeds
 Argument  : A pad ID and the public status you want to set : 1 or 0
 See       : https://etherpad.org/doc/v1.6.0/#index_setpublicstatus_padid_publicstatus

=head3 get_public_status

 Usage     : $ec->get_public_status('padID')
 Purpose   : Return true of false
 Returns   : 1 or 0
 Argument  : A pad ID
 See       : https://etherpad.org/doc/v1.6.0/#index_getpublicstatus_padid

=head3 set_password

 Usage     : $ec->set_password('padID', 'password')
 Purpose   : Returns ok or a error message
 Returns   : 1 if it succeeds
 Argument  : A pad ID and a password
 See       : https://etherpad.org/doc/v1.6.0/#index_setpassword_padid_password

=head3 is_password_protected

 Usage     : $ec->is_password_protected('padID')
 Purpose   : Returns true or false
 Returns   : 1 or 0
 Argument  : A pad ID
 See       : https://etherpad.org/doc/v1.6.0/#index_ispasswordprotected_padid

=head3 list_authors_of_pad

 Usage     : $ec->list_authors_of_pad('padID')
 Purpose   : Returns an array of authors who contributed to this pad
 Returns   : An array or an array reference depending on the context, containing the epl authors IDs
 Argument  : A pad ID
 See       : https://etherpad.org/doc/v1.6.0/#index_listauthorsofpad_padid

=head3 list_names_of_authors_of_pad

 Usage     : $ec->list_names_authors_of_pad('padID')
 Returns   : Returns an array of the names of the authors who contributed to this pad in list context
             Returns an array reference in scalar context
 Argument  : The pad ID
 See       : This is not part of the Etherpad API but a facility offered by this module

=head3 get_last_edited

 Usage     : $ec->get_last_edited('padID')
 Purpose   : Returns the timestamp of the last revision of the pad
 Returns   : A unix timestamp
 Argument  : A pad ID
 See       : https://etherpad.org/doc/v1.6.0/#index_getlastedited_padid

=head3 send_clients_message

 Usage     : $ec->send_clients_message('padID', 'msg')
 Purpose   : Sends a custom message of type msg to the pad
 Returns   : 1 if it succeeds
 Argument  : A pad ID and the message you want to send
 See       : https://etherpad.org/doc/v1.6.0/#index_sendclientsmessage_padid_msg

=head2 check_token

 Usage     : $ec->check_token()
 Purpose   : Returns ok when the current api token is valid
 Returns   : 1 if the token is valid, 0 otherwise
 Argument  : None
 See       : https://etherpad.org/doc/v1.6.0/#index_checktoken

=head2 Pads

See L<https://etherpad.org/doc/v1.6.0/#index_pads>

=head3 list_all_pads

 Usage     : $ec->list_all_pads()
 Purpose   : Lists all pads on this epl instance
 Returns   : An array or an array reference depending on the context, containing the pads names
 See       : https://etherpad.org/doc/v1.6.0/#index_listallpads

=head2 Global

See L<https://etherpad.org/doc/v1.8.3/#global>

(URL not usable yet)

=head3 get_stats

 Usage     : $ec->get_stats()
 Purpose   : Get stats of the etherpad instance
 Returns   : A hash reference, containing 3 keys : totalPads, totalSessions and totalActivePads
 See       : https://etherpad.org/doc/v1.8.3/#getstats (URL not usable yet)

=head1 INSTALL

After getting the tarball on https://metacpan.org/release/Etherpad, untar it, go to the directory and:

    perl Makefile.PL
    make
    make test
    make install

If you are on a windows box you should use 'nmake' rather than 'make'.

=head1 BUGS and SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Etherpad

Bugs and feature requests will be tracked on:

    https://framagit.org/fiat-tux/etherpad/issues

The latest source code can be browsed and fetched at:

    https://framagit.org/fiat-tux/etherpad
    git clone https://framagit.org/fiat-tux/etherpad.git

Source code mirror:

    https://github.com/ldidry/etherpad

You can also look for information at:

    AnnoCPAN: Annotated CPAN documentation

    http://annocpan.org/dist/Etherpad
    CPAN Ratings

    http://cpanratings.perl.org/d/Etherpad
    Search CPAN

    http://search.cpan.org/dist/Etherpad

=head1 AUTHOR

    Luc DIDRY
    CPAN ID: LDIDRY
    ldidry@cpan.org
    https://fiat-tux.fr/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1), L<Mojolicious>

=head1 AUTHOR

Luc Didry <ldidry@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Luc Didry.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
