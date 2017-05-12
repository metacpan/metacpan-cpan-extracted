use inc::Module::Install 0.76;

all_from       'lib/File/IgnoreReadonly.pm';
requires       'constant' => 0;
requires       'Win32::File::Object' => '0.01' if $^O eq 'MSWin32';
requires       'File::chmod'         => '0.32' if $^O ne 'MSWin32';
build_requires 'Test::More'          => '0.42';
build_requires 'File::Spec'          => '0.80';
build_requires 'File::Remove'        => '1.42';

WriteAll;
