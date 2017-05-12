use 5.005;
use ExtUtils::MakeMaker;
use Config;
use File::Spec;
#use strict;
use warnings;

$Verbose = 1;

my ($INC, $DEFINE, $LIBS, $O_FILES, $STATIC_BUILD);

our $VERSION='';
eval `grep 'VERSION *=' lib/HTML/Template/Pro.pm`;

if (grep {/^DYNAMIC=1/} @ARGV) {
    $STATIC_BUILD=0;
    $INC='-I/usr/include/htmltmplpro';
    $DEFINE='-DUSE_SYSTEM_HTP_HEADER';
    $LIBS='-lhtmltmplpro';
    $O_FILES='';
} else {
    $STATIC_BUILD=1;
    $INC='-I.';
    $DEFINE='-DHTMLTMPLPRO_STATIC';
    $LIBS='-lm';
    $O_FILES='$(O_FILES)';
}

my %DEF=(
    MAINTAINER  => $^O eq 'linux' && -d '.git' ? 1 : 0,
    PCRE  => 1,
    DEBUG => 0,
    MMAP  => 1,
    IMITATE=>0,
);
$DEF{PACKAGE_VERSION}=$VERSION if $VERSION;


&configure() if $STATIC_BUILD;

### --------------------------------------
### testing whether sources are consistent
### --------------------------------------

unless ((stat('test_crlf.out'))[7] == 47) {
    my @tests_to_skip=('HTML-Template-Pro.t', 'HTML-Template.t', 'realloc.t');
    print <<ENDTEXT;
#=================================
#
#          WARNING!!!
#   test data are corrupted!
#   may be CRLF conversion?
#   skipping most of tests!!!!
#   skipped: 
#   @tests_to_skip
#
#=================================
ENDTEXT
    sleep(2);
    chdir 't';
    # test that fail with corrupted data
    unlink @tests_to_skip;
    chdir '..';
}

WriteMakefile(
    NAME              => 'HTML::Template::Pro',
    VERSION_FROM      => 'lib/HTML/Template/Pro.pm', # finds $VERSION
    PREREQ_PM         => {'JSON', => 2.0, # safe to skip
			  'File::Path' => 2.0,
			  'File::Spec' => 0,
			  'Test::More' => 0,
			  }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/Template/Pro.pm', # retrieve abstract from module
       AUTHOR         => 'I. Yu. Vlasenko <viy@altlinux.org>') : ()),
    LIBS              => [$LIBS],
    DEFINE            => $DEFINE, # e.g., '-DHAVE_SOMETHING'
    INC               => $INC, 
    OBJECT            => $O_FILES, # link all the C files too
    # license is: as perl itself or Artistic or GPL2+ or LGPL2+.
    # 'perl' is a valid string for META1.4 spec
    # https://rt.cpan.org/Public/Bug/Display.html?id=44210
    LICENSE           => 'perl',
#   PERL_MALLOC_OK    => 1 # read first, static only
    depend => {
        'expr.o'    => 'calc.inc exprtool.inc exprpstr.inc',
        'procore.o' => 'proscope.inc pstrutils.inc loadfile.inc loopvar.inc',
    },
);

sub MY::postamble {
    return '' unless $DEF{MAINTAINER};
    return <<'MAKE_FRAG';
expr.c: calc.inc exprtool.inc exprpstr.inc
procore\$(OBJ_EXT): loadfile.inc tagstack.inc
optint.c: optint.re2c.m4

#proparam.c proparam.h: pparam.h
#	./pparam2proparam

rpm: dist
	rpmbuild -ta --clean HTML-Template-Pro-$(VERSION).tar.gz

.re2c.c:
	re2c $< > $@

%.re2c: %.re2c.m4
	m4 -P $< > $@

MANIFEST.git::
	git-ls-files > MANIFEST.git

index.html: README Makefile
	echo '<html><body><p><a href="http://sourceforge.net"><img src="http://sourceforge.net/sflogo.php?group_id=138507&amp;type=5" width="210" height="62" border="0" alt="SourceForge.net Logo" /></a><br> <a href="http://sourceforge.net/projects/html-tmpl-pro/">SourceForge Summary page of the project</a><br><a href="http://www.imath.kiev.ua/~vlasenko/">Home page of the author</a><br><a href="http://prdownloads.sourceforge.net/html-tmpl-pro/HTML-Template-Pro-$(VERSION).tar.gz?download">Download</a><p><pre>' > $@
	cat $< >> $@
	echo '</pre></body></html>' >> $@

TARBALL=HTML-Template-Pro-$(VERSION).tar.gz
SF_HOME='viy2@html-tmpl-pro.sf.net:/home/groups/h/ht/html-tmpl-pro/htdocs/'
sourceforge: tardist index.html
	ssh-add ~/.ssh/id_dsa.sf
	( echo cd uploads;	\
	  echo put $(TARBALL);	\
	  echo quit ) | /usr/bin/sftp viy2@frs.sourceforge.net
	scp index.html $(SF_HOME)
 
json::
	rm -rf templates-Pro/json
	export HTP_DUMP=1; $(MAKE) test

.SUFFIXES: .re2c
MAKE_FRAG
}

# those tests are based on ones from Time-HiRes-01.20

sub try_compile_and_link {
    my ($c, $cccmd, $ccflags, $verbose) = @_;
    $verbose = 1 unless defined $verbose;
    my ($ok) = 0;
    my ($tmp) =  File::Spec->catfile( File::Spec->tmpdir(), "tmp$$" );
    local(*TMPC);

    my $obj_ext = $Config{obj_ext} || ".o";
    unlink("$tmp.c", "$tmp$obj_ext");

    if (open(TMPC, ">$tmp.c")) {
	print TMPC $c;
	close(TMPC);
	my $COREincdir = File::Spec->canonpath(File::Spec->catfile($Config{'archlibexp'}, 'CORE'));
	$ccflags .= ' '. $Config{'ccflags'} . ' ' . "-I$COREincdir";
	my $cc=$Config{'cc'};
	$cc||='cc';
	if ($^O eq 'VMS') {
	    my $perl_core = $Config{'installarchlib'};
	    $perl_core =~ s/\]$/.CORE]/;
	    $cccmd = "$cc /include=(perl_root:[000000],$perl_core) $tmp.c"; 
	}
	$cccmd = "$cc -o $tmp $ccflags $tmp.c @$LIBS"
	 unless (defined $cccmd);
	print "trying $cccmd\n" if $verbose;
	system($cccmd);
	if ($^O eq 'VMS') {
	    $ok = -s "$tmp$obj_ext" && -x _;
	    unlink("$tmp.c", "$tmp$obj_ext");
	}
	else
	{
		my $exe = $tmp . ($Config{_exe} || '');
	    $ok = -s $exe && -x _;
	    unlink("$tmp.c", $exe);
	}
    }
    
    $ok;
}

sub has_header {
    my $header=shift;
    print "looking for $header...\n";
    if (try_compile_and_link('
#include <'.$header.'>
    static int foo()
    {
	return 0;
    }
    int main (int argc, char** argv)
    {
	foo();
    }
',undef, '')){
	print "$header found.\n";
	return 1;
    }
    print "$header not found.\n";
    return 0;
}

sub has_pcre {
    print "looking for pcre...\n";
    if (try_compile_and_link('
#include <pcre.h>
    static int foo()
    {
	return 0;
    }
    int main (int argc, char** argv)
    {
	foo();
    }
',undef, '-I/usr/include/pcre -lpcre')){
	print "pcre found.\n";
	return 1;
    }
    print "pcre not found.\n";
    return 0;
}

sub has_mmap {
    print "looking for mmap...\n";
    if (try_compile_and_link('
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

static
char*
mmap_load_file (const char* filepath) {
  int fd;
  struct stat st;
  size_t size_in_bytes;
  char* memarea=NULL;
  fd = open(filepath, O_RDONLY);
  if (fd == -1) return memarea; /* {NULL,NULL} */
  fstat(fd, &st);
  size_in_bytes = st.st_size;
  /* mmap size_in_bytes+1 to avoid crash with empty file */
  memarea = (char *) mmap(0, size_in_bytes+1,  PROT_READ,  MAP_SHARED, fd, 0);
  close(fd);
  return memarea;
}
    int main (int argc, char** argv)
    {
	mmap_load_file("file");
    }
',undef, '')){
	print "mmap found.\n";
	return 1;
    }
    print "mmap not found.\n";
    return 0;
}

sub has_func {
    my ($func_call)=@_;
    print "looking for $func_call\n";
    if (try_compile_and_link('
#include <string.h>
    int main (int argc, char** argv)
    {
	'.$func_call.';
    }
',undef, '')){
	print "$func_call found.\n";
	return 1;
    }
    print "$func_call not found.\n";
    return 0;
}

sub find_int64 {
    foreach my $type ('__int64','long long','int64_t','long','int') {
	return $type if try_as_int64($type);
    }
    return;
}

sub try_as_int64 {
    my $type=shift;
    print "looking for int64: trying $type...";
    if (try_compile_and_link('
    int main (int argc, char** argv)
    {
	if (sizeof('.$type.')==8) return 0; 
        return sizeof('.$type.');
    }
',undef, '',0)){
	print "Ok.\n";
	return 1;
    }
    print "no.\n";
    return 0;
}

sub configure {
    $DEF{PCRE}=has_pcre();
    if ($^O eq 'os2' or $^O eq 'dos') {
	$DEF{MMAP}=0;
    } elsif ($^O eq 'MSWin32') {
    # win 32 mmap is disabled by default
#    $DEF{MMAP}=1;
    $DEF{MMAP}=0;
    # no, compiler is yet unknown here;
    # and some creepy M**soft tools may not understand long long :(
    # $DEF{INT64_NAME} = "long long";?
    } else {
	$DEF{HAS_MMAP}=has_mmap();
    }
    $DEF{INT64_NAME} ||= find_int64();
    $DEF{INT64_NAME} ||= $Config{i64type};

    my $i;
    for ($i=0; $i<@ARGV; $i++)  {
	if ($ARGV[$i]=~/^(PCRE|PEDANTIC|DEBUG|MMAP|IMITATE)=(.+)/) {
	    $DEF{$1}=$2;
	} else {
	    next;
	}
	splice @ARGV, $i, 1;
	$i--;
    }

    #$DEF{MMAP}=0 if $^O =~ /MSWin32/ and $DEF{'IMITATE'};
    $DEFINE.=' -DDEBUG' if $DEF{DEBUG};
    $DEFINE.=' -DUSE_MMAP ' if $DEF{MMAP};

    $DEFINE.=' -DHAVE_STDINT_H ' if has_header('stdint.h');
    $DEFINE.=' -DHAVE_INTTYPES_H ' if has_header('inttypes.h');
    $DEFINE.=' -DHAVE_STRDUP' if  has_func('strdup("str")');
    $DEFINE.=' -DHAVE__STRDUP' if  has_func('_strdup("str")');
    
    $DEFINE.=' -DHAVE_SYS_MMAN_H -DHAVE_SYS_STAT_H' if ($DEF{HAS_MMAP});
    $DEFINE.=' -DCOMPAT_ON_BROKEN_QUOTE -DCOMPAT_ALLOW_NAME_IN_CLOSING_TAG' if ($DEF{'IMITATE'});
    $DEFINE.=' -pedantic -DPEDANTIC' if ($DEF{'PEDANTIC'});
    $DEFINE.=' -DINT64_NAME="' . $DEF{'INT64_NAME'}.'"' if ($DEF{'INT64_NAME'});
    if ($DEF{'INT64_NAME'}) {
	if ($DEF{'INT64_NAME'} eq "long long") {
	    $DEFINE.=' -DSIZEOF_LONG_LONG=8';
	} elsif ($DEF{'INT64_NAME'} eq "long") {
	    $DEFINE.=' -DSIZEOF_LONG=8';
	}
    }

    if ($DEF{PCRE}) {
	$INC.=' -I/usr/include/pcre';
	$DEFINE.=' -DHAVE_PCRE';
	$LIBS.=' -lpcre';
	print "
=====================================================================
build with libpcre (Stanislav Yadykin's regexp extension) is enabled.
=====================================================================
if you have not installed libpcre, you still can build the module 
without libpcre (with this extension disabled) using 
perl Makefile.PL PCRE=0
";
    } else {
	print "
=================================================
build with libpcre is disabled.
=================================================
Stanislav Yadykin's regexp extension is disabled.
";
    }

    if ($DEF{IMITATE}) {
	print "
=====================================================================
Compatibility mode for syntactically incorrect templates is enabled.
Note, that this mode could be a bit slower than default but it will be
useful if you rely on HTML::Template behaviour in undefined cases.
=====================================================================
";
    } else {
	print "
=====================================================================
Compatibility mode for syntactically incorrect templates is disabled.
It is the fast default.
=====================================================================
";
    }
}
