package Feed::Data::AlJazeera::Base;

use strict;
use warnings;

use Rope;
use Rope::Autoload;
use Feed::Data;

property url => (
	initable => 1,
	enumerable => 1,
	writeable => 1,
);

property feed => (
	initable => 1,
	enumerable => 1,
	writeable => 1,
	builder => sub {
		for my $key (qw/render all count delete get pop insert is_empty title link description rss_channel/) {
			$_[0]->{properties}->{$key} = {
				enumerable => 1,
				index => ++$_[0]->{keys},
				value => sub {
					my ($self, $param) = @_;
					$self->feed->$key($param)
				}
			};
		}
		Feed::Data->new();
	}
);

function parse => sub {
	my ($self) = @_;
	$self->feed->parse($self->url);
};

1;
