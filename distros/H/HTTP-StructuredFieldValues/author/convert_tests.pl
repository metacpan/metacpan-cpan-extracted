#!/usr/bin/env perl

use strict;
use warnings;
use JSON::PP;
use File::Find;
use File::Basename;
use File::Path qw(make_path);
use Getopt::Long;
use MIME::Base64;
use Tie::IxHash;
use B;

# git clone https://github.com/httpwg/structured-field-tests.git

# For debugging
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

# Command line options
my $test_dir = './structured-field-tests';
my $output_dir = '../t/generated';
my $verbose = 0;
my $debug = 0;

GetOptions(
    'dir=s' => \$test_dir,
    'output-dir=s' => \$output_dir,
    'verbose' => \$verbose,
    'debug' => \$debug,
) or die "Usage: $0 [--dir=TEST_DIR] [--output-dir=OUTPUT_DIR] [--verbose] [--debug]\n";

# Create output directory
make_path($output_dir) unless -d $output_dir;

# Collect test cases
print "Searching for test files in $test_dir...\n" if $verbose;
my @test_files;
find(sub {
    return unless -f $_ && /\.json$/;
    my $dir = $File::Find::dir;
    my $basename = basename($_, '.json');
    
    push @test_files, $File::Find::name;
}, $test_dir);

print "Found " . scalar(@test_files) . " test files\n" if $verbose;

# Process each test file
my %all_tests;
my $total_tests = 0;
my $skipped_tests = 0;
my $json = JSON::PP->new->allow_bignum->utf8;

for my $file (sort @test_files) {
    print "\nProcessing $file...\n" if $verbose;
    
    # Read JSON file
    my $json_text = do {
        open my $fh, '<', $file or die "Cannot open $file: $!";
        local $/;
        <$fh>;
    };

    # monkey patch
    # examples.json
    $json_text =~ s/\["q", "9"\]/\["q", {"__type": "string", "value": "9"}\]/;
    
    my $data;
    eval {
        $data = $json->decode($json_text);
    };
    if ($@) {
        warn "Failed to parse $file: $@\n";
        next;
    }
    
    # Extract test cases
    next unless ref($data) eq 'ARRAY';
    
    my $basename = basename($file, '.json');
    if (dirname($file) eq './structured-field-tests/serialisation-tests') {
        $basename = 'serial_' . $basename;  # Special name for root dir
    }
    my @valid_tests;
    
    for my $test (@$data) {
        next unless ref($test) eq 'HASH';
        
        # Check required fields
        unless (exists $test->{name}) {
            warn "Test without name in $file\n" if $debug;
            next;
        }
        
        # Skip conditions
        if ($test->{skip} || $test->{name} =~ /SKIP/) {
            $skipped_tests++;
            next;
        }
        
        push @valid_tests, $test;
        $total_tests++;
    }
    
    if (@valid_tests) {
        $all_tests{$basename} = \@valid_tests;
        print "  Found " . scalar(@valid_tests) . " valid tests\n" if $verbose;
    }
}

print "\nTotal tests collected: $total_tests\n";
print "Skipped tests: $skipped_tests\n" if $skipped_tests;

# Generate test files
for my $suite (sort keys %all_tests) {
    my $filename = "$output_dir/${suite}.t";
    generate_test_file($filename, $suite, $all_tests{$suite});
}

print "\nTest generation completed.\n";

# Test file generation function
sub generate_test_file {
    my ($filename, $suite_name, $tests) = @_;
    
    open my $fh, '>:encoding(UTF-8)', $filename or die "Cannot open $filename: $!";
    
    print $fh <<'HEADER';
#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use lib 'lib';

BEGIN {
    eval { 
      require HTTP::StructuredFieldValues; 
      HTTP::StructuredFieldValues->import(qw(encode decode_dictionary decode_list decode_item));
       1; 
    } or do {
        plan skip_all => "HTTP::StructuredFieldValues module not available";
    };
}

use MIME::Base32;
use Tie::IxHash;

sub _h {
  tie my %hash, 'Tie::IxHash', @_;
  return \%hash;
}

HEADER

    print $fh "# Generated from $suite_name.json\n";
    print $fh "# Total tests: " . scalar(@$tests) . "\n\n";
    
    print $fh "plan tests => " . scalar(@$tests) . ";\n\n";
    
    # Generate test cases
    my $test_num = 0;
    for my $test (@$tests) {
        $test_num++;
        generate_test_case($fh, $test, $suite_name, $test_num);
    }
    
    close $fh;
    
    print "Generated $filename (" . scalar(@$tests) . " tests)\n";
}

# Generate individual test case
sub generate_test_case {
    my ($fh, $test, $suite_name, $test_num) = @_;
    
    my $name = $test->{name} || "unnamed_${suite_name}_${test_num}";
    my $header_type = $test->{header_type} || $suite_name;
    my $must_fail = $test->{must_fail} // 0;
    my $can_fail = $test->{can_fail} // 0;
    
    # Get and process input data
    my $input_code = process_test_input($test, $header_type);
    
    # Sanitize test name
    $name =~ s/[^\x20-\x7E]/_/g;
    $name =~ s/'/\\'/g;
    
    print $fh "# Test $test_num: $name\n";
    
    if ($debug) {
        print $fh "# Test data:\n";
        my $dumper = Data::Dumper->new([$test]);
        $dumper->Indent(1)->Terse(1)->Sortkeys(1);
        my $dump = $dumper->Dump;
        $dump =~ s/^/# /mg;
        print $fh $dump;
    }
    
    if (!defined $input_code) {
        if (defined $test->{canonical}) {
            generate_encode_test($fh, $name, $test, $header_type);
        } else {
            generate_failed_encode_test($fh, $name, $test, $header_type);
        }
    }
    elsif ($must_fail) {
        generate_must_fail_test($fh, $name, $input_code, $header_type);
    }
    elsif ($can_fail) {
        generate_can_fail_test($fh, $name, $input_code, $header_type);
    }
    else {
        generate_normal_test($fh, $name, $input_code, $test, $header_type);
    }
}

# Process test input
sub process_test_input {
    my ($test, $header_type) = @_;
    
    # Check raw field
    if (exists $test->{raw}) {
        my $raw = $test->{raw};
        
        if (ref($raw) && ref($raw) eq 'ARRAY') {
                return B::perlstring(join(',', @$raw));
        }
        else {
            die "Unsupported raw data type: " . ref($raw);
        }
    }
    else {
        # No input data
        return undef;
    }
}

sub generate_encode_test {
    my ($fh, $name, $test, $header_type) = @_;

    my $expected_code = generate_expected_structure($test->{expected}, $header_type);
    my $canonical = B::perlstring($test->{canonical}[0]);

    print $fh "{\n";
    print $fh "    my \$test_name = '$name - encode only';\n";
    print $fh "    my \$expected = $expected_code;\n";
    print $fh "    my \$canonical = $canonical;\n";
    print $fh "    \n";
    print $fh "    my \$result = eval { encode(\$expected); };\n";
    print $fh "    if (\$@) {\n";
    print $fh "        fail(\$test_name);\n";
    print $fh "        diag(\"Eecode error:\", \$@);\n";
    print $fh "        diag(\"Input was: \", \$expected);\n";
    print $fh "    } else {\n";
    print $fh "        is(\$result, \$canonical, \$test_name) or do {\n";
    print $fh "            diag(\"Got: \", explain(\$result));\n";
    print $fh "            diag(\"Expected: \", explain(\$canonical));\n";
    print $fh "            diag(\"Input was: \", explain(\$expected));\n";
    print $fh "        };\n";
    print $fh "    }\n";
    print $fh "}\n\n";
}

sub generate_failed_encode_test {
    my ($fh, $name, $test, $header_type) = @_;

    my $expected_code = generate_expected_structure($test->{expected}, $header_type);

    print $fh "{\n";
    print $fh "    my \$test_name = '$name - must fail';\n";
    print $fh "    my \$expected = $expected_code;\n";
    print $fh "    \n";
    print $fh "    eval { encode(\$expected); };\n";
    print $fh "    if (\$@) {\n";
    print $fh "        note(\$@);\n";
    print $fh "        pass(\$test_name);\n";
    print $fh "    } else {\n";
    print $fh "        diag(\"Expected failure but got success\");\n";
    print $fh "        fail(\$test_name);\n";
    print $fh "    }\n";
    print $fh "}\n\n";
}

# Generate must-fail test
sub generate_must_fail_test {
    my ($fh, $name, $input_code, $header_type) = @_;
    
    print $fh "{\n";
    print $fh "    my \$test_name = '$name - must fail';\n";
    print $fh "    my \$input = $input_code;\n";
    print $fh "    \n";
    print $fh "    eval { decode_$header_type(\$input); };\n";
    print $fh "    ok(\$@, \$test_name) or diag(\"Expected failure but got success\");\n";
    print $fh "}\n\n";
}

# Generate can-fail test
sub generate_can_fail_test {
    my ($fh, $name, $input_code, $header_type) = @_;
    
    print $fh "{\n";
    print $fh "    my \$test_name = '$name - can fail';\n";
    print $fh "    my \$input = $input_code;\n";
    print $fh "    \n";
    print $fh "    eval { decode_$header_type(\$input); };\n";
    print $fh "    pass(\$test_name); # Can fail tests always pass\n";
    print $fh "}\n\n";
}

# Generate normal test
sub generate_normal_test {
    my ($fh, $name, $input_code, $test, $header_type) = @_;
    
    # Decode test
    my $expected_code = generate_expected_structure($test->{expected}, $header_type);
    my $canonical;
    if(defined $test->{canonical}) {
        $canonical = B::perlstring($test->{canonical}[0] // '');
    } else {
        $canonical = '$input';
    }
    print $fh <<"CODE"
subtest \"$name\" => sub {
    my \$test_name = \"$name\";
    my \$input = $input_code;
    my \$expected = $expected_code;
    my \$canonical = $canonical;
    
    my \$result = eval { decode_$header_type(\$input); };
    
    if (\$@) {
        fail(\$test_name);
        diag(\"Decode error: \$@\");
        diag(\"Input was: \$input\");
    } else {
        is_deeply(\$result, \$expected, \$test_name) or do {
            diag(\"Got: \", explain(\$result));
            diag(\"Expected: \", explain(\$expected));
            diag(\"Input was: \", \$input);
        };
    }
    \$result = eval { encode(\$expected); };
    if (\$@) {
        fail(\$test_name);
        diag(\"Encode error:\", \$@);
        diag(\"Input was: \", explain(\$expected));
    } else {
        is(\$result, \$canonical, \$test_name) or do {
            diag(\"Got: \", explain(\$result));
            diag(\"Expected: \", explain(\$canonical));
            diag(\"Input was: \", explain(\$expected));
        };
    }
};

CODE
    ;
}

# Generate expected structure
sub generate_expected_structure {
    my ($expected, $header_type) = @_;
    
    return 'undef' unless defined $expected;
    
    print STDERR "Generating structure for type: $header_type\n" if $debug;
    print STDERR "Expected data: " . Dumper($expected) if $debug;
    
    if ($header_type eq 'dictionary') {
        return generate_dictionary_structure($expected);
    }
    elsif ($header_type eq 'list') {
        return generate_list_structure($expected);
    }
    elsif ($header_type eq 'item' || $header_type eq 'number' || 
           $header_type eq 'string' || $header_type eq 'token' || 
           $header_type eq 'binary' || $header_type eq 'boolean'||
           $header_type eq 'date') {
        return generate_item_structure($expected);
    }
    else {
        warn "Unknown header type: $header_type, treating as item\n";
        return generate_item_structure($expected);
    }
}

# Generate dictionary structure
sub generate_dictionary_structure {
    my ($dict) = @_;
    
    return '{}' unless ref($dict) eq 'ARRAY';
    
    my @parts;
    for my $element (@$dict) {
        if (ref($element) ne 'ARRAY') {
            warn "Invalid dictionary element: " . Dumper($element) if $debug;
            next;
        }
        my ($key, $value) = @$element;
        my $safe_key = B::perlstring($key);
        
        my $value_code = generate_item_structure($value);
        push @parts, "$safe_key => $value_code";
    }
    
    if (@parts == 0) {
        return "_h()";
    }
    elsif (@parts == 1) {
        return "_h( $parts[0] )";
    }
    else {
        return "_h(\n        " . join(",\n        ", @parts) . "\n    )";
    }
}

# Generate list structure
sub generate_list_structure {
    my ($list) = @_;
    
    return '[]' unless ref($list) eq 'ARRAY' && @$list;
    
    my @parts;
    for my $item (@$list) {
        push @parts, generate_item_structure($item);
    }
    
    if (@parts == 1) {
        return "[ $parts[0] ]";
    }
    else {
        return "[\n        " . join(",\n        ", @parts) . "\n    ]";
    }
}

# Generate item structure
sub generate_item_structure {
    my ($item) = @_;
    
    if (!defined $item) {
        return 'undef';
    }
    elsif (ref($item) eq 'ARRAY') {
        print STDERR "ARRAY $#{$item}\n" if $debug;
        if ($#{$item} == 1 ) {
            # Item with parameters or inner list with parameters
            my ($value, $paramsarray) = @$item;
            my $params = make_hash_from_array($paramsarray);
            
            # If value is array, check for inner list
            if (ref($value) eq 'ARRAY') {
                # Inner list
                print STDERR "Inner list with params\n" if $debug;
                my $inner_list_structure = generate_list_structure($value);
                
                # If parameters exist
                if (ref($params) eq 'HASH' && keys %$params) {
                    return "{ _type => 'inner_list', value => $inner_list_structure, params => " . generate_params_structure($params) . " }";
                }
                else {
                    return "{ _type => 'inner_list', value => $inner_list_structure }";
                }
            }
            else {
                # Normal item with parameters
                printf STDERR "Parameterized item: value=%s\n", Dumper($value) if $debug;
                
                my $base_structure = generate_bare_item_structure($value);
                
                # If parameters exist
                if (ref($params) eq 'HASH' && keys %$params) {
                    # If base_structure is hashref
                    if ($base_structure =~ /^\s*\{\s*_type\s*=>\s*'[^']+'\s*,\s*value\s*=>\s*[^}]+\s*\}\s*$/) {
                        # Insert params before closing brace
                        $base_structure =~ s/\s*\}\s*$//;
                        $base_structure .= ", params => " . generate_params_structure($params) . " }";
                    }
                    return $base_structure;
                }
                else {
                    return $base_structure;
                }
            }
        }
        else {
            # Treat as inner list (no params)
            print STDERR "Inner list without params\n" if $debug;
            return "{ _type => 'inner_list', value => " . generate_list_structure($item) . " }";
        }
    }
    elsif (ref($item) eq 'HASH') {
        # Check for dictionary
        if (keys %$item && !exists $item->{'__type'}) {
            # Normal dictionary
            return generate_dictionary_structure($item);
        }
        else {
            # Typed item
            return generate_typed_item_structure($item);
        }
    }
    else {
        # Scalar value
        return generate_bare_item_structure($item);
    }
}

sub make_hash_from_array {
    my ($array) = @_;
    tie my %ret, 'Tie::IxHash';

    print STDERR Dumper($array) if $debug;
    for(@$array) {
        if (ref($_) eq 'ARRAY' && $#$_ == 1) {
            my ($key, $value) = @$_;
            $ret{$key} = $value;
            print STDERR "Key: $key, Value: $value\n" if $debug;
        }
    }
    return \%ret;
}

# Generate typed item structure
sub generate_typed_item_structure {
    my ($item) = @_;
    
    if (exists $item->{'__type'}) {
        my $type = $item->{'__type'};
        my $value = $item->{value};
        
        if ($type eq 'token') {
            my $safe_value = B::perlstring($value);
            return "{ _type => 'token', value => $safe_value }";
        }
        elsif ($type eq 'binary') {
            # Encode binary data as Base64
            my $b64 = encode_base64($value, '');
            return "{ _type => 'binary', value => decode_base64('$b64') }";
        }
    }
    
    # Otherwise, treat as normal hash
    return generate_dictionary_structure($item);
}

# Generate bare item structure
sub generate_bare_item_structure {
    my ($item) = @_;
    
    if (!defined $item) {
        return 'undef';
    }
    elsif (ref($item)) {
        # Reference type
        if (ref($item) eq 'HASH' && exists $item->{'__type'}) {
            # Typed item
            my $type = $item->{'__type'};
            my $value = $item->{value};
            
            if ($type eq 'token') {
                my $safe_value = B::perlstring($value);
                return "{ _type => 'token', value => $safe_value }";
            }
            elsif ($type eq 'binary') {
                # Handle binary data
                if (defined $value) {
                    $value =~ s/=+//g;
                    return "{ _type => 'binary', value => decode_base32('$value') }";
                }
                else {
                    return "{ _type => 'binary', value => '' }";
                }
            }
            elsif ($type eq 'string') {
                my $safe_value = B::perlstring(defined $value ? $value : '');
                return "{ _type => 'string', value => $safe_value }";
            }
            elsif ($type eq 'integer') {
                return "{ _type => 'integer', value => " . (defined $value ? $value : 0) . " }";
            }
            elsif ($type eq 'decimal') {
                return "{ _type => 'decimal', value => " . (defined $value ? $value : '0.0') . " }";
            }
            elsif ($type eq 'boolean') {
                return "{ _type => 'boolean', value => " . ($value ? 1 : 0) . " }";
            }
            elsif ($type eq 'displaystring') {
                my $safe_value = defined $value ? $value : '';
                $safe_value =~ s/'/\\'/g;
                return "{ _type => 'displaystring', value => '$safe_value' }";
            }
            elsif ($type eq 'date') {
                my $safe_value = defined $value ? $value : '';
                $safe_value =~ s/'/\\'/g;
                return "{ _type => 'date', value => '$safe_value' }";
            }
        }
        elsif (ref($item) eq 'JSON::PP::Boolean') {
            # JSON::PP boolean value
            return "{ _type => 'boolean', value => " . $item . " }";
        }
        elsif (ref($item) eq 'Math::BigFloat') {
            # decimal value
            return "{ _type => 'decimal', value => " . $item->bstr() . " }";
        }
        else {
            # Other reference types
            warn "Unexpected reference type in bare item: " . ref($item) . "\n" if $debug;
            return Data::Dumper->new([$item])->Terse(1)->Indent(0)->Sortkeys(1)->Dump;
        }
    }
    else {
        # Guess scalar value type
        if ($item =~ /^-?\d+$/ && $item !~ /^-?0\d/) {
            return "{ _type => 'integer', value => $item }";
        }
        elsif ($item =~ /^-?\d+\.\d{1,3}$/) {
            return "{ _type => 'decimal', value => $item }";
        }
        elsif ($item eq 'true') {
            return "{ _type => 'boolean', value => 1 }";
        }
        elsif ($item eq 'false') {
            return "{ _type => 'boolean', value => 0 }";
        }
        else {
            # Treat as string
            my $safe_value = B::perlstring($item);
            return "{ _type => 'string', value => $safe_value }";
        }
    }
}

# Generate parameter structure
sub generate_params_structure {
    my ($params) = @_;
    
    return '{}' unless ref($params) eq 'HASH' && keys %$params;
    
    my @parts;
    for my $key (keys %$params) {
        my $safe_key = B::perlstring($key);
        push @parts, "$safe_key => " . generate_bare_item_structure($params->{$key});
    }
    
    return "_h( " . join(", ", @parts) . " )";
}
