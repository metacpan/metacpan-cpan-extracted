package HTML::HTML5::Table::ColGroup;

use 5.010;
use namespace::autoclean;
use utf8;

BEGIN {
	$HTML::HTML5::Table::ColGroup::AUTHORITY = 'cpan:TOBYINK';
	$HTML::HTML5::Table::ColGroup::VERSION   = '0.004';
}

use Moose;

has node => (
	is        => 'rw',
	isa       => 'Maybe[XML::LibXML::Element]',
	default   => undef,
	);

has cols => (
	is        => 'rw',
	isa       => 'ArrayRef[HTML::HTML5::Table::Col]',
	default   => sub { [] },
	traits    => [qw/Array/],
	handles   => {
		push_col   => 'push',
		get_col    => 'get',
		count_cols => 'count',
		}
	);

after push_col => sub
{
	my ($self, $col) = @_;
	$col->group($self);
};

sub parse
{
	my ($self, $node) = @_;
	$self = $self->new unless ref $self;
	
	$self->node($node);
	
	foreach my $col ($node->getChildrenByTagName('col'))
	{
		$self->push_col(HTML::HTML5::Table::Col->parse($col));
	}
	
	$self;
}

1;