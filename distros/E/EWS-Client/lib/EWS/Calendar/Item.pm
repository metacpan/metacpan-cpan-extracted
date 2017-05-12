package EWS::Calendar::Item;
BEGIN {
  $EWS::Calendar::Item::VERSION = '1.143070';
}
use Moose;

use Moose::Util::TypeConstraints;
use DateTime::Format::ISO8601;
use DateTime;
use HTML::Strip;
use Encode;
use EWS::Calendar::Mailbox;

has Start => (
    is => 'ro',
    isa => 'DateTime',
    required => 1,
);

has End => (
    is => 'ro',
    isa => 'DateTime',
    required => 1,
);

has TimeSpan => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_TimeSpan {
    my $self = shift;
    # FIXME: plenty of edge cases we are not picking up on, yet

    if ($self->IsAllDayEvent) {
        if ($self->Start->day == ($self->End->day - 1)) {
            return sprintf '%s %s %s',
                $self->Start->day, $self->Start->month_abbr,
                $self->Start->year;
        }
        else {
            return sprintf '%s %s - %s, %s',
                $self->Start->month_abbr, $self->Start->day,
                ($self->End->day - 1), $self->Start->year;
        }
    }
    else {
        return sprintf '%s %s %s %s - %s',
            $self->Start->day, $self->Start->month_abbr,
            $self->Start->year, $self->Start->strftime('%H:%M'),
            $self->End->strftime('%H:%M');
    }
}

has Subject => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has Body => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    default => '',
);

sub has_Body { return length ((shift)->Body) }

has Location => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    default => '',
);

sub has_Location { return length ((shift)->Location) }

has CalendarItemType => (
    is => 'ro',
    isa => enum([qw/Single Occurrence Exception/]),
    required => 1,
);

sub Type { (shift)->CalendarItemType }

sub IsRecurring { return ((shift)->Type ne 'Single') }

has Sensitivity => (
    is => 'ro',
    isa => enum([qw/Normal Personal Private Confidential/]),
    required => 1,
);

has DisplayTo => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    required => 1,
);

sub has_DisplayTo { return scalar @{(shift)->DisplayTo} }

has Organizer => (
    is => 'ro',
    isa => 'EWS::Calendar::Mailbox',
    required => 1,
);

has IsCancelled => (
    is => 'ro',
    isa => 'Int', # bool
    lazy_build => 1,
);

sub _build_IsCancelled {
    my $self = shift;
    return ($self->AppointmentState & 0x0004);
}

has AppointmentState => (
    is => 'ro',
    isa => 'Str', # bool - Was 'Int' but failed type constraint on 2012-06-20
    required => 1,
);

has LegacyFreeBusyStatus => (
    is => 'ro',
    isa => 'Str',	# Was enum([qw/Free Tentative Busy OOF NoData/]),
    required => 0,
    default => 'NoData',
);

sub Status  { (shift)->LegacyFreeBusyStatus }

has IsDraft => (
    is => 'ro',
    isa => 'Int', # bool
    required => 1,
);

has IsAllDayEvent => (
    is => 'ro',
    isa => 'Int', # bool
    required => 0,
    default => 0,
);

has Sensitivity => (
    is => 'ro',
    isa => enum([qw/Normal Personal Private Confidential/]),
    required => 1,
);

has RequiredAttendees => (
    is => 'ro',
    isa => 'ArrayRef[EWS::Calendar::Mailbox]',
    required => 0,
);

has Duration => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has OptionalAttendees => (
    is => 'ro',
    isa => 'ArrayRef[EWS::Calendar::Mailbox]',
    required => 0,
);

has UID => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    default => '',
);

sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    # could coerce but this is always required, so do it here instead
    $params->{'Start'} = DateTime::Format::ISO8601->parse_datetime($params->{'Start'});
    $params->{'End'}   = DateTime::Format::ISO8601->parse_datetime($params->{'End'});

    # fish data out of deep structure
    $params->{'Organizer'} = EWS::Calendar::Mailbox->new($params->{'Organizer'}->{'Mailbox'});
    $params->{'OptionalAttendees'} = [ map { EWS::Calendar::Mailbox->new($_->{'Mailbox'}) }
					@{$params->{'OptionalAttendees'}->{Attendee}} ];
    $params->{'RequiredAttendees'} = [ map { EWS::Calendar::Mailbox->new($_->{'Mailbox'}) }
					@{$params->{'RequiredAttendees'}->{Attendee}} ];
    $params->{'Body'} = $params->{'Body'}->{'_'};

    # rework semicolon separated list into array, and also remove Organizer
    $params->{'DisplayTo'} = [ grep {$_ ne $params->{'Organizer'}->{'Name'}}
                                    split m/; /, $params->{'DisplayTo'} ];

    # set Perl's encoding flag on all data coming from Exchange
    # also strip HTML tags from incoming data
    my $hs = HTML::Strip->new(emit_spaces => 0);

    foreach my $key (keys %$params) {
        if ( $key =~ /RequiredAttendees|OptionalAttendees|IsDraft|IsAllDayEvent/ ) {
            next;
        }
        elsif (ref $params->{$key} eq 'ARRAY') {
            $params->{$key} = [
                map {$hs->parse($_)}
                map {Encode::encode('utf8', $_)}
                    @{ $params->{$key} }
            ];
        }
        elsif (ref $params->{$key}) {
            next;
        }
        else {
            $params->{$key} = $hs->parse(Encode::encode('utf8', $params->{$key}));
        }
    }

    # the Body is usually a mess if created by Outlook
    $params->{'Body'} =~ s/^\s+//;
    $params->{'Body'} =~ s/\s+$//;
    $params->{'Body'} =~ s/\n{3,}/\n\n/g;
    $params->{'Body'} =~ s/ {2,}/ /g;

    return $params;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
