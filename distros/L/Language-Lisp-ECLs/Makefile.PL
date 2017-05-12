use strict;
use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub ecl_config {
    my $args = shift;
    open(ECLCONFIG, "ecl-config $args|")
	or do {
	    warn "can't run \"ecl-config $args|\" - $!\n";
	    exit 0;
	};
    my $res = join '', <ECLCONFIG>;
    $res =~ s/[\r\n]+$//;
    do {
        warn "can't get output from ecl-config";
	exit 0;
    } if $res eq '';
    return $res;
}

my $ecl_cflags = ecl_config("--cflags");
my $ecl_ldflags = ecl_config("--ldflags");

WriteMakefile(
    NAME          => 'Language::Lisp::ECLs',
    VERSION_FROM  => 'lib/Language/Lisp/ECLs.pm', # finds $VERSION
    PREREQ_PM     => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM => 'lib/Language/Lisp/ECLs.pm', # retrieve abstract from module
    AUTHOR        => 'Vadim Konovalov <vkon@cpan.org>',
    LIBS          => ["$ecl_ldflags"],
    # DEFINE        => '-DECL_UNICODE',
    INC           => "$ecl_cflags", # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
