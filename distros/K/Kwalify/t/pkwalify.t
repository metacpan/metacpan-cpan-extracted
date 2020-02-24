#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use Getopt::Long;

BEGIN {
    if (!eval q{
	use Test::More;
	use File::Temp;
	use File::Spec 0.8; # rel2abs
	1;
    }) {
	print "1..0 # skip: no Test::More, File::Spec and/or File::Temp modules\n";
	exit;
    }
}

require blib; # just to get blib's VERSION
my $skip_warnings_test = $blib::VERSION < 1.01;

# Test cases with single documents
my @yaml_mod_defs = (
		      ["schema05.yaml", "document05a.yaml", 1],
		      ["schema05.yaml", "document05b.yaml", 0],
		    );

# Test cases with multiple documents (by combining single documents)
my %combined_document;
{
    for my $def (["invalid_diff",   "document05a.yaml", "document05b.yaml"],
		 ["valid_same",     "document05a.yaml", "document05a.yaml"],
		 ["invalid_same",   "document05b.yaml", "document05b.yaml"],
		 ["invalid_schema", "schema05.yaml", "schema05.yaml"],
		) {
	my($newname, @yaml) = @$def;

	my($fh,$outfile) = File::Temp::tempfile(SUFFIX => ".yaml",
						UNLINK => 1);
	if (!$fh) {
	    die "Cannot create temporary file: $!";
	}

	# fix possible problem if somebody sets TMPDIR=.
	$outfile = File::Spec->rel2abs($outfile)
	    if !File::Spec->file_name_is_absolute($outfile);

	for my $document (@yaml) {
	    print $fh "--- \n";
	    {
		open IN, "$FindBin::RealBin/testdata/$document"
		    or die $!;
		local $/ = undef;
		print $fh <IN>;
		close IN;
	    }
	}

	$combined_document{$newname} = $outfile;
	close $fh;
    }
}

# Test cases for YAML/YAML::XS/YAML::Syck (schema+document combinations)
push @yaml_mod_defs, (
		       [$combined_document{"invalid_schema"}, "document05a.yaml", 0],
		       ["schema05.yaml", $combined_document{"invalid_diff"}, 0],
		       ["schema05.yaml", $combined_document{"valid_same"}, 1],
		       ["schema05.yaml", $combined_document{"invalid_same"}, 0],
		      );

my $can_yaml = (eval { require YAML::Syck; 1 } || eval { require YAML::XS; 1 } || eval { require YAML; 1 });
if ($can_yaml) {
    *YAML_LoadFile = defined &YAML::Syck::LoadFile ? \&YAML::Syck::LoadFile : defined &YAML::XS::LoadFile ? \&YAML::XS::LoadFile : \&YAML::LoadFile;
}
my $can_json = (eval { require JSON::XS; 1 }   || eval { require JSON; 1 });
if ($can_json) {
    *JSON_encode   = defined &JSON::XS::encode_json ? \&JSON::XS::encode_json : \&JSON::encode_json;
}

# Test cases for JSON (generated from YAML documents)
my @json_defs = ();
if ($can_yaml && $can_json) {
    my %json_equivalent;
    for my $file ('schema05.yaml',  'document05a.yaml', 'document05b.yaml') {
	my($tmpfh,$tmpfile) = File::Temp::tempfile(SUFFIX => '.json',
						   UNLINK => 1);
	my $data = YAML_LoadFile("$FindBin::RealBin/testdata/$file");
	print $tmpfh JSON_encode($data);
	close $tmpfh
	    or die "Can't write JSON data to $tmpfile: $!";
	$json_equivalent{$file} = $tmpfile;
    }
    push @json_defs, ([$json_equivalent{'schema05.yaml'}, $json_equivalent{'document05a.yaml'}, 1],
		      [$json_equivalent{'schema05.yaml'}, $json_equivalent{'document05b.yaml'}, 0],
		     );
}

my $v;
GetOptions("v!")
    or die "usage: $0 [-v]";

my $tests_per_case = 3;
plan tests => 13 + $tests_per_case*(scalar(@yaml_mod_defs) + scalar(@json_defs));

my $script = "$FindBin::RealBin/../blib/script/pkwalify";
my @cmd = ($^X, "-Mblib=$FindBin::RealBin/..", $script, "-s");

SKIP: {
    skip("Need YAML, YAML::XS or YAML::Syck for tests", $tests_per_case*scalar(@yaml_mod_defs))
	if !$can_yaml;

    for my $def (@yaml_mod_defs) {
	any_test($def);
    }
}

SKIP: {
    skip("Need JSON or JSON::XS for tests", $tests_per_case*scalar(@json_defs))
	if !$can_json;

    for my $def (@json_defs) {
	any_test($def);
    }
}

{
    my $result = run_pkwalify();
    is($result->{success}, 0, "No success without options");
 SKIP: {
	skip("Skip STDERR test", 1) if !$result->{can_capture};
	like($result->{stderr}, qr{-f option is mandatory}, "usage -f");
    }
}

{
    my $result = run_pkwalify("-xxx");
    is($result->{success}, 0, "Invalid option");
 SKIP: {
	skip("Skip STDERR test", 1) if !$result->{can_capture};
	like($result->{stderr}, qr{usage}, "got usage");
    }
}

{
    my $result = run_pkwalify("-f", "foo");
    is($result->{success}, 0, "Missing data file");
 SKIP: {
	skip("Skip STDERR test", 1) if !$result->{can_capture};
	like($result->{stderr}, qr{datafile is mandatory}, "usage datafile");
    }
}

{
    my $result = run_pkwalify("-f", $0, $0);
    is($result->{success}, 0, "No YAML/JSON file");
 SKIP: {
	skip("Skip STDERR test", 1) if !$result->{can_capture};
	like($result->{stderr}, qr{cannot parse}i, "cannot parse file");
    }
}

SKIP: {
    skip("Need YAML, YAML::XS or YAML::Syck for tests", 4)
	if !$can_yaml;

    my $schema_file = "schema05.yaml";
    my $data_file   = "document05a.yaml";
    for ($schema_file, $data_file) {
	if (!File::Spec->file_name_is_absolute($_)) {
	    $_ = "$FindBin::RealBin/testdata/$_";
	}
    }

    {
	my @args = ('-f', $schema_file, $data_file, '-s');
	my $result = run_pkwalify_non_silent(@args);
	is($result->{success}, 1, "Success with -s");
    SKIP: {
	    skip("Skip STDOUT test", 1) if !$result->{can_capture};
	    is($result->{stdout}, "", "silent output");
	}
    }

    {
	my @args = ('-f', $schema_file, $data_file);
	my $result = run_pkwalify_non_silent(@args);
	is($result->{success}, 1, "Success without -s");
    SKIP: {
	    skip("Skip STDOUT test", 1) if !$result->{can_capture};
	    like($result->{stdout}, qr{\Q: valid.}, "non-silent output for validity");
	}
    }
}

sub any_test {
    my($def) = @_;
    local $Test::Builder::Level = $Test::Builder::Level+1;
    my($schema_file, $data_file, $expect_validity) = @$def;
    for ($schema_file, $data_file) {
	if (!File::Spec->file_name_is_absolute($_)) {
	    $_ = "$FindBin::RealBin/testdata/$_";
	}
    }
    
    my @args = ('-f' => $schema_file, $data_file);

    my $result = run_pkwalify(@args);

    my($valid, $stdin, $stdout, $stderr, $can_capture) =
	@{$result}{qw(success stdin stdout stderr can_capture)};

    if ($can_capture) {
	if (!$valid) {
	    diag "STDOUT=$stdout\nSTDERR=$stderr\n" if $v;
	}
    SKIP: {
	    skip("Older blib versions write to STDERR", 2)
		if $skip_warnings_test;
	    if ($valid) {
		is($stdout, "", "No warnings in @args");
	    } else {
		isnt($stdout, "", "There are warnings in @args");
	    }
	    is($stderr, "", "Nothing in STDERR");
	}
    } else {
    SKIP: { skip("No stdout/stderr tests without IPC::Run", 2) }
    }
    is($valid, $expect_validity, "@args")
	or diag("@args");
}

sub _run_pkwalify {
    my(@cmd) = @_;
    my($success,$stdin,$stdout,$stderr,$can_capture);
    if (eval { require IPC::Run; 1 }) {
	$can_capture = 1;
	$success = IPC::Run::run(\@cmd, \$stdin, \$stdout, \$stderr) ? 1 : 0;
    } else {
	*OLDOUT = *OLDOUT; # cease -w
	*OLDERR = *OLDERR; # cease -w
	open(OLDOUT, ">&STDOUT") or die $!;
	open(OLDERR, ">&STDERR") or die $!;
	open(STDOUT, ">".File::Spec->devnull) or die $!;
	open(STDERR, ">".File::Spec->devnull) or die $!;
	system(@cmd);
	close STDERR;
	close STDOUT;
	open(STDERR, ">&OLDERR") or die $!;
	open(STDOUT, ">&OLDOUT") or die $!;

	$success = $? == 0 ? 1 : 0;
    }

    return { success => $success,
	     stdin   => $stdin,
	     stdout  => $stdout,
	     stderr  => $stderr,
	     can_capture => $can_capture,
	   };
}

sub run_pkwalify {
    my(@args) = @_;
    my @cmd = (@cmd, @args);
    _run_pkwalify(@cmd);
}

sub run_pkwalify_non_silent {
    my(@args) = @_;
    my(@cmd) = grep { $_ ne '-s' } @cmd;
    push @cmd, @args;
    _run_pkwalify(@cmd);
}

# Should be last because of STDERR redirection
{
    open(STDERR, ">" . File::Spec->devnull);
    system($^X, "-c", "-Mblib=$FindBin::RealBin/..", $script);
    ok($?==0, "$script compiles OK");
}

__END__
