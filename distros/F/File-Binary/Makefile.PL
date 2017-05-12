use ExtUtils::MakeMaker;

$module = 'lib/File/Binary.pm';

%depends = (    'IO::Scalar' => '1.126',
                'IO::File'   => '1.14',
                'Test::More' => 0,
           );

# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'            => 'File::Binary',
    'VERSION_FROM'    => 'lib/File/Binary.pm', # finds $VERSION
    'PREREQ_PM'        => \%depends,
    'AUTHOR'        => 'Simon Wistow <simon@thegestalt.org>',
) if $0 =~ m/makefile.pl/i;

sub MY::postamble {
    return <<EOF
README: $module Changes ../makereadme
\t../makereadme $module \$(NAME) \$(VERSION) > README

dist: README

EOF
}

1;
