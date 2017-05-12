use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

################################################################
##    if built from a parent directory,                        #
##    at install, the parent Makefile must execute             #
##                                                             #
##          as step immediately after 'all'                    #
## @cd Tools && $(MAKE) relink4_$(LINKTYPE)_install $(PASTHRU) #
##                                                             #
################################################################

unless ((caller)[1]) {
  print "\n	WARNING... Please run from the parent directory\n\n";
}
$rebuild	= '.rebuild4test';

# generate a permanently OLD time for convenience
my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
#                      YYCC MM  DD  HH  MM	current - 10 years
my $oldtime = sprintf("%04d%02d%02d%02d%02d ",$year+1890,$mon+1,$mday,$hour,$min);

my $relink_LD_RUN_PATH	= '/lib:/usr/local/lib';
my $relink_LIBS		= '-ldb -ldbtarpit';
my $relink_OBJECT	= 'Tools$(OBJ_EXT)';

WriteMakefile(
    'NAME'		=> 'IPTables::IPv4::DBTarpit::Tools',
    'VERSION_FROM'	=> 'Tools.pm', # finds $VERSION
    'LIBS'		=> ['-ldb '], # e.g., '-lm'
#    'LIBS'		=> ['-ldb -ldbtarpit'], # e.g., '-lm'
#    'INC'		=> "-I/usr/local/lib",
    'depend'		=> {'Tools.c'	=> 'bdbtarpit.o xs_include/miniSocket.inc',
			},
    'OBJECT'		=> "Tools.o bdbtarpit.o",
#    'OBJECT'		=> "Tools.o",
    'clean'		=> { FILES	=> "bdbtarpit.* *.bs *.o *~ $rebuild tmp*"},
);

sub MY::top_targets {
  package MY;
  my $inherited = shift->SUPER::top_targets(@_);
  $inherited =~ s/\n(pure_all\s+::.+)/\n$1 README/;
  $inherited .= q|
bdbtarpit.o	: bdbtarpit.c bdbtarpit.h
	$(CC) -c $(INC) $(CCFLAGS) $(OPTIMIZE) bdbtarpit.c

bdbtarpit.c	:
	@$(CP) ../bdbtarpit.c ./
	@$(NOOP)

bdbtarpit.h	:
	@$(CP) ../bdbtarpit.h ./
	@$(NOOP)
|;
}

sub inst_split {
  my $test = '# Linking for testing is done by default. The Tools module is
# linked directly to the object. At install time, the Tools module
# is re-linked to the shared library but will revert back to test mode 
# for other operations on the next make.

' . shift;
  my $type = shift;
  my $TYPE = '$(INST_'. uc $type . ')';
  $test =~ s#\n(\$\(INST.[^\s]+)\s*:(.+)#\n$1 : $rebuild $2#;	### dependency to rebuild if linked for install

  my $real = qq|
.PHONY: link4_${type}_install

relink4_${type}_install	:|. $';

  $real =~ s/\$\@/$TYPE/g;
  while ($real =~ /\s$/) {chop $real};
  while ($test =~ /\s$/) {chop $test};
#  $real =~ s/^\n//;

  foreach( qw(
	OBJECT
	EXTRALIBS
	LDFROM
	LDLOADLIBS
	LD_RUN_PATH
      )
  ) {  $real =~ s/\($_\)/(R_$_)/g;  };

  $real .= q|
	@echo LINKED |. $type . q| library for INSTALLATION
	@$(RM_F) |. $rebuild . "\n";
  $test .= q|
	@$(TOUCH) |. $rebuild . q|
	@echo LINKED |. $type . q| library for TESTING
|;
  $test .= $real;
};

sub MY::dynamic_lib {
  my $inherited;
  {
    package MY;
    $inherited = shift->SUPER::dynamic_lib(@_);
  }
  ($inherited = inst_split($inherited,'dynamic')) =~ s/(LD_RUN_PATH=([^\s]+))/$1 LD_LIBRARY_PATH=$2/g;
  $inherited;
}

# poorly tested! I have only an elf machine and while it builds static libs,
# it does not do it completely the way one would expect because it does not 
# properly build perl.a -- which fails

sub MY::static_lib {
  my $inherited;
  {
    package MY;
    $inherited= shift->SUPER::static_lib(@_);
  }
  inst_split($inherited,'static');
}

sub MY::post_constants {
  package MY;
  use Config;
  my $post_constants = $Config{scriptdirexp} .'/pod2text';
  if (-e $post_constants) {
    $post_constants = q|   
MY_POD2TEXT = |. $post_constants .q|
|;
  } else {
    $post_constants = q|
MY_POD2TEXT = echo "perl distro missing 'pod2text' to convert " 
|;
  }
  $post_constants .= q|
R_OBJECT = |. $relink_OBJECT . q|
R_LDFROM = $(R_OBJECT)
R_LDLOADLIBS = |. $relink_LIBS . q|
R_EXTRALIBS = $(EXTRALIBS)
R_LD_RUN_PATH = |. $relink_LD_RUN_PATH . q|

|;
}

sub MY::postamble {
  my $postamble = q|
README	: Tools.pm
	@$(MY_POD2TEXT) Tools.pm > README

| .
$rebuild . q| :
	@$(NOOP)

|;
}

#sub MY::dist_basic {'
#  package MY;
#  my $inherited = shift->SUPER::dist_basics(@_);
#dist	:
#	@echo Please use top level directory for distribution'}
#
sub MY::dist_core {
  package MY;
  my $inherited = shift->SUPER::dist_core(@_);
  $inherited =~ s/\ndist(\s+:\s+.+)/\nreally_dist${1}/;
  $inherited = q|
.PHONY: dist
dist	:
	@echo	"# #############################################################	#"
	@echo	"#								#"
	@echo	"# WARNING: do not distribute from this directory!!!		#"
	@echo	"# This module is dependent on the parent directory for some of	#"
	@echo	"# its components, including the shared library, and can not be	#"
	@echo	"# independently distributed or built on a stand-alone basis.	#"
	@echo	"# Please create the distribution from the parent directory.	#"
	@echo	"#								#"
	@echo	"# #############################################################	#"
	@echo	"#								#"
	@echo	"#	if you really want to create a distribution, type:	#"
	@echo	"#								#"
	@echo	"#	make really_dist					#"	
	@echo	"#								#"
	@echo	"# #############################################################	#"

|.  $inherited;
}

sub MY::install {
  package MY;
# get the real inherited stuff
  $inherited = shift->SUPER::install(@_);
  $inherited =~ s/\n(install\s+::)/\nreally_$1/;
  $inherited =~ s/\b(all)\b/$1 relink4_\$(LINKTYPE)_install/g;
  $inherited .= q|
.PHONY : install

install	::
	@echo
	@echo Please build in the parent directory. This module
	@echo has dependencies in the parent directory, including
	@echo the shared library. If you really have a reason to
	@echo install from this directory, then type:
	@echo
	@echo		make really_install
	@echo

|;
};

sub MY::const_config {
  package MY;
  $inherited = shift->SUPER::const_config(@_);
  return q|LANG=en_US
SUPPORTED=en_US:en
|. $inherited;
}
