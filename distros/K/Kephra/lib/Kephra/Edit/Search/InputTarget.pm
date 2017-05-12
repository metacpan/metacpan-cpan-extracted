package Kephra::Edit::Search::InputTarget;
our $VERSION = '0.04';

use strict;
use base qw(Wx::TextDropTarget);
use Wx;
use Wx::DND;

sub new {
	my $class  = shift;
	my $target  = shift;
	my $kind  = shift;
	my $self = $class->SUPER::new(@_);
	$self->{target} = $target if substr(ref $target, 0, 12) eq 'Wx::ComboBox';
	$self->{kind} = $kind;
	return $self;
}

sub OnDropText {
	my ( $self, $x, $y, $text ) = @_;
	$self->{target}->SetValue( $text ) if $self->{target};
	$self->{kind} eq 'replace'
		? Kephra::Edit::Search::set_replace_item($text)
		: Kephra::Edit::Search::set_find_item($text);
	0; #don't skip event
}

1;