use Test::More;
use warnings;
use strict;

# <test-body>

require_ok('HTML5::DOM');

# test static API
can_ok('HTML5::DOM', qw(new));
can_ok('HTML5::DOM::Collection', qw(new));
can_ok('HTML5::DOM::Encoding', qw(
	id2name name2id detectAuto detect detectRussian detectUnicode
	detectByPrescanStream detectByCharset detectBomAndCut
));
can_ok('HTML5::DOM::CSS', qw(new));
can_ok('HTML5::DOM::CSS::Selector', qw(new));

#####################################
# HTML5::DOM
#####################################

# new without options
my $parser = HTML5::DOM->new;
isa_ok($parser, 'HTML5::DOM', 'create parser without options');

# new with options
$parser = HTML5::DOM->new({
	threads	=> 2
});
isa_ok($parser, 'HTML5::DOM', 'create parser with options');

# test api
can_ok($parser, qw(parse parseChunkStart parseChunk parseChunkEnd));

# test html parsing with threads
my $tree = $parser->parse('<div id="test">bla bla<!-- o_O --></div>');
isa_ok($tree, 'HTML5::DOM::Tree', 'parse with threads');

# test html parsing without threads
$tree = $parser->parse('<div id="test">bla bla<!-- o_O --></div>', {threads => 0});
isa_ok($tree, 'HTML5::DOM::Tree', 'parse without threads');

# test api
can_ok($tree, qw(
	createElement createComment createTextNode parseFragment document root head body
	at querySelector find querySelectorAll findId getElementById findTag getElementsByTagName
	findClass getElementsByClassName findAttr getElementByAttribute encoding encodingId
	tag2id id2tag namespace2id id2namespace wait parsed parser
));

# test chunks
isa_ok($parser->parseChunkStart(), 'HTML5::DOM');
isa_ok($parser->parseChunk('<div'), 'HTML5::DOM');
isa_ok($parser->parseChunk('>ololo'), 'HTML5::DOM');
isa_ok($parser->parseChunk('</div>'), 'HTML5::DOM');
isa_ok($parser->parseChunk('ololo'), 'HTML5::DOM');
isa_ok($parser->parseChunkEnd, 'HTML5::DOM::Tree');

#####################################
# HTML5::DOM::Tree
#####################################

# wait
isa_ok($tree->wait, "HTML5::DOM::Tree");
ok($tree->parsed == 1, "parsed");

# basic tree api
isa_ok($tree->root, 'HTML5::DOM::Element');
ok($tree->root->tag eq 'html', 'root tag name');
ok($tree->root->tagId == HTML5::DOM->TAG_HTML, 'root tag id');

isa_ok($tree->head, 'HTML5::DOM::Element');
ok($tree->head->tag eq 'head', 'head tag name');
ok($tree->head->tagId == HTML5::DOM->TAG_HEAD, 'head tag id');

isa_ok($tree->body, 'HTML5::DOM::Element');
ok($tree->body->tag eq 'body', 'body tag name');
ok($tree->body->tagId == HTML5::DOM->TAG_BODY, 'body tag id');

isa_ok($tree->document, 'HTML5::DOM::Document');
ok($tree->document->tag eq '-undef', 'document tag name');
ok($tree->document->tagId == HTML5::DOM->TAG__UNDEF, 'document tag id');

# createElement with namespace
my $new_node = $tree->createElement("mycustom", "svg");
isa_ok($new_node, 'HTML5::DOM::Element');
ok($new_node->tag eq 'mycustom', 'mycustom tag name');
ok($new_node->namespace eq 'SVG', 'mycustom namespace name');
ok($new_node->namespaceId eq HTML5::DOM->NS_SVG, 'mycustom namespace id');
ok($new_node->tagId == $tree->tag2id('mycustom'), 'mycustom tag id');

# createElement with default namespace
$new_node = $tree->createElement("mycustom2");
isa_ok($new_node, 'HTML5::DOM::Element');
ok($new_node->namespace eq 'HTML', 'mycustom2 namespace name');
ok($new_node->namespaceId eq HTML5::DOM->NS_HTML, 'mycustom2 namespace id');

# createComment
$new_node = $tree->createComment(" my comment >_< ");
isa_ok($new_node, 'HTML5::DOM::Comment');
ok($new_node->text eq ' my comment >_< ', 'Comment serialization text');
ok($new_node->html eq '<!-- my comment >_< -->', 'Comment serialization html');

# createTextNode
$new_node = $tree->createTextNode(" my text >_< ");
isa_ok($new_node, 'HTML5::DOM::Text');
ok($new_node->text eq ' my text >_< ', 'Text serialization text');
ok($new_node->html eq ' my text &gt;_&lt; ', 'Text serialization html');

# parseFragment
$new_node = $tree->parseFragment(" <div>its <b>a</b><!-- ololo --> fragment</div> ");
isa_ok($new_node, 'HTML5::DOM::Fragment');
ok($new_node->text eq ' its a fragment ', 'Fragment serialization text');
ok($new_node->html eq ' <div>its <b>a</b><!-- ololo --> fragment</div> ', 'Fragment serialization html');

# encoding
ok($tree->encoding() eq "UTF-8", "encoding");
ok($tree->encodingId() == HTML5::DOM::Encoding->UTF_8, "encodingId");

# tag2id
ok($tree->tag2id("div") == HTML5::DOM->TAG_DIV, "tag2id");
ok($tree->tag2id("DiV") == HTML5::DOM->TAG_DIV, "tag2id");
ok($tree->tag2id("blablabla") == HTML5::DOM->TAG__UNDEF, "tag2id not exists");

# id2tag
ok($tree->id2tag(HTML5::DOM->TAG_DIV) eq "div", "id2tag");
ok(!defined $tree->id2tag(8274242), "id2tag not exists");

# namespace2id
ok($tree->namespace2id("SvG") == HTML5::DOM->NS_SVG, "namespace2id");
ok($tree->namespace2id("svg") == HTML5::DOM->NS_SVG, "namespace2id");
ok($tree->namespace2id("blablabla") == HTML5::DOM->NS_UNDEF, "namespace2id not exists");

# id2namespace
ok($tree->id2namespace(HTML5::DOM->NS_SVG) eq "SVG", "id2namespace");
ok(!defined $tree->id2namespace(8274242), "id2namespace not exists");

# parser
isa_ok($tree->parser, 'HTML5::DOM');
ok($tree->parser == $parser, 'parser');

# finders
$tree = $parser->parse('
	<!DOCTYPE html>
	<div id="test0" some-attr="ololo trololo" class="red blue">
		<div class="yellow" id="test1"></div>
	</div>
	<div id="test2" some-attr="ololo" class="blue">
		<div class="yellow" id="test3"></div>
	</div>
	
	<span test-attr-eq="test"></span>
	<span test-attr-eq="testt"></span>
	
	<span test-attr-space="wefwef   test   wefewfew"></span>
	<span test-attr-space="wefewwef testt wewe"></span>
	
	<span test-attr-dash="test-fwefwewfe"></span>
	<span test-attr-dash="testt-"></span>
	
	<span test-attr-substr="wefwefweftestfweewfwe"></span>
	
	<span test-attr-prefix="testewfwefewwf"></span>
	
	<span test-attr-suffix="ewfwefwefweftest"></span>
');

# querySelector + at
for my $method (qw|at querySelector|) {
	isa_ok($tree->$method('div'), 'HTML5::DOM::Element');
	ok($tree->$method('div')->attr("id") eq 'test0', "$method: find div");
	ok(!defined $tree->$method('xuj'), "$method: not found");
}

# findId + getElementById
for my $method (qw|findId getElementById|) {
	isa_ok($tree->$method('test2'), 'HTML5::DOM::Element');
	ok($tree->$method('test2')->attr("id") eq 'test2', "$method: find #test2");
	ok(!defined $tree->$method('xuj'), "$method: not found");
}

# find + querySelectorAll
for my $method (qw|find querySelectorAll|) {
	isa_ok($tree->$method('.blue'), 'HTML5::DOM::Collection');
	isa_ok($tree->$method('.ewfwefwefwefwef'), 'HTML5::DOM::Collection');
	ok($tree->$method('.blue')->length == 2, "$method: find .blue");
	ok($tree->$method('.bluE')->length == 0, "$method: find .bluE");
	ok($tree->$method('.ewfwefwefwefwef')->length == 0, "$method: not found");
	ok($tree->$method('.blue')->item(1)->attr("id") eq "test2", "$method: check result element");
}

# findTag + getElementsByTagName
for my $method (qw|findTag getElementsByTagName|) {
	isa_ok($tree->$method('div'), 'HTML5::DOM::Collection');
	isa_ok($tree->$method('ewfwefwefwefwef'), 'HTML5::DOM::Collection');
	ok($tree->$method('div')->length == 4, "$method: find div");
	ok($tree->$method('dIv')->length == 4, "$method: find dIv");
	ok($tree->$method('ewfwefwefwefwef')->length == 0, "$method: not found");
	ok($tree->$method('div')->item(0)->attr("id") eq "test0", "$method: check result element");
}

# findClass + getElementsByClassName
for my $method (qw|findClass getElementsByClassName|) {
	isa_ok($tree->$method('blue'), 'HTML5::DOM::Collection');
	isa_ok($tree->$method('ewfwefwefwefwef'), 'HTML5::DOM::Collection');
	ok($tree->$method('blue')->length == 2, "$method: find .blue");
	ok($tree->$method('red')->length == 1, "$method: find .red");
	ok($tree->$method('bluE')->length == 0, "$method: find .bluE");
	ok($tree->$method('ewfwefwefwefwef')->length == 0, "$method: not found");
	ok($tree->$method('yellow')->item(0)->attr("id") eq "test1", "$method: check result element");
}

# findAttr + getElementByAttribute
for my $method (qw|findAttr getElementByAttribute|) {
	for my $cmp (qw(= ~ | * ^ $)) {
		for my $i ((0, 1)) {
			my $attrs = {
				'='	=> 'test-attr-eq', 
				'~'	=> 'test-attr-space', 
				'|'	=> 'test-attr-dash', 
				'*'	=> 'test-attr-substr', 
				'^'	=> 'test-attr-prefix', 
				'$'	=> 'test-attr-suffix', 
			};
			
			my $values = [['test', 'tesT'], ['tEsT', 'test2']];
			
			# test found
			my $collection = $tree->$method($attrs->{$cmp}, $values->[$i]->[0], $i, $cmp);
			isa_ok($collection, 'HTML5::DOM::Collection');
			ok($collection->length == 1, "$method(".$attrs->{$cmp}.", $cmp, $i): found ".$collection->length);
			
			# test not found
			$collection = $tree->$method($attrs->{$cmp}, $values->[$i]->[1], $i, $cmp);
			isa_ok($collection, 'HTML5::DOM::Collection');
			ok($collection->length == 0, "$method(".$attrs->{$cmp}.", $cmp, $i): not found ".$collection->length);
		}
	}
}

# compatMode
ok($parser->parse('<div></div>')->compatMode eq 'BackCompat', 'compatMode: BackCompat');
ok($parser->parse('<!DOCTYPE html><div></div>')->compatMode eq 'CSS1Compat', 'compatMode: CSS1Compat');

#####################################
# HTML5::DOM::Node
#####################################

my @node_methods = qw(
	tag nodeName tagId namespace namespaceId tree nodeType next nextElementSibling
	prev previousElementSibling nextNode nextSibling prevNode previousSibling 
	html innerHTML outerHTML text innerText outerText textContent
	nodeHtml nodeValue data isConnected parent parentElement document ownerDocument
	append appendChild prepend prependChild replace replaceChild before insertBefore
	after insertAfter remove removeChild clone cloneNode void selfClosed position
	isSameNode wait parsed
);
my @element_methods = qw(
	first firstElementChild last lastElementChild firstNode firstChild lastNode lastChild
	children childrenNode childNodes attr removeAttr getAttribute setAttribute
	removeAttribute at querySelector find querySelectorAll findId getElementById
	findTag getElementsByTagName findClass getElementsByClassName findAttr
	getElementByAttribute getDefaultBoxType
);

# check elements + nodeType
my $el_node = $tree->createElement("div");
can_ok($el_node, @node_methods);
can_ok($el_node, @element_methods);
ok(ref($el_node) eq 'HTML5::DOM::Element', 'check element ref');
ok($el_node->nodeType == $el_node->ELEMENT_NODE, 'nodeType == ELEMENT_NODE');

# check comments + nodeType
my $comment_node = $tree->createComment("comment...");
can_ok($comment_node, @node_methods);
ok(ref($comment_node) eq 'HTML5::DOM::Comment', 'check comment ref');
ok($comment_node->nodeType == $comment_node->COMMENT_NODE, 'nodeType == COMMENT_NODE');

# check texts + nodeType
my $text_node = $tree->createTextNode("text?");
can_ok($text_node, @node_methods);
ok(ref($text_node) eq 'HTML5::DOM::Text', 'check text ref');
ok($text_node->nodeType == $text_node->TEXT_NODE, 'nodeType == TEXT_NODE');

# check doctype + nodeType
my $doctype_node = $parser->parse('<!DOCTYPE html>')->document->[0];
can_ok($doctype_node, @node_methods);
ok(ref($doctype_node) eq 'HTML5::DOM::DocType', 'check doctype ref');
ok($doctype_node->nodeType == $doctype_node->DOCUMENT_TYPE_NODE, 'nodeType == DOCUMENT_TYPE_NODE');

# check fragment + nodeType
my $frag_node = $tree->parseFragment('test...');
can_ok($frag_node, @node_methods);
can_ok($frag_node, @element_methods);
ok(ref($frag_node) eq 'HTML5::DOM::Fragment', 'check fragment ref');
ok($frag_node->nodeType == $frag_node->DOCUMENT_FRAGMENT_NODE, 'nodeType == DOCUMENT_FRAGMENT_NODE');

# check document + nodeType
my $doc_node = $tree->document;
can_ok($doc_node, @node_methods);
can_ok($doc_node, @element_methods);
ok(ref($doc_node) eq 'HTML5::DOM::Document', 'check document ref');
ok($doc_node->nodeType == $doc_node->DOCUMENT_NODE, 'nodeType == DOCUMENT_NODE');

# tag + nodeName
$el_node = $tree->createElement("div");
ok($el_node->tag eq "div", "node->tag");
ok($el_node->nodeName eq "DIV", "node->nodeName");
ok($el_node->tagName eq "DIV", "node->tagName");

for my $method (qw|tag nodeName tagName|) {
	my $node = $tree->createElement("div");
	
	isa_ok($node->$method("span"), 'HTML5::DOM::Node');
	ok($node->nodeName eq "SPAN", "$method: change tag to span");
	
	isa_ok($node->$method("blablaxuj"), 'HTML5::DOM::Node');
	ok($node->nodeName eq "BLABLAXUJ", "$method: change tag to blablaxuj");
	
	isa_ok($node->$method("blablaxuj" x 102400), 'HTML5::DOM::Node');
	ok($node->nodeName eq "BLABLAXUJ" x 102400, "$method: change tag to long blablaxuj");
	
	eval { $node->$method(""); };
	ok($@ =~ /empty tag name not allowed/, "$method: change tag to empty string");
}

# tagId
$el_node = $tree->createElement("div");
ok($el_node->tagId == HTML5::DOM->TAG_DIV, "node->tagId");
isa_ok($el_node->tagId(HTML5::DOM->TAG_SPAN), 'HTML5::DOM::Node');
ok($el_node->tagId == HTML5::DOM->TAG_SPAN, "node->tagId");
eval { $el_node->tagId(9999999999999); };
ok($@ =~ /unknown tag id/, "tagId: change tag to unknown id");

# namespace
$el_node = $tree->createElement("div", "svg");
ok($el_node->namespace eq "SVG", "node->namespace");
isa_ok($el_node->namespace("hTml"), 'HTML5::DOM::Node');
ok($el_node->namespace eq "HTML", "node->namespace");
eval { $el_node->namespace("ewfwefwefwefwef"); };
ok($@ =~ /unknown namespace/, "node->namespace: set unknown namespace");

# namespaceId
$el_node = $tree->createElement("div");
ok($el_node->namespaceId == HTML5::DOM->NS_HTML, "node->namespaceId");
isa_ok($el_node->namespaceId(HTML5::DOM->NS_SVG), 'HTML5::DOM::Node');
ok($el_node->namespaceId == HTML5::DOM->NS_SVG, "node->namespaceId");
eval { $el_node->namespaceId(9999999999999); };
ok($@ =~ /unknown namespace/, "node->namespaceId: set unknown namespace");

# tree
isa_ok($el_node->tree, "HTML5::DOM::Tree");
ok($el_node->tree == $tree, "node->tree");

$tree = HTML5::DOM->new->parse('
   <ul>
       <li>Linux</li>
       <!-- comment -->
       <li>OSX</li>
       <li>Windows</li>
   </ul>
');

# test all siblings navigators
my $siblings_tests = [
	{
		methods	=> [qw|next nextElementSibling|], 
		index	=> 1, 
		results	=> [
			['HTML5::DOM::Element',	qr/^Linux$/], 
			['HTML5::DOM::Element',	qr/^OSX$/], 
			['HTML5::DOM::Element',	qr/^Windows$/], 
			['',					undef]
		]
	}, 
	{
		methods	=> [qw|prev previousElementSibling|], 
		index	=> -2, 
		results	=> [
			['HTML5::DOM::Element',	qr/^Windows$/], 
			['HTML5::DOM::Element',	qr/^OSX$/], 
			['HTML5::DOM::Element',	qr/^Linux$/], 
			['',					undef]
		]
	}, 
	{
		methods	=> [qw|nextNode nextSibling|], 
		index	=> 0, 
		results	=> [
			['HTML5::DOM::Text',	qr/^\s+$/], 
			['HTML5::DOM::Element',	qr/^Linux$/], 
			['HTML5::DOM::Text',	qr/^\s+$/], 
			['HTML5::DOM::Comment',	qr/^ comment $/], 
			['HTML5::DOM::Text',	qr/^\s+$/], 
			['HTML5::DOM::Element',	qr/^OSX$/], 
			['HTML5::DOM::Text',	qr/^\s+$/], 
			['HTML5::DOM::Element',	qr/^Windows$/], 
			['HTML5::DOM::Text',	qr/^\s+$/], 
			['',					undef]
		]
	}, 
	{
		methods	=> [qw|prevNode previousSibling|], 
		index	=> -1, 
		results	=> [
			['HTML5::DOM::Text',	qr/^\s+$/], 
			['HTML5::DOM::Element',	qr/^Windows$/], 
			['HTML5::DOM::Text',	qr/^\s+$/], 
			['HTML5::DOM::Element',	qr/^OSX$/], 
			['HTML5::DOM::Text',	qr/^\s+$/], 
			['HTML5::DOM::Comment',	qr/^ comment $/], 
			['HTML5::DOM::Text',	qr/^\s+$/], 
			['HTML5::DOM::Element',	qr/^Linux$/], 
			['HTML5::DOM::Text',	qr/^\s+$/], 
			['',					undef]
		]
	}
];

for my $test (@$siblings_tests) {
	my $ul = $tree->at('ul');
	ok($ul->tag eq 'ul', "siblings test: check test element");
	
	for my $method (@{$test->{methods}}) {
		my $next = $ul->childrenNode->[$test->{index}];
		my @chain = ($method);
		for my $result (@{$test->{results}}) {
			ok(ref($next) eq $result->[0], join(" > ", @chain)." check ref");
			
			if (defined $result->[1]) {
				ok($next->text =~ $result->[1], join(" > ", @chain)." check value");
			} else {
				ok(!defined $result->[1], join(" > ", @chain)." (undef)");
			}
			
			last if (!$next);
			
			$next = $next->$method;
			push @chain, $method;
		}
	}
}

$tree = HTML5::DOM->new->parse('
   <ul><!--
        first comment -->
       <li>Linux</li>
       <li>OSX</li>
       <li>Windows</li>
       <!-- last comment 
   --></ul>
');

# test all first/last navigators
my $first_last_tests = [
	{
		methods	=> [qw|first firstElementChild|], 
		results	=> [
			['HTML5::DOM::Element',	qr/^Linux$/], 
			['',					undef]
		]
	}, 
	{
		methods	=> [qw|last lastElementChild|], 
		results	=> [
			['HTML5::DOM::Element',	qr/^Windows$/], 
			['',					undef], 
		]
	}, 
	{
		methods	=> [qw|firstNode firstChild|], 
		results	=> [
			['HTML5::DOM::Comment',	qr/^\s+first comment\s+$/]
		]
	}, 
	{
		methods	=> [qw|lastNode lastChild|], 
		results	=> [
			['HTML5::DOM::Comment',	qr/^\s+last comment\s+$/]
		]
	}
];

for my $test (@$first_last_tests) {
	my $ul = $tree->at('ul');
	ok($ul->tag eq 'ul', "first/last test: check test element");
	
	for my $method (@{$test->{methods}}) {
		my $next = $ul->$method;
		my @chain = ($method);
		for my $result (@{$test->{results}}) {
			ok(ref($next) eq $result->[0], join(" > ", @chain)." check ref .. ".ref($next));
			
			if (defined $result->[1]) {
				ok($next->text =~ $result->[1], join(" > ", @chain)." check value");
			} else {
				ok(!defined $result->[1], join(" > ", @chain)." (undef)");
			}
			
			last if (!$next || !$next->can($method));
			
			$next = $next->$method;
			push @chain, $method;
		}
	}
}

# html and text serialzation
$tree = HTML5::DOM->new->parse('<body aaa="bb"><b>      <!-- super cool new comment --> ololo ??? <div class="red">&nbsp;&gt;&lt;&quot;</div></b></body>');

my $html_serialize2 = {
	'html'			=> '<body aaa="bb"><b>      <!-- super cool new comment --> ololo ??? <div class="red">&nbsp;&gt;&lt;"</div></b></body>', 
	'innerHTML'		=> '<b>      <!-- super cool new comment --> ololo ??? <div class="red">&nbsp;&gt;&lt;"</div></b>', 
	'outerHTML'		=> '<body aaa="bb"><b>      <!-- super cool new comment --> ololo ??? <div class="red">&nbsp;&gt;&lt;"</div></b></body>', 
	'nodeHtml'		=> '<body aaa="bb">', 
	'text'			=> '       ololo ???  ><"', 
	'innerText'		=> "ololo ???\n ><\"\n", 
	'outerText'		=> "ololo ???\n ><\"\n", 
	'textContent'	=> '       ololo ???  ><"', 
	'nodeValue'		=> undef, 
	'data'			=> undef
};

for my $method (keys %$html_serialize2) {
	if (defined $html_serialize2->{$method}) {
		ok($tree->body->$method eq $html_serialize2->{$method}, "$method serialization");
	} else {
		ok(!defined $tree->body->$method, "$method serialization (undef)");
	}
}

# html/text fragments
my $html_serialize3 = [
	{
		method	=> 'html', 
		html	=> '<b>      <!-- super cool new comment --> ololo ??? <div class="red">&nbsp;&gt;&lt;&quot;</div></b>', 
		body	=> '<body><div id="test"><b>      <!-- super cool new comment --> ololo ??? <div class="red">&nbsp;&gt;&lt;"</div></b></div></body>'
	}, 
	{
		method	=> 'innerHTML', 
		html	=> '<b>      <!-- super cool new comment --> ololo ??? <div class="red">&nbsp;&gt;&lt;&quot;</div></b>', 
		body	=> '<body><div id="test"><b>      <!-- super cool new comment --> ololo ??? <div class="red">&nbsp;&gt;&lt;"</div></b></div></body>'
	}, 
	{
		method	=> 'outerHTML', 
		html	=> '<b>      <!-- super cool new comment --> ololo ??? <div class="red">&nbsp;&gt;&lt;&quot;</div></b>', 
		body	=> '<body><b>      <!-- super cool new comment --> ololo ??? <div class="red">&nbsp;&gt;&lt;"</div></b></body>'
	}, 
	{
		method	=> 'text', 
		html	=> "\nololo   >^_^<   trololo\n", 
		body	=> "<body><div id=\"test\">\nololo   &gt;^_^&lt;   trololo\n</div></body>"
	}, 
	{
		method	=> 'textContent', 
		html	=> "\nololo   >^_^<   trololo\n", 
		body	=> "<body><div id=\"test\">\nololo   &gt;^_^&lt;   trololo\n</div></body>"
	}, 
	{
		method	=> 'innerText', 
		html	=> "\nololo   >^_^<   trololo\n", 
		body	=> "<body><div id=\"test\"><br>ololo   &gt;^_^&lt;   trololo<br></div></body>"
	}, 
	{
		method	=> 'outerText', 
		html	=> "\nololo   >^_^<   trololo\n", 
		body	=> "<body><br>ololo   &gt;^_^&lt;   trololo<br></body>"
	}
];

for my $test (@$html_serialize3) {
	$tree = HTML5::DOM->new->parse('<div id="test"><b><!-- super cool new comment --> ololo ??? <div class="red">&nbsp;&gt;&lt;&quot;</div></b></div>');
	
	my $method = $test->{method};
	my $method2 = $test->{method2};
	my $test_el = $tree->at('#test');
	
	my $ret = $test_el->$method($test->{html});
	isa_ok($ret, "HTML5::DOM::Node");
	ok($ret == $test_el, "$method return test: '".$tree->body->html."'");
	ok($tree->body->html eq $test->{body}, "$method content test");
}

# isConnected
my $node_test_connected = $tree->createElement('ololo');
ok($node_test_connected->isConnected == 0, 'isConnected == 0');
$tree->body->append($node_test_connected);
ok($node_test_connected->isConnected == 1, 'isConnected == 1');

# parent
for my $method (qw|parent parentElement|) {
	ok($node_test_connected->$method == $tree->body, "$method check");
}

# document + ownerDocument
for my $method (qw|document ownerDocument|) {
	ok($node_test_connected->$method == $tree->document, "$method check");
}

# clone
$tree = HTML5::DOM->new->parse('<div id="test"><b><!-- super cool new comment --> ololo ??? <div class="red">&nbsp;&gt;&lt;&quot;</div></b></div>');

my $clone_tests = [
	{
		src		=> $tree->at('#test'), 
		html	=> '<div id="test"></div>', 
		deep	=> 0
	}, 
	{
		src		=> $tree->at('#test'), 
		html	=> $tree->at('#test')->html, 
		deep	=> 1
	}, 
	{
		src		=> $tree->createComment(" comment >^_^< "), 
		html	=> $tree->createComment(" comment >^_^< ")->html, 
		deep	=> 0
	}, 
	{
		src		=> $tree->createComment(" comment >^_^< "), 
		html	=> $tree->createComment(" comment >^_^< ")->html, 
		deep	=> 1
	}, 
	{
		src		=> $tree->createTextNode(" text >^_^< "), 
		html	=> $tree->createTextNode(" text >^_^< ")->html, 
		deep	=> 0
	}, 
	{
		src		=> $tree->createTextNode(" text >^_^< "), 
		html	=> $tree->createTextNode(" text >^_^< ")->html, 
		deep	=> 1
	}, 
];

my $new_tree = HTML5::DOM->new->parse('<div id="test"></div>');

for my $copy_dst_tree (($tree, $new_tree)) {
	for my $method (qw|clone cloneNode|) {
		for my $test (@$clone_tests) {
			my $clone = $test->{src}->$method($test->{deep}, $copy_dst_tree);
			ok($copy_dst_tree == $clone->tree, ref($test->{src})."->$method(".$test->{deep}.") tree");
			ok($clone != $test->{src}, ref($test->{src})."->$method(".$test->{deep}.") eq");
			ok($clone->html eq $test->{html}, ref($test->{src})."$method(".$test->{deep}.") content");
		}
	}
}

# void
ok($tree->createElement('br')->void == 1, 'void == 1');
ok($tree->createElement('div')->void == 0, 'void == 0');

# selfClosed
ok($tree->parseFragment('<meta />')->first->selfClosed == 1, 'selfClosed == 1');
ok($tree->parseFragment('<meta></meta>')->first->selfClosed == 0, 'selfClosed == 0');

# wait
my $test_pos_buff = '<div><div id="position"></div></div>';
$tree = HTML5::DOM->new->parse($test_pos_buff);
isa_ok($tree->body->wait, "HTML5::DOM::Node");
ok($tree->body->parsed == 1, "parsed");

# position
my $pos = $tree->at('#position')->position;
ok(ref($pos) eq 'HASH', 'position is HASH');
ok(substr($test_pos_buff, $pos->{raw_begin}, $pos->{raw_length}) eq 'div', 'position raw begin/length');
ok(substr($test_pos_buff, $pos->{element_begin}, $pos->{element_length}) eq '<div id="position">', 'position element begin/length');

# isSameNode
ok($tree->body->isSameNode($tree->body) == 1, 'isSameNode == 1');
ok($tree->body->isSameNode($tree->head) == 0, 'isSameNode == 0');

# DOM node insertion manipulations
my $test_manipulations = [
	{
		method	=> 'append', 
		method2	=> 'last', 
		arg		=> sub { shift->createElement('div') }, 
		return	=> 'self', 
		type	=> 'add'
	}, 
	{
		method	=> 'appendChild', 
		method2	=> 'last', 
		arg		=> sub { shift->createElement('div') }, 
		return	=> 'added', 
		type	=> 'add'
	}, 
	{
		method	=> 'prepend', 
		method2	=> 'first', 
		arg		=> sub { shift->createElement('div') }, 
		return	=> 'self', 
		type	=> 'add'
	}, 
	{
		method	=> 'prependChild', 
		method2	=> 'first', 
		arg		=> sub { shift->createElement('div') }, 
		return	=> 'added', 
		type	=> 'add'
	}, 
	{
		method	=> 'replace', 
		method2	=> 'first', 
		arg		=> sub { shift->createElement('div') }, 
		return	=> 'self', 
		type	=> 'replace'
	}, 
	{
		method	=> 'replaceChild', 
		method2	=> 'first', 
		arg		=> sub { shift->createElement('div') }, 
		return	=> 'self', 
		type	=> 'replace', 
		parent	=> 1
	}, 
	{
		method	=> 'before', 
		method2	=> 'first', 
		arg		=> sub { shift->createElement('div') }, 
		return	=> 'self', 
		type	=> 'add2', 
		custom	=> [2, 0, 4], 
		offset	=> -1
	}, 
	{
		method	=> 'insertBefore', 
		method2	=> 'first', 
		arg		=> sub { shift->createElement('div') }, 
		return	=> 'added', 
		type	=> 'add2', 
		custom	=> [2, 0, 4], 
		offset	=> -1, 
		parent	=> 1
	}, 
	{
		method	=> 'after', 
		method2	=> 'first', 
		arg		=> sub { shift->createElement('div') }, 
		return	=> 'self', 
		type	=> 'add2', 
		custom	=> [2, 0, 4], 
		offset	=> 1
	}, 
	{
		method	=> 'insertAfter', 
		method2	=> 'first', 
		arg		=> sub { shift->createElement('div') }, 
		return	=> 'added', 
		type	=> 'add2', 
		custom	=> [2, 0, 4], 
		offset	=> 1, 
		parent	=> 1
	}, 
	{
		method	=> 'remove', 
		type	=> 'del'
	}, 
	{
		method	=> 'removeChild', 
		type	=> 'del', 
		parent	=> 1
	}
];

for my $test (@$test_manipulations) {
	$test->{custom} = [0] if (!$test->{custom});
	
	for my $custom_arg1 (@{$test->{custom}}) {
		$tree = HTML5::DOM->new->parse('
			<div id="test"><b><!-- super cool new comment --> ololo ??? <div class="red">&nbsp;&gt;&lt;&quot;</div></b></div>
			<ul>
			   <li>UNIX</li>
			   <li>Linux</li>
			   <!-- comment -->
			   <li>OSX</li>
			   <li>Windows</li>
			   <li>FreeBSD</li>
		   </ul>
		');
		
		my $arg = $test->{arg};
		
		$arg = $arg->($tree) if (ref($test->{arg}) eq 'CODE');
		
		my $method = $test->{method};
		my $method2 = $test->{method2};
		
		if ($test->{type} eq 'add') {
			my $test_el = $tree->at('#test');
			my $result = $test_el->$method($arg);
			my $old_parent = $test_el->parent;
			
			if ($test->{return} eq 'self') {
				ok($result == $test_el, "$method: check return (self)");
			} elsif ($test->{return} eq 'added') {
				ok($result == $arg, "$method: check return (added)");
			}
			
			ok($test_el->$method2 == $arg, "$method: check position");
			ok($test_el == $arg->parent, "$method: check parent for new");
			ok($old_parent == $test_el->parent, "$method: check parent for old");
		} elsif ($test->{type} eq 'replace') {
			my $test_el = $tree->at('#test');
			my $result;
			my $old_parent = $test_el->parent();
			
			my $test_el_index = 0;
			for my $child (@{$old_parent->children}) {
				last if ($child == $test_el);
				++$test_el_index;
			}
			
			if ($test->{parent}) {
				$result = $old_parent->$method($arg, $test_el);
			} else {
				$result = $test_el->$method($arg);
			}
			
			if ($test->{return} eq 'self') {
				ok($result == $test_el, "$method: check return (self)");
			} elsif ($test->{return} eq 'added') {
				ok($result == $arg, "$method: check return (added)");
			}
			
			ok($old_parent->children->item($test_el_index) == $arg, "$method: check position");
			ok($old_parent == $arg->parent, "$method: check parent for new");
			ok($test_el->isConnected == 0, "$method: check parent for old");
		} elsif ($test->{type} eq 'add2') {
			my $test_el = $tree->find('ul li')->[$custom_arg1];
			my $result;
			my $old_parent = $test_el->parent();
			
			my $test_el_index = 0;
			for my $child (@{$old_parent->children}) {
				last if ($child == $test_el);
				++$test_el_index;
			}
			
			if ($test->{parent}) {
				$result = $old_parent->$method($arg, $test_el);
			} else {
				$result = $test_el->$method($arg);
			}
			
			if ($test->{return} eq 'self') {
				ok($result == $test_el, "$method: check return (self) [ref=$custom_arg1]");
			} elsif ($test->{return} eq 'added') {
				ok($result == $arg, "$method: check return (added) [ref=$custom_arg1]");
			}
			
			my $check_offset = $test->{offset} < 0 ? $test_el_index : $test_el_index + $test->{offset};
			ok($old_parent->children->item($check_offset) == $arg, "$method: check position [ref=$custom_arg1]");
			ok($old_parent == $arg->parent, "$method: check parent for new [ref=$custom_arg1]");
			ok($old_parent == $test_el->parent, "$method: check parent for old [ref=$custom_arg1]");
		} elsif ($test->{type} eq 'del') {
			my $test_el = $tree->at('#test');
			my $result;
			my $old_parent = $test_el->parent();
			
			my $test_el_index = 0;
			for my $child (@{$old_parent->children}) {
				last if ($child == $test_el);
				++$test_el_index;
			}
			
			if ($test->{parent}) {
				$result = $old_parent->$method($test_el);
			} else {
				$result = $test_el->$method($test_el);
			}
			
			ok($result == $test_el, "$method: check return (self)");
			ok($test_el->isConnected == 0, "$method: check isConnected");
			ok($old_parent->children->[$test_el_index] != $test_el, "$method: check parent children");
		}
	}
}

#####################################
# HTML5::DOM::DocType
#####################################
my $doctype_lists = [
	{
		'in'		=> '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
		'out'		=> '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">', 
		'name'		=> 'html', 
		'systemId'	=> 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd',
		'publicId'	=> '-//W3C//DTD XHTML 1.0 Strict//EN',
	}, {
		'in'		=> '<!DOCTYPE html>',
		'out'		=> '<!DOCTYPE html>', 
		'name'		=> 'html',
		'systemId'	=> '',
		'publicId'	=> '',
	}, {
		'in'		=> '<!DOCTYPE html PUBLIC>',
		'out'		=> '<!DOCTYPE html>',
		'name'		=> 'html',
		'publicId'	=> '',
		'systemId'	=> '',
	}, {
		'in'		=> '<!DOCTYPE html SYSTEM>',
		'out'		=> '<!DOCTYPE html>', 
		'name'		=> 'html',
		'publicId'	=> '',
		'systemId'	=> ''
	}, {
		'in'		=> '<!DOCTYPE html allala>',
		'out'		=> '<!DOCTYPE html>',
		'name'		=> 'html',
		'publicId'	=> '',
		'systemId'	=> ''
	}, {
		'out'		=> '<!DOCTYPE html>',
		'in'		=> '<!DOCTYPE html "allala">',
		'name'		=> 'html',
		'publicId'	=> '',
		'systemId'	=> ''
	}, {
		'in'		=> '<!doctype HTML system "about:legacy-compat">',
		'out'		=> '<!DOCTYPE html SYSTEM "about:legacy-compat">',
		'name'		=> 'html', 
		'publicId'	=> '',
		'systemId'	=> 'about:legacy-compat'
	}, {
		'in'		=> '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0//EN">',
		'out'		=> '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0//EN">',
		'name'		=> 'html',
		'publicId'	=> '-//W3C//DTD HTML 4.0//EN',
		'systemId'	=> ''
	}, {
		'in'		=> '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0//EN" "http://www.w3.org/TR/REC-html40/strict.dtd">',
		'out'		=> '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0//EN" "http://www.w3.org/TR/REC-html40/strict.dtd">',
		'name'		=> 'html',
		'publicId'	=> '-//W3C//DTD HTML 4.0//EN',
		'systemId'	=> 'http://www.w3.org/TR/REC-html40/strict.dtd'
	}, {
		'in'		=> '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">',
		'out'		=> '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">',
		'name'		=> 'html',
		'publicId'	=> '-//W3C//DTD HTML 4.01//EN',
		'systemId'	=> ''
	}, {
		'in'		=> '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',
		'out'		=> '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',
		'name'		=> 'html',
		'publicId'	=> '-//W3C//DTD HTML 4.01//EN',
		'systemId'	=> 'http://www.w3.org/TR/html4/strict.dtd'
	}, {
		'in'		=> '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
		'out'		=> '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
		'name'		=> 'html',
		'publicId'	=> '-//W3C//DTD XHTML 1.0 Strict//EN',
		'systemId'	=> 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'
	}, {
		'in'		=> '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">',
		'out'		=> '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">',
		'name'		=> 'html',
		'publicId'	=> '-//W3C//DTD XHTML 1.1//EN',
		'systemId'	=> 'http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd'
	}, {
		'in'		=> '<!DOCTYPE html SYSTEM "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">',
		'out'		=> '<!DOCTYPE html SYSTEM "-//W3C//DTD XHTML 1.1//EN">',
		'name'		=> 'html',
		'publicId'	=> '',
		'systemId'	=> '-//W3C//DTD XHTML 1.1//EN',
	}, {
		'in'		=> '<!DOCTYPE OlOlLo>',
		'out'		=> '<!DOCTYPE olollo>',
		'name'		=> 'olollo',
		'publicId'	=> '',
		'systemId'	=> '',
	}, {
		'in'		=> '<!DOCTYPE html PUBLIC "" "xxx">',
		'out'		=> '<!DOCTYPE html SYSTEM "xxx">',
		'name'		=> 'html',
		'publicId'	=> '',
		'systemId'	=> 'xxx',
	}, {
		'in'		=> '<!DOCTYPE svg:svg PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN" "http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd">',
		'out'		=> '<!DOCTYPE svg:svg PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN" "http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd">',
		'name'		=> 'svg:svg',
		'publicId'	=> '-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN',
		'systemId'	=> 'http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd'
	}
];

# basic doctype tests
for my $dt (@$doctype_lists) {
	my $tree = HTML5::DOM->new->parse($dt->{in});
	
	if ($dt == $doctype_lists->[0]) {
		isa_ok($tree->document->firstChild, 'HTML5::DOM::DocType', 'check doctype isa');
		can_ok($tree->document->firstChild, @node_methods);
		can_ok($tree->document->firstChild, qw|name publicId systemId|);
	}
	
	# check serialization
	# ok($tree->document->firstChild->html eq $dt->{out}, 'check doctype serialization');
	
	# check name
	ok($tree->document->firstChild->name eq $dt->{name}, 'check doctype name');
	
	# check systemId
	ok($tree->document->firstChild->publicId eq $dt->{publicId}, 'check doctype publicId');
	
	# check publicId
	ok($tree->document->firstChild->systemId eq $dt->{systemId}, 'check doctype systemId');
}

# test change value
my $doctype_test_change = [
	{
		method		=> 'name', 
		value		=> 'svg'
	}, 
	{
		method		=> 'publicId', 
		value		=> '-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN'
	}, 
	{
		method		=> 'systemId', 
		value		=> 'http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd'
	}
];
for my $test (@$doctype_test_change) {
	my @doctypes = (
		'<!DOCTYPE>', 
		'<!DOCTYPE html>', 
		'<!DOCTYPE html SYSTEM "blabla">', 
		'<!DOCTYPE html PUBLIC "blabla">', 
		'<!DOCTYPE html PUBLIC "blabla" "blabla222">'
	);
	
	my $method = $test->{method};
	for my $dt (@doctypes) {
		my $tree = HTML5::DOM->new->parse($dt);
		
		my @check;
		for my $method2 (qw|name publicId systemId|) {
			if ($method2 ne $method) {
				push @check, {
					method	=> $method2, 
					value	=> $tree->document->firstChild->$method2()
				};
			}
		}
		
		isa_ok($tree->document->firstChild->$method($test->{value}), 'HTML5::DOM::DocType');
		ok($tree->document->firstChild->$method() eq $test->{value}, "$method: test new val");
		
		for my $c (@check) {
			my $method2 = $c->{method};
			my $value = $tree->document->firstChild->$method2();
			
			ok($tree->document->firstChild->$method2() eq $c->{value}, "$method: test old val of $method2");
		}
	}
}

#####################################
# HTML5::DOM::Element
#####################################
# classList

$tree = HTML5::DOM->new->parse('
	<div class="red blue">ololo</div>
');
my $cl_test_node = $tree->at('.red');
isa_ok($cl_test_node->classList, 'HTML5::DOM::TokenList');

isa_ok($cl_test_node->classList->add('blue', 'right', 'red', 'brown'), 'HTML5::DOM::TokenList');
ok($cl_test_node->classList->text eq 'red blue right brown', 'class add '.$cl_test_node->classList->text);

isa_ok($cl_test_node->classList->remove('blue', 'right', 'red'), 'HTML5::DOM::TokenList');
ok($cl_test_node->classList->text eq 'brown', 'class remove');

isa_ok($cl_test_node->classList->add('blue', 'right', 'red', 'brown'), 'HTML5::DOM::TokenList');
isa_ok($cl_test_node->classList->replace('right', 'right2'), 'HTML5::DOM::TokenList');

ok($cl_test_node->classList->text eq 'brown blue right2 red', 'class replace');

ok($cl_test_node->classList->length == 4, 'class length');

isa_ok($cl_test_node->classList->each(sub {
	my ($class, $index) = @_;
	ok($class eq $cl_test_node->classList->[$index], 'classList each ['.$index.']');
}), 'HTML5::DOM::TokenList');

isa_ok($cl_test_node->classList->remove('blue', 'right2', 'red', 'brown'), 'HTML5::DOM::TokenList');

ok($cl_test_node->classList->length == 0, 'class length after remove');

$tree = HTML5::DOM->new->parse('
	<ul>
	   <li>UNIX</li>
	   <li>Linux</li>
	   <!-- comment -->
	   <li>OSX</li>
	   <li>Windows</li>
	   <li>FreeBSD</li>
   </ul>
');

# children
my $childrens_tests = [
	{
		method	=> 'children', 
		results	=> [
			['HTML5::DOM::Element', qr/^UNIX$/], 
			['HTML5::DOM::Element', qr/^Linux$/], 
			['HTML5::DOM::Element', qr/^OSX$/], 
			['HTML5::DOM::Element', qr/^Windows$/], 
			['HTML5::DOM::Element', qr/^FreeBSD$/], 
		], 
	}, 
	{
		method	=> 'childrenNode', 
		results	=> [
			['HTML5::DOM::Text', qr/^\s+$/], 
			['HTML5::DOM::Element', qr/^UNIX$/], 
			['HTML5::DOM::Text', qr/^\s+$/], 
			['HTML5::DOM::Element', qr/^Linux$/], 
			['HTML5::DOM::Text', qr/^\s+$/], 
			['HTML5::DOM::Comment', qr/^ comment $/], 
			['HTML5::DOM::Text', qr/^\s+$/], 
			['HTML5::DOM::Element', qr/^OSX$/], 
			['HTML5::DOM::Text', qr/^\s+$/], 
			['HTML5::DOM::Element', qr/^Windows$/], 
			['HTML5::DOM::Text', qr/^\s+$/], 
			['HTML5::DOM::Element', qr/^FreeBSD$/], 
			['HTML5::DOM::Text', qr/^\s+$/], 
		], 
	}, 
	{
		method	=> 'childNodes', 
		results	=> [
			['HTML5::DOM::Text', qr/^\s+$/], 
			['HTML5::DOM::Element', qr/^UNIX$/], 
			['HTML5::DOM::Text', qr/^\s+$/], 
			['HTML5::DOM::Element', qr/^Linux$/], 
			['HTML5::DOM::Text', qr/^\s+$/], 
			['HTML5::DOM::Comment', qr/^ comment $/], 
			['HTML5::DOM::Text', qr/^\s+$/], 
			['HTML5::DOM::Element', qr/^OSX$/], 
			['HTML5::DOM::Text', qr/^\s+$/], 
			['HTML5::DOM::Element', qr/^Windows$/], 
			['HTML5::DOM::Text', qr/^\s+$/], 
			['HTML5::DOM::Element', qr/^FreeBSD$/], 
			['HTML5::DOM::Text', qr/^\s+$/], 
		], 
	}
];

for my $test (@$childrens_tests) {
	my $method = $test->{method};
	
	my $collection = $tree->at('ul')->$method;
	
	ok($collection->length == scalar(@{$test->{results}}), "$method: check length");
	
	for (my $index = 0; $index < scalar(@{$test->{results}}); ++$index) {
		my $child = $test->{results}->[$index];
		my $element = $collection->[$index];
		ok(ref($element) eq $child->[0], "$method: check result ref");
		ok($element->text =~ $child->[1], "$method: check result content");
	}
}

# finders
$tree = $parser->parse('
	<!DOCTYPE html>
	<div id="test0" some-attr="ololo trololo" class="red blue">
		<div class="yellow" id="test1"></div>
	</div>
	<div id="test2" some-attr="ololo" class="blue">
		<div class="yellow" id="test3"></div>
	</div>
	
	<span test-attr-eq="test"></span>
	<span test-attr-eq="testt"></span>
	
	<span test-attr-space="wefwef   test   wefewfew"></span>
	<span test-attr-space="wefewwef testt wewe"></span>
	
	<span test-attr-dash="test-fwefwewfe"></span>
	<span test-attr-dash="testt-"></span>
	
	<span test-attr-substr="wefwefweftestfweewfwe"></span>
	
	<span test-attr-prefix="testewfwefewwf"></span>
	
	<span test-attr-suffix="ewfwefwefweftest"></span>
');

# querySelector + at
for my $method (qw|at querySelector|) {
	isa_ok($tree->body->$method('div'), 'HTML5::DOM::Element');
	ok($tree->body->$method('div')->attr("id") eq 'test0', "$method: find div");
	ok(!defined $tree->body->$method('xuj'), "$method: not found");
}

# findId + getElementById
for my $method (qw|findId getElementById|) {
	isa_ok($tree->body->$method('test2'), 'HTML5::DOM::Element');
	ok($tree->body->$method('test2')->attr("id") eq 'test2', "$method: find #test2");
	ok(!defined $tree->body->$method('xuj'), "$method: not found");
}

# find + querySelectorAll
for my $method (qw|find querySelectorAll|) {
	isa_ok($tree->body->$method('.blue'), 'HTML5::DOM::Collection');
	isa_ok($tree->body->$method('.ewfwefwefwefwef'), 'HTML5::DOM::Collection');
	ok($tree->body->$method('.blue')->length == 2, "$method: find .blue");
	ok($tree->body->$method('.bluE')->length == 0, "$method: find .bluE");
	ok($tree->body->$method('.ewfwefwefwefwef')->length == 0, "$method: not found");
	ok($tree->body->$method('.blue')->item(1)->attr("id") eq "test2", "$method: check result element");
}

# findTag + getElementsByTagName
for my $method (qw|findTag getElementsByTagName|) {
	isa_ok($tree->body->$method('div'), 'HTML5::DOM::Collection');
	isa_ok($tree->body->$method('ewfwefwefwefwef'), 'HTML5::DOM::Collection');
	ok($tree->body->$method('div')->length == 4, "$method: find div");
	ok($tree->body->$method('dIv')->length == 4, "$method: find dIv");
	ok($tree->body->$method('ewfwefwefwefwef')->length == 0, "$method: not found");
	ok($tree->body->$method('div')->item(0)->attr("id") eq "test0", "$method: check result element");
}

# findClass + getElementsByClassName
for my $method (qw|findClass getElementsByClassName|) {
	isa_ok($tree->body->$method('blue'), 'HTML5::DOM::Collection');
	isa_ok($tree->body->$method('ewfwefwefwefwef'), 'HTML5::DOM::Collection');
	ok($tree->body->$method('blue')->length == 2, "$method: find .blue");
	ok($tree->body->$method('red')->length == 1, "$method: find .red");
	ok($tree->body->$method('bluE')->length == 0, "$method: find .bluE");
	ok($tree->body->$method('ewfwefwefwefwef')->length == 0, "$method: not found");
	ok($tree->body->$method('yellow')->item(0)->attr("id") eq "test1", "$method: check result element");
}

# findAttr + getElementByAttribute
for my $method (qw|findAttr getElementByAttribute|) {
	for my $cmp (qw(= ~ | * ^ $)) {
		for my $i ((0, 1)) {
			my $attrs = {
				'='	=> 'test-attr-eq', 
				'~'	=> 'test-attr-space', 
				'|'	=> 'test-attr-dash', 
				'*'	=> 'test-attr-substr', 
				'^'	=> 'test-attr-prefix', 
				'$'	=> 'test-attr-suffix', 
			};
			
			my $values = [['test', 'tesT'], ['tEsT', 'test2']];
			
			# test found
			my $collection = $tree->body->$method($attrs->{$cmp}, $values->[$i]->[0], $i, $cmp);
			isa_ok($collection, 'HTML5::DOM::Collection');
			ok($collection->length == 1, "$method(".$attrs->{$cmp}.", $cmp, $i): found ".$collection->length);
			
			# test not found
			$collection = $tree->body->$method($attrs->{$cmp}, $values->[$i]->[1], $i, $cmp);
			isa_ok($collection, 'HTML5::DOM::Collection');
			ok($collection->length == 0, "$method(".$attrs->{$cmp}.", $cmp, $i): not found ".$collection->length);
		}
	}
}

# getDefaultBoxType
my $test_box_type = [
	{
		element	=> $tree->createElement('script'), 
		type	=> 'none'
	}, 
	{
		element	=> $tree->createElement('span'), 
		type	=> 'inline'
	}, 
	{
		element	=> $tree->createElement('div'), 
		type	=> 'block'
	}, 
	{
		element	=> $tree->createElement('table'), 
		type	=> 'table'
	}, 
	{
		element	=> $tree->createElement('wefewfwefewwefew'), 
		type	=> 'inline'
	},
];

for my $test (@$test_box_type) {
	ok($test->{element}->getDefaultBoxType eq $test->{type}, "getDefaultBoxType: ".$test->{type});
}

# get attr
$tree = $parser->parse('
	<div id="test" test data-test="'."\n".' 123409 >^_^< '."\n".'" test-empty="" test-one="1">
		
	</div>
');
for my $method (qw|attr getAttribute attrArray|) {
	my $test = $tree->at('#test');
	
	my $method2 = $method eq 'attrArray' ? 'attr' : $method;
	
	ok(!defined $test->$method2("iwefwefwefewfwe"), "$method2 (undef)");
	
	my $attrs_test = [
		['id', 'test'], 
		['test', ''], 
		['data-test', "\n 123409 >^_^< \n"], 
		['test-empty', ''], 
		['test-one', '1'], 
	];
	
	for my $attr (@$attrs_test) {
		ok($test->$method2($attr->[0]) eq $attr->[1], "$method2(".$attr->[0].")");
	}
	
	# bulk test attr
	if ($method eq 'attr') {
		my $hash = $test->attr;
		ok(scalar(keys(%$hash)) == scalar(@$attrs_test), 'attr bulk: result length');
		
		for my $attr (@$attrs_test) {
			ok($hash->{$attr->[0]} eq $attr->[1], 'attr bulk: test '.$attr->[0]);
		}
	}
	
	# bulk test attrArray
	if ($method eq 'attrArray') {
		my $i = 0;
		
		for my $attr (@{$test->$method()}) {
			ok($attrs_test->[$i]->[0] eq $attr->{name}, 'attrArray bulk: test key '.$attr->{name}." eq ".$attrs_test->[$i]->[0]);
			ok($attrs_test->[$i]->[1] eq $attr->{value}, 'attrArray bulk: test val '.$attr->{name});
			++$i;
		}
	}
}

# remove attr
for my $method (qw|attr removeAttribute setAttribute removeAttr|) {
	$tree = $parser->parse('
		<div id="test" test data-test="'."\n".' 123409 >^_^< '."\n".'" test-empty="" test-one="1">
			
		</div>
	');
	
	my $test = $tree->at('#test');
	for my $attr (qw|id test-one test-empty data-test|) {
		my $result;
		if ($method eq 'attr' || $method eq 'setAttribute') {
			ok($test == $test->$method($attr, undef), "$method($attr, undef): return ref");
		} else {
			ok($test == $test->$method($attr), "$method($attr, undef): return ref");
		}
		ok(!defined $test->attr($attr), "$method($attr): confirm delete");
	}
}

# get attr
for my $method (qw|attr setAttribute|) {
	$tree = $parser->parse('<div></div>');
	my $test = $tree->at('div');
	
	my $attrs_test = [
		['test', ''], 
		['id', 'test'], 
		['test-one', '1'], 
		['test-empty', ''], 
		['data-test', "\n 123409 >^_^< \n"]
	];
	
	for my $attr (@$attrs_test) {
		ok($test->$method($attr->[0], $attr->[1]) == $test, "set $method(".$attr->[0].")");
		ok($test->attr($attr->[0]) eq $attr->[1], "get $method(".$attr->[0].")");
	}
}

# bulk attr set/unset
$tree = $parser->parse('
	<div id="test" test data-test="'."\n".' 123409 >^_^< '."\n".'" test-empty="" test-one="1">
		
	</div>
');

my $test_bulk_attr_set = {
	'id'			=> undef, 
	'test'			=> undef, 
	'data-test'		=> undef, 
	'test-empty'	=> undef, 
	'abcd'			=> '123', 
	'abc323d'		=> " 123 >^_^< \n\n\n", 
	'qqq'			=> 1
};

my $test_attr_el = $tree->at('#test');
ok($test_attr_el->attr($test_bulk_attr_set) == $test_attr_el, 'bulk attr set: ref');
for my $attr (keys %$test_bulk_attr_set) {
	my $val = $test_bulk_attr_set->{$attr};
	if (defined $val) {
		ok($test_attr_el->attr($attr) eq $val, 'bulk attr set: check '.$attr);
	} else {
		ok(!defined $test_attr_el->attr($attr), 'bulk attr set: check '.$attr.' (undef)');
	}
}

#####################################
# HTML5::DOM::Collection
#####################################
$tree = HTML5::DOM->new->parse('
	<ul>
	   <li>UNIX</li>
	   <li>Linux</li>
	   <!-- comment -->
	   <li>OSX</li>
	   <li>Windows</li>
	   <li>FreeBSD</li>
   </ul>
');
my $collection = $tree->find('li');
ok($collection->length == 5, 'colection: length');
ok(scalar(@{$collection}) == 5, 'colection: scalar length');
ok(scalar(@{$collection->array}) == 5, 'colection->array: length');
ok($collection->item(1) == $collection->[1], 'colection->item check');
ok($collection->first == $collection->[0], 'colection->first check');
ok($collection->last == $collection->[-1], 'colection->last check');
ok($collection->html eq "<li>UNIX</li><li>Linux</li><li>OSX</li><li>Windows</li><li>FreeBSD</li>", 'colection->html check');
ok($collection->text eq "UNIXLinuxOSXWindowsFreeBSD", 'colection->text check');

$collection->each(sub {
	my ($node, $index) = @_;
	ok($node == $collection->[$index], 'collection each ['.$index.']');
});

my $result = $collection->map(sub {
	my ($node, $index) = @_;
	ok($node == $collection->[$index], 'collection map ['.$index.']');
	return $node->text;
});

ok(join('', @$result) eq "UNIXLinuxOSXWindowsFreeBSD", 'colection map result join');
ok(join('', @{$collection->map('text')}) eq "UNIXLinuxOSXWindowsFreeBSD", 'colection map result join 2');
$collection->map('text', 1);
ok(join('', @{$collection->map('text')}) eq "11111", 'colection map result join 3');

######################################################################################
# HTML5::DOM::CSS + HTML5::DOM::CSS::Selector + HTML5::DOM::CSS::Selector::Entry
######################################################################################
my $css = HTML5::DOM::CSS->new;
isa_ok($css, 'HTML5::DOM::CSS');
can_ok($css, qw|parseSelector new|);

# parseSelector
my $selector = $css->parseSelector('div:last-child > span.red[attr=value], div, img:nth-child(2n+1), table ~ tr, div + div');
isa_ok($selector, 'HTML5::DOM::CSS::Selector');
can_ok($selector, qw|text new ast length entry|);

my $entry = $selector->entry(0);
isa_ok($entry, 'HTML5::DOM::CSS::Selector::Entry');
can_ok($entry, qw|text ast specificity specificityArray|);

# length
ok($selector->length == 5, 'css selector length');

# entry
ok(!defined $selector->entry(-1), 'css selector entry undef');
ok(!defined $selector->entry(5), 'css selector entry undef');

# text
ok($selector->text eq 'div:last-child > span.red[attr = value], div, img:nth-child(2n+1), table ~ tr, div + div', 'css selector text');
ok($selector->entry(0)->text eq 'div:last-child > span.red[attr = value]', 'css selector entry 0 text');
ok($selector->entry(4)->text eq 'div + div', 'css selector entry 5 text');

# ast
ok(ref($selector->ast) eq 'ARRAY', 'selector ast');
ok(ref($selector->entry(0)->ast) eq 'ARRAY', 'selector entry ast');

# specificity + specificityArray
my $test_specificity = {
	'*'				=> '0,0,0', 
	'a'				=> '0,0,1', 
	'#id'			=> '1,0,0', 
	'.class'		=> '0,1,0', 
	'[a=b]'			=> '0,1,0', 
	':after'		=> '0,0,1', 
	'::after'		=> '0,0,1', 
	':first-child'	=> '0,1,0', 
};

for my $selector (keys %$test_specificity) {
	my $ent = HTML5::DOM::CSS::Selector->new($selector)->entry(0);
	
	my $spec = join(",", @{$ent->specificityArray});
	ok($spec eq $test_specificity->{$selector}, "test specificityArray($selector) $spec eq ".$test_specificity->{$selector});
	
	$spec = join(",", ($ent->specificity->{a}, $ent->specificity->{b}, $ent->specificity->{c}));
	ok($spec eq $test_specificity->{$selector}, "test specificity($selector)");
}

# valid
ok(HTML5::DOM::CSS::Selector->new('')->valid == 0, 'css selector valid=0');
ok(HTML5::DOM::CSS::Selector->new('(*&*^&**%%*(')->valid == 0, 'css selector valid=0');
ok(HTML5::DOM::CSS::Selector->new('div[attr]')->valid == 1, 'css selector valid=1');

# pseudoElement
ok(HTML5::DOM::CSS::Selector->new('div:after')->entry(0)->pseudoElement eq 'after', 'css selector entry pseudoElement');
ok(!defined HTML5::DOM::CSS::Selector->new('div')->entry(0)->pseudoElement, 'css selector entry pseudoElement (undef)');


######################################################################################
# HTML5::DOM::Encoding
######################################################################################

# name2id
ok(HTML5::DOM::Encoding::name2id("UTF-8") == HTML5::DOM::Encoding->UTF_8, 'encoding name2id');
ok(!defined HTML5::DOM::Encoding::name2id("wefewf"), 'encoding name2id non exists');

# id2name
ok(HTML5::DOM::Encoding::id2name(HTML5::DOM::Encoding->UTF_8) eq "UTF-8", 'encoding id2name');
ok(!defined HTML5::DOM::Encoding::id2name(332322242424), 'encoding name2id non exists');

# detectBomAndCut
my ($encoding_id, $new_text) = HTML5::DOM::Encoding::detectBomAndCut("\xEF\xBB\xBFtest214");
ok($encoding_id == HTML5::DOM::Encoding->UTF_8, 'detectBomAndCut id');
ok($new_text eq 'test214', 'detectBomAndCut text');

# detectByCharset
$encoding_id = HTML5::DOM::Encoding::detectByCharset("text/html; charset=windows-1251");
ok($encoding_id == HTML5::DOM::Encoding->WINDOWS_1251, 'detectByCharset');

# detectByPrescanStream
$encoding_id = HTML5::DOM::Encoding::detectByPrescanStream('<meta http-equiv="content-type" content="text/html; charset=windows-1251">');
ok($encoding_id == HTML5::DOM::Encoding->WINDOWS_1251, 'detectByPrescanStream');

my $utf16 = "\x21\x04\x4a\x04\x35\x04\x48\x04\x4c\x04\x20\x00\x35\x04\x49\x04\x51\x04\x20\x00\x4d\x04\x42\x04\x38\x04\x45\x04\x20\x00\x3c\x04\x4f\x04\x33\x04\x3a\x04\x38\x04\x45\x04\x20\x00\x44\x04\x40\x04\x30\x04\x3d\x04\x46\x04\x43\x04\x37\x04\x41\x04\x3a\x04\x38\x04\x45\x04\x20\x00\x31\x04\x43\x04\x3b\x04\x3e\x04\x3a\x04\x2c\x00\x20\x00\x34\x04\x30\x04\x20\x00\x32\x04\x4b\x04\x3f\x04\x35\x04\x39\x04\x20\x00\x36\x04\x35\x04\x20\x00\x47\x04\x30\x04\x4e\x04\x2e\x00";
my $cp1251 = "\xe5\xed\xe8\x20\xee\xe3\xee\x20\xf1\xf2\xe2\x20\xed\xe8\xff\x20\xee\xe2\xe0\x20\xf2\xe5\xeb\x20\xf0\xe5\xe4\x20\xee\xf1\xf2" x 100;

# detectUnicode
$encoding_id = HTML5::DOM::Encoding::detectUnicode($utf16);
ok($encoding_id == HTML5::DOM::Encoding->UTF_16LE, 'detectUnicode');

# detect
$encoding_id = HTML5::DOM::Encoding::detect($utf16);
ok($encoding_id == HTML5::DOM::Encoding->UTF_16LE, 'detect (pass utf-16)');

# detectRussian
$encoding_id = HTML5::DOM::Encoding::detectRussian($cp1251);
ok($encoding_id == HTML5::DOM::Encoding->WINDOWS_1251, 'detectRussian');

# detect
$encoding_id = HTML5::DOM::Encoding::detect($cp1251);
ok($encoding_id == HTML5::DOM::Encoding->WINDOWS_1251, 'detect (pass cp1251)');

done_testing;

# </test-body>
