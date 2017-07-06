package Finance::GDAX::API::Report;
our $VERSION = '0.01';
use 5.20.0;
use warnings;
use Moose;
use Finance::GDAX::API::TypeConstraints;
use Finance::GDAX::API;
use namespace::autoclean;

extends 'Finance::GDAX::API';

has 'type' => (is  => 'rw',
	       isa => 'ReportType',
    );
has 'start_date' => (is  => 'rw',
		     isa => 'Str',
    );
has 'end_date' => (is  => 'rw',
		   isa => 'Str',
    );
has 'product_id' => (is  => 'rw',
		     isa => 'Str',
    );
has 'account_id' => (is  => 'rw',
		     isa => 'Str',
    );
has 'format' => (is  => 'rw',
		 isa => 'ReportFormat',
		 default => 'pdf',
    );
has 'email' => (is  => 'rw',
		isa => 'Str',
    );

# For checking with "get" method
has 'report_id' => (is  => 'rw',
		    isa => 'Str',
    );

sub get {
    my ($self, $report_id) = @_;
    $report_id = $report_id || $self->report_id;
    die 'no report_id specified to get' unless $report_id;
    $self->report_id($report_id);
    my $path = "/reports/$report_id";
    warn $path;
    $self->path($path);
    $self->method('GET');
    return $self->send;
}

sub create {
    my $self = shift;
    die 'report type is required' unless $self->type;
    die 'report start date is required' unless $self->start_date;
    die 'report end date is required' unless $self->end_date;
    my %body = ( type       => $self->type,
		 start_date => $self->start_date,
		 end_date   => $self->end_date,
		 format     => $self->format );
    if ($self->type eq 'fills') {
	die 'product_id is required for fills report' unless $self->product_id;
        $body{product_id} = $self->product_id;
    }
    if ($self->type eq 'account') {
	die 'account_id is required for account report' unless $self->account_id;
        $body{account_id} = $self->account_id;
    }
    $body{email} = $self->email if $self->email;
    $self->method('POST');
    $self->body(\%body);
    $self->path('/reports');
    return $self->send;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Finance::GDAX::API::Report - Generate GDAX Reports

=head1 SYNOPSIS

  use Finance::GDAX::API::Report;

  $report = Finance::GDAX::API::Report->new(
            start_date => '2017-06-01T00:00:00.000Z',
            end_date   => '2017-06-15T00:00:00.000Z',
            type       => 'fills');

  $report->product_id('BTC-USD');
  $result = $report->create;

  $report_id = $$result{id};

  # After you create the report, you check if it's generated yet

  $report = Finance::GDAX::API::Report->new;
  $result = $report->get($report_id);
  
  if ($$result{status} eq 'ready') {
     `wget $$result{file_url}`;
  }

=head2 DESCRIPTION

Generating reports at GDAX is a 2-step process. First you must tell
GDAX to create the report, then you must check to see if the report is
ready for download at a URL. You can also specify and email address to
have it mailed.

Reports can be "fills" or "account". If fills, then a product_id is
needed. If account then an account_id is needed.

The format can be "pdf" or "csv" and defaults to "pdf".

=head1 ATTRIBUTES

=head2 C<type> $string

Report type, either "fills" or "account". This must be set before
calling the "create" method.

=head2 C<start_date> $datetime_string

Start of datetime range of report in the format
"2014-11-01T00:00:00.000Z" (required for create)

=head2 C<end_date> $datetime_string

End of datetime range of report in the format
"2014-11-01T00:00:00.000Z" (required for create)

=head2 C<product_id> $string

The product ID, eg 'BTC-USD'. Required for fills type.

=head2 C<account_id> $string

The account ID. Required for account type.

=head2 C<format> $string

Output format of report, either "pdf" or "csv" (default "pdf")

=head2 C<email> $string

Email address to send the report to (optional)

=head2 C<report_id> $string

This is used for the "get" method only, and can also be passed as a
parameter to the "get" method.

It is the report id as returned by the "create" method.

=head1 METHODS

=head2 C<create>

Creates the GDAX report based upon the attributes set and returns a
hash result as documented in the API:

  {
    "id": "0428b97b-bec1-429e-a94c-59232926778d",
    "type": "fills",
    "status": "pending",
    "created_at": "2015-01-06T10:34:47.000Z",
    "completed_at": undefined,
    "expires_at": "2015-01-13T10:35:47.000Z",
    "file_url": undefined,
    "params": {
        "start_date": "2014-11-01T00:00:00.000Z",
        "end_date": "2014-11-30T23:59:59.000Z"
    }
  }

=head2 C<get> [$report_id]

Returns a hash representing the status of the report created with the
"create" method.

The parameter $report_id is optional - if it is passed to the method,
it overrides the object's report_id attribute.

The result when first creating the report might look like this:

  {
    "id": "0428b97b-bec1-429e-a94c-59232926778d",
    "type": "fills",
    "status": "creating",
    "created_at": "2015-01-06T10:34:47.000Z",
    "completed_at": undefined,
    "expires_at": "2015-01-13T10:35:47.000Z",
    "file_url": undefined,
    "params": {
        "start_date": "2014-11-01T00:00:00.000Z",
        "end_date": "2014-11-30T23:59:59.000Z"
    }
  }

While the result when GDAX finishes generating the report might look
like this:

  {
    "id": "0428b97b-bec1-429e-a94c-59232926778d",
    "type": "fills",
    "status": "ready",
    "created_at": "2015-01-06T10:34:47.000Z",
    "completed_at": "2015-01-06T10:35:47.000Z",
    "expires_at": "2015-01-13T10:35:47.000Z",
    "file_url": "https://example.com/0428b97b.../fills.pdf",
    "params": {
        "start_date": "2014-11-01T00:00:00.000Z",
        "end_date": "2014-11-30T23:59:59.000Z"
    }
  }

=cut


=head1 AUTHOR

Mark Rushing <mark@orbislumen.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Home Grown Systems, SPC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

