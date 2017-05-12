
add_defs 'pkg-zvt.defs';
add_typemap 'pkg-zvt.typemap';

add_headers (qw( <zvt/zvtterm.h> ));
$zvtlibs = `gnome-config --libs zvt` || "-lzvt";
$libs = "$libs $zvtlibs";
chomp($libs);
