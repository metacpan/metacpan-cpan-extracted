use v5.44;

use Module::CPANfile;
use File::Find ();
use ExtUtils::MakeMaker::CPANfile 0.11;

my $prereqs = Module::CPANfile->load('cpanfile')->prereqs;
my (%provides, %install);
if (-d 'lib') {
    File::Find::find(
        {
            no_chdir => 1,
            wanted   => sub {
                my $file = $File::Find::name;
                return unless -f $file && $file =~ /\.(?:pm|json)\z/;
                (my $relative = $file) =~ s!^lib/!!;
                $install{$file} = '$(INST_LIB)/' . $relative;
                if ($file =~ /\.pm\z/) {
                    open my $in, '<:raw', $file or die "$file: $!";
                    my $source = do { local $/; <$in> };
                    while ($source =~
                        /^package\s+(LibTmux(?:::[A-Za-z0-9_]+)*)\s*[;{]/mg)
                    {
                        $provides{$1} = {file => $file, version => '0.003'};
                    }
                }
            }
        },
        'lib'
    );
}

WriteMakefile(
    NAME     => 'LibTmux',
    VERSION  => '0.003',
    ABSTRACT => 'Captured tmux graph queries and explicit process execution',
    AUTHOR   => 'libtmux contributors',
    LICENSE  => 'mit',
    MIN_PERL_VERSION => $prereqs->requirements_for('runtime', 'requires')
        ->requirements_for_module('perl'),
    PM         => \%install,
    test       => {TESTS => 't/unit/*.t'},
    META_MERGE => {
        'meta-spec'    => {version => 2},
        dynamic_config => 0,
        release_status => 'stable',
        prereqs        => $prereqs->as_string_hash,
        provides       => \%provides,
        resources      => {
            bugtracker => {
                web => 'https://github.com/libtmux/libtmux-perl/issues',
            },
            homepage   => 'https://libtmux.org/en/perl/',
            repository => {
                type => 'git',
                url  => 'https://github.com/libtmux/libtmux-perl.git',
                web  =>
'https://github.com/libtmux/libtmux-perl/tree/master/packages/core',
            },
        },
    },
);
