#
# $Id: Build.PL,v 1.1 2003/12/28 00:15:12 james Exp $
#

use Module::Build;

# figure out our prerequisites based upon platform
my %prereqs = (
    dos     => [ qw|Archive::Zip| ],
    MSWin32 => [ qw|Archive::Zip| ],
    '*'     => [ qw|IO::Zlib Compress::Zlib| ],
);
my @requires = @{ $prereqs{$^O} || $prereqs{'*'} };

my $build = Module::Build->new(
	module_name         => 'IO::File::CompressOnClose',
    dist_version_from   => 'lib/IO/File/CompressOnClose.pm',
	license             => 'perl',
    create_makefile_pl  => 'passthrough',
    build_requires      => {
        Test::More      => 0,
        Test::Exception => 0,
        IO::Zlib        => 0,
        Compress::Zlib  => 0,
        Archive::Zip    => 0,
    },
    requires            => { map { $_ => 0 } @requires },
);

$build->create_build_script;

#
# EOF

