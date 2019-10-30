package Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator;

use strict;
use warnings;

our $VERSION = '0.2';

use 5.010_000;

use autodie;
use Carp qw(cluck);
use Type::Params qw(compile_named);
use Types::Standard qw(Int HashRef Any slurpy);
use Google::RestApi::Utils qw(named_extra);
use YAML::Any qw(Dump);

no autovivification;

use parent qw(Google::RestApi::SheetsApi4::RangeGroup::Iterator);

do 'Google/RestApi/logger_init.pl';

sub new {
  my $class = shift;
  state $check = compile_named(
    tied    => HashRef,
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  my $ptied = delete $p->{tied};
  my $tied = tied(%$ptied);
  my $ranges = $tied->ranges();
  my $range_group = $tied->spreadsheet()->range_group(values %$ranges);

  my $self = $class->SUPER::new(
    %$p,
    range_group => $range_group,
  );
  $self->{keys} = [ keys %$ranges ];
  $self->{tied} = $ptied;

  return bless $self, $class;
}

sub iterate {
  my $self = shift;
  my $iterate = $self->SUPER::iterate(@_) or return;
  my @ranges = $iterate->ranges();
  my %ranges = map {
    $self->{keys}->[$_] => $ranges[$_];
  } (0..$#ranges);
  return $self->spreadsheet()->tie(%ranges);
}
sub next { iterate(@_); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator - An iterator for tied Ranges.

=head1 DESCRIPTION

A RangeGroup::Tie::Iterator is used to iterate through a tied range group,
returning a tied range group of cells, one group at a time.

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 SUBROUTINES

=over

=item new(tied => <hashref>, %args);

Creates a new Iterator object for the given tied range group.

 tied: A hashref tied to the RangeGroup::Tie object.

'args' are passed through to the parent RangeGroup::Iterator::new
object's routine.

You would not normally call this directly, you'd use the RangeGroup::Tie::iterator
method to create the iterator object for you.

=item iterate();

Return the next group of tied cells in the iteration sequence.

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
