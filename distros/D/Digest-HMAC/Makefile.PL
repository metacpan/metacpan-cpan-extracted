require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'Digest::HMAC',
    'VERSION_FROM' => 'lib/Digest/HMAC.pm',
    'ABSTRACT_FROM' => 'lib/Digest/HMAC.pm',
    'PREREQ_PM'    => { 'Digest::MD5' => 2.00,
                        'Digest::SHA' => 1.00,
                      },
    'AUTHOR'       => 'Gisle Aas <gisle@activestate.com>',
    'LICENSE'      => 'perl',
    'MIN_PERL_VERSION' => 5.004,
);


BEGIN {
    # compatibility with older versions of MakeMaker
    my $developer = -f ".gitignore";
    my %mm_req = (
        LICENCE => 6.31,
        META_MERGE => 6.45,
        META_ADD => 6.45,
        MIN_PERL_VERSION => 6.48,
    );
    undef(*WriteMakefile);
    *WriteMakefile = sub {
        my %arg = @_;
        for (keys %mm_req) {
            unless (eval { ExtUtils::MakeMaker->VERSION($mm_req{$_}) }) {
                warn "$_ $@" if $developer;
                delete $arg{$_};
            }
        }
        ExtUtils::MakeMaker::WriteMakefile(%arg);
    };
}
