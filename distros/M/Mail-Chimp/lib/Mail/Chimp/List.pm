package Mail::Chimp::List;
use strict;
use warnings;
use Moose;
use MooseX::Types::DateTimeX qw(DateTime);
our $VERSION = '0.2.1';


has '_api'                         => (is => 'ro', isa => 'Mail::Chimp::API');
has 'id'                           => (is => 'ro', isa => 'Str');
has 'web_id'                       => (is => 'ro', isa => 'Int');
has 'name'                         => (is => 'ro', isa => 'Str');
has 'date_created'                 => (is => 'ro', isa => DateTime, coerce => 1);
has 'member_count'                 => (is => 'ro', isa => 'Int');
has 'unsubscribe_count'            => (is => 'ro', isa => 'Int');
has 'email_type_option'            => (is => 'ro', isa => 'Bool');
has 'default_from_name'            => (is => 'ro', isa => 'Str');
has 'default_from_email'           => (is => 'ro', isa => 'Str');
has 'default_subject'              => (is => 'ro', isa => 'Str');
has 'default_language'             => (is => 'ro', isa => 'Str');
has 'list_rating'                  => (is => 'ro', isa => 'Num');
has 'member_count_since_send'      => (is => 'ro', isa => 'Int');
has 'unsubscribe_since_send_count' => (is => 'ro', isa => 'Int');
has 'cleaned_count_since_send'     => (is => 'ro', isa => 'Int');


sub _call {
    my ( $self, $method, @args ) = @_;
    return $self->_api->_call( $method, $self->_api->apikey, $self->id, @args );
}

sub abuse_reports {
    my ( $self, $start, $limit, $since ) = @_;
    my $reports = $self->_call( 'listAbuseReports', $start, $limit, $since );
    return [ map { Mail::Chimp::AbuseReport->new( _api => $self->api, %$_) } @$reports ];
}

sub batch_subscribe {
    my ( $self, $batch, $double_optin, $update_existing, $replace_interests ) = @_;
    return $self->_call( 'listBatchSubscribe', $batch, $double_optin, $update_existing, $replace_interests );
}

sub batch_unsubscribe {
    my ( $self, $addresses, $delete_member, $send_goodbye, $send_notify ) = @_;
    return $self->_call( 'listBatchUnsubscribe', $addresses, $delete_member, $send_goodbye, $send_notify );
}

sub growth_history {
    my ( $self ) = @_;
    return $self->_call( 'listGrowthHistory' );
}

sub add_interest_group {
    my ( $self, $name ) = @_;
    return $self->_call( 'listInterestGroupAdd', $name );
}

sub delete_interest_group {
    my ( $self, $name ) = @_;
    return $self->_call( 'listInterestGroupDel', $name );
}

sub update_interest_group {
    my ( $self, $old_name, $new_name ) = @_;
    return $self->_call( 'listInterestGroupDel', $old_name, $new_name );
}

sub interest_groups {
    my ( $self ) = @_;
    return $self->_call( 'listInterestGroups' );
}

sub member_info {
    my ( $self, $email ) = @_;
    return $self->_call( 'listMemberInfo', $email );
}

sub members {
    my ( $self, $status, $since, $start, $limit ) = @_;
    return $self->_call( 'listMembers', $status, $since, $start, $limit );
}

sub add_merge_var {
    my ( $self, $name, $description, $options ) = @_;
    return $self->_call( 'listMergeVarAdd', uc $name, $description, $options );
}

sub delete_merge_var {
    my ( $self, $name ) = @_;
    return $self->_call( 'listMergeVarDel', uc $name );
}

sub update_merge_var {
    my ( $self, $name ) = @_;
    return $self->_call( 'listMergeVarUpdate', uc $name );
}

sub merge_vars {
    my ( $self ) = @_;
    return $self->_call( 'listMergeVars' );
}

sub subscribe_address {
    my ( $self, $email, $merge_vars ) = @_;
    $merge_vars ||= {};
    return $self->_call( 'listSubscribe', $email, $merge_vars );
}

sub unsubscribe_address {
    my ( $self, $email, $delete ) = @_;
    return $self->_call( 'listUnsubscribe', $email, $delete );
}

sub update_member {
    my ( $self, $email, $merge_vars, $email_type, $replace_interests ) = @_;
    $merge_vars ||= {};
    return $self->_call( 'listUpdateMember', $email, $merge_vars, $email_type, $replace_interests );
}

sub webhooks {
    my ( $self ) = @_;
    return $self->_call('listWebhooks' );
}

sub add_webhook {
    my ( $self, $url, $actions, $sources ) = @_;
    return $self->_call( 'listWebhookAdd', $url, $actions, $sources );
}

sub delete_webhook {
    my ( $self, $url, $actions, $sources ) = @_;
    return $self->_call( 'listWebhookDel', $url );
}

1;
