package HTML::HTML5::Table::Section;

use 5.010;
use namespace::autoclean;
use utf8;

BEGIN {
	$HTML::HTML5::Table::Section::AUTHORITY = 'cpan:TOBYINK';
	$HTML::HTML5::Table::Section::VERSION   = '0.004';
}

use Moose;

has node => (
	is        => 'rw',
	isa       => 'Maybe[XML::LibXML::Element]',
	default   => undef,
	);

has rows => (
	is        => 'rw',
	isa       => 'ArrayRef[HTML::HTML5::Table::Row]',
	default   => sub { [] },
	traits    => [qw/Array/],
	handles   => {
		push_row   => 'push',
		get_row    => 'get',
		count_rows => 'count',
		}
	);

has table => (
	is        => 'rw',
	isa       => 'Maybe[HTML::HTML5::Table]',	
	default   => undef,
	weak_ref  => 1,
	);

after push_row => sub
{
	my ($self, $row) = @_;
	$row->section($self);
};

sub parse
{
	my ($self, $node, %attrs) = @_;
	$self = $self->new(%attrs) unless ref $self;

	$self->node($node);

	#warn "----\n";

	my $pos_col = my $pos_row = 0;
	foreach my $tr ($node->childNodes)
	{
		next unless $tr->nodeName eq 'tr';
		my $row = $self->get_row($pos_row);

		$row->node($tr);

		foreach my $td ($tr->childNodes)
		{
			next if $td->localname !~ /^t[dh]$/;
			
			while ($row->cells->[ $pos_col ]) # skip already occupied cells
			{
				$pos_col++;
			}
			
			my $cell = {
				td => 'HTML::HTML5::Table::Cell',
				th => 'HTML::HTML5::Table::HeadCell',
				}->{ $td->localname }->new(
					node    => $td,
					row     => $row,
					col     => $self->table->get_col($pos_col),
					);
			
			for (my $c = $pos_col; $c <= $pos_col + $cell->colspan - 1; $c++)
			{
				for (my $r = $pos_row; $r <= $pos_row + $cell->rowspan - 1; $r++)
				{
					die "double occupied cell at $r, $c" if $self->get_row($r)->cells->[ $c ];
					$self->get_row($r)->cells->[ $c ] = $cell;
					$self->table->get_col($c)->push_cell($cell);					
				}
				push @{ $cell->all_cols }, $self->table->get_col($c);
			}

			for (my $r = $pos_row; $r <= $pos_row + $cell->rowspan - 1; $r++)
			{
				push @{ $cell->all_rows }, $self->get_row($r);
			}

			$pos_col += $cell->colspan;
		}

		$pos_col = 0;
		$pos_row++;
	}
	
	$self;
}

sub ensure_row
{
	my ($self, $n) = @_;
	for (0 .. $n)
	{
		$self->rows->[$_] //= HTML::HTML5::Table::Row->new(section => $self);
	}
	$self;
}

before get_row => sub
{
	my ($self, $n) = @_;
	$self->ensure_row($n);
};


1;
