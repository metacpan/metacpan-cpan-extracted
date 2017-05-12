package Microsoft::AdCenter::Retry;
# Copyright (C) 2010 Andre Paterlini Oliveira Vieira
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Class::Accessor::Chained Exporter Microsoft::AdCenter/;

our @EXPORT_OK = qw/CALL_RATE_EXCEEDED CONNECTION_ERROR INTERNAL_SERVER_ERROR/;
our %EXPORT_TAGS = (
    ErrorTypes => [qw/CALL_RATE_EXCEEDED CONNECTION_ERROR INTERNAL_SERVER_ERROR/]
);

=head1 NAME

Microsoft::AdCenter::Retry - Defines when and how to retry a failed API call.

=cut

=head1 SYNOPSIS

    my $retry = Microsoft::AdCenter::Retry->new(
        ErrorType => Microsoft::AdCenter::Retry->CONNECTION_ERROR | Microsoft::AdCenter::Retry->INTERNAL_SERVER_ERROR,
        RetryTimes => 3,
        WaitTime => 30,
        ScalingWaitTime => 2,
        Callback => sub { my $e = shift; warn "Successfully retried API call for " . __PACKAGE__ . " after error $e was caught"; },
    );

    my $service_client = Microsoft::AdCenter::V7::CampaignManagementService->new
        ->ApplicationToken("application token")
        ->CustomerAccountId("customer account id")
        ->CustomerId("customer id")
        ->DeveloperToken("developer token")
        ->Password("password")
        ->UserName("user name")
        ->RetrySettings([ $retry ]);


=head1 METHODS

=head2 ErrorType

Returns / sets the error type you want to retry upon. Can either be CONNECTION_ERROR or INTERNAL_SERVER_ERROR or a combination of the two

=head2 RetryTimes

Returns / sets the number of times you want to retry the API call

=head2 WaitTime

Returns / sets the time to wait between retries, in seconds

=head2 ScalingWaitTime

Returns / sets an optional interval that, will increase the wait time by the interval at each retry. From the above example:
30 seconds on the first try, 60 on the second, 90 on the third, and so on.

=head2 Callback

Returns / sets an optional callback sub that will be called upon every retry

=cut

use constant CONNECTION_ERROR => 0x01;
use constant INTERNAL_SERVER_ERROR => 0x02;
use constant CALL_RATE_EXCEEDED => 0x04;

sub new {
    my ($pkg, %args) = @_;
    my $self = bless {}, $pkg;
    foreach my $k (keys %args) {
        if ($self->can($k)) {
            $self->$k($args{$k});
        }
    }
    return $self;
}

sub match {
    my ($self, $error) = @_;

    if (ref($error) eq 'Microsoft::AdCenter::SOAPFault') {
        my %error_codes;
        if (defined $error->detail) {
            _get_error_codes_from_fault_object(\%error_codes, $error->detail);
            if ($self->ErrorType & INTERNAL_SERVER_ERROR && exists $error_codes{'0'}) {
                return 1;
            }
            if ($self->ErrorType & CALL_RATE_EXCEEDED && exists $error_codes{'117'}) {
                return 1;
            }
        }
    }
    else {
        if ($self->ErrorType & CONNECTION_ERROR && $error =~ /^(500 SSL negotiation failed|500 Can't connect|500 read failed|500 write failed)/) {
            return 1;
        }
    }

    return 0;
}

sub _get_error_codes_from_fault_object {
    my ($results, $error) = @_;
    _get_error_codes_from_error_object($results, $error->Errors) if ($error->can('Errors'));
    _get_error_codes_from_error_object($results, $error->BatchErrors) if ($error->can('BatchErrors'));
    _get_error_codes_from_error_object($results, $error->EditorialErrors) if ($error->can('EditorialErrors'));
    _get_error_codes_from_error_object($results, $error->OperationErrors) if ($error->can('OperationErrors'));
    if ($error->can('GoalErrors') && (defined $error->GoalErrors)) {
        foreach my $e (@{$error->GoalErrors}) {
            _get_error_codes_from_fault_object($results, $e);
        }
    }
}

sub _get_error_codes_from_error_object {
    my ($results, $errors) = @_;
    return unless (defined $errors);
    foreach my $error (@$errors) {
        if ($error->can('Code')) {
            $results->{$error->Code} = 1;
        }
    }
}

__PACKAGE__->mk_accessors(qw/ErrorType RetryTimes WaitTime ScalingWaitTime Callback/);

1;
