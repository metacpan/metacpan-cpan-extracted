package EV::Telegram::TDLib::Users;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.04';

=head1 NAME

EV::Telegram::TDLib::Users - user methods for EV::Telegram::TDLib

=head1 DESCRIPTION

One of the mixins L<EV::Telegram::TDLib> inherits from. It has no
interface of its own and is not meant to be used directly: loading the
main module loads this one, and its methods are called on a client.

They are documented together with the rest of the API, under
L<EV::Telegram::TDLib/"Users mixin">.

=cut

sub CLONE_SKIP { 1 }


our %UPDATES = (
    updateUser => \&update_user,
);

sub users { $_[0]{cache}{users} ||= {} }

sub update_user {
    my ($self, $obj) = @_;
    my $user = $obj->{user} or return;
    $self->users->{ $user->{id} } = $user;
    if (my $cb = $self->{on_user}) { $cb->($user) }
}

sub me {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('me', 0, \@args);
    $self->send({ '@type' => 'getMe' }, sub {
        my ($user, $err) = @_;
        $self->users->{ $user->{id} } = $user if $user;
        $cb->($user, $err);
    });
    return;
}

sub user {
    my ($self, $id) = @_;
    # a cache read documented to answer undef for a user not yet seen: an
    # undef id answers the same way rather than croaking, and returning early
    # keeps the lookup from warning from inside the module
    return undef unless defined $id;
    $id = 0 + $id if !ref $id && $id =~ /\A\s*[+-]?[0-9]+\s*\z/;
    return $self->users->{$id};
}

sub on_user {
    my ($self, $cb) = @_;
    $self->{on_user} = $cb if @_ > 1;
    return $self->{on_user};
}

# searchPublicChat resolves any public @name; only a private chat carries a
# user behind it, so a channel or group is reported as such rather than undef
sub user_by_username {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('user_by_username', 1, \@args);
    my ($name) = @args;
    need('username', $name);
    $name = plain_text('a username', $name);
    $name =~ s/^\@//;
    $self->send({ '@type' => 'searchPublicChat', username => $name }, sub {
        my ($chat, $err) = @_;
        if ($err) { $cb->(undef, $err); return }
        my $uid = $chat->{type}{user_id};
        if (!$uid) {
            $cb->(undef, { '@type' => 'error', code => -1,
                           message => "\@$name is not a user" });
            return;
        }
        $self->send({ '@type' => 'getUser', user_id => 0 + $uid }, sub {
            my ($user, $err) = @_;
            $self->users->{ $user->{id} } = $user if $user;
            $cb->($user, $err);
        });
    });
    return;
}

# a profile photo is an InputChatPhoto, which wraps an InputFile the same way
# message media do; an animated one also needs the frame to show when still
sub input_chat_photo {
    my ($self, $path, $opt) = @_;
    need('path', $path);
    my $file = input_file($path);
    return { '@type' => 'inputChatPhotoStatic', photo => $file }
        unless $opt->{animation};
    return {
        '@type'    => 'inputChatPhotoAnimation',
        animation  => $file,
        main_frame_timestamp =>
            real('main_frame_timestamp', $opt->{main_frame_timestamp} // 0),
    };
}

sub set_profile_photo {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($path, @rest) = @args;
    my %opt = opts(@rest);
    $self->send({
        '@type'   => 'setProfilePhoto',
        photo     => $self->input_chat_photo($path, \%opt),
        is_public => json_bool($opt{public}),
    }, $cb);
    return;
}

sub set_name {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_name', 2, \@args);
    my ($first, $last) = @args;
    $first = plain_text('a first name', $first);
    croak 'set_name needs a first name' unless length $first;
    $self->send({ '@type' => 'setName', first_name => $first,
                  last_name => plain_text('a last name', $last) }, $cb);
    return;
}

# The value is required even though the empty string is a legal one. Popping
# the callback made set_bio($cb) look like "no value given", and clearing on
# that reading turned a call that used to fail harmlessly into one that wipes
# the account's bio -- and, for set_username, frees its public username.
sub set_bio {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_bio', 1, \@args);
    croak 'set_bio needs a bio; pass the empty string to clear yours'
        unless @args;
    my ($bio) = @args;
    $self->send({ '@type' => 'setBio', bio => plain_text('a bio', $bio) }, $cb);
    return;
}

sub set_username {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_username', 1, \@args);
    croak 'set_username needs a username; pass the empty string to remove yours'
        unless @args;
    my $name = plain_text('a username', $args[0]);
    $name =~ s/^\@//;
    # The command router caches our username and asks for it once, so a rename
    # would otherwise leave every /command@newname unmatched for the life of
    # the process. Re-fetching cannot fix it: a getMe issued after the rename
    # can still be answered from TDLib's own user cache with the old name, and
    # memoing that freezes it again. The server accepting setUsername is what
    # makes the new name true, so the memo is written from here instead.
    delete @{$self}{qw(my_username my_username_asked my_username_pending)};
    my $gen = ++$self->{my_username_gen};
    $self->send({ '@type' => 'setUsername', username => $name }, sub {
        my ($res, $err) = @_;
        if (!$err && ($self->{my_username_gen} // 0) == $gen) {
            # a getMe issued while the rename was in flight is still owed an
            # answer, and TDLib can serve it from its own cache with the old
            # name: move the generation on so that reply is discarded
            $self->{my_username_gen}++;
            delete $self->{my_username_pending};
            $self->{my_username} = length $name ? $name : undef;
            $self->{my_username_asked} = 1;
        }
        $cb->($res, $err);
    });
    return;
}

# a contact carries a phone number even when the user id is known: Telegram
# matches on the number, and an empty one simply means "no number to import"
sub contact {
    my ($self, $spec) = @_;
    croak 'each contact must be a hashref' unless ref $spec eq 'HASH';
    my $contact = {
        '@type'       => 'importedContact',
        # stringified, not just defaulted: a phone number written without
        # quotes is a number, and TDLib refuses a Number in a string slot
        phone_number  => plain_text('a phone number', $spec->{phone}),
        first_name    => plain_text('a first name', $spec->{first_name}),
        last_name     => plain_text('a last name', $spec->{last_name}),
    };
    $contact->{note} = $self->format_text($spec->{note}) if defined $spec->{note};
    return $contact;
}

sub contacts {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('contacts', 0, \@args);
    $self->send({ '@type' => 'getContacts' }, $cb);
    return;
}

sub add_contact {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($user_id, @rest) = @args;
    my %opt = opts(@rest);
    need('user_id', $user_id);
    $self->send({
        '@type'              => 'addContact',
        user_id              => 0 + $user_id,
        contact              => contact($self, \%opt),
        share_phone_number   => json_bool($opt{share_phone}),
    }, $cb);
    return;
}

sub remove_contacts {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('remove_contacts', 1, \@args);
    my ($user_ids) = @args;
    need('user_ids', $user_ids);
    croak 'remove_contacts needs an arrayref of user ids' unless ref $user_ids eq 'ARRAY';
    $self->send({ '@type' => 'removeContacts',
                  user_ids => num_list('user_ids', $user_ids) }, $cb);
    return;
}

sub search_contacts {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($query, @rest) = @args;
    my %opt = opts(@rest);
    $self->send({ '@type' => 'searchContacts',
                  query => plain_text('a query', $query),
                  limit => num('limit', $opt{limit} // 50) }, $cb);
    return;
}

sub import_contacts {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('import_contacts', 1, \@args);
    my ($list) = @args;
    need('contacts', $list);
    croak 'import_contacts needs an arrayref of contacts' unless ref $list eq 'ARRAY';
    $self->send({ '@type' => 'importContacts',
                  contacts => [ map { contact($self, $_) } @$list ] }, $cb);
    return;
}

# an omitted birthdate clears it; year is optional and 0 means unstated.
# TDLib takes any date it cannot store as a request to clear it.
sub set_birthdate {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my (@rest) = @args;
    my %opt = opts(@rest);
    my %req = ('@type' => 'setBirthdate');
    if (defined $opt{day} || defined $opt{month} || defined $opt{year}) {
        croak 'set_birthdate needs both day and month; pass none of day, month '
            . 'and year to clear the birthdate'
            unless defined $opt{day} && defined $opt{month};
        my $day   = num('day', $opt{day});
        my $month = num('month', $opt{month});
        my $year  = num('year', $opt{year} // 0);
        croak "month must be 1 to 12, and perl's localtime gives 0 to 11: add 1 to it"
            unless $month >= 1 && $month <= 12;
        croak 'year must be 1800 to 3000, or 0 or omitted when unknown'
            if $year && ($year < 1800 || $year > 3000);
        my $leap = !$year || ($year % 4 == 0 && ($year % 100 || $year % 400 == 0));
        my $max = (31, $leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[$month - 1];
        croak "day must be 1 to $max for month $month" . ($year ? " of $year" : '')
            unless $day >= 1 && $day <= $max;
        $req{birthdate} = { '@type' => 'birthdate',
                            day => $day, month => $month, year => $year };
    }
    $self->send(\%req, $cb);
    return;
}

sub set_accent_color {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($color_id, @rest) = @args;
    my %opt = opts(@rest);
    need('accent_color_id', $color_id);
    $self->send({ '@type' => 'setAccentColor', accent_color_id => 0 + $color_id,
                  background_custom_emoji_id =>
                      plain_text('a custom emoji id',
                                 $opt{background_custom_emoji_id} // 0) }, $cb);
    return;
}

sub profile_photos {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($user_id, @rest) = @args;
    my %opt = opts(@rest);
    need('user_id', $user_id);
    $self->send({ '@type' => 'getUserProfilePhotos', user_id => 0 + $user_id,
                  offset => num('offset', $opt{offset} // 0),
                  limit => num('limit', $opt{limit} // 100) }, $cb);
    return;
}

# profile photo ids are TL int64
sub delete_profile_photo {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('delete_profile_photo', 1, \@args);
    my ($photo_id) = @args;
    need('profile_photo_id', $photo_id);
    $self->send({ '@type' => 'deleteProfilePhoto',
                  profile_photo_id =>
                      plain_text('a profile photo id', $photo_id) }, $cb);
    return;
}


sub search_by_phone {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($phone, @rest) = @args;
    my %opt = opts(@rest);
    need('phone_number', $phone);
    $self->send({ '@type' => 'searchUserByPhoneNumber',
                  phone_number => plain_text('a phone number', $phone),
                  only_local => json_bool($opt{local}) }, $cb);
    return;
}

sub my_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('my_link', 0, \@args);
    $self->send({ '@type' => 'getUserLink' }, $cb);
    return;
}

sub toggle_username {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($username, $active, @rest) = @args;
    no_opts('toggle_username', @rest);
    need('username', $username);
    $self->send({ '@type' => 'toggleUsernameIsActive',
                  username => plain_text('a username', $username),
                  is_active => json_bool(defined $active ? $active : 1) }, $cb);
    return;
}

my %PRIVACY = (
    status          => 'userPrivacySettingShowStatus',
    profile_photo   => 'userPrivacySettingShowProfilePhoto',
    phone           => 'userPrivacySettingShowPhoneNumber',
    bio             => 'userPrivacySettingShowBio',
    birthdate       => 'userPrivacySettingShowBirthdate',
    forwards        => 'userPrivacySettingShowLinkInForwardedMessages',
    invites         => 'userPrivacySettingAllowChatInvites',
    calls           => 'userPrivacySettingAllowCalls',
    find_by_phone   => 'userPrivacySettingAllowFindingByPhoneNumber',
);

sub privacy {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('privacy', 1, \@args);
    my ($setting) = @args;
    my $t = $PRIVACY{ $setting // '' }
        or croak "unknown privacy setting '" . ($setting // '') . "'";
    $self->send({ '@type' => 'getUserPrivacySettingRules',
                  setting => { '@type' => $t } }, $cb);
    return;
}

# rules are an ordered list and the first match wins, so their order matters
sub set_privacy {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_privacy', 2, \@args);
    my ($setting, $rules) = @args;
    need('setting, rules', $setting, $rules);
    croak 'set_privacy needs an arrayref of rules' unless ref $rules eq 'ARRAY';
    my $t = $PRIVACY{$setting} or croak "unknown privacy setting '$setting'";
    $self->send({ '@type' => 'setUserPrivacySettingRules',
                  setting => { '@type' => $t },
                  rules   => { '@type' => 'userPrivacySettingRules',
                               rules => $rules } }, $cb);
    return;
}

1;
