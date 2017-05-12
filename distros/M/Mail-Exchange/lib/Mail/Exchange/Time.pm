package Mail::Exchange::Time;

=head1 NAME

Mail::Exchange::Time - time object to convert between unix time and MS time

=head1 SYNOPSIS

    use Mail::Exchange::Time;
    my $now=Mail::Exchange::Time->new($unixtime);
    my $now=Mail::Exchange::Time->from_mstime($mstime);

    print $now->unixtime;
    print $now->mstime;


    use Mail::Exchange::Time qw(mstime_to_unixtime unixtime_to_mstime);

    print mstime_to_unixtime($mstime);
    print unixtime_to_mstime($unixtime);

=head1 DESCRIPTION

A Mail::Exchange::Time object allows you to convert between unix time
and the time used internally in by Microsoft, which is defined as number
of 100-nsec-intervals since Jan 01, 1901.

=cut

use strict;
use warnings;
use 5.008;

use Exporter;
use vars qw ($VERSION @ISA @EXPORT_OK);
@ISA=qw(Exporter);
@EXPORT_OK=qw(mstime_to_unixtime unixtime_to_mstime);
$VERSION=0.03;


=head2 new()

$now=Mail::Exchange::Time->new(time())

Creates a time object from unix time.

=cut

sub new {
	my $class=shift;
	my $time=shift;

	my $self={
		unixtime => $time,
		mstime   => unixtime_to_mstime($time),
	};
	bless $self;
}

=head2 from_mstime()

$now=Mail::Exchange::Time->from_mstime(129918359788540682)

Creates a time object from unix time.

=cut

sub from_mstime {
	my $class=shift;
	my $time=shift;

	my $self={
		mstime   => $time,
		unixtime => mstime_to_unixtime($time),
	};
	bless $self;
}

=head2 unixtime()

$unixtime=$now->unixtime()

Returns the unix time from a time object.

=cut

sub unixtime () { my $self=shift; return $self->{unixtime}; }

=head2 mstime()

$mstime=$now->mstime()

Returns the Microsoft time from a time object.

=cut

sub mstime () { my $self=shift; return $self->{mstime}; }

=head2 mstime_to_unixtime()

    use Mail::Exchange::Time qw(mstime_to_unixtime)
    $unixtime=mstime_to_unixtime(129918359788540682)

Converts a microsoft time to unix format.

=cut

sub mstime_to_unixtime {
	my $mstime=shift;

	return ($mstime - 116_444_736_000_000_000)/10_000_000;
}

=head2 unixtime_to_mstime()

    use Mail::Exchange::Time qw(unixtime_to_mstime)
    $mstime=unixtime_to_mstime(time())

Converts a unix time to microsoft format.

=cut

sub unixtime_to_mstime{
	my $unixtime=shift;

	return $unixtime * 10_000_000 + 116_444_736_000_000_000;
}
