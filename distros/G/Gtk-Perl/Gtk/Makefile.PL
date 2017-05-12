use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use Cwd;
use Config;
require '../Depends.pm';

$gtk = new ExtUtils::Depends ('Gtk');

# Guess packages
#print "You may use '--lazy-load', which will reduce initial memory usage\n";
#print "and loading time, at the cost of some internal glitches.\n\n";

@defines = ();

# Starting with Perl 5.005 all embed variables got PL_ prefix
# so, to avoid errorswith sv_undef, we enable polluting name space..
if ($] > 5.004) {
	push @defines, "-DPERL_POLLUTE";
} else {
	push @defines, "-DNEED_DERIVED";
}

$Lazy = grep($_ eq "--lazy-load", @ARGV);
@ARGV = grep($_ ne "--lazy-load", @ARGV);

$Lazy = 1;

if ($Lazy) {
	#print "\n\nLazy loading enabled -- if anything breaks, please try disabling this.\n";
	push @defines, "-DLAZY_LOAD";
}

if (exists($Config{usethreads}) && $Config{usethreads} eq 'define') {
	print "Current perl supports threads. Enabling thread support\n";
	push(@defines, "-DPGTK_THREADS");
	$threadl = " gthread ";
} else {
	$threadl = "";
}

$libs = `gtk-config --libs $threadl`;
$inc = `gtk-config --cflags $threadl`;
$libs =~ s/\s+/ /g;
$inc =~ s/\s+/ /g;

$inc .= ' -I. -I./build';

$gtk_version = gtk_version();

if ($gtk_version =~ /^(\d+)\.(\d+)\.(\d+)/) {
	$gtk_major = $1;
	$gtk_minor = $2;
	$gtk_micro = $3;
} else {
	$gtk_major = $gtk_minor = $gtk_micro = 0;
}

$gtk_hverstr = sprintf("0x%02x%02x%02x", $gtk_major, $gtk_minor, $gtk_micro);

push @defines, "-DGTK_HVER=$gtk_hverstr";

if (not defined $gtk_version) {
	die "Unable to find  Gtk version...\n";
} else {
	print "Located Gtk version $gtk_version...\n";
}

mkdir("build", 0777);

$gtk->set_inc($inc);
$gtk->set_libs($libs);
$gtk->add_typemaps(map {cwd().'/'.$_} "build/GtkTypemap", "gtk-0.99.typemap", "gtk-1.2.typemap");
$gtk->add_headers ('<gtk/gtk.h>', '<gtk/gtkinvisible.h>', '"GtkTypes.h"', '"GdkTypes.h"', '"MiscTypes.h"');
$gtk->install (qw(build/PerlGtkInt.h build/PerlGtkExt.h ppport.h build/GtkDefs.h));
$gtk->add_c(qw(build/GtkDefs.c build/PerlGtkExt.c 
	GdkTypes.c GtkTypes.c MiscTypes.c Derived.c));
$gtk->add_xs ('Gtk.xs', "Gtk-1.1.xs", "GtkAccelGroup.xs", "GtkProgressBar-1.1.xs", 
	"GtkToolbar-1.1.6.xs", "GtkAccelGroup.xs", "GtkProgressBar-1.1.xs", "GtkCList-1.2.xs",
	"GtkTearoffMenuItem.xs", "GtkCalendar.xs", "Gtk-1.2.xs");
$gtk->add_defs (qw(gtk-0.99.defs gtk-1.0.defs gtk-1.1.defs gtk-1.1.1.defs gtk-1.1.3.defs gtk-1.1.4.defs gtk-1.1.6.defs gtk-1.2.defs ));

$gtk->add_xs ("GtkSelection.xs");
$gtk->add_boot ("Gtk::Selection", "Gtk11", "Gtk__AccelGroup", "Gtk::ProgressBar11",
	"Gtk::Toolbar116", "Gtk__AccelGroup", "Gtk::ProgressBar11", "Gtk::CList12", "Gtk12");

$gtk->add_pm (
	'Gdk.pm' => '$(INST_LIBDIR)/Gtk/Gdk.pm',
	'Gtk.pm' => '$(INST_LIBDIR)/Gtk.pm',
	'LWP.pm' => '$(INST_LIBDIR)/Gtk/LWP.pm',
	'http.pm' => '$(INST_LIBDIR)/Gtk/LWP/http.pm',
	'io.pm' => '$(INST_LIBDIR)/Gtk/io.pm',
	'lazy.pm' => '$(INST_LIBDIR)/Gtk/lazy.pm',
	'Atoms.pm' => '$(INST_LIBDIR)/Gtk/Atoms.pm',
	'GtkCListModel.pm' => '$(INST_LIBDIR)/Gtk/CListModel.pm',
	'GtkColorSelectButton.pm' => '$(INST_LIBDIR)/Gtk/ColorSelectButton.pm',
	'LogHandler.pm' => '$(INST_LIBDIR)/Gtk/LogHandler.pm',
	'build/GtkTypes.pm' => '$(INST_ARCHLIBDIR)/Gtk/Types.pm',
	'build/GtkKeysyms.pm' => '$(INST_ARCHLIBDIR)/Gtk/Keysyms.pm'
);

$gtk->add_pm(
	'build/GtkTypesLazy.pm' => '$(INST_ARCHLIBDIR)/Gtk/TypesLazy.pm'
) if $Lazy;

@clean = qw( build/* */*.o */*/*.o);

require "../tools/gendefs.pl";

print "Invoking gendefs.pl with [",join(", ",$gtk->get_defs), "].\n";
print "Please wait, this may take a moment...\n";

@a = (	'-f', 'Gtk', 
		'-p', 'Gtk=Gtk',
		'-p', 'GdkGL=Gtk::Gdk::GL',
		'-p', 'GdkRgb=Gtk::Gdk::Rgb',
		'-p', 'Gdk=Gtk::Gdk',
		'-p', 'Gnome=Gnome',
		'-p', 'Panel=Gnome::Panel',
		'-m', 'Gtk');
if ($Lazy) {
	push @a, "-L";
}
foreach ($gtk->get_defs) {
	push @a, '-d', $_;
}
foreach ($gtk->get_headers) {
	push @a, '-i', $_;
}

$gtk->add_xs(gendefs::gendefs(@a));

# documentation
gendefs::gen_doc();
system($Config{perlpath}, "../tools/gendoc.pl", $gtk->get_xs);
system($Config{perlpath}, "../tools/gpdoc2pod");

use File::Basename;

foreach ( '../tools/gendefs.pl', '../tools/genext.pl', '../tools/gendoc.pl', '../tools/gpdoc2pod') {
	$gtk->add_pm($_, '$(INST_ARCHLIBDIR)/Gtk/Install/' . basename($_));
}

$depend = {'build/GtkDefs.c' => 'build/PerlGtkExt.h build/PerlGtkInt.h'};

$gtk->add_defines(@defines);
$gtk->save_config('build/IFiles.pm');

build_ksyms();
$gtk->write_ext("build/extension.xsh");

WriteMakefile(
	'DISTNAME' => 'Gtk-Perl',
    'NAME'	=> 'Gtk',
    'VERSION_FROM'	=> 'Gtk.pm',
    'XSOPT' => '-noversioncheck',
	'XSPROTOARG' => '-noprototypes',
	'depend' => $depend,
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'OPTIMIZE' => '-O2 -g',
	'MAN3PODS' => {
		'cookbook.pod' => '$(INST_MAN3DIR)/Gtk::cookbook.3pm',
		'Gtk.pm' => '$(INST_MAN3DIR)/Gtk.3pm',
		'objects.pod' => '$(INST_MAN3DIR)/Gtk::objects.3pm',
		'GtkCListModel.pm' => '$(INST_MAN3DIR)/Gtk::CListModel.3pm',
		'build/perl-gtk-ref.pod' => '$(INST_MAN3DIR)/Gtk::reference.3pm',
		},
	$gtk->get_makefile_vars,
);

sub MY::postamble {

'
Makefile: ' . join(' ',
	sort {$defs{$a} <=> $defs{$b}} keys %defs,
	<*/pkg*.pl>
	) . '

build/PerlGtkExt.h build/PerlGtkExt.c build/PerlGtkInt.h: build/GtkDefs.h ../tools/genext.pl
	$(PERL) ../tools/genext.pl Gtk

gendoc:
	$(PERL) ../tools/gendoc.pl $(XS_FILES)

';

}

sub MY::c_o {
	package MY; # so that "SUPER" works right
	my $inherited = shift->SUPER::c_o(@_);
	$inherited =~ s/CCCMD.*$/$&\n\t\@if test -f `basename \$*.o` -a "`basename \$*.o`" != "\$*.o"; then mv `basename \$*.o` \$*.o; fi/mg;
    $inherited;
}

sub MY::const_config
{
	package MY;
	my $self = shift;
	my $flags = $self->{'CCCDLFLAGS'};
	$flags =~ s/(-[fK]?\s*)pic\b/${1}PIC/;
	$self->{'CCCDLFLAGS'} = $flags;
	return $self->SUPER::const_config;
}

sub gtk_version {
	my($result);

	$result = `gtk-config --version`;
	chomp $result;
	return $result;
}

# build the keysyms mapping
sub build_ksyms {
	my ($dir) = `gtk-config --prefix`;
	chomp($dir);
	my $incfile;
	foreach ("/", "/gtk-1.2") {
		$incfile = "$dir/include$_/gdk/gdkkeysyms.h";
		last if -f $incfile;
	}

	open(OUT, '>build/GtkKeysyms.pm') || die "Cannot open build/GtkKeysyms.pm: $!";
	print OUT "# DO NOT EDIT!\n";
	print OUT "# This file was built by Gtk's Makefile.PL from $incfile.\n";
	print OUT "\npackage Gtk::Keysyms;\n\n";
	print OUT "%Gtk::Keysyms = (\n";
	if (open(IN, $incfile)) {
		while(<IN>) {
			print OUT "\t'$1'\t=>\t$2,\n" if /^\s*#\s*define\s+GDK_([a-zA-Z0-9_]+)\s+(\w+)$/;
		}
		close(IN);
	}
	print OUT ");\n\n1;\n";
	close(OUT);
}

