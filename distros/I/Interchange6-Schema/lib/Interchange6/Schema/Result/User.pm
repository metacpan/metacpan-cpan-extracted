use utf8;

package Interchange6::Schema::Result::User;

=head1 NAME

Interchange6::Schema::Result::User

=cut

use base 'Interchange6::Schema::Base::Attribute';

use Interchange6::Schema::Candy -components =>
  [qw(InflateColumn::DateTime PassphraseColumn TimeStamp)];

use Class::Method::Modifiers;
use Data::UUID;
use DateTime;
use Digest::MD5;
use DateTime;
use Session::Token;

=head1 ACCESSORS

=head2 users_id

Primary key.

=cut 

primary_column users_id => {
    data_type         => "integer",
    is_auto_increment => 1,
    sequence          => "users_users_id_seq",
};

=head2 username

The username is automatically converted to lowercase so
we make sure that the unique constraint on username works.

=cut

unique_column username => {
    data_type   => "varchar",
    size        => 255,
    accessor    => '_username',
};

sub username {
    my $self = shift;
    if ( @_ ) {
        my $value = shift;
        $value = check_username($value);
        $self->_username($value);
    }
    return $self->_username();
}

=head2 nickname

Unique nickname for user.

=cut

unique_column nickname => {
    data_type   => "varchar",
    is_nullable => 1,
    size        => 255,
};

=head2 email

email address.

=cut

column email => {
    data_type     => "varchar",
    default_value => "",
    size          => 255,
};

=head2 password

See L<DBIx::Class::PassphraseColumn> and its dependency
L<Authen::Passphrase> for full details of supported password encodings.

New/changed passwords are currently encoded using
L<Authen::Passphrase::BlowfishCrypt> using 2^14 rounds and random salt.

Check password method is C<check_password>.

Default value is '{CRYPT}*' which causes C<check_password> to fail.

=cut

column password => {
    data_type        => "varchar",
    size             => 2048,
    default_value    => '*', # reject
    passphrase       => 'crypt',
    passphrase_class => 'BlowfishCrypt',
    passphrase_args  => {
        cost        => 14,
        key_nul     => 1,
        salt_random => 1,
    },
    passphrase_check_method => 'check_password',
};

around 'check_password' => sub { 
    my $orig = shift;
    my $self = shift;
    my $ret;
    # DBIx::Class::PassphraseColumn v0.02 can throw exceptions so use eval.
    # Must investigate further why column inflation sometimes returns undef
    # which cause ->match to fail.
    eval { $ret = $orig->($self, @_) };
    if ( $ret ) {
        $self->update( { fail_count => 0, last_login => DateTime->now } );
    }
    else {
        $self->update( { fail_count => ( $self->fail_count || 0 ) + 1 } );
    }
    return $ret;
};

=head2 first_name

User's first name.

=cut

column first_name => {
    data_type     => "varchar",
    default_value => "",
    size          => 255,
};

=head2 last_name

User's last name.

=cut

column last_name => {
    data_type     => "varchar",
    default_value => "",
    size          => 255,
};

=head2 last_login

Last login returned as L<DateTime> object. Updated on successful call to
C<check_password>.

=cut

column last_login => {
    data_type   => "datetime",
    is_nullable => 1,
};

=head2 fail_count

Count of failed logins since last successful login. On successful call to
C<check_password> gets reset to zero but on fail is incremented.

=cut

column fail_count => {
    data_type     => "integer",
    default_value => 0,
};

=head2 reset_expires

Date and time when L</reset_token> expires.

=cut

column reset_expires => {
    data_type   => "datetime",
    is_nullable => 1,
};

=head2 reset_token

Used to store password reset token.

=cut

column reset_token => {
    data_type   => "varchar",
    size        => 255,
    is_nullable => 1,
};

=head2 is_anonymous

Boolean denoting an anonymous user. Defaults to 0 (false);

=cut

column is_anonymous => {
    data_type     => "boolean",
    default_value => 0,
};

=head2 created

Date and time when this record was created returned as L<DateTime> object.
Value is auto-set on insert.

=cut

column created => {
    data_type     => "datetime",
    set_on_create => 1,
};

=head2 last_modified

Date and time when this record was last modified returned as L<DateTime> object.
Value is auto-set on insert and update.

=cut

column last_modified => {
    data_type     => "datetime",
    set_on_create => 1,
    set_on_update => 1,
};

=head2 active

Is this user account active? Default is yes.

=cut

column active => {
    data_type     => "boolean",
    default_value => 1,
};

=head1 RELATIONS

=head2 addresses

Type: has_many

Related object: L<Interchange6::Schema::Result::Address>

=cut

has_many
  addresses => "Interchange6::Schema::Result::Address",
  "users_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 carts

Type: has_many

Related object: L<Interchange6::Schema::Result::Cart>

=cut

has_many
  carts => "Interchange6::Schema::Result::Cart",
  "users_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 orders

Type: has_many

Related object: L<Interchange6::Schema::Result::Order>

=cut

has_many
  orders => "Interchange6::Schema::Result::Order",
  "users_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 user_attributes

Type: has_many

Related object: L<Interchange6::Schema::Result::UserAttribute>

=cut

has_many
  user_attributes => "Interchange6::Schema::Result::UserAttribute",
  "users_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 user_roles

Type: has_many

Related object: L<Interchange6::Schema::Result::UserRole>

=cut

has_many
  user_roles => "Interchange6::Schema::Result::UserRole",
  "users_id";

=head2 roles

Type: many_to_many

Composing rels: L</user_roles> -> role

=cut

many_to_many roles => "user_roles", "role";

=head2 approvals

Type: has_many

Related object: L<Interchange6::Schema::Result::Message> FK C<approved_by_users_id>

=cut

has_many
  approvals => "Interchange6::Schema::Result::Message",
  { 'foreign.approved_by_users_id' => 'self.users_id' };

=head2 messages

Type: has_many

Related object: L<Interchange6::Schema::Result::Message> FK C<author_users_id>

=cut

has_many
  messages => "Interchange6::Schema::Result::Message",
  { 'foreign.author_users_id' => 'self.users_id' };

=head1 METHODS

Attribute methods are provided by the L<Interchange6::Schema::Base::Attribute> class.

=head2 sqlt_deploy_hook

Called during table creation to add indexes on the following columns:

=over 4

=item * reset_token

=back

=cut

sub sqlt_deploy_hook {
    my ( $self, $table ) = @_;

    $table->add_index(
        name   => 'users_idx_reset_token',
        fields => ['reset_token']
    );
}

=head2 reset_token_generate( %args );

Arguments should be a hash of the following key/value pairs:

=over

=item * duration => $datetime_duration_hashref

Value should be a hash reference containing values that can be passed directly
to L<DateTime::Duration/new>. Passing an undef value to duration will lead
to the creation of a reset token that does not expire. Default duration is
24 hours.

=item * entropy => $number_of_bits

The number of bits of entropy to be used by L<Session::Token/new>. Defaults
to 128.

=back

This method sets L</reset_expires> and L</reset_token> and returns the value
of L</reset_token> with checksum added.

=cut

sub reset_token_generate {
    my ( $self, %args ) = @_;

    if ( exists $args{duration} && !defined $args{duration} ) {

        # we got undef duration so clear reset_expires

        $self->reset_expires(undef);
    }
    else {

        # attempt to set reset_expires to appropriate value

        if ( $args{duration} ) {
            $self->throw_exception(
                "duration arg to reset_token_generate must be a hashref")
              unless ref( $args{duration} ) eq 'HASH';
        }
        else {
            $args{duration} = { hours => 24 };
        }

        my $dt = DateTime->now;
        $dt->add( %{$args{duration}} );
        $self->reset_expires($dt);
    }

    # generate random token and store it in the DB

    # Session::Token->new assumes entropy is numeric but first check is '>'
    # which causes a warning on non-numeric so we check here 1st
    die "bad value for entropy"
      if ( $args{entropy} && $args{entropy} !~ /^\d+$/ );

    # set default entropy if not defined
    $args{entropy} = 128 unless $args{entropy};

    my $token = Session::Token->new( entropy => $args{entropy} )->get;
    $self->reset_token( $token );

    # flush changes to DB

    $self->update;

    # return combined token and checksum

    return join( "_", $token, $self->reset_token_checksum($token) );
}

=head2 reset_token_checksum

Returns the checksum for the token stored in L</reset_token>.

Checksum is a digest of L</password>, L</reset_token> and L</reset_expires>
(if this is defined). This ensures that a reset token is not valid if password
has changed or if a newer token has been generated.

=cut

sub reset_token_checksum {
    my $self = shift;
    my $digest = Digest::MD5->new();
    $digest->add( $self->password->as_crypt ) if $self->password;
    $digest->add( $self->reset_token );
    $digest->add( $self->reset_expires->datetime ) if $self->reset_expires;
    return $digest->hexdigest();
}

=head2 reset_token_verify

When passed combined token and checksum as argument returns 1 if token
and checksum are correct and L</reset_expires> is not in the past (if
it is defined). Returns 0 on failure.

=cut

sub reset_token_verify {
    my $self = shift;
    my ( $token, $checksum ) = split(/_/, shift);

    $self->throw_exception("Bad argument to reset_token_verify")
      unless $checksum;

    # check token and expiry against DB and compare checksum

    # The following should be combined in a single 'if' statement but sadly
    # we then end up with Devel::Cover being unable to test the condition
    # correctly so instead we break it out into ugly code. At least it
    # means we know our tests are covering all condition. :(
    if ( $self->reset_token eq $token ) {
        if ( !$self->reset_expires || DateTime->now <= $self->reset_expires ) {
            if ( $self->reset_token_checksum eq $checksum ) {
                return 1;
            }
        }
    }
    return 0;
}

=head2 new

Overloaded method.

If L</username> is undefined and L</is_anonymous> is defined then create
a unique username for this anonymous user and set L</active> to false.
Otherwise check username using L</check_username>.

=cut

sub new {
    my ( $class, $attrs ) = @_;

    if ( defined $attrs->{is_anonymous} && !defined $attrs->{username} ) {
        my $ug = Data::UUID->new;
        $attrs->{username} = "anonymous-" . lc( $ug->create_str );
        $attrs->{active}   = 0;
    }
    else {
        $attrs->{username} = check_username($attrs->{username});
    }

    my $new = $class->next::method($attrs);
    return $new;
}

=head2 insert

Overloaded method. Always add new users to Role with name 'user' unless user
has L</is_anonymous> set in which case add user to role 'anonymous';

=cut

sub insert {
    my ($self, @args) = @_;
    
    my $guard = $self->result_source->schema->txn_scope_guard;

    $self->next::method(@args);

    my $role_name = $self->is_anonymous ? 'anonymous' : 'user';

    my $user_role = $self->result_source->schema->resultset('Role')
      ->find( { name => $role_name } );

    # uncoverable branch false
    if ( $user_role ) {
        $self->create_related( 'user_roles', { roles_id => $user_role->id } );
    }
    else {
        # we should never get here
        # uncoverable statement
        $self->throw_exception(
            "Role with name 'user' must exist when creating a new user");
    }
    
    $guard->commit;
    return $self;
}

=head2 update

Overloaded method. Check username using L</check_username> if supplied.

=cut

sub update {
    my ( $self, $upd ) = @_;

    my $username;

    # username may have been passed as arg or previously set

    if ( exists $upd->{username} ) {
        $upd->{username} = check_username($upd->{username});
    }

    return $self->next::method($upd);
}

=head2 check_username( $username )

Die if C<$username> is undef or empty string. Otherwise return C<lc($username)>

=cut

sub check_username {
    my $value = shift;
    die "username cannot be undef" unless defined $value;
    $value =~ s/(^\s+|\s+$)//g;
    die "username cannot be empty string" if $value eq '';
    return lc($value);
}

=head2 blog_posts

Returns resultset of messages that are blog posts

=cut

sub blog_posts {
    my $self = shift;
    return $self->messages->search( { 'message_type.name' => 'blog_post' },
        { join => 'message_type' } );
}

=head2 name

Returns L</first_name> and L</last_name> joined by a single space.

=cut

sub name {
    my $self = shift;
    return join( " ", $self->first_name, $self->last_name );
}

=head2 reviews

Returns resultset of messages that are reviews.

=cut

sub reviews {
    my $self = shift;
    return $self->messages->search( { 'message_type.name' => 'product_review' },
        { join => 'message_type' } );
}

1;
