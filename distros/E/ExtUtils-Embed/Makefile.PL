# -*- perl -*-
use ExtUtils::MakeMaker;
use Config;

$VERSION = "1.14";

print "Writing files for ExtUtils::Embed tests...\n";

$make = $Config{make} || "make";
%libperl = ();
@cprogs = qw(embed);
push @cprogs, 'loop' if $] >= 5.00393;

if((-e "$Config{archlibexp}/CORE/libperlm.a") or $ENV{TEST_MULTIPLICITY}) {
    push @cprogs, 'multiplicity';
    system "$Config{cp} -f ./eg/multiplicity.c ./t";
    $libperl{multiplicity} = "-lperlm";
}

$tests = scalar @cprogs;
chdir "./t";

open FH, ">build.t" or die;
print FH 
    qq{\$test = 0;\n},
    qq{print "1..$tests\\n";\n},
    qq{chdir "t" if -d "t";\n\n};

for (@cprogs) {
    system "$^X ../genmake $_ Makefile.$_ $libperl{$_}";
    print FH <<"EOF";
#system "make -f Makefile.$_ clean";
\$res = system("$make -f Makefile.$_") == 0 ? "ok" : "not ok";
print \$res, " ", ++\$test, "\\n";

EOF

}

print FH "chdir '..' if -d '../t';\n";

close FH;

chdir "..";
 
WriteMakefile(
    'INSTALLDIRS' => 'perl',  # as it is coming with perl     
    'VERSION'   => $VERSION,
    'NAME'  => 'ExtUtils-Embed',
    'dist'    => {
	COMPRESS=> 'gzip -9f', SUFFIX=>'gz',
	CI => qq(ci -u -m\\"See Changes file\\"),
    },
    'linkext' => {LINKTYPE => '' }, 
);

sub MY::clean {
    my($self) = shift;
    my $string = $self->MM::clean;

    for (@cprogs) {
	$string .= "\t-cd t/ && \$(MAKE) -f Makefile.$_ clean\n";
    }
    
    return $string;
}



