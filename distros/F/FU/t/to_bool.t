use v5.36;
use Test::More;
use FU::Util 'to_bool';
use experimental 'builtin';
use builtin 'true', 'false';

is to_bool undef, undef;
is to_bool '', undef;
is to_bool 1, undef;
is to_bool [], undef;
is to_bool {}, undef;
is to_bool bless(\(my $x = 1), 'FU::Bullshit'), undef;

is to_bool builtin::true, true;
is to_bool builtin::false, false;

is to_bool \1, true;
is to_bool \0, false;
is to_bool \'1', true;
is to_bool \'0', false;
is to_bool \2, undef;

SKIP: {
    eval { require Types::Serialiser; 1 } || skip 'Types::Serialiser not installed';
    is to_bool Types::Serialiser::true(), true;
    is to_bool Types::Serialiser::false(), false;
}

SKIP: {
    eval { require JSON::Tiny; 1 } || skip 'JSON::Tiny not installed';
    is to_bool JSON::Tiny::true(), true;
    is to_bool JSON::Tiny::false(), false;
}

SKIP: {
    eval { require Cpanel::JSON::XS; 1 } || skip 'Cpanel::JSON::XS not installed';
    is to_bool Cpanel::JSON::XS::true(), true;
    is to_bool Cpanel::JSON::XS::false(), false;
}

SKIP: {
    eval { require boolean; 1 } || skip '"boolean" not installed';
    is to_bool boolean::true(), true;
    is to_bool boolean::false(), false;
}

done_testing;
