	# Load the Module::Install bundled in ./inc/
	use inc::Module::Install;

	# Define metadata
	name 'MOBY';
	version '1.16';
	license 'perl';
	abstract
'This distribution is for communicating with or creating your own MOBY Central registry';
	all_from 'lib/MOBY/Central.pm';

	# Specific dependencies
	requires 'Carp'                => '0';
	requires 'File::Spec'          => '0.80';
	requires 'SOAP::Lite'          => '0.69';
	requires 'XML::LibXML::Common' => '0.13';
	requires 'XML::LibXML'         => '1.62';
	requires 'IO::Stringy'         => '2.110';
	requires 'File::HomeDir'       => '0.8';
	requires 'Unicode::String'     => '2.09';
	requires 'File::ShareDir'      => '0.05';
	requires 'Template'            => '0';
	requires 'Class::Inspector'    => '1.17';
	requires 'RDF::Core'           => '0.51';
	requires 'XML::XPath'          => '1.12';
	requires 'Text::Shellwords'    => '1.00';
	requires 'HTML::Entities'      => '0.01';
	requires 'LS'                  => '1.1.7';
	requires 'DBI'                 => '0.01';
	requires 'DBD::mysql'          => '0.01';
	# used in MobyUnitTest
	requires 'XML::Simple'         => '2.18';
	requires 'XML::SemanticCompare'=> '0';

    # MOBY::Async requires
	requires 'WSRF::Lite'          => '0.8.2.5';
	
	if ( not( $^O =~ /MSWin32|Windows_NT/i ) ) {

		# non portable requires
		requires 'Want'           => '0';
		requires 'IO::Prompt'     => '0.99.2';
		requires 'IPC::Shareable' => '0.6';

	} else {
		print STDOUT <<'END_OF_TEXT';
			
################### IMPORTANT ###################

	Windows is not a suitable platform for those 
	wishing to maintain a registry that supports
	asynchronous services due to the lack of
	support for that platform of some of the 
	required libraries.
	
	The libraries in question are as follows:
		IPC::Shareable, IO::Prompt.
	
	Sorry for any inconvenience caused!
	
##################################################

END_OF_TEXT

	}

	build_requires 'Test::More'   => '0.42';
	build_requires 'Test::Simple' => '0.44';

	no_index 'directory' => 'bin/scripts';

	install_script 'bin/scripts/moby-s-install.pl';
	install_script 'bin/scripts/moby-s-caching.pl';
	install_script 'bin/scripts/moby-s-update-db.pl';

	install_share 'share';

	auto_install;
	WriteAll;

