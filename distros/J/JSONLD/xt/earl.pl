use strict;
use warnings;
no warnings 'redefine';
use Scalar::Util qw(blessed);
use DateTime::Format::W3CDTF;

sub init_earl {
	my $name	= 'JSONLD';
	my $cpan_id	= $name;
	$cpan_id	=~ s/::/-/g;
	
	my $version	= do { no strict 'refs'; ${"${name}::VERSION"} };
	my $v_id	= 'v_' . $version;
	$v_id		=~ s/[.]/-/;
	
	my $out		= '';
	open( my $fh, '>', \$out );
	my $earl	= {out => \$out, fh => $fh, name => $name, version => $v_id, subject => "my:$v_id" };
	my $w3c	= DateTime::Format::W3CDTF->new;
	my $dt	= $w3c->format_datetime(DateTime->now);
	
	print {$fh} <<"END";
\@prefix doap: <http://usefulinc.com/ns/doap#> .
\@prefix earl: <http://www.w3.org/ns/earl#> .
\@prefix foaf: <http://xmlns.com/foaf/0.1/> .
\@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
\@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
\@prefix xml: <http://www.w3.org/XML/1998/namespace> .
\@prefix dct: <http://purl.org/dc/terms/> .
\@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
\@prefix my: <http://purl.org/NET/cpan-uri/dist/${cpan_id}/> .

<> foaf:primaryTopic my:project ;
	dct:issued "${dt}"^^xsd:dateTime ;
	foaf:maker <http://kasei.us/about/#greg> ;
	.

my:project
	a doap:Project ;
	doap:name "${name}" ;
	doap:description "Perl module ${name}" ;
	doap:homepage <http://metacpan.org/dist/${cpan_id}/> ;
	doap:developer <http://kasei.us/about/#greg> ;
	doap:programming-language "Perl" ;
	doap:release my:$v_id ;
	.

my:$v_id a doap:Version ;
	doap:name "${name} $version" ;
	doap:revision "$version" ;
	.

<http://kasei.us/about/#greg> a foaf:Person ;
	foaf:name "Gregory Todd Williams" ;
	foaf:mbox <mailto:gwilliams\@cpan.org> ;
	foaf:mbox_sha1sum "f80a0f19d2a0897b89f48647b2fb5ca1f0bc1cb8" ;
	foaf:homepage <http://kasei.us/> ;
	.

my:test-harness
	a earl:Software ;
	dct:title "${name} test harness" ;
	foaf:maker <http://kasei.us/about/#greg> ;
	.

END
	return $earl;
}

sub earl_pass_test {
	my $earl	= shift;
	my $test	= shift;
	my $subject	= $earl->{subject};
	
	print {$earl->{fh}} <<"END";
[] a earl:Assertion;
	earl:assertedBy my:test-harness ;
	earl:result [
		a earl:TestResult ;
		earl:outcome earl:passed
	] ;
	earl:subject $subject ;
	earl:test <$test> .
END
}

sub earl_fail_test {
	my $earl	= shift;
	my $test	= shift;
	my $msg		= shift;
	my $subject	= $earl->{subject};

	no warnings 'uninitialized';
	$msg		=~ s/\n/\\n/g;
	$msg		=~ s/\t/\\t/g;
	$msg		=~ s/\r/\\r/g;
	$msg		=~ s/"/\\"/g;
	
	print {$earl->{fh}} <<"END";
[] a earl:Assertion;
	earl:assertedBy my:test-harness ;
	earl:result [
		a earl:TestResult ;
		earl:outcome earl:failed ;
END
	print {$earl->{fh}} qq[\t\trdfs:comment "$msg" ;\n] if (defined $msg);
	print {$earl->{fh}} <<"END";
	] ;
	earl:subject $subject ;
	earl:test <$test> ;
	.

END
}

sub earl_output {
	my $earl	= shift;
	close($earl->{fh});
	return ${ $earl->{out} };
}

1;

__END__

