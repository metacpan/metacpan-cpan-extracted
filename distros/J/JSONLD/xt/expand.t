use v5.14;
use autodie;
use utf8;
use Carp qw(confess);
use Test::More;
use Test::Exception;
use FindBin qw($Bin);
use File::Glob qw(bsd_glob);
use File::Spec;
use JSON qw(decode_json);
use Data::Dumper;
use JSONLD;
use open ':std', ':encoding(UTF-8)';

use Moo;
use Type::Tiny::Role;

our $debug	= 0;
$JSONLD::debug	= $debug;
our $PATTERN;
if ($debug) {
	$PATTERN = qr/t0104/;
} else {
	$PATTERN	= /./;
}

my $REPORT_NEGATIVE_TESTS	= 0;

sub load_json {
	my $file	= shift;
	open(my $fh, '<:utf8', $file);
	my $j	= JSON->new();
	return $j->decode(do { local($/); <$fh> });
}

sub _normalize {
	# give array elements a predictable order (https://w3c.github.io/json-ld-api/tests/#json-ld-object-comparison)
	my $data			= shift;
	my $preserve_order	= shift || 0;
	return $data unless (ref($data));
	if (ref($data) eq 'ARRAY') {
		my $j		= JSON->new->canonical(1);
		my @v		= map { _normalize($_) } @$data;
		unless ($preserve_order) {
			@v	= sort { $j->encode($a) cmp $j->encode($b) } @v;
		}
		return [@v];
	} elsif (ref($data) eq 'HASH') {
		my %hash;
		foreach my $k (keys %$data) {
			my $preseve_order	= ($k eq '@list');
			$hash{$k}	= _normalize($data->{$k}, $preseve_order);
		}
		return \%hash;
	} else {
		die "Unexpected ref type: " . ref($data);
	}
}

$Data::Dumper::Sortkeys	= 1;
my $path	= File::Spec->catfile( $Bin, 'data', 'json-ld-api-w3c' );
my $manifest	= File::Spec->catfile($path, 'expand-manifest.jsonld');
my $d		= load_json($manifest);
my $tests	= $d->{'sequence'};
my $base	= IRI->new(value => $d->{'baseIri'} // 'http://example.org/');
foreach my $t (@$tests) {
	my $id		= $t->{'@id'};
	next unless ($id =~ $PATTERN);
	
	my $input	= $t->{'input'};
	my $expect	= $t->{'expect'} // '';
	my $name	= $t->{'name'};
	my $purpose	= $t->{'purpose'};
	my $options	= $t->{'option'} // {};
	my $_base	= $options->{'base'};
	my $spec_v	= $options->{'specVersion'} // '';
	my @types	= @{ $t->{'@type'} };
	my %types	= map { $_ => 1 } @types;
	my %args;
	if (my $expand = $options->{'expandContext'}) {
		$args{'expandContext'}	= $expand;
	}

	my $test_base;
	if (defined($_base)) {
		$test_base	= IRI->new(value => $_base, base => $base)->abs;
	} else {
		$test_base	= IRI->new(value => $input, base => $base)->abs;
	}
	my $j		= JSON->new->canonical(1);
	note($id) if $debug;
	if ($spec_v eq 'json-ld-1.0') {
		diag("IGNORING JSON-LD-1.0-only test $id\n");
	} elsif ($types{'jld:PositiveEvaluationTest'} or $types{'jld:NegativeEvaluationTest'}) {
		my $positive	= $types{'jld:PositiveEvaluationTest'};
		my $jld			= JSONLD->new(base_iri => IRI->new($test_base));
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
				fail("$id: $@")
			} else {
				if ($REPORT_NEGATIVE_TESTS) {
					pass("$id: NegativeEvaluationTest");
				}
			}
		} else {
			my $got			= _normalize($j->encode($expanded));
			if ($positive) {
				my $expected	= _normalize($j->encode(load_json($outfile)));
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
						my $out	= Data::Dumper->Dump([$j->decode($data)], ["*$name"]);
						warn $out;
						print {$fh} $out;
						close($fh);
					}
					unless ($got eq $expected) {
						system('/usr/local/bin/bbdiff', '--wait', '--resume', @files);
					}
				}
				is($got, $expected, "$id: $name");
			} else {
				if ($REPORT_NEGATIVE_TESTS) {
					fail("$id: expected failure but found success");
				}
			}
		}
	} else {
		diag("Not a recognized evaluation test: " . Dumper(\@types));
		next;
	}
}

done_testing();
