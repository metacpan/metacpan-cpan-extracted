use strict;
use warnings;
use Test::More;
use Project::Libs;
use Getopt::TypeConstraint::Mouse;

subtest 'alias of documentation option' => sub {
    local @ARGV = qw(--out=bar);
    {
        package MyApp;
        use Mouse;
        with 'MouseX::Getopt';
        has 'out' => (
            is            => 'ro',
            isa           => 'Str',
            documentation => 'foo',
        );
    }
    my $app = MyApp->new_with_options;
    {
        my $opts = Getopt::TypeConstraint::Mouse->get_options(
            out => +{ isa => 'Str', desc => 'foo' },
        );
        is_deeply \%$app, \%$opts;
    }
    {
        my $opts = Getopt::TypeConstraint::Mouse->get_options(
            out => +{ isa => 'Str', doc => 'foo' },
        );
        is_deeply \%$app, \%$opts;
    }
    {
        my $opts = Getopt::TypeConstraint::Mouse->get_options(
            out => +{ isa => 'Str', description => 'foo' },
        );
        is_deeply \%$app, \%$opts;
    }
};

done_testing;
