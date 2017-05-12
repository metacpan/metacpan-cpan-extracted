{ use 5.008001; }
use warnings;
use strict;
 
use Module::Build;
 
Module::Build->subclass(code => q{
        unless(__PACKAGE__->can("cbuilder")) {
                *cbuilder = sub { $_[0]->_cbuilder or die "no C support" };
        }
        sub compile_c {
                my($self, $file, %args) = @_;
                my $cc0_h =
                        $self->localize_file_path("lib/JSON/XS/callchecker0.h");
                unless(-f $cc0_h) {
                        require Devel::CallChecker;
                        Devel::CallChecker->VERSION(0.001);
                        my $content = &Devel::CallChecker::callchecker0_h();
                        $self->add_to_cleanup($cc0_h);
                        require IO::File;
                        my $fh = IO::File->new($cc0_h, "w") or die $!;
                        $fh->printflush($content) or die $!;
                        $fh->close or die $!;
                }
                return $self->SUPER::compile_c($file, %args);
        }
        sub link_c {
                no strict "refs";
                my($self, $spec) = @_;
                my $cb = $self->cbuilder;
                my $cbclass = ref($cb);
                my $orig_cb_link = $cb->can("link");
                local *{"${cbclass}::link"} = sub {
                        my($self, %args) = @_;
                        if($args{module_name} eq "JSON::XS::Sugar") {
                                require Devel::CallChecker;
                                Devel::CallChecker->VERSION(0.002);
                                $args{objects} = [
                                    @{$args{objects}},
                                    Devel::CallChecker::callchecker_linkable(),
                                ];
                        }
                        @_ = ($self, %args);
                        goto &$orig_cb_link;
                };
                $self->SUPER::link_c($spec);
        }
})->new( __mb_args() )->create_build_script();

sub __mb_args {

    # This is a funky way of allowing this code to run stand-alone and as a
    # template to be processed by Dist::Zilla::Plugin::ModuleBuild::Custom
    my $data = do { local $/; <DATA> };

    if ( $data !~ /^\#/ ) {
        my $args = eval $data;
        return %{$args};
    }
    else {
        return (
            module_name          => 'JSON::XS::Sugar',
            dist_abstract        => 'Whatever',
            license              => 'perl',
            recursive_test_files => 1,
        );
    }
}
 
1;

__DATA__
 {
          'license' => 'perl',
          'build_requires' => {
                                'Module::Build' => '0.28'
                              },
          'recommends' => {},
          'script_files' => [],
          'dist_version' => '1.01',
          'configure_requires' => {
                                    'perl' => '5.014000',
                                    'strict' => '0',
                                    'warnings' => '0',
                                    'Module::Build' => '0.28'
                                  },
          'requires' => {
                          'Types::Serialiser' => '0',
                          'perl' => '5.014000',
                          'XSLoader' => '0',
                          'Devel::CallChecker' => '0.003',
                          'strict' => '0',
                          'constant' => '0',
                          'base' => '0',
                          'warnings' => '0',
                          'Exporter' => '0'
                        },
          'module_name' => 'JSON::XS::Sugar',
          'dist_name' => 'JSON-XS-Sugar',
          'test_requires' => {
                               'Test::Warn' => '0',
                               'File::Spec' => '0',
                               'IPC::Open3' => '0',
                               'perl' => '5.014000',
                               'B' => '0',
                               'IO::Handle' => '0',
                               'Test::More' => '0.96',
                               'ExtUtils::MakeMaker' => '0'
                             },
          'recursive_test_files' => 1,
          'dist_abstract' => 'sugar for using JSON::XS',
          'dist_author' => [
                             'Mark Fowler <mfowler@maxmind.com>'
                           ]
        };
