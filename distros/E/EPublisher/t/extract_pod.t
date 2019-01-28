#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use EPublisher::Utils::PPI qw/extract_pod/;

my $dir = dirname __FILE__;
my $pod = q~=pod

Test

=cut
~;

{
    is extract_pod(), undef;
}

{
    is extract_pod(undef), undef;
}

{
    is extract_pod( $dir ), undef;
}

{
    is extract_pod( $dir . '/does_not_exist.txt' ), undef;
}

{
    is extract_pod( __FILE__ ), $pod;
}

{
    is extract_pod( __FILE__, { encoding => 'utf-8' } ), $pod;
}

{
    is extract_pod( $dir . '/fourth_lib/empty.txt' ), undef;
}

{
    is extract_pod( $dir . '/fourth_lib/test.db' ), undef;
}

{
    my $pod = qq~=pod

=head1 A unit test

=cut
~;
    is extract_pod( $dir . '/03_base_source.t' ), $pod;
}

done_testing();

{
    package # private pod
        EPublisher::Test;

    1;
=pod

Test

=cut
}
