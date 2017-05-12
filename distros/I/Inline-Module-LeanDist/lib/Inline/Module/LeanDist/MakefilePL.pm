package Inline::Module::LeanDist::MakefilePL;

use strict;

require Inline::Module::LeanDist;


sub import {
    my $class = shift;

    *MY::postamble = \&postamble;
}

sub postamble {
    my ($makemaker, %args) = @_;

    my $inline_file = $args{inline}->{file} || die "unable to find 'file' param in postamble.inline";

    my $section = <<"END_OF_SECTION";
clean ::
\t- \$(RM_RF) $Inline::Module::LeanDist::inline_build_path

distdir :
\t\$(NOECHO) \$(ABSPERLRUN) $inline_file # ensure the .inline directory is populated
\t\$(NOECHO) \$(ABSPERLRUN) -MInline::Module::LeanDist::DistDir -e 'Inline::Module::LeanDist::DistDir::run()' -- \$(DISTVNAME) $inline_file
END_OF_SECTION
}


1;
