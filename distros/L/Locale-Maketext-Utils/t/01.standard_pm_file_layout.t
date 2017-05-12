use Test::More tests => 4;

BEGIN {
    chdir 't';
    unshift @INC, qw(lib ../lib);
    use_ok('Locale::Maketext::Utils');
    use_ok('MyTestLocale');
}

my $lh = MyTestLocale->get_handle('fr');

ok( $lh->get_base_class_dir() . '.pm' eq $INC{'MyTestLocale.pm'}, 'get_base_class_dir() returns the correct path' );

is_deeply(
    [ sort $lh->list_available_locales() ],
    [qw(es fr pt_br)],
    'list_available_locales() returns correct langtags based on "Standard .pm file" file system'
);

# TODO, tests for this sort of madness
#   $INC{'MyTestLocale.pm'} = 'MyTestLocale.pm';
#   $INC{'My/TestLocale.pm'} = 'My/TestLocale.pm';
#   $INC{'My/Test/Locale.pm'} = 'My/Test/Locale.pm';
#   $INC{'My/Test/Locale.pm'} = 'non path value';
#   $INC{'My/Test/Locale.pm'} = '/none/existant/My/Test/Locale.pm';
