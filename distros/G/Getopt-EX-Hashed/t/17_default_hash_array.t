use strict;
use warnings;
use Test::More;
use lib './t';

use Getopt::Long qw(GetOptionsFromArray);

use Getopt::EX::Hashed 'has'; {

    has items  => '=s@', default => ['aaa'];
    has config => '=s%', default => { length => 10000 };

} no Getopt::EX::Hashed;

subtest 'array default preserved' => sub {
    my $app = Getopt::EX::Hashed->new;
    $app->getopt([ '--items', 'bbb' ]);
    is_deeply($app->{items}, ['aaa', 'bbb'],
	      "default value preserved when option is given");
};

subtest 'array default untouched' => sub {
    my $app = Getopt::EX::Hashed->new;
    $app->getopt([]);
    is_deeply($app->{items}, ['aaa'],
	      "default value preserved when option is not given");
};

subtest 'hash default preserved' => sub {
    my $app = Getopt::EX::Hashed->new;
    $app->getopt([ '--config', 'line=200' ]);
    is_deeply($app->{config}, { length => 10000, line => '200' },
	      "default value preserved when option is given");
};

subtest 'hash default untouched' => sub {
    my $app = Getopt::EX::Hashed->new;
    $app->getopt([]);
    is_deeply($app->{config}, { length => 10000 },
	      "default value preserved when option is not given");
};

done_testing;
