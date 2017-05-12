use ExtUtils::MakeMaker;

# Gather some variables for tests.
$| = 1;

$catalog = '/etc/fs/samfs/sam_historian';
# This keeps the variables $dir, $eq, and $catalog from a previous run.
eval { require 't/vars.pl'; };

print <<'EOF';
We need some information about your installation of SamFS to be able
to run the tests. Please answer a few questions.

We would like to know where the SamFS include files and
libraries are located.

We will need a directory in a SamFS filesystem where we can create
files and symlinks for the stat() and lstat() tests.

Then we need the equipment ordinal of a tape drive or MO drive
to test the ndevstat() call. Note that this call can only be
executed by the superuser. Refer to the README for instructions.

Finally, we need the location of a catalog file to test the
catalog calls.

All tests we run are non-destructive. The only changes we make are
the files and symlinks that will be created in the directory
you specify. Anything else happens either here or in your perl
installation when you do the 'make install'.

EOF

$SamFS_dir = prompt("Where is SamFS located:", '/opt/SUNWsamfs');
unless (-d $SamFS_dir && -d "$SamFS_dir/include" && -d "$SamFS_dir/lib") {
    print "Sorry, you must specify the SamFS location.\n";
    exit 0;
}

$dir = prompt("A directory in a SamFS filesystem writable by this user:",
              $dir);
unless (length($dir)) {
    print "Sorry, but you have to provide an answer. There is no default.\n";
    exit 0;
}
unless (-d $dir) {
    print "Sorry, but $dir is not a directory.\n";
    exit 0;
}
unless (-w _) {
    print "Sorry, but $dir is not writeable by you.\n";
    exit 0;
}

$eq = prompt("The equipment ordinal of a tape drive or MO drive:",
             $eq);
unless (length($eq)) {
    print "Sorry, but you have to provide an answer. There is no default.\n";
    exit 0;
}
unless ($eq =~ /^\d+$/) {
    print "Sorry, but the answer must be numeric.\n";
    exit 0;
}

$catalog = prompt("The location of a catalog file:",
                  $catalog);
unless (-e $catalog) {
    print "Sorry, but $catalog does not exist.\n";
    exit 0;
}
unless (-f _) {
    print "Sorry, but $catalog is not a file.\n";
    exit 0;
}
unless (-r _) {
    print "Sorry, but $catalog is not readable by you.\n";
    exit 0;
}

open (VARS, '>t/vars.pl') || die "Can't open t/vars.pl for writing: $!\n";
print VARS <<"EOF";
\$dir = '$dir';
\$eq = $eq;
\$catalog = '$catalog';
EOF
close(VARS);

print <<"EOF";

We will now create a file '$dir/archived'.
Please make sure that this file has been archived before running
any test. This file is used to test the stat() system call.
EOF

open(ARCHIVED, ">$dir/archived") ||
  die "Cannot open $dir/archived for writing: $!\n";
seek(DATA, 0, 0);
print ARCHIVED <DATA>;
close(ARCHIVED);

# Early versions of SamFS omitted the definition of sam_devstr from
# lib.h. Find out if it is defined in *this* version. We do this
# dynamically to avoid pinpointing the version that introduced teh
# definition.

WriteMakefile(
	      'NAME'	     => 'Filesys::SamFS',
	      'VERSION_FROM' => 'SamFS.pm',
              'DEFINE'       => "@ARGV",
	      'LIBS'	     => ["-R$SamFS_dir/lib -L$SamFS_dir/lib -lsam"],
	      'INC'	     => "-I$SamFS_dir/include",
	      'PM'           => {'SamFS.pm' => '$(INST_LIBDIR)/SamFS.pm'},
	      'MAN3PODS'     => {'SamFS.pm' => '$(INST_MAN3DIR)/Filesys::SamFS.$(MAN3EXT)'},
	      'realclean'    => {FILES => 't/vars.pl'}
);

sub MY::postamble {
  return <<'EOF';
.SUFFIXES: .pod .html
.pod:
	$(FULLPERL) -MPod::Text -e "pod2text('$<')" > $@
.pod.html:
	$(FULLPERL) -MPod::Html -e "pod2html('--noindex', '--outfile', '$@', '$<')"

docfiles: README README.html Changes Changes.html
EOF
}

__DATA__
We need this for the cute "copy this file to $dir/archived".
