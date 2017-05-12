use strict;
use warnings;

use Test::More;
use Test::Exception;
use Hash::Convert;

sub verify {
    my (%specs) = @_;
    my ($rules, $options, $input, $expects, $desc) = @specs{qw/rules options input expects desc/};

    subtest $desc => sub {
        my $converter = Hash::Convert->new($rules, $options);
        my $result = $converter->convert($input);
        is_deeply $result, $expects;
        note explain $result;
        done_testing;
    };
}

sub verify_hash {
    my (%specs) = @_;
    my ($rules, $options, $input, $expects, $desc) = @specs{qw/rules options input expects desc/};

    subtest $desc => sub {
        my $converter = Hash::Convert->new($rules, $options);
        my %result = $converter->convert(%{$input});
        is_deeply \%result, $expects;
        note explain \%result;
        done_testing;
    };
}

sub verify_error {
    my (%specs) = @_;
    my ($rules, $options, $input, $error, $desc) = @specs{qw/rules options input error desc/};

    subtest $desc => sub {
        throws_ok {
            my $converter = Hash::Convert->new($rules, $options);
            $converter->convert($input);
        } qr/$error/;
        done_testing;
    };
}

1;
