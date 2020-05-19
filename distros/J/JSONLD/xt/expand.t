use v5.14;
use strict;
use warnings;
use autodie;
use utf8;
use Carp qw(confess);
use Test::More;
use Test::Exception;
use FindBin qw($Bin);
use File::Glob qw(bsd_glob);
use File::Spec;
use JSON;
use Data::Compare;
use Data::Dumper;
use JSONLD;
use B qw(svref_2object SVf_IOK SVf_POK SVf_NOK SVf_IOK);
use open ':std', ':encoding(UTF-8)';
use Data::Compare;
use Clone 'clone';
use Storable qw(freeze);
use Devel::Peek;
use lib qw(.);
require "xt/earl.pl";

use Moo;
use Type::Tiny::Role;

our $debug	= 0;
$JSONLD::debug	= $debug;
our $PATTERN;
if ($debug) {
	$PATTERN = qr/t0034/;
} else {
	$PATTERN	= qr/./;
}

my $REPORT_NEGATIVE_TESTS	= 1;

sub load_json {
	my $file	= shift;
	open(my $fh, '<:utf8', $file);
	my $j	= JSON->new()->canonical(1);
	return $j->decode(do { local($/); <$fh> });
}

sub _is_numeric {
	my $v	= shift;
	return 0 unless defined($v);
	return 0 if ref($v);
	my $sv	= svref_2object(\$v);
	my $flags	= $sv->FLAGS;
	my $is_num	= (($flags & SVf_NOK) or ($flags & SVf_IOK));
	return $is_num;
}


sub _normalize {
	# give array elements a predictable order (https://w3c.github.io/json-ld-api/tests/#json-ld-object-comparison)
	my $data			= shift;
	my $preserve_order	= shift || 0;
	if (not ref($data)) {
		if (_is_numeric($data)) {
			return 1.0 * $data;
		} else {
			return $data;
		}
	} elsif (ref($data) eq 'JSON::PP::Boolean') {
		my $bool	= ($data) ? 1 : 0;
		return \$bool;
	} elsif (ref($data) eq 'ARRAY') {
		my @v		= map { _normalize($_, 0) } @$data;
		unless ($preserve_order) {
			local($Storable::canonical)	= 1;
			@v	= map { $_->[0] }
				sort { $a->[1] cmp $b->[1] }
					map { [$_, freeze([$_])] } @v;
# 					map { Dump(freeze([$_])); [$_, freeze([$_])] } @v;
		}
		return [@v];
	} elsif (ref($data) eq 'HASH') {
		my %hash;
		foreach my $k (keys %$data) {
			my $preserve_order	= ($k eq '@list');
			$hash{$k}	= _normalize(clone($data->{$k}), $preserve_order);
		}
		return \%hash;
	} else {
		die "Unexpected ref type: " . ref($data);
	}
}

$Data::Dumper::Sortkeys	= 1;
my $component	= 'expand';
my $earl		= init_earl();
my $path		= File::Spec->catfile( $Bin, 'data', 'json-ld-api-w3c' );
my $manifest	= File::Spec->catfile($path, "${component}-manifest.jsonld");
my $d			= load_json($manifest);
my $base_url	= "https://w3c.github.io/json-ld-api/tests/${component}-manifest";
my $jj			= JSONLD->new(base_iri => IRI->new('file://' . $manifest));

my $tests	= $d->{'sequence'};
my $base	= IRI->new(value => $d->{'baseIri'} // 'http://example.org/');
foreach my $t (@$tests) {
	my $id		= $t->{'@id'};
	next unless ($id =~ $PATTERN);
	my $test_iri	= $jj->expand($t, expandContext => [{'@base' => $base_url}, 'context.jsonld'])->[0]{'@id'};
	
	my $input	= $t->{'input'};
	my $expect	= $t->{'expect'} // '';
	my $name	= $t->{'name'};
	my $purpose	= $t->{'purpose'};
	my $options	= $t->{'option'} // {};
	my $_base	= $options->{'base'};
	my $spec_v	= $options->{'specVersion'} // '';
	my $mode	= $options->{'processingMode'} // 'json-ld-1.1';
	my @types	= @{ $t->{'@type'} };
	my %types	= map { $_ => 1 } @types;
	my $infile		= File::Spec->catfile($path, $input);
	my %args;
	if (my $expand = $options->{'expandContext'}) {
		warn "Expand Context: $expand\n" if ($debug);
		my $base	= IRI->new(value => 'file://' . $manifest);
		my $iri		= IRI->new(value => $expand, base => $base);
		$args{'expandContext'}	= $iri->abs;
	}

	my $test_base;
	if (defined($_base)) {
		$test_base	= IRI->new(value => $_base, base => $base)->abs;
	} else {
		$test_base	= IRI->new(value => $input, base => $base)->abs;
	}
	my $j		= JSON->new->canonical(1);
	note($id) if $debug;
	SKIP: {
		skip("skipping IGNORING JSON-LD-1.0-only test $id", 1) if ($spec_v eq 'json-ld-1.0');
		if ($types{'jld:PositiveEvaluationTest'} or $types{'jld:NegativeEvaluationTest'}) {
			my $positive	= $types{'jld:PositiveEvaluationTest'};
			my $jld			= JSONLD->new(base_iri => IRI->new($test_base), processing_mode => $mode);
			my $infile		= File::Spec->catfile($path, $input);
			my $outfile		= File::Spec->catfile($path, $expect);
			my $data		= load_json($infile);
			if ($debug) {
				warn "Input file: $infile\n";
				warn "INPUT:\n===============\n" . JSON->new->pretty->encode($data); # Dumper($data);
			}
			my $expanded	= eval { $jld->expand($data, %args) };
			if ($@) {
				if ($positive) {
					earl_fail_test( $earl, $test_iri, $@ );
					fail("$id: $@")
				} else {
					if ($REPORT_NEGATIVE_TESTS) {
						earl_pass_test( $earl, $test_iri );
						pass("$id: NegativeEvaluationTest");
					}
				}
			} else {
				my $got			= _normalize($expanded);
				if ($positive) {
					my $expected	= _normalize(load_json($outfile));
					if ($debug) {
						my @data	= (
							['EXPECTED', $expected],
							['OUTPUT__', $got],
						);
						my @files;
						foreach my $d (@data) {
							my ($name, $data)	= @$d;
							warn "=======================\n";
							my $filename	= "/tmp/json-ld-$$-$name.out";
							open(my $fh, '>', $filename) or die $!;
							push(@files, $filename);
							my $out	= Data::Dumper->Dump([$data], ["*$name"]);
							warn $out;
							print {$fh} $out;
							close($fh);
						}
						unless (Compare($got, $expected)) {
							system('/usr/local/bin/bbdiff', '--wait', '--resume', @files);
						}
					}
					my $pass	= ok(Compare($got, $expected), "$id: $name");
					if ($pass) {
						earl_pass_test( $earl, $test_iri );
					} else {
						earl_fail_test( $earl, $test_iri, 'computed value differes from expected value' );
					}
				} else {
					if ($REPORT_NEGATIVE_TESTS) {
						earl_fail_test( $earl, $test_iri, 'expected failure but found success' );
						fail("$id: expected failure but found success");
						my $out	= Data::Dumper->Dump([$j->decode($got)], ["got"]);
						warn $out;
					}
				}
			}
		} else {
			diag("Not a recognized evaluation test: " . Dumper(\@types));
			next;
		}
	}
}

done_testing();

unless ($debug) {
	my $output	= earl_output($earl);
	open(my $fh, '>:utf8', "jsonld-${component}-earl.ttl") or die $!;
	print {$fh} $output;
	close($fh);
}
