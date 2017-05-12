use ExtUtils::MakeMaker;

if ($ExtUtils::MakeMaker::VERSION < 5.16) {
    local *F;
    open F, "lib/Devel/CoreStack.pm";
    while (<F>) {
	next unless /VERSION/;
	eval;
	last;
    }
    @version = ( VERSION => $VERSION );
} else {
    @version = (VERSION_FROM => "lib/Devel/CoreStack.pm");
}
WriteMakefile(
	NAME => "Devel::CoreStack",
	DISTNAME => "Devel-CoreStack",
	INSTALLDIRS => 'perl',
	linkext => {LINKTYPE => ''}, # not needed for MakeMakers >= 5
	clean => {FILES => 't/core'},
	@version,
        dist => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);

package MY;
sub MY::test {
    local $_ = shift->SUPER::test(@_);
    s|t/\*\.t|t/*.t 2>&1 \| \$(PERL) filter_test_out|;
    $_;
}
