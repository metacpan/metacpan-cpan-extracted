package Mail::Chimp::API;
use strict;
use warnings;
use Moose;
use XMLRPC::Lite;
use Data::Dumper;

our $VERSION = '0.2.1';


has 'username'      => (is => 'ro', isa => 'Str');
has 'password'      => (is => 'ro', isa => 'Str');
has 'api'           => (is => 'rw', isa => 'XMLRPC::Lite');
has 'api_version'   => (is => 'ro', isa => 'Num', default => 1.2);
has 'api_url'       => (is => 'rw', isa => 'Str');
has 'apikey'        => (is => 'rw', isa => 'Str');
has 'use_secure'    => (is => 'ro', isa => 'Bool', default => 1);
has 'datacenter'    => (is => 'ro', isa => 'Str', default => 'us1');
has 'output_format' => (is => 'rw', isa => 'Str', default => 'json');


sub BUILD {
    my ( $self ) = @_;
    
    die 'apikey or username and password is required'
        unless ($self->apikey or ($self->username and $self->password));
    my $url = 'http';
    $url .= 's' if $self->use_secure();
    $url .= "://" . $self->datacenter() . ".api.mailchimp.com/" . $self->api_version() . '/';
    warn "# $url\n";
    $self->api_url( $url );
    $self->api( XMLRPC::Lite->proxy( $url ) );
    unless ($self->apikey) {
        $self->apikey( $self->_call( 'login', $self->username(), $self->password() ) );
    }
}

sub _call {
    my $self = shift;

    my $call = $self->api->call( @_ );
    return $call->result
        || confess( sprintf( "MailChimp Error %d: %s", $call->fault->{faultCode}, $call->fault->{faultString} ) );
}

sub all_lists {
    my ( $self ) = @_;

    my $lists = $self->_call( 'lists', $self->apikey );
    require Mail::Chimp::List;
    return [ map { Mail::Chimp::List->new( _api => $self, %$_ ) } @$lists ];
}

sub get_list {
    my ( $self, $id ) = @_;
    my $lists = $self->get_lists();
    return grep { $_->id() == $id or $_->name() eq $id } @$lists;
}


{
    no strict 'refs';
    sub _make_api_method { 
        my ($class, $method) = @_;
        *{"${class}::$method"} = sub { my $self = shift; $self->_call( $method, $self->apikey, @_ ) };
    }
}

my @api_methods = qw(
    campaignContent
    campaignCreate
    campaignDelete
    campaignEcommAddOrder
    campaignFolders
    campaignPause
    campaignReplicate
    campaignResume
    campaignSchedule
    campaignSegmentTest
    campaignSendNow
    campaignSendTest
    campaignTemplates
    campaignUnschedule
    campaignUpdate
    campaigns

    campaignAbuseReports
    campaignAdvice
    campaignAnalytics
    campaignBounceMessages
    campaignClickStats
    campaignEcommOrders
    campaignEepUrlStats
    campaignEmailDomainPerformance
    campaignGeoOpens
    campaignGeoOpensForCountry
    campaignHardBounces
    campaignSoftBounces
    campaignStats
    campaignUnsubscribes

    campaignClickDetailAIM
    campaignEmailStatsAIM
    campaignEmailStatsAIMAll
    campaignNotOpenedAIM
    campaignOpenedAIM

    chimpChatter
    createFolder
    exommAddOrder
    generateText
    getAccountDetails
    getAffiliateInfo
    inlineCss
    listsForEmail
    ping

    listAbuseReports
    listBatchSubscribe
    listBatchUnsubscribe
    listGrowthHistory
    listInterestGroupAdd
    listInterestGroupDel
    listInterestGroupUpdate
    listInterestGroups
    listMemberInfo
    listMembers
    listMergeVarAdd
    listMergeVarDel
    listMergeVarUpdate
    listMergeVars
    listSubscribe
    listUnsubscribe
    listUpdateMember
    listWebhookAdd
    listWebhookDel
    listWebhooks
    lists
    
    apikeyAdd
    apikeyExpire
    apikeys
);

__PACKAGE__->_make_api_method( $_ ) for @api_methods;

=head1 NAME

Mail::Chimp::API - Perl wrapper around the Mailchimp API

=head1 SYNOPSIS

  use strict;
  use Mail::Chimp::API;

  my $chimp = Mail::Chimp::API->new(apikey      => $apikey,
                                    api_version => 1.2);

  # or if you have no apikey setup:
  # my $chimp = Mail::Chimp::API->new(username    => $username,
  #                                   password    => $password,
  #                                   api_version => 1.1,
  #                                  );

  my $apikey      = $chimp->apikey;   # generated on first login if none was setup

  my $campaigns   = $chimp->campaigns;
  my $lists       = $chimp->lists;
  my $subscribers = $chimp->listMembers($lists->[0]->{id});

  print 'success' if $chimp->listSubscribe($lists->[0]->{id}, 'someone@somewhere.com', {}, 1);

=head1 DESCRIPTION

Mail::Chimp::API is a simple Perl wrapper around the MailChimp API.
The object exposes the MailChimp XML-RPC methods and confesses
fault codes/messages when errors occur.  Further, it keeps track of
your API key for you so you do not need to enter it each time.

Method parameters are passed straight through, in order, to MailChimp.
Thus, you do need to understand the MailChimp API as documented
at <http://api.mailchimp.com/> so that you will know the
appropriate parameters to pass to each method.

This API has been tested with version 1.0, 1.1 and 1.2 of the API.

=head1 NOTES

If you find yourself getting '-32602' errors, you are probably missing
a required (even if empty) hash.  The API documentation should be your
first destination to verify the validity of your parameters.  For
example:

  # MailChimp Error -32602: server error. invalid method parameters
  print 'fail'    if $chimp->listSubscribe($lists->[0]->{id}, 'someone@somewhere.com');
  
  # The {} is required by MailChimp to indicate that you do not want any MergeVars
  print 'success' if $chimp->listSubscribe($lists->[0]->{id}, 'someone@somewhere.com', {}, 1);


=head1 DEPENDENCIES

  Moose
  XMLRPC::Lite

=head1 SEE ALSO

  XMLRPC::Lite
  <http://www.mailchimp.com/api/1.2/>

=head1 COPYRIGHT

Copyright (C) 2009 Dave Pirotte.  All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Dave Pirotte (dpirotte@gmail.com)

Drew Taylor (drew@drewtaylor.com)

Ask Bjørn Hansen (ask@develooper.com)

=cut

1;
