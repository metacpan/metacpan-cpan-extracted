#!/usr/bin/perl -w
use ExtUtils::MakeMaker;
use Config;

# data structure to handle sub-module detection and dependencies
# the key in the hash is the tag name
# the value is a hash ref with these keys:
# 	dir		string		directory with Makefile.PL (required)
#	order	number		compilation order (required)
#	check	sub ref		returns true if module can be compiled (required)
#	needed	bool		module must be compiled
#	skip	bool		do not compile nor check this module
#	force	bool		compile even if check fails
#	depends array ref	names of the submodules the module depends upon

%detect = (
	gtk => {order => 1, dir => 'Gtk', needed => 1, 
		check => sub {cconfig('gtk-config --version', '1\.2\.')}},
	gdkimlib => {order => 2, dir => 'GdkImlib', depends => [qw(gtk)],
		check => sub {cconfig('imlib-config --version', '1\.9\.') && `imlib-config --libs-gdk`}},
	gtkglarea => {order => 2, dir => 'GtkGLArea', depends => [qw(gtk)],
		check => sub {ccompile('#include <gtkgl/gtkglarea.h>', "", `gtk-config --cflags`,
					"-lgtkgl  -lGL -lGLU " . `gtk-config --libs`)}},
	gdkpixbuf => {order => 2, dir => 'GdkPixbuf', depends => [qw(gtk)],
		check => sub {cconfig('gdk-pixbuf-config --version', '0\.(8|9|1\d|2\d)\.?')}},
	gtkhtml => {order => 2, dir => 'GtkHTML', depends => [qw(gtk)],
		check => sub {cconfig('gnome-config --modversion gtkhtml', 'gtkhtml-0\.(8|9|10|11|12|13|14|15)')}},
	gtkxmhtml => {order => 2, dir => 'GtkXmHTML', depends => [qw(gtk)],
		check => sub {cconfig('gnome-config --libs gtkxmhtml', '-lgtkxmhtml')}},
	gnome => {order => 3, dir => 'Gnome', depends => [qw(gdkimlib)],
		check => sub {cconfig('gnome-config --version', '1\.[234]\.')}},
	gnomeprint => {order => 4, dir => 'GnomePrint', depends => [qw(gnome gdkpixbuf)],
		check => sub {cconfig('gnome-config --modversion print', 'gnome-print-0\.(2[5-9]|[3-9][0-9])')}},
	applets => {order => 4, dir => 'Applet', depends => [qw(gnome)],
		check => sub {cconfig('gnome-config --modversion applets', 'applets-1\.[234]\.') &&
			# --modversion capplet is broken
			cconfig('gnome-config --modversion capplet', 'capplet-')}},
	glade => {order => 4, dir => 'Glade', depends => [qw(gtk)],
		check => sub {cconfig('libglade-config --version', '0\.1\d')}},
);

@subdirs = ();
$dontguess = 0;

# autodetect available packages...
foreach (@ARGV) {
	if (/^--without-guessing$/) {
		$dontguess = 1;
		next;
	}
	if (/^--with(out)?-([^-]+)(-force)?/) {
		my $pkg = $2;
		die Usage("No module '$pkg'.\n") unless exists $detect{$pkg};
		$detect{$pkg}->{needed} = 1;
		$detect{$pkg}->{skip} = 1 if defined $1;
		$detect{$pkg}->{force} = 1 if defined $3;
	}
}
@ARGV = grep {!/^--with/} @ARGV;

foreach (sort {$detect{$a}->{order} <=> $detect{$b}->{order}} keys %detect) {
	my $pkg = $detect{$_};
	next if $pkg->{skip};
	next if ($dontguess && !$pkg->{needed});
	foreach my $submodule (@{$pkg->{depends}}) {
		die "Submodule $submodule is needed to build $_ but it appears \nit's misdetected or not selected for compilation.\n".Usage()
			unless ($detect{$submodule}->{ok});
	}
	if ($pkg->{check}->()) {
		push @subdirs, $pkg->{dir};
		$pkg->{ok} = 1;
		next;
	}
	if ($pkg->{force}) {
		warn "Adding package $_ even if it's misdetected.\n";
		push @subdirs, $pkg->{dir};
		$pkg->{ok} = 1;
		next;
	}
	if ($pkg->{needed}) {
		die "Package '$_' needed but it was not detected on your system.\n".
			"You may want to force it using --with-$_-force if you know better than me.\n";
	}
}

print "Packages to compile: ", join(' ', @subdirs), ".\n";

@clean = map {"build/$_"} qw(
GtkKeysyms.pm  IFiles.pm	PerlGtkExt.o  extension.xsh    perl-gtk-ref.xml
GtkDefs.c  GtkTypemap	  PerlGtkExt.c	PerlGtkInt.h  objects.xsh
GtkDefs.o  GtkTypes.pm	  PerlGtkExt.h	boxed.xsh     perl-gtk-ds.pod
);

WriteMakefile (
	'DISTNAME' => 'Gtk-Perl',
    'NAME'	=> 'Gtk::base',
	'NEEDS_LINKING' => 0,
	'PM' => {},
	'OPTIMIZE' => '-O2 -g',
    'VERSION_FROM'	=> 'Gtk/Gtk.pm',
    'XSOPT' => '-noversioncheck',
    'DIR'	=> [shift @subdirs], # only Gtk here
	'XSPROTOARG' => '-noprototypes',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'linkext' => {LINKTYPE => ''},
	'clean' => {FILES => join(' ', @clean)},
	'PREREQ_PM' => {'XML::Writer'=>0, 'XML::Parser' => 0},
);

# subdirs are handled here because we need to build dependent
# sub-module _before_ running perl Makefile.PL ...
sub MY::postamble {
	my $out='';
	foreach my $d (@subdirs) {
		$out .= <<"		EOM";

		subdirs :: $d/Makefile
			\@cd $d && \$(MAKE) all \$(PASTHRU)

		install ::
			cd $d && \$(MAKE) install INSTALLDIRS=\$(INSTALLDIRS)

		clean ::
			-cd $d && \$(TEST_F) Makefile && \$(MAKE) clean

		realclean purge :: clean
			-cd $d && \$(TEST_F) Makefile.old && \$(MAKE) -f Makefile.old realclean
			-cd $d && \$(TEST_F) Makefile && \$(MAKE)  realclean

		$d/Makefile: Makefile $d/Makefile.PL
			cd $d && \$(PERL) Makefile.PL \$(PASTHRU) INSTALLDIRS=\$(INSTALLDIRS)

		EOM
	}
	$out =~ s/^\t\t//gm;
	return $out;
}

sub cconfig {
	my ($cmd, $re) = @_;
	$out = `$cmd`;
	return 0 unless defined $out;
	return $out =~ /$re/;
}

sub ccompile {
	my ($headers, $main, $cflags, $libs) = @_;
	my $fname = "temctest";
	my $r;
	chomp($cflags, $libs);
	open(CTEST, ">$fname.c") || return 0;
	print CTEST <<"EOTEST";
$headers

int main (int argc, char* argv[]) {
$main;
}
EOTEST
	close(CTEST);
	$r = system("$Config{cc} -o $fname $fname.c $cflags $libs 2>/dev/null 1>/dev/null");
	warn("RUNNING: $Config{cc} -o $fname $fname.c $cflags $libs\n") if $ENV{VERBOSE};
	unlink($fname, "$fname.c");
	return $r == 0;
}

sub Usage {
	my $out = shift;
	my @pkgs = sort {$detect{$a}->{order} <=> $detect{$b}->{order}} keys %detect;
	$out .= "Available modules: @pkgs.\n\n";
	$out .= "You can disable the inclusion of a module using --without-pkgname.\n";
	$out .= "If a package is misdetected and you still want it to compile \nuse --with-pkgname-force.\n";
	$out .= "To disable autodetection of modules use --without-guessing.\n";
}


