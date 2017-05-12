use Test::More tests => 14;
use Test::RDF;

use HTML::HTML5::Microdata::Parser;
use RDF::Trine qw[iri literal variable statement blank];
use RDF::Trine::Namespace qw[rdf rdfs xsd owl];
my $s = RDF::Trine::Namespace->new('http://schema.org/');

my $p = HTML::HTML5::Microdata::Parser->new(<<'MARKUP', 'http://example.com/', {xhtml_time=>1});
<div itemscope itemtype="http://schema.org/Person">
	<h1 itemprop="name">Alice</h1>
	<time itemprop="birthday">1980-06-01</time>
</div>
<div itemscope itemtype="http://schema.org/Person">
	<h1 itemprop="name">Bob</h1>
	<time itemprop="birthday" datetime="1980-06-02">2 June 1980</time>
</div>
<div itemscope itemtype="http://schema.org/Person">
	<h1 itemprop="name">Carol</h1>
	<time itemprop="birthday" datetime="1980-06">June 1980</time>
</div>
<div itemscope itemtype="http://schema.org/Person">
	<h1 itemprop="name">David</h1>
	<time itemprop="birthday" datetime="1980">1980</time>
</div>
<div itemscope itemtype="http://schema.org/Person">
	<h1 itemprop="name">Eve</h1>
	<time itemprop="birthday" datetime="1980-06-03T12:00pm">3 June 1980</time>
</div>
<div itemscope itemtype="http://schema.org/Person">
	<h1 itemprop="name">Fred</h1>
	<time itemprop="birthday" datetime="1980-06-04T12:00:00Z">4 June 1980</time>
</div>
<div itemscope itemtype="http://schema.org/Person">
	<h1 itemprop="name">Georgia</h1>
	<time itemprop="birthday" datetime="1980-06-05T12:00:00.000Z">5 June 1980</time>
</div>
<div itemscope itemtype="http://schema.org/Person">
	<h1 itemprop="name">Harold</h1>
	<time itemprop="birthday" datetime="1980-06-06T12:00+0100">6 June 1980</time>
</div>
<div itemscope itemtype="http://schema.org/Person">
	<h1 itemprop="name">Ingrid</h1>
	<time itemprop="birthday" datetime="--06-07">7 June</time>
</div>
<div itemscope itemtype="http://schema.org/Person">
	<h1 itemprop="name">John</h1>
	<time itemprop="birthday" datetime="---08">The 8th</time>
</div>
<div itemscope itemtype="http://schema.org/Person">
	<h1 itemprop="name">Kylie</h1>
	<time itemprop="birthday" datetime="--06">June</time>
</div>
<div itemscope itemtype="http://schema.org/Person">
	<h1 itemprop="name">Lesley</h1>
	<time itemprop="birthday">12:00</time>
</div>
<div itemscope itemtype="http://schema.org/Person">
	<h1 itemprop="name">Maurice</h1>
	<time itemprop="birthday">12:00:01.123456789-05:00</time>
</div>
MARKUP

pattern_target($p->graph);

pattern_ok(
	statement(variable('x'), $rdf->type, $s->Person),
	statement(variable('x'), $s->name, literal('Alice')),
	statement(variable('x'), $s->birthday, literal('1980-06-01', undef, $xsd->date->uri)),
	'<time> with no @datetime'
	);

pattern_ok(
	statement(variable('x'), $rdf->type, $s->Person),
	statement(variable('x'), $s->name, literal('Bob')),
	statement(variable('x'), $s->birthday, literal('1980-06-02', undef, $xsd->date->uri)),
	'xsd:date'
	);

pattern_ok(
	statement(variable('x'), $rdf->type, $s->Person),
	statement(variable('x'), $s->name, literal('Carol')),
	statement(variable('x'), $s->birthday, literal('1980-06', undef, $xsd->gYearMonth->uri)),
	'xsd:gYearMonth'
	);

pattern_ok(
	statement(variable('x'), $rdf->type, $s->Person),
	statement(variable('x'), $s->name, literal('David')),
	statement(variable('x'), $s->birthday, literal('1980', undef, $xsd->gYear->uri)),
	'xsd:gYear'
	);

pattern_ok(
	statement(variable('x'), $rdf->type, $s->Person),
	statement(variable('x'), $s->name, literal('Eve')),
	statement(variable('x'), $s->birthday, literal('1980-06-03T12:00pm', undef, undef)),
	'Malformed dateTime not given a datatype'
	);

pattern_ok(
	statement(variable('x'), $rdf->type, $s->Person),
	statement(variable('x'), $s->name, literal('Fred')),
	statement(variable('x'), $s->birthday, literal('1980-06-04T12:00:00Z', undef, $xsd->dateTime->uri)),
	'xsd:dateTime'
	);

pattern_ok(
	statement(variable('x'), $rdf->type, $s->Person),
	statement(variable('x'), $s->name, literal('Georgia')),
	statement(variable('x'), $s->birthday, literal('1980-06-05T12:00:00.000Z', undef, $xsd->dateTime->uri)),
	'xsd:dateTime with fractional seconds'
	);

pattern_ok(
	statement(variable('x'), $rdf->type, $s->Person),
	statement(variable('x'), $s->name, literal('Harold')),
	statement(variable('x'), $s->birthday, literal('1980-06-06T12:00+0100', undef, $xsd->dateTime->uri)),
	'non-Z timezone'
	);

pattern_ok(
	statement(variable('x'), $rdf->type, $s->Person),
	statement(variable('x'), $s->name, literal('Ingrid')),
	statement(variable('x'), $s->birthday, literal('--06-07', undef, $xsd->gMonthDay->uri)),
	'xsd:gMonthDay'
	);

pattern_ok(
	statement(variable('x'), $rdf->type, $s->Person),
	statement(variable('x'), $s->name, literal('John')),
	statement(variable('x'), $s->birthday, literal('---08', undef, $xsd->gDay->uri)),
	'xsd:gDay'
	);

pattern_ok(
	statement(variable('x'), $rdf->type, $s->Person),
	statement(variable('x'), $s->name, literal('Kylie')),
	statement(variable('x'), $s->birthday, literal('--06', undef, $xsd->gMonth->uri)),
	'xsd:gMonth'
	);

pattern_ok(
	statement(variable('x'), $rdf->type, $s->Person),
	statement(variable('x'), $s->name, literal('Lesley')),
	statement(variable('x'), $s->birthday, literal('12:00', undef, $xsd->time->uri)),
	'xsd:time'
	);

pattern_ok(
	statement(variable('x'), $rdf->type, $s->Person),
	statement(variable('x'), $s->name, literal('Maurice')),
	statement(variable('x'), $s->birthday, literal('12:00:01.123456789-05:00', undef, $xsd->time->uri)),
	'xsd:time complex'
	);

#use RDF::TrineShortcuts;
#diag rdf_string($p->graph => 'Turtle');
