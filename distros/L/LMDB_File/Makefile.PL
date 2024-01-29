use 5.010000;
use strict;
use ExtUtils::MakeMaker;
use Config;

if($Config{archname} =~ /686/) {
    warn "liblmdb isn't supported in your platform, sorry.\n";
    exit 0;
}

my $lmdb_dir = 'liblmdb/libraries/liblmdb';

my $LNAME = 'LMDB';
my $NAME = "${LNAME}_File";
my ($LIBS) = map { /^LIBS=(.*)$/ && $1 || () } @ARGV;
my ($INC) = map { /^INC=(.*)/ && $1 || () } @ARGV;
my $NOSYS = grep /\bNOSYSTEM\b/, @ARGV;

my $myextlib = '';
{
    $LIBS ||= '';
    my @libdata = ExtUtils::Liblist->ext($LIBS || '-llmdb', 0, 'mdb_env_create');
    my @stdinc = qw(/usr/include /usr/local/include);
    push @stdinc, $libdata[3] if $libdata[3];
    my($Head) = grep -f "$_/lmdb.h", @stdinc;
    if(!$NOSYS && ($INC || $Head) && $libdata[0]) {
	$INC ||= "-I$Head" if -f "$libdata[3]/lmdb.h";
	warn "Will use SYSTEM lmdb in @{[$libdata[3] || $Head]}\n";
	$LIBS ||= '-llmdb';
	warn "If that path isn't a standard one, you may need to set LD_LIBRARY_PATH!\n"
	    if($libdata[4][0] =~ /.so/);
    } elsif (eval { require Alien::LMDB }) {
	my $alien = Alien::LMDB->new;
	$INC = $alien->cflags;
	$LIBS = $alien->libs;
	warn "Using Alien::LMDB (" . $alien->install_type . "): " . $alien->dist_dir . "\n";
    } else {
	unless(-e "$lmdb_dir/Makefile") {
	    warn "Clone lmdb from its repo and put a copy/link in 'liblmdb' directory";
	    exit 0;
	}
	$myextlib = "$lmdb_dir/liblmdb\$(LIB_EXT)";
    }

    $LIBS .= ' -lrt' if $^O =~ /solaris/i;

    if($myextlib) {
	#lmdb's Makefile needs care
	if($^O =~ /MSWin32|freebsd/i) {
	    if($ENV{AUTOMATED_TESTING}) {
		warn "Can't build liblmdb in $^O without human help, sorry\n";
	    } else {
		warn "Please install a recent version of liblmdb or try to build the included one.\n";
	    }
	    exit 0;
	}
	warn "Will try to build and use my included copy of liblmdb.\n";
    }

    if($^O =~ /MSWin32/) {

    } else {
	#LMDB needs pthread, so perl needs to be linked with.
	unless ($Config{perllibs} =~ 'pthread') {
	    warn "LMDB_File needs a perl linked with 'pthread'.\n" .
		 "The module will be build, but can't be loaded\n" .
		 "without proper initialization.\n(See perl #122906)\n";
	    $LIBS .= ' -lpthread';
	}
    }
}

WriteMakefile(
    NAME		=> $NAME,
    MIN_PERL_VERSION	=> '5.10.0',
    CONFIGURE_REQUIRES	=> { 'ExtUtils::MakeMaker' => '6.64' },
    VERSION_FROM	=> "lib/$NAME.pm", # finds $VERSION
    PREREQ_PM		=> {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM	=> "lib/$NAME.pm", # retrieve abstract from module
    AUTHOR		=> 'Salvador Ortiz <sog@msg.com.mx>',
    DEFINE		=> '', # e.g., '-DHAVE_SOMETHING'
    XSPROTOARG		=> '-noprototypes',
    LICENSE		=> 'artistic_2',
    META_MERGE		=> {
	"meta-spec" => { version => 2 },
	resources => {
	    repository => {
		type => 'git',
		url =>  'git://github.com/salortiz/LMDB_File.git',
		web =>  'https://github.com/salortiz/LMDB_File',
	    }
	}
    },
    TEST_REQUIRES	=> {
	'Test::More' => 0,
	'Test::Exception' => 0,
	#'Test::ZeroCopy' => 0	 Dependency chain broken in String::Slice
    },
    OBJECT		=> '$(O_FILES)', # link all the C files too
    LIBS		=> $LIBS,
    ($myextlib ? (
	MYEXTLIB	=> $myextlib,
	INC		=> "-I$lmdb_dir",
	) : (
	INC		=> $INC
	)
    ),
    realclean		=> { FILES => 'const-*.inc' }
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (
    qw(MDB_APPEND MDB_APPENDDUP
    MDB_BAD_RSLOT MDB_BAD_DBI MDB_BAD_TXN MDB_BAD_VALSIZE
    MDB_CP_COMPACT
    MDB_CORRUPTED MDB_CREATE MDB_CURRENT MDB_CURSOR_FULL
    MDB_DBS_FULL MDB_DUPFIXED MDB_DUPSORT
    MDB_FIXEDMAP
    MDB_INCOMPATIBLE MDB_INTEGERDUP MDB_INTEGERKEY MDB_INVALID
    MDB_KEYEXIST MDB_LAST_ERRCODE
    MDB_MAPASYNC MDB_MAP_FULL MDB_MAP_RESIZED MDB_MULTIPLE
    MDB_NODUPDATA MDB_NOLOCK MDB_NOMEMINIT
    MDB_NOMETASYNC MDB_NOOVERWRITE MDB_NORDAHEAD
    MDB_NOSUBDIR MDB_NOSYNC MDB_NOTFOUND MDB_NOTLS
    MDB_PAGE_FULL MDB_PAGE_NOTFOUND MDB_PANIC
    MDB_RDONLY MDB_READERS_FULL MDB_RESERVE MDB_REVERSEDUP MDB_REVERSEKEY
    MDB_SUCCESS
    MDB_TLS_FULL MDB_TXN_FULL
    MDB_VERSION_FULL MDB_VERSION_MAJOR MDB_VERSION_MINOR
    MDB_VERSION_MISMATCH MDB_VERSION_PATCH
    MDB_WRITEMAP),
    # My own
    qw(LMDB_OFLAGN),
    {name=>"MDB_VERSION_STRING", type=>"PV", macro=>"1"},
    {name=>"MDB_VERSION_DATE", type=>"PV", macro=>"1"},
    {name=>"MDB_FIRST", macro=>"1"},
    {name=>"MDB_FIRST_DUP", macro=>"1"},
    {name=>"MDB_GET_BOTH", macro=>"1"},
    {name=>"MDB_GET_BOTH_RANGE", macro=>"1"},
    {name=>"MDB_GET_CURRENT", macro=>"1"},
    {name=>"MDB_GET_MULTIPLE", macro=>"1"},
    {name=>"MDB_LAST", macro=>"1"},
    {name=>"MDB_LAST_DUP", macro=>"1"},
    {name=>"MDB_NEXT", macro=>"1"},
    {name=>"MDB_NEXT_DUP", macro=>"1"},
    {name=>"MDB_NEXT_MULTIPLE", macro=>"1"},
    {name=>"MDB_NEXT_NODUP", macro=>"1"},
    {name=>"MDB_PREV", macro=>"1"},
    {name=>"MDB_PREV_DUP", macro=>"1"},
    {name=>"MDB_PREV_NODUP", macro=>"1"},
    {name=>"MDB_SET", macro=>"1"},
    {name=>"MDB_SET_KEY", macro=>"1"},
    {name=>"MDB_SET_RANGE", macro=>"1"}
  );
  ExtUtils::Constant::WriteConstants(
     NAME         => $NAME,
     NAMES        => \@names,
     DEFAULT_TYPE => 'IV',
     C_FILE       => 'const-c.inc',
     XS_FILE      => 'const-xs.inc',
  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

sub MY::postamble {
    if($myextlib) {
	if ($^O =~ /MSWin32/ && !defined($ENV{SYSTEMROOT})) {
	    if ($Config{'make'} =~ /dmake/i) {
		return <<'EOT';
$(MYEXTLIB): liblmdb/Makefile
@[
	cd liblmdb/libraries/liblmdb
	$(MAKE) XCFLAGS=-fPIC liblmdb$(LIB_EXT)
	cd ..
]
EOT
	    } elsif ($Config{'make'} =~ /nmake/i) {
		return <<'EOT';
$(MYEXTLIB): liblmdb/Makefile
	cd liblmdb/libraries/liblmdb
	$(MAKE) XCFLAGS=-fPIC liblmdb$(LIB_EXT)
	cd ..
EOT
	    }
	} else {
	    return <<'EOT';
$(MYEXTLIB): liblmdb/libraries/liblmdb/Makefile
	cd liblmdb/libraries/liblmdb && $(MAKE) XCFLAGS=-fPIC liblmdb$(LIB_EXT)
EOT
	}
    }
}
