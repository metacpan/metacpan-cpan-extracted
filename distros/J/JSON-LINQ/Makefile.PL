use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
use ExtUtils::MakeMaker;

my %args = (
    'NAME'      => q{JSON::LINQ},
    'VERSION'   => q{1.00},
    'ABSTRACT'  => q{LINQ-style query interface for JSON and JSONL files},
    'PREREQ_PM' => {
        'Carp' => '0',
        'perl' => '5.00503',
        'strict' => '1.01',
        'vars' => '0',
        'warnings' => '0',
    },
    'AUTHOR'    => q{ina <ina@cpan.org>},
);

# LICENSE was introduced in ExtUtils::MakeMaker 6.31 (2006).
# Passing it to older versions produces an "is not a known parameter" warning
# without failing, but we suppress the noise by checking the version.
if ($ExtUtils::MakeMaker::VERSION >= 6.31) {
    $args{LICENSE} = q{perl};
}

# MIN_PERL_VERSION (6.48) and META_MERGE (6.46) arrived together in the
# same EUMM release cycle; guard them under the higher threshold (6.48)
# so both are always either present or absent.
if ($ExtUtils::MakeMaker::VERSION >= 6.48) {
    $args{MIN_PERL_VERSION} = q{5.00503};
    $args{META_MERGE} = {
        'meta-spec' => { version => 2 },
        'resources' => {
            'license'    => [ 'http://dev.perl.org/licenses/' ],
            'bugtracker' => {
                'web' => 'https://github.com/ina-cpan/JSON-LINQ/issues',
            },
            'repository' => {
                'url'  => 'https://github.com/ina-cpan/JSON-LINQ',
                'web'  => 'https://github.com/ina-cpan/JSON-LINQ',
                'type' => 'git',
            },
        },
        'provides' => {
            'JSON::LINQ' => {
                'file'    => 'lib/JSON/LINQ.pm',
                'version' => '1.00',
            },
            'JSON::LINQ::Boolean' => {
                'file'    => 'lib/JSON/LINQ.pm',
                'version' => '1.00',
            },
            'JSON::LINQ::Ordered' => {
                'file'    => 'lib/JSON/LINQ.pm',
                'version' => '1.00',
            }
        },
    };
}

WriteMakefile(%args);

__END__
