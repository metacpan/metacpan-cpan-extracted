package EWS::Calendar::Role::RetrieveAvailability;
BEGIN {
  $EWS::Calendar::Role::RetrieveWithinWindow::VERSION = '1.141040';
}
use Moose::Role;

sub retrieve_availability {
    my ($self, $opts) = @_;

    # GetUserAvailability docs:
    # http://msdn.microsoft.com/en-us/library/office/aa564001%28v=exchg.140%29.aspx
    my ($response, $trace) = $self->client->GetUserAvailability->(
        TimeZone => {
            Bias => 0,
            StandardTime => {
                Bias => 0,
                Time => '00:00:00',
                DayOrder => 0,
                Month => 0,
                DayOfWeek => 'Sunday',
            },
            DaylightTime => {
                Bias => 0,
                Time => '00:00:00',
                DayOrder => 0,
                Month => 0,
                DayOfWeek => 'Sunday',
            },
        },
        MailboxDataArray => {
            MailboxData => {
                Email => {
                    Address => $opts->{email},
                },
                AttendeeType => 'Required',
                ExcludeConflicts => 'false',
            },
        },
        FreeBusyViewOptions => {
            TimeWindow => {
                StartTime => $opts->{window}->start->iso8601,
                EndTime   => $opts->{window}->end->iso8601,
            },
            RequestedView => 'MergedOnly',
            MergedFreeBusyIntervalInMinutes => 15,
        },
    );

    if($response->{GetUserAvailabilityResult}
                ->{FreeBusyResponseArray}
                ->{FreeBusyResponse}->[0]
                ->{ResponseMessage}
                ->{ResponseClass} ne 'Success'){
        return $response->{GetUserAvailabilityResult}
                        ->{FreeBusyResponseArray}
                        ->{FreeBusyResponse}->[0]
                        ->{ResponseMessage}
                        ->{MessageText};
    }
    # MergedFreeBusy: http://msdn.microsoft.com/en-us/library/office/aa566048%28v=exchg.140%29.aspx
    my $merged = $response->{GetUserAvailabilityResult}
                          ->{FreeBusyResponseArray}
                          ->{FreeBusyResponse}->[0]
                          ->{FreeBusyView}
                          ->{MergedFreeBusy};

    # actual interface?
    return split('', $merged);
}

no Moose::Role;
1;
