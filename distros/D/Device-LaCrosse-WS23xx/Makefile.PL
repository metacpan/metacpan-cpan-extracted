use strict;
use warnings;
use ExtUtils::MakeMaker;

# I like the three-argument open, and there might be other 5.6isms.
use 5.006;

# The .xs would need to be rewritten to work on Windows
die "OS unsupported"	if $^O =~ /mswin/i;


my $pm = 'lib/Device/LaCrosse/WS23xx.pm';

(my $mmap = $pm) =~ s!\.pm$!/MemoryMap\.pm!;

my $mm = WriteMakefile(
    NAME          => 'Device::LaCrosse::WS23xx',
    AUTHOR        => 'Eduardo Santiago <esm@cpan.org>',
    VERSION_FROM  => $pm,
    ABSTRACT_FROM => $pm,
    PL_FILES      => { 'memory_map_2300.PL' => $mmap },
    PREREQ_PM     => { 'Test::More' => 0 },
    dist          => {
	COMPRESS => 'gzip -9f',
	SUFFIX   => 'gz',
	PREOP    => 'fgrep  \?\? Changes && exit 1 || true',
    },
    clean         => { FILES => 'Device-LaCrosse-WS23xx-*' },
);

#
# To keep the README up-to-date: every time 'perl Makefile.PL' is run
# on Ed's home system -- which includes README.template -- regenerate
# the README file.
#
my $readme   = 'README';
my $template = 'README.template';
if (-e $template) {
    my $tmpfile = "$readme.tmp.$$";
    unlink $tmpfile;
    open my $template_fh, '<', $template or die "Cannot read $template: $!";
    open my $readme_fh,   '>', $tmpfile  or die "Cannot create $tmpfile: $!";

    while (my $line = <$template_fh>) {
	$line =~ s{\[VERSION\]}{
	    $mm->parse_version($pm);
	}e;

	if ($line =~ /\[DESCRIPTION\]/) {
	    my $x = qx(podselect -section DESCRIPTION $pm|pod2text --indent=0 --width=70 --sentence);
	    $x =~ s/^DESCRIPTION\n//m;
	    $x =~ s/\n\n$/\n/s;

	    print { $readme_fh } $x;
	    next;
	}

	print { $readme_fh } $line;
    }
    close $template_fh;
    close $readme_fh		or die "Error writing $tmpfile: $!\n";

    chmod 0444 => $tmpfile;
    rename $tmpfile => $readme	or die "Cannot rename $tmpfile: $!\n";
}
