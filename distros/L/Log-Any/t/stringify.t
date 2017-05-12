use warnings;
use strict;
use Test::More tests => 1;

{

    package Test_URI;

    use overload '""' => \&stringify;

    sub new {
        my ( $class, $s ) = @_;
        return bless { s => $s }, $class;
    }

    sub stringify {
        my ($self) = @_;
        return $self->{s};
    }

}

use Log::Any '$log';
use Log::Any::Adapter 'Test';

my $uri = Test_URI->new('http://slashdot.org/');

$log->infof( 'Fetching %s', $uri );

is(
    Log::Any::Adapter::Test->msgs->[0]->{message},
    'Fetching http://slashdot.org/',
    'URI was correctly stringified'
);

