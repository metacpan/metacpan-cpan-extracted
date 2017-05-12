use strict;
use warnings;

use lib 't/lib';

use Test::More 0.88;

use Test::DZil;

my $tzil = Builder->from_config( { dist_root => 'corpus/DZ2' }, );

$tzil->build;

my $contents = $tzil->slurp_file('build/Makefile.PL');

{
    my $conditional = q|if ( $^O eq 'MSWin32' ) {|;
    my $prereq      = q|$WriteMakefileArgs{PREREQ_PM}{'Win32API::File'} = '0.11'|;

    like(
        $contents,
        qr/\Q$conditional\E.*?\Q$prereq\E.*?^\}/ms,
        "saw MSWin32 conditional"
    );
}

{
    my $conditional = q|if ( $^O eq 'Haiku' ) {|;
    my $prereq      = q|$WriteMakefileArgs{PREREQ_PM}{'File::Temp'} = '0.18'|;

    like(
        $contents,
        qr/\Q$conditional\E.*?\Q$prereq\E.*?^\}/ms,
        "saw Haiku conditional"
    );
}

done_testing;

