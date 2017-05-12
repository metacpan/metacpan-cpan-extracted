package Elive::Entity::User;
use warnings; use strict;

use Mouse;
use Mouse::Util::TypeConstraints;

extends 'Elive::Entity';

use Elive::Entity::Role;
use Elive::Util;

__PACKAGE__->entity_name('User');
__PACKAGE__->collection_name('Users');

has 'userId' => (is => 'rw', isa => 'Str', required => 1,
		 documentation => 'user identifier (numeric, unless LDAP configured)');
__PACKAGE__->primary_key('userId');
__PACKAGE__->params(userName => 'Str');

has 'deleted' => (is => 'rw', isa => 'Bool');

has 'loginPassword' => (is => 'rw', isa => 'Str');

has 'loginName' => (is => 'rw', isa => 'Str',
		    documentation => 'login name - must be unique');
		    
has 'email' => (is => 'rw', isa => 'Str',
		documentation => 'users email address');

has 'role' => (is => 'rw', isa => 'Elive::Entity::Role',
	       documentation => 'default user role',
	       coerce => 1);

has 'firstName' => (is => 'rw', isa => 'Str', 
		    documentation => 'users given name');

has 'lastName' => (is => 'rw', isa => 'Str',
		   documentation => 'users surname');

#
# 'groups' and 'domain' propreties made a brief appearence in Elm 9.5.0
# but haven't survived past 9.5.2. Will cull these shortly.
#

has 'groups' => (is => 'rw', isa => 'Any',
		documentation => 'groups that this user belongs to?');

has 'domain' => (is => 'rw', isa => 'Any',
		documentation => 'groups that this user belongs to?');

sub BUILDARGS {
    my $class = shift;
    my $spec = shift;

    my %args;
    if (defined $spec && ! ref $spec) {
	%args = (userId => $spec);
    }
    else {
	%args = %$spec;
    }

    return \%args;
}

coerce 'Elive::Entity::User' => from 'HashRef|Str'
    => via {Elive::Entity::User->new($_)};

=head1 NAME

Elive::Entity::User - Elluminate Users entity class

=cut

=head1 DESCRIPTION

This class is used to query and maintain information on registered Elluminate I<Live!> users.

=cut

=head1 METHODS

=cut

sub _readback_check {
    my ($class, $update_ref, $rows, @args) = @_;

    my %updates = %$update_ref;

    #
    # password not included in readback record - skip it
    #

    delete $updates{loginPassword};

    #
    # retrieve can accept either a userId or loginName
    #
    delete $updates{userId}
    if ($updates{userId} && @$rows
	&& exists $rows->[0]{loginName}
	&& $updates{userId} eq $rows->[0]{loginName});

    return $class->SUPER::_readback_check(\%updates, $rows, @args, case_insensitive => 1);
}

=head2 get_by_loginName

    my $user = Elive::Entity::User->get_by_loginName('joebloggs');

Retrieve on loginName, which is a co-key for the users table.

Please note that the Elluminate Web Services raise an error if the user
was not found. So, if you're not sure if the user exists:

    use Try::Tiny;
    my $user = try {Elive::Entity::User->get_by_loginName('joebloggs')};

=cut

sub get_by_loginName {
    my ($class, $loginName, @args) = @_;
    #
    # The entity name is loginName, but the fetch key is userName.
    #
    my $results = $class->_fetch({userName => $loginName},
				 @args,
	);

    return @$results && $results->[0];
}

=head2 insert

    my $new _user = Elive::Entity::User->insert({
	      loginName => ...,
	      loginPassword => ...,
	      firstName => ...,
	      lastName => ...,
	      email => ...,
	      role => ${Elive::Entity::Role::PARTICIPANT},
	    )};

Insert a new user

=cut

sub _safety_check {
    my ($self, %opt) = @_;

    unless ($opt{force}) {

	my $connection = $opt{connection} || $self->connection
	    or die "Not connected";

	die "Cowardly refusing to update login user"
	    if $self->userId eq $connection->login->userId;

	die "Cowardly refusing to update system admin account for ".$self->loginName.": (pass force => 1 to override)"
	    if ($self->_db_data->role->stringify <= ${Elive::Entity::Role::SYSTEM_ADMIN});
    }
}

=head2 update

    my $user_obj = Elive::Entity::user->retrieve($user_id);

    $user_obj->update(role => ${Elive::Entity::Role::SYSTEM_ADMIN}); # upgrade to an app admin
    $user_obj->lastName('Smith');
    $user_obj->update(undef, force => 1);

Update an Elluminate user. Everything can be changed, other than userId.
This includes the loginName. However loginNames must all remain unique.

As a safeguard, you'll need to pass C<force =E<gt> 1> to update:
    (a) users with a Role Id of 0, i.e. system administrator accounts, or
    (b) the login user

=cut

sub update {
    my ($self, $data_href, %opt) = @_;

    $self->_safety_check(%opt);
    return $self->SUPER::update( $data_href, %opt);
}

=head2 change_password

Implements the C<changePassword> SDK method.

    my $user = Elive::Entity::User->retrieve($user_id);
    $user->change_password($new_password);

This is equivalent to:

    my $user = Elive::Entity::User->retrieve($user_id);
    $user->update({loginPassword => $new_password});    

=cut

sub change_password {
    my ($self, $new_password, %opt) = @_;

    if (defined $new_password && $new_password ne '') {
	$self->_safety_check(%opt);
	$self->SUPER::update({loginPassword => $new_password},
			     command => 'changePassword',
			     %opt,
	    )
    }

    return $self;
}

=head2 delete

    $user_obj->delete();
    $admin_user_obj->delete(force => 1);

Delete user objects. As a safeguard, you need to pass C<force =E<gt> 1> to delete
system administrator accounts, or the login user.

Note that a deleted user, will have its deleted property immediately set,
but may remain accessible for a short period of time until garbage collected.

So to check for a deleted user:

    my $user = Elive::Entity::User->retrieve( $user_id ); 
    my $user_is_deleted = !$user || $user->deleted;

=cut

sub delete {
    my ($self, %opt) = @_;

    $self->_safety_check(%opt);

    return $self->SUPER::delete( %opt );
}

=head1 RESTRICTIONS

Elluminate I<Live!> can be configured to use LDAP for user management and
authentication.

If LDAP is in use, the fetch and retrieve methods will continue to operate
via the Elluminate SOAP command layer. User access becomes read-only.
The affected methods are: C<insert>, C<update>, C<delete> and C<change_password>.

=cut

1;
