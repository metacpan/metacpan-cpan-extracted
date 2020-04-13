package Mail::TLSRPT::Report;
# ABSTRACT: TLSRPT report object
our $VERSION = '1.20200413.1'; # VERSION
use 5.20.0;
use Moo;
use Mail::TLSRPT::Pragmas;
use Mail::TLSRPT::Policy;
use Mail::TLSRPT::Failure;
use DateTime;
use Date::Parse qw{ str2time };
use IO::Uncompress::Gunzip;
use Text::CSV;
    has organization_name => (is => 'rw', isa => Str, required => 1);
    has start_datetime => (is => 'rw', isa => class_type('DateTime'), required => 1, coerce => sub{&_coerce_datetime});
    has end_datetime => (is => 'rw', isa => class_type('DateTime'), required => 1, coerce => sub{&_coerce_datetime});
    has contact_info => (is => 'rw', isa => Str, required => 1);
    has report_id => (is => 'rw', isa => Str, required => 1);
    has policies => (is => 'rw', isa => ArrayRef, required => 0, lazy => 1, builder => sub{return []} );

sub _coerce_datetime {
    my $time = shift;
    $time = DateTime->from_epoch( epoch=>$time ) unless ref $time eq 'DateTime';
    return $time;
}


sub new_from_json($class,$json) {
    if ( $json =~ /^\037\213/ ) {
        return $class->new_from_json_gz($json);
    }
    my $j = JSON->new;
    my $data = $j->decode($json);
    return $class->new_from_data($data);
}


sub new_from_json_gz($class,$compressed_json) {
  my $json;
  IO::Uncompress::Gunzip::gunzip(\$compressed_json,\$json);
  return $class->new_from_json($json);
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

sub _register_prometheus($self,$prometheus) {
    $prometheus->declare('tlsrpt_reports_processed_total', help=>'TLSRPT reports processed', type=>'counter' );
}


sub process_prometheus($self,$prometheus) {
    $self->_register_prometheus($prometheus);
    $prometheus->add('tlsrpt_reports_processed_total',1,{
        organization_name=>$self->organization_name,
        policies=>scalar $self->policies->@*,
    });
    Mail::TLSRPT::Policy->_register_prometheus($prometheus) if ! scalar $self->policies->@*;
    Mail::TLSRPT::Failure->_register_prometheus($prometheus) if ! scalar $self->policies->@*;
    foreach my $policy ( $self->policies->@* ) {
        $policy->process_prometheus($self,$prometheus);
    }
}

sub _csv_headers($self) {
    return (
        'report id',
        'organization name',
        'start date time',
        'end date time',
        'contact info',
    );
}

sub _csv_fragment($self) {
    return (
        $self->report_id,
        $self->organization_name,
        $self->start_datetime->datetime.'Z',
        $self->end_datetime->datetime.'Z',
        $self->contact_info,
    );
}


sub as_csv($self,$args) {
    my @output;
    my $csv = Text::CSV->new;
    if ( $args->{add_header} ) {
      $csv->combine($self->_csv_headers,Mail::TLSRPT::Policy->_csv_headers,Mail::TLSRPT::Failure->_csv_headers);
      push @output, $csv->string;
    }
    if ( scalar $self->policies->@* ) {
        foreach my $policy ( $self->policies->@* ) {
            if ( scalar $policy->failures->@* ) {
                foreach my $failure ( $policy->failures->@* ) {
                    $csv->combine($self->_csv_fragment,$policy->_csv_fragment,$failure->_csv_fragment);
                    push @output, $csv->string;
                }
            }
            else {
                $csv->combine($self->_csv_fragment,$policy->_csv_fragment);
                push @output, $csv->string;
            }
        }
    }
    else {
        $csv->combine($self->_csv_fragment);
        push @output, $csv->string;
    }
    return join( "\n", @output );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::TLSRPT::Report - TLSRPT report object

=head1 VERSION

version 1.20200413.1

=head1 SYNOPSIS

my $report = Mail::TLSRPT::Report->new(
    organization_name => 'My Corp',
    start_datetime => $date,
    end_datetime => $enddate,
    contact_info => 'reports@example.com',
    report_id => '123abc',
    policies => $policies,
};

=head1 DESCRIPTION

Classes to process tlsrpt report

=head1 CONSTRUCTOR

=head2 I<new($class)>

Create a new object

=head2 I<new_from_json($json)>

Create a new object using a JSON string, this will create sub-objects as required.

Will detect and handle a gzipped string.

=head2 I<new_from_json_gz($json)>

Create a new object using a gzipped JSON string, this will create sub-objects as required.

=head2 I<new_from_data($data)>

Create a new object using a data structure, this will create sub-objects as required.

=head1 METHODS

=head2 I<as_json>

Return the current object and sub-objects as a json string

=head2 I<as_struct>

Return the current object and sub-objects as a data structure

=head2 I<as_string>

Return a textual human readable representation of the current object and its sub-objects

=head2 I<process_prometheus($prometheus)>

Generate metrics using the given Prometheus::Tiny object

=head2 I<as_csv($args)>

Return a csv representation of the current object and its sub-objects

If the argument add_header is true then a csv header will be included in the output.

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
