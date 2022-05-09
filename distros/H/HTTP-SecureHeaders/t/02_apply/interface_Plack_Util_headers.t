use strict;
use warnings;

use lib qw(./t/lib);

use Test::More;
use HTTPSecureHeadersTestApply;

{
    package MyHeaders;

    sub new {
        my ($class, %args) = @_;
        bless { %args }, $class;
    }

    sub exists {
        my ($self, $key) = @_;
        exists $self->{$key}
    }

    sub get {
        my ($self, $key) = @_;
        $self->{$key}
    }

    sub set {
        my ($self, $key, $value) = @_;
        $self->{$key} = $value;
    }
}

subtest 'Tests on headers with same interface as HTTP::Headers' => sub {
    local $HTTPSecureHeadersTestApply::CREATE_HEADERS = sub {
        MyHeaders->new(@_)
    };
    HTTPSecureHeadersTestApply::main();
};

done_testing;
