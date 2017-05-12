package Log::Saftpresse::Plugin::LimitDay;

use Moose;

# ABSTRACT: plugin to skip messages not from today or yesterday
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::Plugin';

use Time::Piece;
use Time::Seconds;

has 'day' => ( is => 'rw', isa => 'Maybe[Str]' );

has 'now' => ( is => 'rw', isa => 'Time::Piece', lazy => 1,
	default => sub { Time::Piece->new },
);

has 'yesterday' => ( is => 'rw', isa => 'Time::Piece', lazy => 1,
	default => sub {
		return Time::Piece->new - ONE_DAY;
	},
);

sub is_yesterday {
	my ( $self, $time ) = @_;
	if( $self->yesterday->ymd eq $time->ymd ) {
		return( 1 );
	}
	return( 0 );
}

sub is_today {
	my ( $self, $time ) = @_;
	if( $self->now->ymd eq $time->ymd ) {
		return( 1 );
	}
	return( 0 );
}

sub process {
	my ( $self, $stash ) = @_;
	my $day = $self->day;
	my $time = $stash->{'time'};
	if( ! defined $time ) {
		return;
	}

	if( $day eq 'today' && ! $self->is_today($time) ) {
		return('next');
	} elsif( $day eq 'yesterday' && ! $self->is_yesterday($time) ) {
		return('next');
	}
	
	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::LimitDay - plugin to skip messages not from today or yesterday

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
