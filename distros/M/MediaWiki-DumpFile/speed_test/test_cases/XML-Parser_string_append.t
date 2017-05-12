#!/usr/bin/env perl
use strict;
use warnings;
 
use XML::Parser;

use Bench;

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $self = ExpatHandler->new;

my $parser = XML::Parser->new(Handlers => {
	Start => sub { $self->starthandler(@_) },
	End => sub { $self->endhandler(@_) },
	Char => sub { $self->char_handler(@_) },
});

if(scalar(@ARGV)) {
	$parser->parsefile(shift(@ARGV));
} else {
	$parser->parse(\*STDIN);
}

package ExpatHandler;

sub new {
	return(bless({ }, $_[0]));
}

sub starthandler {
	my ($self, $e, $element) = @_;
	
	if ($element eq 'title') {
		$self->char_on;
		$self->{in_title} = 1;
	} elsif ($element eq 'text') {
		$self->char_on;
		$self->{in_text} = 1;
	}	
}

sub endhandler {
	my ($self, $e, $element) = @_;
	
	if ($self->{in_text}) {
		$self->{text} = $self->get_chars;
		$self->char_off;
		$self->{in_text} = 0;
	} elsif ($self->{in_title}) {
		$self->{title} = $self->get_chars;
		$self->char_off;
		$self->{in_title} = 0;
	} elsif ($element eq 'revision') {
		Bench::Article($self->{title}, $self->{text});
	}
}

sub char_handler {
	my ($self, $e, $chars) = @_;
	
	if ($self->{char}) {
		$self->{a} .= $chars;
	}
}

sub char_on {
	my ($self) = @_;
	
	$self->{a} = undef;
	$self->{char} = 1;
}

sub char_off {
	my ($self) = @_;
	
	$self->{a} = undef;
	$self->{char} = 0;
}

sub get_chars {
	my ($self) = @_;
	
	return $self->{a};
}
