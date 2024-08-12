use Module::Build;


my $build_pkg = eval { require Apache::TestMB }
  ? 'Apache::TestMB' : 'Module::Build';

my $class = $build_pkg->subclass(
    class => 'My::Builder',
    code => q{
        sub ACTION_tarball_name { print shift->dist_dir . ".tar.gz\n" }
        sub ACTION_latest_changes {
            my $self = shift;
            (my $dv = $self->dist_version) =~ s/^v//;
            open my $in, '<:raw', 'Changes' or die "Cannot open Changes: $!\n";
            open my $out, '>:raw', 'latest_changes.md' or die "Cannot open latest_changes.md: $!\n";
            while (<$in>) { last if /^\Q$dv\E\b/ }
            print {$out} "Changes for v$dv\n";
            while (<$in>) {
                last if /^\s*$/;
                chomp;
                if (s/^\s+-/-  /) {
                    print {$out} "\n";
                } else {
                    s/^\s+/ /;
                }
                print {$out} $_;
            }
            $self->add_to_cleanup('latest_changes.md');
        }
    },
);

$class->new(
    module_name        => 'MasonX::Interp::WithCallbacks',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.4209' },
    build_requires     => { 'Module::Build' => '0.4209' },
    test_requires      => { 'Test::More'    => '0.17' },
    recommends         => {
        'Test::Pod'      => '1.20',
        'Apache::TestMB' => 0
    },
    requires           => {
        'HTML::Mason'             => '1.23',
        'Test::Simple'            => '0.17',
        'Class::Container'        => '0.09',
        'Params::CallbackRequest' => '1.15',
    },
    add_to_cleanup     => ['t/mason'],
    meta_merge => {
        "meta-spec" => { version => 2 },
        resources => {
            homepage   => 'https://metacpan.org/pod/MasonX::Interp::WithCallbacks',
            bugtracker => 'https://github.com/theory/masonx-interp-withcallbacks/issues/',
            repository => 'https://github.com/theory/masonx-interp-withcallbacks',
        },
        prereqs => {
            develop => {
                requires => {
                    'Test::Pod'           => '1.41',
                    'Test::Pod::Coverage' => '1.06',
                    'Test::Spelling'      => '0.25',
                },
            },
        },
    },
)->create_build_script;
