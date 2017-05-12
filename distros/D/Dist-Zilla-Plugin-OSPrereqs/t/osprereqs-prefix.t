use strict;
use warnings;

use lib 't/lib';

use Test::More 0.88;

use Test::DZil;

my $tzil = Builder->from_config( { dist_root => 'corpus/DZ4' }, );

$tzil->build;

my $contents = $tzil->slurp_file('build/Makefile.PL');

{
    my $conditional = q|if ( $^O ne 'MSWin32' ) {|;
    my $prereq      = q|$WriteMakefileArgs{PREREQ_PM}{'Proc::ProcessTable'} = '0.50'|;
    like(
        $contents,
        qr/\Q$conditional\E.*?\Q$prereq\E.*?^\}/ms,
        "saw !prefix conditional"
    );
}

{
    my $conditional = q|if ( $^O =~ /foo/i ) {|;
    my $prereq      = q|$WriteMakefileArgs{PREREQ_PM}{'Acme::One'} = '0.01'|;
    like(
        $contents,
        qr/\Q$conditional\E.*?\Q$prereq\E.*?^\}/ms,
        "saw ~prefix conditional"
    );
}

{
    my $conditional = q|if ( $^O !~ /bar/i ) {|;
    my $prereq      = q|$WriteMakefileArgs{PREREQ_PM}{'Acme::Two'} = '0.02'|;
    like(
        $contents,
        qr/\Q$conditional\E.*?\Q$prereq\E.*?^\}/ms,
        "saw !~prefix conditional"
    );
}

done_testing;

