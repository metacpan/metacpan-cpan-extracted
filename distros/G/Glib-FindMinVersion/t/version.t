use Test::More;

BEGIN {
    use_ok 'Glib::FindMinVersion';
}

my ($LESS, $EQUAL, $GREATER) = (-1, 0, 1);

is Glib::FindMinVersion::version_cmp('2.26', '2.6'), $GREATER;
is Glib::FindMinVersion::version_cmp('2.20', '2.2'), $GREATER;
is Glib::FindMinVersion::version_cmp('2.6', '2.26'), $LESS;
is Glib::FindMinVersion::version_cmp('2.2', '2.20'), $LESS;
is Glib::FindMinVersion::version_cmp('2.3', '2.25'), $LESS;
is Glib::FindMinVersion::version_cmp('2.2', '2.2'),  $EQUAL;
is Glib::FindMinVersion::version_cmp('0.26', '2.6'), $LESS;

done_testing;
