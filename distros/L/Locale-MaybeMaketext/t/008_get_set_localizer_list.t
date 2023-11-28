#!perl
use strict;
use warnings;
use File::Basename qw/dirname/;
use lib dirname(__FILE__);
use MaybeMaketextTestdata;

unload_mocks();
Locale::MaybeMaketext::maybe_maketext_reset();
my @received_list = Locale::MaybeMaketext::maybe_maketext_get_localizer_list();
my @initial_list  = (
    'Cpanel::CPAN::Locale::Maketext::Utils',
    'Locale::Maketext::Utils',
    'Locale::Maketext',
);
is( @received_list, @initial_list, 'List of localizers should be in prescribed order' );
my @test_list = ( 'Locale::Maketext', 'Cpanel::CPAN::Locale::Maketext::Utils', 'DoesNot::Exist' );
ok(
    Locale::MaybeMaketext::maybe_maketext_set_localizer_list(@test_list),
    'List of localizers should be accepted no matter what'
);
@received_list = Locale::MaybeMaketext::maybe_maketext_get_localizer_list();
is( @received_list, @test_list, 'List of localizers be as set' );

Locale::MaybeMaketext::maybe_maketext_reset();
@received_list = Locale::MaybeMaketext::maybe_maketext_get_localizer_list();
is( @received_list, @initial_list, 'List of localizers should be back to initial setting' );
done_testing();
