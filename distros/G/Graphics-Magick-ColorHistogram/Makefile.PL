use 5.008;

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Getopt::Long;

GetOptions(
    '--with-graphics-magick=s'  => \(my $gm_config),
    '--help!'                   => \(my $help),
) or usage();
usage() if $help;

if (!$gm_config) {
    chomp($gm_config = qx(which GraphicsMagick-config));
    die "couldn't find a suitable GraphicsMagick-config; use --with-graphics-magick\n"
        unless $gm_config;
}
die "$gm_config isn't executable\n" unless -x $gm_config;

chomp(my $ldflags = qx($gm_config --ldflags));
chomp(my $libs    = qx($gm_config --libs));
chomp(my $prefix  = qx($gm_config --prefix));

WriteMakefile(
    NAME            => 'Graphics::Magick::ColorHistogram',
    VERSION_FROM    => 'ColorHistogram.pm',
    ABSTRACT_FROM   => 'ColorHistogram.pm',
    AUTHOR          => 'Adam Thomason <athomason@cpan.org>',
    LIBS            => ["$ldflags $libs"],
    CCFLAGS         => "-I$prefix/include/GraphicsMagick",
    INC             => '-I.',
);

sub usage {
    (my $me = $0) =~ s,.*/,,;
    print "usage: $me [--with-graphics-magick=/path/to/GraphicsMagick-config]\n";
    exit 0;
}
