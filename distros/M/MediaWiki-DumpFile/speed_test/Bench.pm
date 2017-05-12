package #go away cpan indexer! 
  Bench;

use strict;
use warnings;

our $hack;
our $profile;

sub Article {
	my ($title, $text) = @_;
	
	$title = '' unless defined $title;
	$text = '' unless defined $text;
	
	print "Title: $title\n";
	print "$text\n";
	
#	if (defined($ENV{PROFILE})) {
#		$profile++;
#		
#		exit 0 if $profile >= $ENV{PROFILE};
#	}
}

package Bench::ExpatHandler;

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
		push(@{ $self->{a} }, $chars);
	}
}

sub char_on {
	my ($self) = @_;
	
	$self->{a} = [];
	$self->{char} = 1;
}

sub char_off {
	my ($self) = @_;
	
	$self->{a} = [];
	$self->{char} = 0;
}

sub get_chars {
	my ($self) = @_;
	
	return join('', @{ $self->{a} });
}

package Bench::SAXHandler;

sub new {
	my ($class) = @_;
	
	return bless({}, $class);
}

sub start_element {
 	my ($self, $element) = @_;
 	
 	$element = $element->{Name};
	
	if ($element eq 'title') {
		$self->char_on;
		$self->{in_title} = 1;
	} elsif ($element eq 'text') {
		$self->char_on;
		$self->{in_text} = 1;
	}	
}

sub end_element {
	my ($self, $element) = @_;     
	
	$element = $element->{Name};   
	
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

sub characters {
	my ($self, $characters) = @_;
	
	if ($self->{char}) {
		push(@{ $self->{a} }, $characters->{Data});
	}
}

sub char_on {
	my ($self) = @_;
	
	$self->{a} = [];
	$self->{char} = 1;
}

sub char_off {
	my ($self) = @_;
	
	$self->{a} = [];
	$self->{char} = 0;
}

sub get_chars {
	my ($self) = @_;
	
	return join('', @{ $self->{a} });
}

package Bench::CompactTree;

use strict;
use warnings;

use XML::LibXML::Reader;

sub run {
	my ($reader, $tree_sub) = @_;

	$reader->nextElement('page');
	
	my $i = 0;
	
	while(++$i) {
		my $page = &$tree_sub($reader);
		my $p;
	
		last unless defined $page;	
		
		die "expected element" unless $page->[0] == XML_READER_TYPE_ELEMENT;
		die "expected <page>" unless $page->[1] eq 'page';
		
		my $title = $page->[4]->[1]->[4]->[0]->[1];
		my $text;
	
		foreach(@{$page->[4]}) {
			next unless $_->[0] == XML_READER_TYPE_ELEMENT;
			if ($_->[1] eq 'revision') {
				$p = $_->[4];
				last;
			}
		}
		
		foreach(@$p) {
			next unless $_->[0] == XML_READER_TYPE_ELEMENT;
			if ($_->[1] eq 'text') {
				$text = $_->[4]->[0]->[1];
				last;
			}
		}
		
		$text = '' unless defined $text;
		
		Bench::Article($title, $text);
	
		my $ret = $reader->nextElement('page');
		
		die "read error" if $ret == -1;
		last if $ret == 0;
		die "expected 1" unless $ret == 1;	
	}

}

1;