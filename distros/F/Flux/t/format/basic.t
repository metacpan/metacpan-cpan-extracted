#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Flux::Storage::Memory;

{
    package Format::Double;

    use Moo;
    with 'Flux::Format';

    use Flux::Simple qw(mapper);

    sub encoder {
        return mapper { shift() * 2 };
    }

    sub decoder {
        return mapper { shift() / 2 };
    }
}

my $storage = Flux::Storage::Memory->new;
my $format = Format::Double->new;
my $formatted_storage = $format->wrap($storage);
$formatted_storage->write(3);
$formatted_storage->write(5);
$formatted_storage->commit;

my $in = $formatted_storage->in('abc');
is($in->read, 3);
is($in->read, 5);
is($in->read, undef);

done_testing;
