use lib "../lib";
use lib "lib";

use HTML::HTML5::Parser;
use HTML::HTML5::ToText;

{
	package Local::Definitions;
	use Moose::Role;
	has defined_terms => (
		is       => 'rw',
		isa      => 'HashRef',
		default  => sub { +{} },
		);
	after [qw/DFN DT/] => sub
	{
		my ($self, $elem) = @_;
		$self->defined_terms->{ $elem->textContent }++;
	};
	around HTML => sub
	{
		my ($orig, $self, @args) = @_;
		$self->defined_terms({});
		my $str  = $self->$orig(@args);
		my @defs = map {" * $_"} sort keys %{ $self->defined_terms };
		unshift @defs, '', 'DEFINITIONS:';
		return $str . join "\n", @defs;
	};
}

my $dom = HTML::HTML5::Parser->load_html(IO => \*DATA);
print HTML::HTML5::ToText->with_traits(qw/ShowLinks +Local::Definitions/)->process( $dom );

__DATA__
<!doctype html>
<h1>Glossary</h1>
<dl>
<dt>Foo</dt>
<dd>Definition of <a href="http://example.com/">foo</a>.</dd>
<dt>Bar</dt>
<dd>Definition of bar.</dd>
</dl>
