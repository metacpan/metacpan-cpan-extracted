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

    sub isa {
        my ($self, $target) = @_;
        return $target eq 'HTTP::Headers';
    }

    sub header {
        my $self = shift;

        if (@_ == 1) {
            my ($key) = @_;
            return $self->{$key}
        }

        if (@_ == 2) {
            my ($key, $value) = @_;
            if (defined $value) {
                $self->{$key} = $value;
            }
            else {
                delete $self->{$key}
            }
        }
    }
}

subtest 'Tests on headers with same interface as HTTP::Headers' => sub {
    local $HTTPSecureHeadersTestApply::CREATE_HEADERS = sub {
        MyHeaders->new(@_)
    };
    HTTPSecureHeadersTestApply::main();
};

done_testing;
