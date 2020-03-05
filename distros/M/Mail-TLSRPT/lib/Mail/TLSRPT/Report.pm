package Mail::TLSRPT::Report;
# ABSTRACT: TLSRPT report object
our $VERSION = '1.20200305.1'; # VERSION
use 5.20.0;
use Moo;
use Carp;
use Mail::TLSRPT::Pragmas;
use Mail::TLSRPT::Policy;
use DateTime;
use Date::Parse qw{ str2time };
    has organization_name => (is => 'rw', isa => Str, required => 1);
    has start_datetime => (is => 'rw', isa => class_type('DateTime'), required => 1);
    has end_datetime => (is => 'rw', isa => class_type('DateTime'), required => 1);
    has contact_info => (is => 'rw', isa => Str, required => 1);
    has report_id => (is => 'rw', isa => Str, required => 1);
    has policies => (is => 'rw', isa => ArrayRef, required => 0, lazy => 1, builder => sub{return []} );

sub new_from_json($class,$json) {
    my $j = JSON->new;
    my $data = $j->decode($json);
    return $class->new_from_data($data);
}

sub new_from_data($class,$data) {
    my @policies;
    foreach my $policy ( $data->{policies}->@* ) {
        push @policies, Mail::TLSRPT::Policy->new_from_data($policy);
    }
    my $self = $class->new(
        organization_name => $data->{'organization-name'},
        start_datetime => DateTime->from_epoch(epoch => str2time($data->{'date-range'}->{'start-datetime'})),
        end_datetime => DateTime->from_epoch(epoch => str2time($data->{'date-range'}->{'end-datetime'})),
        contact_info => $data->{'contact-info'},
        report_id => $data->{'report-id'},
        policies => \@policies,
    );
    return $self;
}

sub as_json($self) {
    my $j = JSON->new;
    $j->canonical;
    return $j->encode( $self->as_struct );
}

sub as_struct($self) {
    my @policies = map {$_->as_struct} $self->policies->@*;
    return {
        'organization-name' => $self->organization_name,
        'date-range' => {
            'start-datetime' => $self->start_datetime->datetime.'Z',
            'end-datetime' => $self->end_datetime->datetime.'Z',
        },
        'contact-info' => $self->contact_info,
        'report-id' => $self->report_id,
        scalar $self->policies->@* ? ( policies => \@policies ) : (),
    };
}

sub as_string($self) {
    return join( "\n",
        'Report-ID: <'.$self->report_id.'>',
        'From: "'.$self->organization_name.'" <'.$self->contact_info.'>',
        'Dates: '.$self->start_datetime->datetime.'Z to '.$self->end_datetime->datetime.'Z',
        map { $_->as_string } $self->policies->@*,
    );
}

1;

