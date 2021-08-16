use Test::More;
BEGIN {
    plan skip_all => 'Need perl v5.16.0: no \N{}'
        if $] < 5.016;
}
plan tests => 3;

require_ok('Encode');
require_ok('File::Rename');

unshift @INC, 't' if -d 't';
require 'testlib.pl';

my $dir = do { require File::Temp; File::Temp::tempdir(); };
chdir $dir or die;

my $test = Encode::encode( 'UTF-8', "A \x{2013} B.txt");  # EN DASH
my $xxx = 'A XXX B.txt';
create_file($test);

SKIP: {
    skip "Can't create filename with unicode \\N{EN DASH}", 1
        unless -e $test;

    our $found;
    our $print;
    our $warn;
    local $SIG{__WARN__} = sub { $warn .= $_[0] };

    test_rename_files( sub { s/\N{EN DASH}+/XXX/ }, $test,
                        {unicode_strings => 1, encoding => 'utf8'});
    ok( (-e $xxx and !-e $test and $found),
        "rename with \\N{EN DASH}");
    diag_rename();
}
 
