# The perl/C checking voodoo is stolen from Graham Barr's
# Scalar-List-Utils distribution.

use strict;

use ExtUtils::MakeMaker;
use Config qw(%Config);
use File::Spec;

my $no_xs;
my $force_xs;
for (@ARGV)
{
    /^--pm/ and $no_xs = 1;
    /^--xs/ and $force_xs = 1;
}

if ($no_xs)
{
    write_makefile();
    exit;
}

my @clean;
unless ($force_xs)
{
    print "Testing if you have a C compiler\n";

    unless ( open F, ">test.c" )
    {
        warn "Cannot write test.c, skipping test compilation and install pure Perl version.\n";
        no_cc();
    }

    print F <<'EOF';
int main() { return 0; }
EOF

    close F or no_cc();

    system("$Config{make} test$Config{obj_ext}") and no_cc();

}

write_makefile();

sub write_makefile
{
    my %prereq = ( 'Test::More' => 0,'Math::Round' => 0, 'Math::Trig' => 0 );
    $prereq{'Attribute::Handlers'} = 0 if $] >= 5.008;

    WriteMakefile( VERSION_FROM    => "lib/Location/GeoTool.pm",
                   NAME            => "Location::GeoTool",
                   PREREQ_PM       => \%prereq,
                   CONFIGURE       => \&init,
                   clean           => { FILES => "test.c test.o @clean" },
                   ( $] >= 5.005 ?
                     ( ABSTRACT_FROM => 'lib/Location/GeoTool.pm',
                       AUTHOR        => 'OHTSUKA Ko-hei <nene@kokogiko.net>') :
                     ()
                   ),
                 );
}

sub init
{
    my $hash = $_[1];

    if ($no_xs)
    {
        @{ $hash }{ 'XS', 'C' } = ( {}, [] );
    }

    $hash;
}

sub no_cc
{
    $no_xs = 1;
    print <<'EOF';

 I cannot determine if you have a C compiler
 so I will install a perl-only implementation

 You can force installation of the XS version with

    perl Makefile.PL --xs

EOF

    write_makefile();
    exit;
}
