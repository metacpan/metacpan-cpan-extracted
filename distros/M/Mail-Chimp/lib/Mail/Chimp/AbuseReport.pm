package Mail::Chimp::AbuseReport;
use strict;
use warnings;
use Moose;
use MooseX::Types::DateTimeX qw(DateTime);
our $VERSION = '0.2.1';

has 'date'        => (is => 'ro', isa => DateTime, coerce => 1);
has 'email'       => (is => 'ro', isa => 'Str');
has 'campaign_id' => (is => 'ro', isa => 'Int');
has 'type'        => (is => 'ro', isa => 'Str');

1;
