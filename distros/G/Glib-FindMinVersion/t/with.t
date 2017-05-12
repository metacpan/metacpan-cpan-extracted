use Test::More;

BEGIN {
    use_ok 'Glib::FindMinVersion';
}

is Glib::FindMinVersion::with($_), '2.0' for 'ABS', 'MIN', 'MAX';

for ($i = 32; $i <= 50; $i += 2) {
    is Glib::FindMinVersion::with("GLIB_VERSION_2_$i"), "2.$i";
}


done_testing;


