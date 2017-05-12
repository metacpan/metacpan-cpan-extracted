use ExtUtils::MakeMaker;
use Config;
use File::Spec;

my $e = $Config{'exe_ext'};
my $o = $Config{'obj_ext'};
my $exeout_flag = '-o ';

if ($^O eq 'MSWin32') {
    if ($Config{'cc'} =~ /^cl/i) {
	$exeout_flag = '-Fe';
    }
    elsif ($Config{'cc'} =~ /^bcc/i) {
	$exeout_flag = '-e';
    }
}

WriteMakefile(
    NAME	    => "Debug::Flags",
    VERSION_FROM    => "lib/Debug/Flags.pm",
    PL_FILES	    => { 'defsubs_h.PL' => 'defsubs.h' },
    MAN3PODS	    => {},
    clean	    => {
	FILES	    => "perl$e *$o Flags.c defsubs.h *~"
    }
);

package MY;

sub post_constants {
    "\nLIBS = $Config::Config{libs}\n"
}

sub headerfilefile {
    push @makefileopts, MAN3PODS => {};
}

sub headerpath {
    return File::Spec->catdir($Config::Config{archlibexp}, "CORE");
}

sub MY::postamble {
    my $headerpath = headerpath();
    my @headers = map { File::Spec->catfile($headerpath, $_) } qw(perl.h);
    my $noecho = shift->{NOECHO};

"
Flags\$(OBJ_EXT) : defsubs.h

defsubs.h :: @headers defsubs_h.PL
	\$(PERL) -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) defsubs_h.PL defsubs.h $headerpath
"
}

sub MY::processPL {
    my $text = shift->SUPER::processPL(@_);
    # Append our extra parameter
    $text =~ s/^\t.*defsubs_h\.PL.*/$& . ' ' . headerpath()/me;
    $text;
}
