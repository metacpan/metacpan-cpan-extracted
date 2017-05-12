use ExtUtils::MakeMaker;

use Config;

print <<EOF;

WARNING: This module is architecture-dependent and will not likely work
         on lesser-used architectures (see Changes). If the module (esp.
         aio_read and aio_write) doesn't work, please report this and I'll
         fix it for you. I promise ;)

EOF

$Config{osvers} >= 2.4 or print <<EOF;

WARNING: This module requires 64 bit file offset functionality only found
         in linux-2.4 and later. You can still compile this module on
         older linuxes, but it won't run.

DEVELOPERS: It is not difficult to get rid of this limitation, ask me and
            I'll tell you what you need to change (and test, so I can add it!).

EOF

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text AIO.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "Linux::AIO",
    VERSION_FROM => "AIO.pm",
});

sub MY::postamble {
   <<EOF;

# set \$VERSION in all modules
setver:
	\$(PERL) -pi -e 's/^(\\s*\\\$\$VERSION\\s*=\\s*).*\$\$/\$\${1}\$(VERSION);/' *.pm

EOF
}

# now get rid of -fpic, because gcc can't use syscall'ed closures
# from within pic code on x86.

use Config;

if ($Config{cppsymbols} =~ /__i386=1/) {
   for ($mm->{CCDLFLAGS}, $mm->{CCCDLFLAGS}, @{$mm->{RESULT}}) {
      s/\B-f(pic|PIC)\b//g
   }

   # Put -O at the front so as not to change any existing optimisation level
   # Need optimization of some form turned on to inline syscall() so that it
   # sets the local errno
   $mm->{OPTIMIZE} = '-O ' . $mm->{OPTIMIZE};
}

$mm->flush;

