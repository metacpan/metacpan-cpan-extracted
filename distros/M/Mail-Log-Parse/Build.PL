use Module::Build;

# See perldoc Module::Build for details of how this works

my $class = Module::Build->subclass(
    code => q|
	use Module::Metadata;
	use Pod::Text;
	sub create_readme {
		my ($self) = @_;

		# Say what we are doing.
		print "Deleting ChangeLog\n";
		unlink 'ChangeLog';
		print "Creating ChangeLog\n";

		# Get the POD-formatted text.
		open my $outfile, '>', 'ChangeLog.pod';
		push my @modules, Module::Build::ModuleInfo->new_from_module(
			'Mail::Log::Parse', collect_pod =>1
			, inc => [$self->base_dir()."/lib"]);
		push @modules, Module::Build::ModuleInfo->new_from_module(
			'Mail::Log::Parse::Postfix', collect_pod =>1
			, inc => [$self->base_dir()."/lib"]);
		foreach my $pm_file ( @modules ) {
			print $outfile "=head1 Changes in: ". $pm_file->name() ."\n\n";
			print $outfile $pm_file->pod('HISTORY');
		}
		close $outfile;

		# Reformat to standard text, and remove temp file.
		my $text = Pod::Text->new();
		$text->parse_from_file('ChangeLog.pod', 'ChangeLog');
		unlink 'ChangeLog.pod';
	}
	|
                                   );

$class->new(
             module_name        => 'Mail::Log::Parse',
             license            => 'perl',
             dist_author        => 'Daniel Staal - <DStaal@usa.net>',
             dist_abstract      => 'Parse and return info in maillogs.',
             create_readme      => 1,
             dynamic_config     => 0,
             create_makefile_pl => 'passthrough',
             configure_requires => {
                                     'Module::Metadata' => 0,
                                   },
             requires           => {
                                   'perl'                  => '5.6.1',
                                   'Scalar::Util'          => 0,
                                   'Time::Local'           => 0,
                                   'IO::File'              => 0,
                                   'File::Basename'        => 0,
                                   'Mail::Log::Exceptions' => 0,
                                   'Memoize'               => 0,
                                   },
             build_requires     => {
                                   'Module::Build'   => 0,
                                   'Test::Warn'      => 0,
                                   'Test::Exception' => 0,
                                    },
             meta_merge => {
                    optional_features => {
                        compressed_files => {
                            description => 'Allows work with compressed files.',
                            requires    => {
                                          'IO::Uncompress::AnyUncompress' => 0,
                                          'File::Temp' => '0.17',
                                        },
                        },
                    },
             },
           )->create_build_script;