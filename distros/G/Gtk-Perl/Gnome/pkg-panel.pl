
add_defs 'pkg-panel.defs';
add_typemap 'pkg-panel.typemap';

add_headers '<applet-widget.h>';

$appletlibs = `gnome-config --libs applets` || "-lpanel_applet -lgnorba -lORBitCosNaming -lORBit -lIIOP -lORBitutil -lgnomeui -lgnome";  

$libs = "$libs $appletlibs";
chomp($libs);
