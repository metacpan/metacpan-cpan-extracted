use strict;
use warnings;

use Test::More;

use List::MoreUtils qw/ any /;
use parent 'Exporter';

our @EXPORT = qw/ run_schema_test run_tests_for /;

sub run_tests_for {
    my $version = shift;
    my $file = shift;

    subtest $file => sub {
        my $data = from_json $file->slurp, { allow_nonref => 1 };
        run_schema_test($version,$_) for @$data;
    };
}

sub run_schema_test {
    my( $version, $test ) = @_;

    subtest $test->{description} => sub {
        my $schema = JSON::Schema::AsType->new( 
            draft_version => $version,
            schema => $test->{schema});

        diag explain $test->{schema} if $::explain;

        for ( @{ $test->{tests} } ) {
            my $desc = $_->{description};
            local $TODO = 'known to fail'
                if any { $desc eq $_ } 
                    'a string is still not an integer, even if it looks like one',
                    'a string is still a string, even if it looks like a number',
                    'a string is still not a number, even if it looks like one'; 

            is !!$schema->check($_->{data}) => !!$_->{valid}, $_->{description} 
                or do {
                    diag explain $_->{data};
                    diag join "\n", @{$schema->validate_explain($_->{data})||[]};
                };

            diag join "\n", @{ $schema->validate_explain($_->{data}) ||[] }
                unless $_->{valid} or not $::explain;
        }
    };

}


