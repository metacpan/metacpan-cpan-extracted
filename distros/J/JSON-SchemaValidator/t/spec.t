use strict;
use warnings;
use Test::More;
use File::Find;
use HTTP::Tiny;
use JSON ();
use JSON::SchemaValidator;

eval { $ENV{JSON_SCHEMA_SPEC} } or plan skip_all => 'Set JSON_SCHEMA_SPEC to run this test';

my @options = split /!/, $ENV{JSON_SCHEMA_SPEC};

my $draft = '';
my $suite;
my $test;

foreach my $option (@options) {
    my ($key, $value) = split /=/, $option;

    if ($key eq 'draft') {
        $draft = $value;
    }
    elsif ($key eq 'suite') {
        $suite = $value;
    }
    elsif ($key eq 'test') {
        $test = $value;
    }
}

my @files;
find(
    sub {
        my $name = $File::Find::name;

        return unless -f $_ && $_ =~ m/\.json$/;

        if ($suite) {
            return unless $_ =~ m/$suite\.json$/;
        }

        push @files, $name;
    },
    "t/spec/tests/$draft"
);

my $validator = JSON::SchemaValidator->new(
    fetcher => sub {
        my ($url) = @_;

        if ($url =~ m/draft-04/) {
            return JSON::decode_json(_slurp('t/schema/draft-04.json'));
        }
        elsif ($url =~ m/localhost:1234/) {
            my ($local_path) = $url =~ m{1234/(.*)$};

            return JSON::decode_json(_slurp('t/spec/remotes/' . $local_path));
        }

        return;
    }
);

foreach my $file (@files) {
    next if $file =~ m/ecmascript-regex/;
    next if $file =~ m/bignum/;
    next if $file =~ m/format/;

    my $test_cases = JSON::decode_json(
        do { local $/; open my $fh, '<', $file or die $!; <$fh> }
    );

    foreach my $test_case (@$test_cases) {
        my $schema = $test_case->{schema};

        my @tests = @{$test_case->{tests}};

        if ($test) {
            @tests = grep { $_->{description} eq $test } @tests;
        }

        next unless @tests;

        subtest "Test Suite: $test_case->{description}" => sub {
            foreach my $test (@tests) {
                subtest "Test: $test->{description}" => sub {
                    my $result = eval { $validator->validate($test->{data}, $schema) };
                    my $e      = $@;

                    if ($result) {
                        my $diag = sprintf '%s <=> %s %s (%s)', JSON::encode_json($schema),
                          JSON->new->utf8->allow_nonref(1)->encode($test->{data}), $result->errors_json, $file;

                        if ($test->{valid}) {
                            ok $result->is_success, "must be valid: $diag";
                        }
                        else {
                            ok !$result->is_success, "must not be valid: $diag";
                        }
                    }
                    else {
                        ok 0, sprintf "exception detected: %s, %s", JSON::encode_json($schema), $e;
                    }
                };
            }
        };
    }
}

done_testing;

sub _slurp {
    my ($file) = @_;

    return do { local $/; open my $fh, '<', $file or die $!; <$fh> };
}
