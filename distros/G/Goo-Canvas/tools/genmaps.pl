#! /usr/bin/perl -w
#read !grep _TYPE_ /usr/include/gtk-2.0/gtk/*.h | grep get_type  
#% s/^.*[ \t]\([_A-Z0-9]*_TYPE_[_A-Z0-9]*\)[ \t].*$/\1/ 
#
# Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the full
# list)
# 
# This library is free software; you can redistribute it and/or modify it under
# the terms of the GNU Library General Public License as published by the Free
# Software Foundation; either version 2.1 of the License, or (at your option)
# any later version.
# 
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Library General Public License for
# more details.
# 
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330, Boston, MA  02111-1307  USA.
#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2/tools/genmaps.pl,v 1.1 2003/12/05 19:33:17 muppetman Exp $
#

my $del_foo = shift;

my $gc = "goocanvas";
my ($dir) = grep {/$gc/} split /\s*-I\s*/, `pkg-config $gc --cflags`;
my @types;
my @lines = `grep _TYPE_ $dir/*.h | grep get_type`;
foreach (@lines) {
    chomp;
    s/^.*\s([A-Z][A-Z0-9_]*_TYPE_[A-Z0-9_]*)\s.*$/$1/;
    #		print "$1\n";
    push @types, $_;
}

if ( $del_foo || !-e 'foo.c' ) {
    create_foo_c();
}

if ( !-e 'foo' || (stat('foo'))[9]<(stat('foo.c'))[9] ) {
    create_foo();
}

foreach (`./foo`) {
	chomp;
	my @p = split;
    my @n = split /(?=[A-Z])/, $p[1];
    my $fullname = join('::', @n[0,1],  join('', @n[2..$#n]));
    $fullname =~ s/::$//;
	print join("\t", @p, $fullname), "\n";
}

sub create_foo {
    system "gcc -DGTK_DISABLE_DEPRECATED -Wall -o foo foo.c `pkg-config $gc --cflags --libs`"
	and die "couldn't compile helper program";
}

sub create_foo_c {
open FOO, "> foo.c";
select FOO;

print '#include <stdio.h>
#include <gtk/gtk.h>
#include <goocanvas.h>

const char * find_base (GType gtype)
{
	if (g_type_is_a (gtype, GTK_TYPE_OBJECT))
		return "GtkObject";
	if (g_type_is_a (gtype, G_TYPE_OBJECT))
		return "GObject";
	if (g_type_is_a (gtype, G_TYPE_BOXED))
		return "GBoxed";
	if (g_type_is_a (gtype, G_TYPE_FLAGS))
		return "GFlags";
	if (g_type_is_a (gtype, G_TYPE_ENUM))
		return "GEnum";
	if (g_type_is_a (gtype, G_TYPE_INTERFACE))
		return "GInterface";
	if (g_type_is_a (gtype, G_TYPE_STRING))
		return "GString";
	{
	GType parent = gtype;
	while (parent != 0) {
		gtype = parent;
		parent = g_type_parent (gtype);
	}
	return g_type_name (gtype);
	}
	return "-";
}

int main (int argc, char * argv [])
{
	g_type_init ();
';

foreach (@types) {
	print '#ifdef '.$_.'
{
        GType gtype = '.$_.';
        printf ("%s\t%s\t%s\n",
                "'.$_.'", 
		g_type_name (gtype),
		find_base (gtype));
}
#endif /* '.$_.' */
';
}

print '
	return 0;
}
';

close FOO;
select STDOUT;
}
