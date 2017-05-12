=out

gconf2

=cut

@dirs = (
	'/usr/include/gconf/2/gconf/',
);

foreach $dir (@dirs) {
	@lines = `grep _TYPE_ $dir/*.h | grep get_type`;
	foreach (@lines) {
		chomp;
		s/^.*\s([A-Z][A-Z0-9_]*_TYPE_[A-Z0-9_]*)\s.*$/$1/;
		#print "$1\n";
		push @types, $_;
	}
}

open FOO, "> foo.c";
select FOO;

print '#include <stdio.h>

#include <gtk/gtk.h>

#include <gconf/gconf.h>
#include <gconf/gconf-client.h>
#include <gconf/gconf-engine.h>
#include <gconf/gconf-value.h>
#include <gconf/gconf-changeset.h>
#include <gconf/gconf-enum-types.h>
#include <gconf/gconf-listeners.h>
#include <gconf/gconf-schema.h>

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

system 'gcc -DGTK_DISABLE_DEPRECATED -Wall -o foo foo.c `pkg-config gtk+-2.0 gconf-2.0 --cflags --libs`'
	and die "couldn't compile helper program";

@packagemap = (
	[ GConf   => 'Gnome2::GConf' ], # fallback
);

foreach (`./foo`) {
	chomp;
	my @p = split;
	my $pkg = 'Gnome2';
	my $prefix = 'GConf';
	foreach $f (@packagemap) {
		my $t = $f->[0];
		if ($p[1] =~ /^$t/) {
			$prefix = $f->[0];
			$pkg = $f->[1];
			last;
		}
	}
	(my $fullname = $p[1]) =~ s/^$prefix/$pkg\::/;
	print join("\t", @p, $fullname), "\n";
}

