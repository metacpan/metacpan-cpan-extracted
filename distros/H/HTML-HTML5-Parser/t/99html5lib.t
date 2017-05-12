## skip Test::Tabs
use Test::More;
use HTML::HTML5::Parser;

BEGIN {
	eval { require Moo; 1 } or plan skip_all => 'Need Moo!'
};

{
	package XML::LibXML::Document;
	sub pythonDebug
	{
		my $self = shift;
		my ($indent, $parser) = @_;
		$indent = '' unless defined $indent;
		
		my $return;
		
		my $element = $parser->dtd_element($self);
		my $public  = $parser->dtd_public_id($self) || '';
		my $system  = $parser->dtd_system_id($self) || '';
		
		if (defined $element)
		{
			$return = sprintf(
				"| <!DOCTYPE %s%s%s>\n",
				$element,
				(($public||$system) ? " \"$public\"" : ""),
				(($public||$system) ? " \"$system\"" : ""),
				);
		}
		
		$return .= $_->pythonDebug(q{| }, $parser) foreach $self->childNodes;
		return $return;
	}
}

{
	package XML::LibXML::DocumentFragment;
	sub pythonDebug
	{
		my $self = shift;
		my ($indent, $parser) = @_;
		$indent = '' unless defined $indent;
		
		$self->normalize;
		
		my $return;
		foreach ($self->childNodes)
		{
			$return .= $_->pythonDebug($indent . q{| }, $parser);
		}		
		return $return;
	}
}

{
	package XML::LibXML::Element;
	sub pythonDebug
	{
		my $self = shift;
		my ($indent, $parser) = @_;
		$indent = '' unless defined $indent;
		
		$self->normalize;
		
		my $nsbit  = '';
		$nsbit = 'svg ' if $self->namespaceURI =~ /svg/i;
		$nsbit = 'math ' if $self->namespaceURI =~ /math/i;
		my $return = sprintf("%s<%s%s>\n", $indent, $nsbit, $self->localname);
		
		my @attribs = 
			sort { $a->localname cmp $b->localname }
			grep { not $_->isa('XML::LibXML::Namespace') }
			$self->attributes;
		foreach (@attribs)
		{
			$return .= $_->pythonDebug($indent . q{  }, $parser);
		}
		
		if ($self->localname eq 'noscript')
		{
			my $innerHTML = join q{}, map { $_->toString } $self->childNodes;
			$return .= $indent . q{  "} . $innerHTML . "\"\n";
		}
		else
		{
			foreach ($self->childNodes)
			{
				$return .= $_->pythonDebug($indent . q{  }, $parser);
			}
		}
		
		return $return;
	}
}

{
	package XML::LibXML::Text;
	sub pythonDebug
	{
		my $self = shift;
		my ($indent, $parser) = @_;
		$indent = '' unless defined $indent;
		
		return sprintf("%s\"%s\"\n", $indent, $self->data);
	}
}

{
	package XML::LibXML::Comment;
	sub pythonDebug
	{
		my $self = shift;
		my ($indent, $parser) = @_;
		$indent = '' unless defined $indent;
		
		return sprintf("%s<!-- %s -->\n", $indent, $self->data);
	}
}

{
	package XML::LibXML::Attr;
	sub pythonDebug
	{
		my $self = shift;
		my ($indent, $parser) = @_;
		$indent = '' unless defined $indent;
		
		return sprintf("%s%s %s=\"%s\"\n", $indent, split(/:/, $self->nodeName), $self->value)
			if $self->namespaceURI && $self->nodeName=~/:/;
		return sprintf("%s%s=\"%s\"\n", $indent, $self->localname, $self->value);
	}
}

{
	package Local::HTML5Lib::Test;
	
	use Moo;
	
	has test_file         => (is => 'rw');
	has test_number       => (is => 'rw');
	has data              => (is => 'rw');
	has errors            => (is => 'rw');
	has document          => (is => 'rw');	
	has document_fragment => (is => 'rw');
	has parser            => (is => 'lazy', builder => '_build_parser');
	
	sub test_id
	{
		my $self = shift;
		if ($self->test_file->filename =~ m{ / ([^/]+) $ }x)
		{
			sprintf('%s:%s', $1, $self->test_number||1);
		}
	}
	
	sub dom
	{
		my ($self) = @_;
		
		if ($self->document_fragment)
		{
			return $self->parser->parse_balanced_chunk(
				$self->data,
				{within => $self->document_fragment},
			);
		}
		
		return eval {
			$self->parser->parse_string($self->data);
		} || do {
			my $e   = $@;
			my $xml = 'XML::LibXML::Document'->new('1.0', 'utf-8');
			$xml->setDocumentElement( $xml->createElementNS('http://www.w3.org/1999/xhtml', 'html') );
			$xml->documentElement->appendText("ERROR: $e");
			$xml;
		}
	}
	
	sub _build_parser
	{
		require HTML::HTML5::Parser;
		'HTML::HTML5::Parser'->new;
	}
	
	sub __uniscape
	{
		my $str = shift;
		eval {
			$str =~ s{ ([^\n\x20-\x7E]) }{ sprintf('\x{%04X}', ord($1)) }gex;
		};
		$str;
	}
	
	sub run
	{
		my ($self) = @_;
		my $expected = $self->document."\n";
		my $got      = $self->dom->pythonDebug(undef, $self->parser);
		utf8::decode($got);
		
		local $Test::Builder::Level = $Test::Builder::Level + 1;
		
		SKIP: {
			my $excuse = $::SKIP->{ $self->test_id };
			Test::More::skip($excuse, 1) if defined $excuse;
			
			if ($got eq $expected)
			{
				Test::More::pass("DATA: ".$self->data);
				return 1;
			}
			else
			{
				Test::More::fail("DATA: ".$self->data);
				Test::More::diag("ID: ".$self->test_id);
				Test::More::diag("GOT:\n" . __uniscape $got);
				Test::More::diag("EXPECTED:\n" . __uniscape $expected);
				return 0;
			}
		}
	}
}
	
{
	package Local::HTML5Lib::TestFile;
	
	use Moo;
	
	has filename   => (is => "rw");
	has tests      => (is => "rw");
	has last_score => (is => "rw");
	
	sub read_file
	{
		my ($class, $filename) = @_;
		
		my $self = $class->new(
			filename  => $filename,
			);
			
		my @tests;
		
		open my $fh, '<', $filename;
		push @tests, (my $current_test = { test_file=>$self });
		my $current_key;
		my @lines = <$fh>; # sometimes we need to peek at the next line;
		while (defined ($_ = shift @lines))
		{
			no warnings;
			
			if (!/\S/ and (!defined $lines[0] or $lines[0]=~ /^\#data/))
			{
				$current_test->{test_number} = @tests;
				chomp $current_test->{$current_key} if defined $current_key;
				$current_test = { test_file=>$self };
				$current_key  = undef;
				push @tests, $current_test;
				next;
			}
			
			if (/^\#(.+)/)
			{
				chomp $current_test->{$current_key} if defined $current_key;
				($current_key = $1) =~ s/-/_/g;
				next;
			}
		
			$current_test->{$current_key} .= $_;
		}

		chomp $current_test->{$current_key};
		
		$self->tests([ map {
			utf8::decode($_->{document});
			utf8::decode($_->{data});
			Local::HTML5Lib::Test->new(%$_);
			} @tests]);
		return $self;
	}

	sub run
	{
		local $Test::Builder::Level = $Test::Builder::Level + 1;

		my $self = shift;
		$self->{last_score} = 0;
		Test::More::subtest(
			sprintf("Test file: %s", $self->filename),
			sub {	$self->{last_score} += ($_->run ? 1 : 0) for @{ $self->tests } },
			);
	}
}

package main;

our $SKIP = {
	'tests26.dat:10'
		=> 'requires HTML parser to construct a DOM tree which is illegal in libxml (bad attribute name)',
	'webkit01.dat:14'
		=> 'requires HTML parser to construct a DOM tree which is illegal in libxml (bad element name)',
	'webkit01.dat:42'
		=> 'requires HTML parser to construct a DOM tree which is illegal in libxml (bad attribute name)',
	'webkit02.dat:4'
		=> 'I basically just disagree with this test.',
	'html5test-com.dat:1'
		=> 'requires HTML parser to construct a DOM tree which is illegal in libxml (bad element name)',
	'html5test-com.dat:2'
		=> 'requires HTML parser to construct a DOM tree which is illegal in libxml (bad attribute name)',
	'html5test-com.dat:4'
		=> 'requires HTML parser to construct a DOM tree which is illegal in libxml (bad attribute name)',
	};

my @fails;
my @passes;

unless (@ARGV)
{
	@ARGV = <t/html5lib-pass/*.dat>;
}

plan tests => scalar(@ARGV);

while (my $f = shift)
{
	my $F = Local::HTML5Lib::TestFile->read_file($f);
	if ($F->run)
	{
		push @passes, $F;
	}
	else
	{
		push @fails, $F;
	}
}

if (@fails)
{
	diag "FAILED:";
	diag sprintf("  %s [%d/%d]", $_->filename, $_->last_score, scalar(@{$_->tests}))
		for @fails;
}

if (@passes)
{
	diag "PASSED:";
	diag sprintf("  %s [%d/%d]", $_->filename, $_->last_score, scalar(@{$_->tests}))
		for @passes;
}

=head1 PURPOSE

Tests from html5lib's testdata/tree-construction.

=head1 SEE ALSO

L<http://code.google.com/p/html5lib/source/browse/testdata/tree-construction>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
