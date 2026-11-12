package Mail::TLSRPT::Report;
# ABSTRACT: TLSRPT report object
our $VERSION = '2.20261112'; # VERSION
use 5.20.0;
use Moo;
use Mail::TLSRPT::Pragmas;
use Mail::TLSRPT::Policy;
use Mail::TLSRPT::Failure;
use DateTime;
use Date::Parse qw{ str2time };
use IO::Uncompress::Gunzip;
use Text::CSV;

use constant DEFAULT_MAX_SIZE => 10 * 1024 * 1024;
    has organization_name => (is => 'rw', isa => Str, required => 1);
    has start_datetime => (is => 'rw', isa => class_type('DateTime'), required => 1, coerce => sub{&_coerce_datetime});
    has end_datetime => (is => 'rw', isa => class_type('DateTime'), required => 1, coerce => sub{&_coerce_datetime});
    has contact_info => (is => 'rw', isa => Str, required => 0);
    has report_id => (is => 'rw', isa => Str, required => 1);
    has policies => (is => 'rw', isa => ArrayRef, required => 0, lazy => 1, builder => sub{return []} );

sub _coerce_datetime {
    my $time = shift;
    $time = DateTime->from_epoch( epoch=>$time ) unless ref $time eq 'DateTime';
    return $time;
}


sub new_from_json($class,$json,$args={}) {
    if ( $json =~ /^\037\213/ ) {
        return $class->new_from_json_gz($json,$args);
    }
    return $class->_new_from_json_string($json,$args);
}


sub new_from_json_gz($class,$compressed_json,$args={}) {
  # JSON that isn't gzipped is read as it is, as when gunzip passed it through
  return $class->_new_from_json_string($compressed_json,$args) unless $compressed_json =~ /^\037\213/;
  my $max_size = $args->{max_size} // DEFAULT_MAX_SIZE;
  # Not transparent, so whatever follows the last member is left unread
  # rather than added to the JSON
  my $gunzip = IO::Uncompress::Gunzip->new(\$compressed_json, Strict => 1, Transparent => 0)
    or croak "Could not gunzip report: $IO::Uncompress::Gunzip::GunzipError";
  my $json = '';
  while (1) {
    my $status = $gunzip->read(my $buffer, 65536);
    croak "Could not gunzip report: $IO::Uncompress::Gunzip::GunzipError" if $status < 0;
    if ( $status == 0 ) {
      my $next = $gunzip->nextStream;
      croak "Could not gunzip report: $IO::Uncompress::Gunzip::GunzipError" if $next < 0;
      last if $next == 0;
      next;
    }
    $json .= $buffer;
    croak "Report is larger than $max_size bytes when gunzipped" if length $json > $max_size;
  }
  # A gzip inside a gzip is not a report: say so, rather than fail as bad JSON
  croak 'Report is gzipped twice' if $json =~ /^\037\213/;
  return $class->_new_from_json_string($json,$args);
}

sub _new_from_json_string($class,$json,$args) {
    my $max_size = $args->{max_size} // DEFAULT_MAX_SIZE;
    croak "Report is larger than $max_size bytes" if length $json > $max_size;
    my $j = JSON->new->utf8;
    my $data = $j->decode($json);
    return $class->new_from_data($data);
}


sub new_from_data($class,$data) {
    croak 'Report is not an object' unless ref $data eq 'HASH';
    my $date_range = $data->{'date-range'} // {};
    croak 'date-range: not an object' unless ref $date_range eq 'HASH';
    my $policies = $data->{policies} // [];
    croak 'policies: not a list' unless ref $policies eq 'ARRAY';
    my @policies;
    foreach my $i ( keys $policies->@* ) {
        my $policy = eval { Mail::TLSRPT::Policy->new_from_data($policies->[$i]) };
        die "policies[$i]: $@" unless $policy;
        push @policies, $policy;
    }
    my $self = $class->new(
        organization_name => $data->{'organization-name'},
        start_datetime => DateTime->from_epoch(epoch => _parse_date($date_range->{'start-datetime'},'date-range.start-datetime')),
        end_datetime => DateTime->from_epoch(epoch => _parse_date($date_range->{'end-datetime'},'date-range.end-datetime')),
        $data->{'contact-info'} ? ( contact_info => $data->{'contact-info'} ) : (),
        report_id => $data->{'report-id'},
        policies => \@policies,
    );
    return $self;
}

# RFC 3339 section 5.6 date-time, with the lowercase t and z and the space
# for T that its notes allow. str2time alone would take "12:00" as today.
my $rfc3339_date_time = qr{\A\d{4}-\d\d-\d\d[Tt ]\d\d:\d\d:\d\d(?:\.\d+)?(?:[Zz]|[+-](?:[01]\d|2[0-3]):[0-5]\d)\z}a;

sub _parse_date($date,$name) {
    croak "$name: missing" unless defined $date;
    croak "$name: not a string" if ref $date;
    my $epoch = $date =~ $rfc3339_date_time ? str2time($date) : undef;
    croak "$name: could not parse date \"$date\"" unless defined $epoch;
    return $epoch;
}


sub as_json($self) {
    my $j = JSON->new->utf8;
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
        $self->contact_info ? ( 'contact-info' => $self->contact_info ) : (),
        'report-id' => $self->report_id,
        policies => \@policies,
    };
}


sub as_string($self) {
    return join( "\n",
        'Report-ID: <'.$self->report_id.'>',
        'From: "'.$self->organization_name.'"'.( $self->contact_info ? ' <'.$self->contact_info.'>' : '' ),
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
        $self->contact_info // '',
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

version 2.20261112

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

=head2 I<new_from_json($json,$args)>

Create a new object using a JSON string, this will create sub-objects as required.

The string should be UTF-8 encoded bytes, as received, rather than decoded characters.

Will detect and handle a gzipped string.

If the argument max_size is given then a report larger than that many bytes
of JSON will die, the default is 10MB. A gzipped report is limited by the size
of the JSON it decompresses to.

=head2 I<new_from_json_gz($json,$args)>

Create a new object using a gzipped JSON string, this will create sub-objects as required.

Takes the same max_size argument as new_from_json.

=head2 I<new_from_data($data)>

Create a new object using a data structure, this will create sub-objects as required.

=head1 METHODS

=head2 I<as_json>

Return the current object and sub-objects as a json string, UTF-8 encoded, as
it would be sent.

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

Jemma Bradshaw <jemma@nothingbutstatic.dev>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Jemma Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
