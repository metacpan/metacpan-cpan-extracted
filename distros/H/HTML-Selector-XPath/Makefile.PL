use ExtUtils::MakeMaker qw(WriteMakefile);

my %module = (
    NAME            => 'HTML::Selector::XPath',
    VERSION_FROM    => 'lib/HTML/Selector/XPath.pm',
    ABSTRACT_FROM   => 'lib/HTML/Selector/XPath.pm',
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                web => 'https://github.com/Corion/HTML-Selector-XPath',
                url => 'git://github.com/Corion/HTML-Selector-XPath.git',
                type => 'git',
            },
            bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Selector-XPath',
            license    => 'http://dev.perl.org/licenses/',
        },
        dynamic_config   => 0, # we promise to keep META.* up-to-date
        x_static_install => 1, # we are pure Perl and don't do anything fancy
        #provides => {
        #    'HTML::Selector::XPath' => {
        #        file => 'lib/HTML/Selector/XPath.pm',
        #        version => 'lib/HTML/Selector/XPath.pm',
        #    }
        #}
    },
    MIN_PERL_VERSION => '5.008001',
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::Base' => 0,
        'Encode'     => 0,
    },
    'PREREQ_PM'    => { 'strict'      => 0,
                        'Exporter'    => 0,
                        'Carp'        => 0,
    }, # e.g., Module::Name => 1.1
    AUTHOR         => 'Max Maischein <corion@cpan.org>',
    LICENSE        => 'perl'
);

sub get_module_info { %module }

if( ! caller ) {
    WriteMakefile(get_module_info);
};

1;
