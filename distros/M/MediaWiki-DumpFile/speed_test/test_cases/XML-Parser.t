#!/usr/bin/env perl
use strict;
use warnings;
 
use XML::Parser;

use Bench;

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $self = Bench::ExpatHandler->new;

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