package HTML::HTML5::Table::Col;

use 5.010;
use namespace::autoclean;
use utf8;

BEGIN {
	$HTML::HTML5::Table::Col::AUTHORITY = 'cpan:TOBYINK';
	$HTML::HTML5::Table::Col::VERSION   = '0.004';
}

use List::Util qw/max/;
use Moose;
use POSIX qw/ceil/;

has node => (
	is        => 'rw',
	isa       => 'Maybe[XML::LibXML::Element]',
	default   => undef,
	);

has group => (
	is        => 'rw',
	isa       => 'Maybe[HTML::HTML5::Table::ColGroup]',
	default   => undef,
	weak_ref  => 1,
	);

has table => (
	is        => 'rw',
	isa       => 'Maybe[HTML::HTML5::Table]',	
	default   => undef,
	weak_ref  => 1,
	);

has width => (
	is        => 'ro',
	isa       => 'Num',
	lazy      => 1,
	builder   => '_build_width',
	clearer   => '_clear_width',
	);

has cells => (
	is        => 'rw',
	isa       => 'ArrayRef[HTML::HTML5::Table::Cell]',
	default   => sub { [] },
	traits    => [qw/Array/],
	handles   => {
		push_cell   => 'push',
		get_cell    => 'get',
		count_cells => 'count',
		}
	);

sub parse
{
	my ($class, $node) = @_;
	my $count = 1;
	$count = $node->getAttribute('span') if $node->hasAttribute('span');

	map { $class->new(node => $node) } 1..$count;
}

after push_cell => sub
{
	my ($self) = @_;
	$self->_clear_width;
};

sub _build_width
{
	my ($self) = @_;
	max map { $_->needs_width } @{ $self->cells };
}

1;