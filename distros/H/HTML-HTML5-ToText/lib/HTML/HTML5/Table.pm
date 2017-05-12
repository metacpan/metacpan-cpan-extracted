package HTML::HTML5::Table;

use 5.010;
use namespace::autoclean;
use utf8;

BEGIN {
	$HTML::HTML5::Table::AUTHORITY = 'cpan:TOBYINK';
	$HTML::HTML5::Table::VERSION   = '0.004';
}

use HTML::HTML5::ToText;
use HTML::HTML5::Table::Section;
use HTML::HTML5::Table::Head;
use HTML::HTML5::Table::Foot;
use HTML::HTML5::Table::Body;
use HTML::HTML5::Table::Row;
use HTML::HTML5::Table::Col;
use HTML::HTML5::Table::ColGroup;
use HTML::HTML5::Table::Head;
use HTML::HTML5::Table::HeadCell;
use Moose;
use Text::Wrap qw/wrap/;

has node => (
	is        => 'rw',
	isa       => 'Maybe[XML::LibXML::Element]',
	default   => undef,
	);

has caption => (
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

has sections => (
	is        => 'rw',
	isa       => 'ArrayRef[HTML::HTML5::Table::Section]',
	default   => sub { [] },
	traits    => [qw/Array/],
	handles   => {
		push_section   => 'push',
		get_section    => 'get',
		count_sections => 'count',		
		}
	);

sub ensure_col
{
	my ($self, $n) = @_;
	for (0 .. $n)
	{
		$self->cols->[$_] //= HTML::HTML5::Table::Col->new(table => $self);
	}
	$self;
}

after push_section => sub
{
	my ($self, $section) = @_;
	$section->table($self);
};

after push_col => sub
{
	my ($self, $col) = @_;
	$col->table($self);
};

before get_col => sub
{
	my ($self, $n) = @_;
	$self->ensure_col($n);
};

sub parse
{
	my ($self, $node) = @_;
	$self = $self->new unless ref $self;
	
	$self->node($node);
	
	foreach my $kid ($node->childNodes)
	{
		if ($kid->nodeName eq 'caption')
		{
			$self->caption($kid);
		}
		elsif ($kid->nodeName eq 'col')
		{
			$self->push_col( HTML::HTML5::Table::Col->parse($kid) )
		}
		elsif ($kid->nodeName eq 'colgroup')
		{
			$self->push_col( @{ HTML::HTML5::Table::ColGroup->parse($kid)->cols } )
		}
		elsif (my $class = {
			thead   => 'HTML::HTML5::Table::Head',
			tfoot   => 'HTML::HTML5::Table::Foot',
			tbody   => 'HTML::HTML5::Table::Body',
			}->{ $kid->nodeName })
		{
			$self->push_section( $class->parse($kid, table => $self) );
		}
	}
	
	$self;
}

sub to_text
{
	my ($self, $tt) = @_;
	$tt //= HTML::HTML5::ToText->new;
	
	foreach my $section (@{$self->sections})
	{
		foreach my $row (@{$section->rows})
		{
			foreach my $cell (@{$row->cells})
			{
				$cell->calculate_celltext($tt);
			}
		}
	}
	
	my $total_width = 0;
	foreach my $col (@{ $self->cols })
	{
		$total_width += $col->width + 3;
	}
	$total_width -= 1;
	
	my $return = ("=" x $total_width) . "\n";
	
	if ($self->caption)
	{
		local $Text::Wrap::columns = $total_width;
		my $caption_text = $tt->process($self->caption, 'no_clone');
		$caption_text =~ s{(\r?\n)+$}{};
		$return = join "\n", ("=" x $total_width), wrap('','',"TABLE: $caption_text"), $return;
	}
	
	foreach my $section (@{$self->sections})
	{
		foreach my $row (@{$section->rows})
		{
			$return .= $row->to_text($tt);
		}
		$return .= ("=" x $total_width) . "\n";
	}
	
	$return
}

__PACKAGE__
__END__

=head1 NAME

HTML::HTML5::Table - representation of an HTML table

=head1 DESCRIPTION

This is not yet fully documented, but the source code should be *gulp*
fairly self-documenting. Just skim the Moose attributes of this module
and the other modules in the "HTML::HTML5::Table" namespace and hopefully
you'll get an idea of how they all hang together. But briefly:

=over

=item * C<HTML::HTML5::Table> - the HTML C<< <table> >> element

=item * C<HTML::HTML5::Table::Body> - the HTML C<< <tbody> >> element

=item * C<HTML::HTML5::Table::Cell> - the HTML C<< <td> >> element

=item * C<HTML::HTML5::Table::Col> - the HTML C<< <col> >> element

=item * C<HTML::HTML5::Table::ColGroup> - the HTML C<< <colgroup> >> element

=item * C<HTML::HTML5::Table::Foot> - the HTML C<< <tfoot> >> element

=item * C<HTML::HTML5::Table::Head> - the HTML C<< <thead> >> element

=item * C<HTML::HTML5::Table::HeadCell> - the HTML C<< <th> >> element

=item * C<HTML::HTML5::Table::Row> - the HTML C<< <tr> >> element

=item * C<HTML::HTML5::Table::Section> - superclass for C<< <thead> >>, C<< <tfoot> >> and C<< <tbody> >>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=HTML-HTML5-ToText>.

=head1 SEE ALSO

L<HTML::HTML5::ToText>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


