use Test::More;

use_ok( 'HTTP::OAI' );
use_ok( 'HTTP::OAI::Metadata::OAI_DC' );
use XML::LibXML;

my $expected = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd"><responseDate>0000-00-00T00:00:00Z</responseDate><request>http://localhost/path/script</request><GetRecord><record><header status="deleted"><identifier>oai:arXiv.org:acc-phys/9411001</identifier><datestamp>2004-06-22T17:51:18Z</datestamp><setSpec>a:a</setSpec><setSpec>a:b</setSpec></header><metadata><oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
<dc:title>Symplectic Computation of Lyapunov Exponents</dc:title>
<dc:creator>Habib, Salman</dc:creator>
<dc:creator>Ryne, Robert D.</dc:creator>
<dc:subject>Accelerator Physics</dc:subject>
<dc:description>A recently developed method for the calculation of Lyapunov exponents of dynamical systems is described. The method is applicable whenever the linearized dynamics is Hamiltonian. By utilizing the exponential representation of symplectic matrices, this approach avoids the renormalization and reorthogonalization procedures necessary in usual techniques. It is also easily extendible to damped systems. The method is illustrated by considering two examples of physical interest: a model system that describes the beam halo in charged particle beams and the driven van der Pol oscillator.</dc:description>
<dc:description>Comment: 12 pages, uuencoded PostScript (figures included)</dc:description>
<dc:date>1994-10-31</dc:date>
<dc:type>text</dc:type>
<dc:identifier>http://arXiv.org/abs/acc-phys/9411001</dc:identifier>
</oai_dc:dc></metadata></record></GetRecord></OAI-PMH>
EOF

my $r = new HTTP::OAI::GetRecord(
	requestURL=>'http://localhost/path/script',
	responseDate=>'0000-00-00T00:00:00Z'
);

my $rec = new HTTP::OAI::Record();
my $str_header = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<header status="deleted">
<identifier>oai:arXiv.org:acc-phys/9411001</identifier>
<datestamp>2004-06-22T17:51:18Z</datestamp>
<setSpec>a:a</setSpec>
<setSpec>a:b</setSpec>
</header>
EOF
$rec->header->dom(XML::LibXML->new()->parse_string($str_header));
ok($rec->identifier eq 'oai:arXiv.org:acc-phys/9411001', 'header/identifier');
ok($rec->datestamp eq '2004-06-22T17:51:18Z', 'header/datestamp');
ok($rec->status eq 'deleted', 'header/status');
my @sets = $rec->header->setSpec;
ok($sets[0] eq 'a:a', 'header/setSpec');

my $str = <<EOF;
<metadata>
<oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
<dc:title>Symplectic Computation of Lyapunov Exponents</dc:title>
<dc:creator>Habib, Salman</dc:creator>
<dc:creator>Ryne, Robert D.</dc:creator>
<dc:subject>Accelerator Physics</dc:subject>
<dc:description>A recently developed method for the calculation of Lyapunov exponents of dynamical systems is described. The method is applicable whenever the linearized dynamics is Hamiltonian. By utilizing the exponential representation of symplectic matrices, this approach avoids the renormalization and reorthogonalization procedures necessary in usual techniques. It is also easily extendible to damped systems. The method is illustrated by considering two examples of physical interest: a model system that describes the beam halo in charged particle beams and the driven van der Pol oscillator.</dc:description>
<dc:description>Comment: 12 pages, uuencoded PostScript (figures included)</dc:description>
<dc:date>1994-10-31</dc:date>
<dc:type>text</dc:type>
<dc:identifier>http://arXiv.org/abs/acc-phys/9411001</dc:identifier>
</oai_dc:dc>
</metadata>
EOF
$rec->metadata(new HTTP::OAI::Metadata());
$rec->metadata->parse_string($str);

$r->record($rec);

{
	# hopefully if we can re-parse our own output we're ok, because we can't
	# compare against the ever changing XML output
	my $str = $r->toDOM->toString;
	my $_r = HTTP::OAI::GetRecord->new(handlers=>{
		metadata=>'HTTP::OAI::Metadata::OAI_DC'
	});
	$_r->parse_string($str);
	is($_r->record->metadata->dc->{creator}->[1], 'Ryne, Robert D.', 'toDOM');
}

SKIP: {
	eval { require XML::SAX::Writer };

	skip "XML::SAX::Writer not installed", 1 if $@;

	my $output;
	my $w = XML::SAX::Writer->new(Output=>\$output);

	my $driver = HTTP::OAI::SAX::Driver->new(
			Handler => my $builder = XML::LibXML::SAX::Builder->new()
		);
	$driver->start_oai_pmh();

	$r->set_handler($w);
	$r->xslt( "/path/to/OAI.xslt" );

	$r->generate($driver);

	$driver->end_oai_pmh();

	my $xml = $builder->result;

	ok($xml, 'got XML output');

	like $xml , qr{<\?xml-stylesheet type='text/xsl' href='/path/to/OAI.xslt'\?>} , 'found the stylesheet';
}

done_testing;
