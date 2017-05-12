use ExtUtils::MakeMaker;

my $opt = '-O3 -funroll-loops -fomit-frame-pointer -fschedule-insns2 -Os -fno-strength-reduce -Wall -pipe';

my $defines = "";

# Comment out the line below if your C compiler does not support
# 64-bit operations, i.e., doesn't undertand "long long" types
$defines .= '-DSHA2_USE_INTTYPES_H';

WriteMakefile(
    'NAME' => 'Digest::SHA2',
    'VERSION_FROM' => 'SHA2.pm',
    'PREREQ_PM' => {'MIME::Base64' => '0', 'Digest::base' => '1.00'},
    'AUTHOR' => 'Julius C. Duque {jcduque}{at}{lycos}{dot}{com}',
    'LIBS' => [''],
    'DEFINE' => $defines,
    'INC' => '-I.',
    'OPTIMIZE' => $opt,
    'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'}
);

