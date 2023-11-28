#!perl
use strict;
use warnings;
use vars;
use File::Basename();
use File::Spec();
use lib File::Spec->catdir( File::Basename::dirname( File::Spec->rel2abs(__FILE__) ), qw/lib/ );
use Test2::V0;
use lib File::Spec->catdir(
    File::Basename::dirname( File::Spec->rel2abs(__FILE__) ), File::Spec->updir(),
    qw/lib/
);
use Test2::Tools::Target 'Locale::MaybeMaketext';

my $version = $CLASS->VERSION;
pass( sprintf( '%s %s with Perl %s, %s', $CLASS, $version, $], $^X ) );
done_testing();
