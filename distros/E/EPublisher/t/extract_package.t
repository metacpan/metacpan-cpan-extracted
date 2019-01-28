#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use EPublisher::Utils::PPI qw/extract_package/;

my $dir = dirname __FILE__;

{
    is extract_package(), undef;
}

{
    is extract_package(undef), undef;
}

{
    is extract_package( $dir ), undef;
}

{
    is extract_package( $dir . '/does_not_exist.txt' ), undef;
}

{
    is extract_package( __FILE__ ), 'EPublisher::Test';
}

{
    is extract_package( __FILE__, { encoding => 'utf-8' } ), 'EPublisher::Test';
}

{
    is extract_package( $dir . '/fourth_lib/empty.txt' ), undef;
}

{
    is extract_package( $dir . '/fourth_lib/test.db' ), undef;
}

{
    is extract_package( $dir . '/03_base_source.t' ), undef;
}

done_testing();

{
    package # private package
        EPublisher::Test;

    1;
}
