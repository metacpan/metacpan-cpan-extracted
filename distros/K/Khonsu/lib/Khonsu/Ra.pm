package Khonsu::Ra;

use strict;
use warnings;

use Khonsu::Shape::Line;
use Khonsu::Shape::Box;
use Khonsu::Shape::Circle;
use Khonsu::Shape::Pie;
use Khonsu::Shape::Ellipse;

use Khonsu::Font;

use Khonsu::Text;
use Khonsu::Text::H1;
use Khonsu::Text::H2;
use Khonsu::Text::H3;
use Khonsu::Text::H4;
use Khonsu::Text::H5;
use Khonsu::Text::H6;

use Khonsu::Image;

use Khonsu::TOC;

use Types::Standard qw/Str Object ArrayRef HashRef Num Bool CodeRef/;

use constant RW => (is => 'rw');
use constant REQ => (required => 1);
use constant STR => (isa => Str);
use constant OBJ => (isa => Object);
use constant BOOL => (isa => Bool);
use constant AR => (isa => ArrayRef);
use constant HR => (isa => HashRef);
use constant DAR => (isa => ArrayRef, default => sub { [ ] });
use constant DHR => (isa => HashRef, default => sub { { } });
use constant NUM => (isa => Num);
use constant CODE => (isa => CodeRef);
use constant POINTS => (
	x => {is => 'rw', isa => Num},
	y => {is => 'rw', isa => Num},
	w => {is => 'rw', isa => Num},
	h => {is => 'rw', isa => Num},
);
use constant LINE => (
	line => {is => 'rw', isa => Object, default => sub { Khonsu::Shape::Line->new() }}
);
use constant BOX => (
	box => {is => 'rw', isa => Object, default => sub { Khonsu::Shape::Box->new() }}
);
use constant CIRCLE => (
	circle => {is => 'rw', isa => Object, default => sub { Khonsu::Shape::Circle->new() }}
);
use constant PIE => (
	pie => {is => 'rw', isa => Object, default => sub { Khonsu::Shape::Pie->new() }}
);
use constant ELLIPSE => (
	ellipse => {is => 'rw', isa => Object, default => sub { Khonsu::Shape::Ellipse->new() }}
);
use constant FONT => (
	font => {is => 'rw', isa => Object, default => sub { Khonsu::Font->new() }}
);
use constant TEXT => (
	text => {is => 'rw', isa => Object, default => sub { Khonsu::Text->new() }}
);
use constant H1 => (
	h1 => {is => 'rw', isa => Object, default => sub { Khonsu::Text::H1->new() }}
);
use constant H2 => (
	h2 => {is => 'rw', isa => Object, default => sub { Khonsu::Text::H2->new() }}
);
use constant H3 => (
	h3 => {is => 'rw', isa => Object, default => sub { Khonsu::Text::H3->new() }}
);
use constant H4 => (
	h4 => {is => 'rw', isa => Object, default => sub { Khonsu::Text::H4->new() }}
);
use constant H5 => (
	h5 => {is => 'rw', isa => Object, default => sub { Khonsu::Text::H5->new() }}
);
use constant H6 => (
	h6 => {is => 'rw', isa => Object, default => sub { Khonsu::Text::H6->new() }}
);
use constant IMAGE => (
	image => {is => 'rw', isa => Object, default => sub { Khonsu::Image->new() }}
);
use constant TOC => (
	toc => {is => 'rw', isa => Object, default => sub { Khonsu::TOC->new() }}
);
sub new {
	my ($pkg, %params) = @_;

	my $self = bless {
		attributes => {}
	}, $pkg;
	my @attributes = $self->attributes();
	for (my $i = 0; $i < $#attributes; $i += 2) {
		my ($key, $value) = ($attributes[$i], $attributes[$i + 1]);
		$self->{attributes}->{$key} = $value->{is} eq 'ro' ? sub { $_[0]->{$key}; } : sub {
			my ($self, $val) = @_;
			if (defined $val) {
				if ($value->{isa}) {
					$val = $value->{isa}->($val);
				}
				$self->{$key} = $val;
			}
			return $self->{$key};
		};

		if ($value->{required} && ! defined $params{$key}) {
			die "$key is required";
		}
	
		if ($value->{default} && !$params{$key}) {
			$params{$key} = $value->{default}->($self);
		}

		if (defined $params{$key}) {
			if ($value->{isa}) {
				$params{$key} = $value->{isa}->($params{$key});
			}
			$self->{$key} = $params{$key};
		}
	}
	
	return $self;
}

sub set_points {
	my ($self, $mx, $my, $mw, $mh) = @_;
	$self->x($mx);
	$self->y($my);
	$self->w($mw);
	$self->h($mh);
	return $self;
}

sub get_points {
	my ($self) = shift;
	return (
		x => $self->x,
		y => $self->y,
		w => $self->w,
		h => $self->h
	);
}

sub attributes { return (); }

sub set_attributes {
	my ($self, %params) = @_;
	for (keys %params) {
		next unless $self->{attributes}->{$_};
		$self->{attributes}->{$_}($self, $params{$_});
	}
	return $self;
}

sub DESTROY {}

sub AUTOLOAD {
        my $classname =  ref $_[0];
        my $validname = '[_a-zA-Z][\:a-zA-Z0-9_]*';
        our $AUTOLOAD =~ /^${classname}::($validname)$/;
        my $key = $1;
        die "illegal key name, must be of $validname form\n$AUTOLOAD" unless $key;
	if ( $_[0]->{attributes}->{$key} ) {
		$_[0]->{attributes}->{$key}->(@_);
	} else {
		die "illegal use of AUTOLOAD $classname -> $key -";
	}
}

1;
