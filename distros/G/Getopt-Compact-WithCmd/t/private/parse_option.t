use strict;
use warnings;
use Test::More;
use Getopt::Compact::WithCmd;

sub test_parse_option {
    my %specs = @_;

    my ($input, $has_error, $error_message, $desc) =
        @specs{qw/input has_error error_message desc/};

    subtest $desc => sub {
        my $go = bless {}, 'Getopt::Compact::WithCmd';

        unless ($has_error) {
            ok +$go->_parse_option(@$input), 'parse success';
        }
        else {
            ok !+$go->_parse_option(@$input), 'parse failed';
            is $go->{error}, $error_message, 'error message';
        }

        done_testing;
    };
};

{
    my $help;
    test_parse_option(
        input => [
            [qw/--help/],
            {
                'h|help!' => \$help,
            },
        ],
        expects => 1,
        desc => 'valid argv',
    );
}

{
    my $help;
    test_parse_option(
        input => [
            [qw/--foo/],
            {
                'h|help!' => \$help,
            },
        ],
        has_error => 1,
        error_message => 'Unknown option: foo',
        desc => 'Unknown option',
    );
}

done_testing;
