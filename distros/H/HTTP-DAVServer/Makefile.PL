use ExtUtils::MakeMaker;

our $VERSION="0.2";

open ABSTRACT, "<", "ABSTRACT";
our $ABSTRACT=<ABSTRACT>;
chomp $ABSTRACT;
close ABSTRACT;

WriteMakefile(
    NAME         => 'HTTP::DAVServer',
    VERSION      => $VERSION,
    AUTHOR       => 'Jay J. Lawrence',
    ABSTRACT     => $ABSTRACT,
    PREREQ_PM    => {
        'XML::Simple' => 2.03,
        'XML::SAX'    => 0.12,
        'DateTime'    => 0.08,
    },

);

open VERSION, ">", "VERSION";
print VERSION "$VERSION";
close VERSION;

