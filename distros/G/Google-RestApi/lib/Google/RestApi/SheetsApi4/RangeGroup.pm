package Google::RestApi::SheetsApi4::RangeGroup;

# some private subroutines of Range are called from here,
# so think of RangeGroup as a friend of Range. the routines
# called are commented thusly:
# "private range routine called here!"

our $VERSION = '0.8';

use Google::RestApi::Setup;

use Carp qw(cluck confess);
use List::Util qw(first);
use Scalar::Util qw(looks_like_number);
use Storable qw(dclone);

use aliased 'Google::RestApi::SheetsApi4::RangeGroup::Iterator';

sub new {
  my $class = shift;

  state $check = compile_named(
    spreadsheet => HasMethods[qw(api)],
    ranges      => ArrayRef[HasMethods['range']], { default => [] },
  );

  return bless $check->(@_), $class;
}

sub push_ranges {
  my $self = shift;
  state $check = compile(slurpy ArrayRef[HasMethods['range']]);
  my ($ranges) = $check->(@_);
  push(@{ $self->{ranges} }, @$ranges);
  return;
}

sub clear {
  my $self = shift;

  $self->clear_cached_values();

  my @ranges = map { $_->range(); } $self->ranges();
  my %p = (
    content => { ranges => \@ranges },
    uri     => "/values:batchClear",
    method  => "post",
  );
  return $self->api(%p);
}

sub clear_cached_values {
  my $self = shift;
  $_->clear_cached_values() foreach $self->ranges();
  return;
}

sub refresh_values {
  my $self = shift;
  $self->clear_cached_values();
  return $self->values();
}

sub values {
  my $self = shift;

  state $check = compile_named(
    params  => HashRef, { default => {} },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  my @ranges = $self->ranges();
  my @needs_values = grep { !$_->has_values(); } @ranges;
  # for some reason google designed this so that you can set
  # various ranges in the params, but only one majorDimension
  # for the entire url. it's a bit strange since the return
  # values have a majorDimension in each range. all other parts
  # of their api treat range/majorDimension as a unit except for
  # batchGet. so we have to potentially do two calls for a
  # batch get, one for cols, and one for rows.
  my (@cols, @rows);
  foreach (@needs_values) {
    if ($_->dimension() =~ /^col/i) { push(@cols, $_); }
    else { push(@rows, $_); }
  }
  $self->_batch_get('col', dclone($p), \@cols);
  $self->_batch_get('row', dclone($p), \@rows);

  my @values = map { $_->values(); } @ranges;
  return \@values;
}

sub _batch_get {
  my $self = shift;

  my ($dim, $p, $ranges) = @_;
  return if !$ranges || !@$ranges;

  my @ranges = map { $_->range(); } @$ranges;
  $p->{params}->{ranges} = \@ranges;
  $p->{params}->{majorDimension} = 'COLUMNS' if $dim =~ /^col/i;
  $p->{uri} = "/values:batchGet";

  my $response = $self->api(%$p);

  my $value_ranges = $response->{valueRanges};
  # private range routine called here!
  my @ranges2 = map { $_->range(); } @$ranges;
  $ranges->[$_]->_cache_range_values(%{ $value_ranges->[$_] })
    foreach (0..$#$ranges);

  return;
}

sub batch_values {
  my $self = shift;

  state $check = compile_named(
    values  => ArrayRef, { optional => 1 },
  );
  my $p = $check->(@_);

  my $values = $p->{values};
  if (defined $values) {
    my @ranges = $self->ranges();
    LOGDIE "Too many values provided for range group" if scalar @$values > scalar @ranges;
    $ranges[$_]->batch_values(values => $values->[$_]) foreach (0..$#$values);
    return $self;
  }

  my @batch_values = map {
    $_->has_values() ? ($_->batch_values()) : ();
  } $self->ranges();

  return \@batch_values;
}

sub values_response_from_api {
  my $self = shift;
  state $check = compile(ArrayRef);
  my ($updates) = $check->(@_);
  my @updates = map {
    $_->has_values() ? ($_->values_response_from_api($updates)) : ();
  } $self->ranges();
  return \@updates;
}

sub submit_values {
  my $self = shift;
  $self->spreadsheet()->submit_values(ranges => [ $self ], @_);
  return $self->values();
}

sub batch_requests {
  my $self = shift;
  my @batch_requests = map {
    $_->batch_requests(@_);
  } $self->ranges();
  return @batch_requests;
}

sub submit_requests {
  my $self = shift;
  return $self->spreadsheet()->submit_requests(ranges => [ $self ], @_);
#  return $self;
}

sub requests_response_from_api {
  my $self = shift;
  state $check = compile(ArrayRef);
  my ($requests) = $check->(@_);
  my @requests = map {
    $_->requests_response_from_api($requests);
  } $self->ranges();
  return \@requests;
}

sub iterator {
  my $self = shift;
  return Iterator->new(@_, range_group => $self);
}

sub has_values {
  my $self = shift;
  return first { $_->has_values(); } $self->ranges();
}

# enables pass-throughs to the underlying ranges so you can go:
# $range_group->red()->bold() etc.
sub AUTOLOAD {
  our $AUTOLOAD;
  return if $AUTOLOAD =~ /DESTROY$/;
  return if $AUTOLOAD =~ /\0$/;   # wtf is this???

  my $self = shift;
  my $method = (split('::', $AUTOLOAD))[-1];
  $_->$method(@_) for $self->ranges();
  return $self;
}

sub ranges { @{ shift->{ranges} }; }
sub spreadsheet { shift->{spreadsheet}; }
sub api { shift->spreadsheet()->api(@_); }
sub sheets_api { shift->spreadsheet()->sheets_api(); }
sub rest_api { shift->sheets_api()->rest_api(); }
sub transaction { shift->rest_api()->transaction(); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::RangeGroup - Represents a group of ranges in a Worksheet.

=head1 DESCRIPTION

A RangeGroup is a lightweight object that represents a collection of ranges
on which you can operate as one unit (e.g. RangeGroup::submit_values
will submit all batch values for the underlying ranges).

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 SUBROUTINES

=over

=item new(spreadsheet => <Spreadsheet>, ranges => <arrayref<Range>>);

Creates a new range group object for the given spreadsheet.

 spreadsheet: The parent Spreadsheet object for this range group.
 ranges: The array of ranges to be grouped into this range group.

You would not normally call this directly, you'd use Spreadsheet::range_group
method to create the range group object for you.

=item api(%args);

Calls the parent spreadsheet's 'api' routine with the ranges added into
the URI or content appropriately.

You would not normally call this directly unless you were
making a Google API call not currently supported by this API
framework.

=item push_ranges(<arrayref<Range>>);

Adds the extra ranges to this range group. No attempt is made to
check for duplicate range objects.

=item clear();

Clears each range in the range group in one call using batchClear
Google API call.

=item values(%args);

Fetches the values of the spreadsheet for each range in the group. Note
that there is no way to set values with this method as it is assumed
that setting will be done via routine batch_values.

'args' are passed to the SheetsApi4's 'api' routine so you may add
extra arguments to the 'params' as necessary.

=item batch_values(values => <arrayref>);

Gets or sets the queued batch values for each range in the range group.
Batch values can be set on particular ranges individually, or can be
set with this routine all in one shot.

=item submit_values(%args);

Sends the previously queued batch values to Google API, if any.

'args' are passed to the SheetsApi4's 'api' routine so you may add
extra arguments to the 'params' or 'content' as necessary.

=item batch_requests();

Gets the queued batch requests for each range in the group.

=item submit_requests(%args);

Sends the previously queued requests (formatting, sheet properties etc)
to Google API, if any.

'args' are passed to the SheetsApi4's 'api' routine so you may add
extra arguments to the 'params' or 'content' as necessary.

=item iterator(%args);

Returns an iterator for this range group. Any 'args' are passed to the
'new' routine for the iterator.

=item has_values();

Returns a true value if any of the underlying ranges has values
associated with it.

=item ranges();

Returns the array of Range objects in this range group.

=item spreadsheet();

Returns the parent Spreadsheet object.

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
