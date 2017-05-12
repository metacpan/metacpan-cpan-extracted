package Integrator::Module::Build;
use warnings;
use strict;

=head1 NAME

Integrator::Module::Build - Gather and synchronize Test::More results in Cydone's Integrator 

=head1 VERSION

Version $Revision: 1.57 $

=cut

use vars qw($VERSION);
$VERSION = sprintf "%d.%03d", q$Revision: 1.57 $ =~ /(\d+)/g;

use File::stat;
use Data::UUID;
use Data::Dumper;
use MIME::Base64;
use Term::ReadKey;
use LWP::UserAgent;
use XML::Simple qw{:strict};

use Test::TAP::Model;
use Integrator::Test::TAP::Model::Patch;

use base 'Module::Build';

our $NEW_LINE   = '__NL__';      # special encoding for '\n'
our $POUND_SIGN = '__PS__'; 	 # special encoding for '#'

$|=1;

=head1 SYNOPSIS

This module is used to construct perl test harnesses suitable for
use with Cydone's Integrator framework.  A test harness created with
Integrator::Module::Build can communicate test results in the style
of Test::More to Cydone Integrator and synchronise test information
(test cases, descriptions, results, log files, measurements, component
states, etc.)

Since the test harness itself is nothing less than a standard perl
module, you can use Module::Start to create a new test harness. Here
is an example on how to create a test harness called 'my-test-module'
using the module-starter script available from Module::Starter:

	module-starter 	--mb 					\
			--email='my-email@cydone.com' 		\
			--author='User Name'	 		\
			--module='My::Test::Module'

Then, you want to edit the Build.PL file under My-Test-Module with the
proper Integrator credentials (go to L<https://www.partnerscydone.com> to
request your demo credentials, a specific Build.PL file will be sent
to you within a demo test harness).

Here is a typical Build.PL file used to instantiate such a perl test
harness (note the 'Integrator::Module::Build' lines):

	use strict;
	use warnings;
	use Integrator::Module::Build;

	my $builder = Integrator::Module::Build->new(
	    module_name           => 'My::Test::Module',
	    dist_author           => ' <my-email@cydone.com>',
	    
	    integrator_project_code 	=> 'demo',
	    integrator_lab_code		=> 'default',
	    integrator_user	 	=> 'your username',
	    integrator_pwd		=> 'the password you received',
	    integrator_url		=> 'https://public1.partnerscydone.com',
	    integrator_http_realm	=> '',
	    integrator_http_user 	=> '',
	    integrator_http_pwd  	=> '',
	);

	$builder->create_build_script();

You can now create/edit the test case files (based on Test::Simple or
Test::More style) under the ./t directory in your new test module and
synchronize the results in Integrator.

To execute the test cases and synchronize the results do:

	perl ./Build.PL
	./Build
	./Build integrator_test
	./Build integrator_sync

=cut

=head1 EXPORT

Integrator::Module::Build exports a set of actions available from the
command line 'Build' script, in the style of what Module::Build does.

Integrator::Module Build supports all actions from Module::Build and
adds specific actions to execute tests in the local database as well as
to synchronise test results with Cydone's Integrator centralized server.

The specific actions of Integrator::Module::Build are:

 Usage: ./Build <action> arg1=value arg2=value ...
 Example: ./Build test verbose=1

 Actions defined:
  integrator_test
  integrator_sync
  integrator_version

  integrator_send_xml  
  integrator_store
  integrator_xml_report
  integrator_download_test_definition
  integrator_upload_test_definition

As of July 2007, Module::Build was in revision 0.2808. The most common
actions inherited from Module::Build are:

  dist		- used to wrap a complete test module into a tar.gz. file.
		  (this is very useful to distribute your tests in a portable module)
  help		- displays a help message

Actions starting with 'integrator' are defined in this document. Please
refer to Module::Build by Ken Williams available at L<http://www.cpan.org>
for the other actions, as they are more related to module distribution,
installation and maintenance.

=cut

# This begin block is used to substitute a portable (but slower) version
# of the MD5 module if the original could not be found.
BEGIN {
    eval {
      require Digest::MD5;
      import Digest::MD5 'md5_hex'
    };
    if ($@) { # oups, no Digest::MD5
      require Digest::Perl::MD5;
      import Digest::Perl::MD5 'md5_hex'
    }             
}

### # We need to protect the credentials of the harness user since they
### # could be stored locally. But the warning is not required when first
### # installing IMB.  Hence we test Build.PL to see if it contains IMB before
### # going any further.  Then we can issue the warning if the credentails
### # are not properly protected.
### if (_file_contains_text('Build.PL', qr{Integrator::Module::Build\s*->\s*new})) {
### 	foreach my $file (qw{ Build.PL _build/build_params}) {
### 		warn( "SECURITY WARNING: '$file' is readable or writeable by others, ".
### 		      "change file permissions with 'chmod 700 $file'")
### 			unless (_is_rw_safe($file));
### 	}
### }

=head1 ACTIONS 

Since this module is used to generate a local 'Build' file called with
actions, we first document these actions. Please note that all the actions
are called from the command line without the 'ACTION_' prefix as in:

	./Build integrator_test	--test_files=./t/00-load.t
			#launches one test and logs the result locally
			#notice the bare 'integrator_test' action

=head2 ACTION_integrator_test

 used with: ./Build integrator_test
 	    ./Build integrator_test --test_files=./t/00-load.t             \
                                    --test_files=./t/tc001_v1_security.t   \
                                    --test_files=./t/tc002_v3_robustness.t  

This action is used to start a test run and gather the results locally
for later upload and analysis in Cydone Integrator. Each sucessive
invocation is logged as a unique test run and can latter be uploaded with
the 'integrator_sync' action.

=cut
	
sub ACTION_integrator_test {
   my ($self) = @_;
   my $p = $self->{properties};
	
   $self->depends_on('code');
   
   # Make sure we test the module in blib/
   local @INC = (File::Spec->catdir($p->{base_dir}, $self->blib, 'lib'),
                 File::Spec->catdir($p->{base_dir}, $self->blib, 'arch'),
                 @INC);

   ### save all the parameters
   $p->{integrator_test_signatures}      = _compute_test_signatures($self);
   $p->{integrator_pwd}			 = '***********';	#we hide the password in the test data...
   $p->{integrator_module_build_version} = $Integrator::Module::Build::VERSION;
   $p->{integrator_os_env}		 = \%ENV;
   delete $p->{build_requires};		#unfortunate, but we don't pass it through since hash keys contains
   					# '::' (as in 'Test::More') and it breaks the xml

   $self->config_data('integrator_harness_info' => $p   );

   # Filter out nonsensical @INC entries - some versions of
   # Test::Harness will really explode the number of entries here
   @INC = grep {ref() || -d} @INC if @INC > 100;

   my $tests = $self->find_test_files;
   my $t = Integrator::Test::TAP::Model::Patch->new_with_struct();
   $t->log_time( 1 eq 1 );

   if (@$tests) {
	$t->run_tests(@$tests);	
	my $time = time;
	_log_results_with_look_up($self, $t);
	my $delay = time - $time;
	print "Data saved localy in $delay sec.\n";
   } else {
     print("No tests defined.\n");
   }
}

=head2 ACTION_integrator_sync

 used with: ./Build integrator_sync

This action will send locally generated test run data to the
web server and will clean-up local data when the transaction is
completed. Aditionally, all configuration data related to the local
test files will be updated (note: the configuration data sync is not
yet implemented as of March 2006).

Credentials are looked-up from the local Build.PL configuration file or
prompted from the user if required.

All local configuration (ENV variables, build parameters, server
configuration) are also uploaded to the server to ensure test
traceability. Please refer to Cydone Integrator for a detailed list of
the information that is sent to the server.

=cut

# This sub also sends the MD5 and the local configuration to the server.

sub ACTION_integrator_sync {
	my $self    = shift;
	my $xml	    = shift;
	my $t	    = time;
	my $store_mode='YES';		#initial assumption
	
	my $credentials = _get_integrator_credentials($self);

	print "== LOCAL DATABASE LOOKUP ===========================================\n";
	unless (defined $xml) {
		$store_mode='NO';

		my $names = join('', (keys %{$self->config_data('regressions')}));

		unless ($names eq '') {
			my $stored = $self->config_data('regressions');

			#list reports to upload
			print "Loading test runs that are ready for upload:\n";
			$xml = _generate_signed_xml_from_struct($self, $credentials, $stored);
########### Removed this on Jan 8th 2007, not needed !!!!
###########		#url encode the document
###########		$xml =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
########### Removed this on Jan 8th 2007, not needed !!!!

			print "done.\n";
		}
		else {
			print "No local test result found. You might want execute the tests first. Exiting.\n";
			exit -1;
		}
	}

	print "== INTEGRATOR SERVER DATA UPLOADING ================================\n";
	print "Sending data to server\n";
	my $response    = _harness_post_url($credentials, $xml);
	print "done.\n";

	#look in the server response and update local stuff
	if ($response->{_rc} eq "200") {
		print "HTTP transfer done.\n";
		print "Analysing results...\n";
		my $xs = XML::Simple->new();
		my %IN_options = (
		    NoAttr  	    => 0,
		    ForceArray 	    => 1,
		    KeyAttr  	    => [],
		);

		my $xml_server;
		eval { $xml_server = $xs->XMLin($response->{_content}, %IN_options) };
		if ($@) {
			open STDOUT, ">server_response.err"
				or die "Error: cannot write malformed xml error file: $!, $?, $@";
			print "$!, $?, $@\nResponse from server was:\n";
			print Dumper $response;
			die "Error, problem loading confirmation from server "
			   ."(see file 'server_response.err'), malformed xml: $@";
		}
		my $persist = $self->config_data('regressions');
		print "XML from server response is loaded.\n";

		print "== INTEGRATOR SERVER INFO ==========================================\n";
		_info_warning_errors_feedback($xml_server);

###print Dumper $xml_server;

		print "== LOCAL DATABASE CLEAN-UP =========================================\n";
		if (defined $xml_server->{integrator_response}[0]{integrator_global_return}[0]) {
			my $resp	= $xml_server->{integrator_response}[0];
			my $global	= $resp->{integrator_global_return}[0];

			if ($global eq 'success') {
				print "\t...local data no longer needed, cleaning-up...\n";
				foreach my $uuid (keys %{$persist}) {
					delete( $persist->{$uuid});
				}
				$self->config_data('regressions' => $persist);
				print "\t...local data cleaned-up.\n";
			}
			else {
				print "Error: Integrator Global Return code is $global, cannot clean-up locally !\n";
				print "see file 'server_response.err' for more details\n";
				open STDOUT, ">server_response.err" or die "Error: cannot write server_log: $!";
				print "$!, $?, $@\nResponse from server was:\n";
				print Dumper $response;
			}
		}
		else {
			print "ERROR: Integrator did not provide a global return code, cannot clean-up locally !\n";
			print "see file 'server_response.err' for more details\n";
			open STDOUT, ">server_response.err" or die "Error: cannot write server_log: $!";
			print "$!, $?, $@\nResponse from server was:\n";
			print Dumper $response;
		}
	}
	else {
		print "HTTP Transfer problem...\n";
		$response->{_rc} ||='';
		$response->{msg} ||='';
		print "Apache: return_code='$response->{_rc}', msg='$response->{_msg}'\n";
		print "Apache: content: $response->{_content}'\n";
	}
	print "Performed sync in " .(time - $t). " sec.\n";
}

=head2  ACTION_integrator_version

 used with: ./Build integrator_version

Displays the Integrator::Module::Build version currently running.

=cut
	
sub ACTION_integrator_version {
	print "This is Integrator::Build::Module version $Integrator::Module::Build::VERSION\n";
	print << 'EOLIC';
Copyright 2007 Cydone Solutions Inc, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
EOLIC
}

=head2 ACTION_version

 used with: ./Build version

See integrator_version ...

=cut

#not documented but will also work...
sub ACTION_version {
	ACTION_integrator_version();
}


=head2 ACTION_integrator_store

 used with: ./Build integrator_store

This action is used as a patch to help load externally generated XML. This
is used only as a debugging mechanism...

=cut

sub ACTION_integrator_store {
	my $self    = shift;

	my @files = _get_valid_filenames($self->{args}{file});
	
	foreach my $file_in (@files) {
		die "Error: could not read '$file_in', $?"
			unless (-r $file_in);

		#list reports to upload
		print "Loading xml report file from $file_in:\n";
		open FIN, "<$file_in" or die "Error: could not open '$file_in', $?";
		my $xml = join '', (<FIN>);
		close FIN or die "Error: could not close '$file_in', $?";
		print "done.\n";
		ACTION_integrator_sync($self, $xml);
	}
}

sub _info_warning_errors_feedback {
	my $xml_server = shift;

#XXX TODO: this error handling will explode in the case where ERROR is not a string
# but a HASH !!! In this case we need to explore the hash (in sub _print_feedback)
# to print what is contained within... On wayt of reproducing this: corrupt the xml !!!

	if (defined $xml_server->{integrator_response}[0]) {
		_print_feedback('INFO',		$xml_server->{integrator_response}[0]{info});
		_print_feedback('WARNING',	$xml_server->{integrator_response}[0]{warning});
		_print_feedback('ERROR',	$xml_server->{integrator_response}[0]{error});
		_print_feedback('TIME',		$xml_server->{integrator_response}[0]{elapsed_time});
	}
	else {
		die "Error: server response does not contain a valid 'integrator_response' field.\n";
	}
}

sub _print_feedback {
	my $tag = shift;
	my $table = shift;

	foreach my $result (@{$table}) {
		print "$tag:\t$result\n";
	}
} 

=head2 ACTION_integrator_download_test_definition

 used with: ./Build integrator_download_test_definition
            ./Build integrator_download_test_definition --file=complete_this.xml

This action is used to download all test definition data from the current
project in Cydone Integrator.

=cut

sub ACTION_integrator_download_test_definition {
	my $self        = shift;
	my $credentials = _get_integrator_credentials($self);
	$credentials->{integrator_test_definition_post}{value} = 'api/downloadTestDefinition';
	#$credentials->{integrator_test_definition_post}{value} = 'frontend_dev.php/api/downloadTestDefinition';
	my $t           = time;
	my @files;
	my $xml;

	#get the filenames of xml files to complete, or setup default download
	if (defined $self->{args}{param_file}) {
		@files = _get_valid_filenames($self->{args}{param_file});
	}
	else {
		push(@files, '___DEFAULT___weird_file_name___');
		print "Default download: all data.\n";
		$xml = _get_default_xml($credentials);
	}
	foreach my $file (@files) {
		#list file to upload
		unless ($file eq '___DEFAULT___weird_file_name___') {
			print "Loading xml file '$file' for upload:\n";
			open FIN,"$file" or die "Error opening file: $!"; 
			$xml = join('', (<FIN>));
			close FIN or die "Error closing file: $!"; 
			print "done.\n";
		}

		print "Contacting server: ... fake ping for now ...";
		print "done.\n";
	
		print "Sending data to server\n";
		my $response    = _test_definition_post_url($credentials, $xml);
		print "done.\n";
	
		_analyse_server_answer($self, $response);

		last if ($file eq '___DEFAULT___weird_file_name___');
	}
	print "Performed download in " .(time - $t). " sec.\n";
}

# a template sub to fake a default xml file
sub _get_default_xml {
	my $credentials = shift;
	return << "EOT";
<xml>
 <version>1.0</version>
 <integrator_version>1.0</integrator_version>
 <integrator_test>
   <project_code>$credentials->{integrator_project_code}{value}</project_code>
 </integrator_test>
</xml>  
EOT
}

=head2 ACTION_integrator_send_xml

 used with: ./Build integrator_send_xml
            ./Build integrator_send_xml --file=commands_api.xml

This action is used to send a an xml api file to Cydone Integrator.

=cut

sub ACTION_integrator_send_xml {
	my $self        = shift;
	my $credentials = _get_integrator_credentials($self);
	$credentials->{integrator_test_definition_post}{value} = 'api/doapi';
	
	my $t           = time;
	my @files;

	#get the filenames to upload
	if (defined $self->{args}{file}) {
		@files = _get_valid_filenames($self->{args}{file});
	}
	else {
		my $default_file = 'server_answer.xml';
		print "Using default file $default_file\n";
		push (@files, $default_file);
	}

	foreach my $file (@files) {
		#list file to upload
		print "Loading xml file '$file' for upload:\n";
		open FIN,"$file" or die "Error opening file: $!"; 
		my $xml = join('', (<FIN>));
		close FIN or die "Error closing file: $!"; 
		print "done.\n";
	
		print "Contacting server: ... fake ping for now ...";
		print "done.\n";
	
		print "Sending data to server\n";
		my $response    = _test_definition_post_url($credentials, $xml);
		print "done.\n";
	
		_analyse_server_answer($self, $response);
	}
	print "Performed upload in " .(time - $t). " sec.\n";
}

=head2 ACTION_integrator_upload_test_definition

 used with: ./Build integrator_upload_test_definition
            ./Build integrator_upload_test_definition --file=definition.xml

This action is used to send a test definition xml file to Cydone Integrator.

=cut

sub ACTION_integrator_upload_test_definition {
	my $self        = shift;
	my $credentials = _get_integrator_credentials($self);
	$credentials->{integrator_test_definition_post}{value} = 'api/uploadTestDefinition';
	#$credentials->{integrator_test_definition_post}{value} = 'frontend_dev.php/api/uploadTestDefinition';
	
	my $t           = time;
	my @files;

	#get the filenames to upload
	if (defined $self->{args}{file}) {
		@files = _get_valid_filenames($self->{args}{file});
	}
	else {
		my $default_file = 'server_answer.xml';
		print "Using default file $default_file\n";
		push (@files, $default_file);
	}

	foreach my $file (@files) {
		#list file to upload
		print "Loading xml file '$file' for upload:\n";
		open FIN,"$file" or die "Error opening file: $!"; 
		my $xml = join('', (<FIN>));
		close FIN or die "Error closing file: $!"; 
		print "done.\n";
	
		print "Contacting server: ... fake ping for now ...";
		print "done.\n";
	
		print "Sending data to server\n";
		my $response    = _test_definition_post_url($credentials, $xml);
		print "done.\n";
	
		_analyse_server_answer($self, $response);
	}
	print "Performed upload in " .(time - $t). " sec.\n";
}

sub _analyse_server_answer {
	my $self        = shift;
	my $response    = shift;
	my $xml_no_attr = 1;
	my $file_out    = $self->{args}{file_out} |= 'server_answer.xml';

	#patch to intercept xml folding request with a '--xml_no_attr=0' on the cmd line
	if (defined $self->{args}{xml_no_attr}) {
		$xml_no_attr = ($self->{args}{xml_no_attr} eq 0) ? 0 : 1;
	}

	if ($response->{_rc} eq '200') {
		print "HTTP transfer done.\n";

		open OUT, ">$file_out" or die "Error, cannot write file $file_out: $!";
		print "Data saved in file $file_out\n";
		print OUT $response->{_content};
		close OUT or die "Error, cannot close file $file_out: $!";
	}
	else {
		print "HTTP Transfer problem...\n";
		$response->{_rc} ||='';
		$response->{msg} ||='';
		print "Apache: return_code='$response->{_rc}', msg='$response->{_msg}'\n";
		print "Apache: content: $response->{_content}'\n";
	}
}

#valid means readable file names from a glob
sub _get_valid_filenames {
	my $glob = shift;
	my @files;
	
	#do something
	@files = glob($glob);

	foreach my $file (@files) {
		die "Error: file $file is not readable, $!"
			unless (-r $file);
		chomp($file);
	}
	return @files;
}

=head2 ACTION_integrator_xml_report

 used with: ./Build integrator_xml_report

This action is used to generate a signed xml representation of all the
test runs launched with the 'integrator_test' action since the last sync
to the server. This action *will not* modify the local data, so it can
be used as often as needed.

To remain compatible with Cydone Integrator, this action requires that
the user provides some credential information. All of this data is
first read from the Build.PL configuration file or prompted from the
command-line if more information is required.

=cut

# This action sub, called as a ./Build parameter, is used to compile all log results from
# the _build/integrator file (under the integrator_test_log key) in one huge xml file
# using the Test::TAP::XML report tool
sub ACTION_integrator_xml_report {
	my $self   = shift;
	
	my $credentials = _get_integrator_credentials($self, qr{or_project_code|or_lab_code});
	my $t           = time;
	my $xml         = _generate_signed_xml_from_struct( $self, $credentials, $self->config_data('regressions'));
	
	open  FOUT, ">", "report.xml" or die "Error: could not create report.xml file, $!, $?";
	print FOUT $xml;
	close FOUT or die "Error: could not close report.xml after creating, $!, $?";
	print STDERR "Generated xtml report in file \"report.xml\". Took ". (time - $t). " sec.\n";
}
sub _remove_undefs {
	my $struct = shift;

	foreach my $key (keys %{$struct}) {
		if (ref $struct->{$key} eq 'HASH') {
			$struct->{$key} = _remove_undefs($struct->{$key});
		}
		elsif (ref $struct->{$key} eq 'ARRAY') {	#an object of some sort
			#XXX TO DO !!! we do nothing... for now... but we could look for undefs inside...
		}
		elsif ((ref $struct->{$key}) =~ /^Module.*Version$/) {	#an object of some sort
			$struct->{$key} = $struct->{$key}{original};
		}
		unless (ref $struct->{$key}) {
			$struct->{$key} = '_UNDEF_' unless defined $struct->{$key};
		}
	}
	return $struct;
}
	
#This sub extracts runs from permanent data struct
sub _load_runs {
	my $struct = shift;
	
	my @all_runs;
	foreach my $uuid (keys %$struct) {
		my $date = localtime($struct->{$uuid}{start_time});
		print "\t...loading test run from user $struct->{$uuid}{integrator_user} ($uuid) "
		      ."dated from $date, for xml conversion.\n";
		
		my $run = Test::TAP::Model->new_with_struct( $struct->{$uuid} );
		$run->{meat}{integrator_test_run_uuid}	= $uuid;
		push(@all_runs, $run->{meat} );
	}
	return @all_runs;
}

sub _load_info {
	my $self = shift;

	#we need to do some clean-up here also...
	#to avoid use of uninitialised values, we patch the undef value into ''
	#for performance reasons, we don't want to traverse the whole structure
	#here, but the risk is that some new fields could create the problem again...
	my $hi = $self->config_data('integrator_harness_info');
	$hi->{script_files} ||= '';

	return $hi;
}

# this sub returns the MD5 checksums for all files in directory 't'
# and will complain if a test file changed compared to the
# signature in the _build/integrator directory
sub _compute_test_signatures {
	my $self = shift;
	my $sign_values;

	#for all files under ./t
	foreach my $file_name (sort @{$self->rscan_dir('t', qr{.*})} ) {
		next if (-d $file_name);		#skip directory entries
		next if ($file_name =~ /\/CVS\//);	#skip CVS files...

		#compute the signature
		open SIGN, "$file_name" or die "Error, cannot read file $file_name for MD5 computation, $?";
		my $file = join('',<SIGN>);
		close SIGN or die "Error, cannot close file $file_name after MD5 computation, $?";
		push(@$sign_values, {
				'filename' => $file_name,
				'md5'      => md5_hex($file),
				#'content'  => $file,		# we don't send the file... but we could...
			     } );
		
	}
	my $date = localtime;
	my $sign = {	
			'sign_date'   => $date,
			'sign_values' => $sign_values,
		};
	return $sign;
}

#the output is a string containing the xml file
sub _generate_signed_xml_from_struct {
	my $self   = shift;
	my $cred   = shift;
	my $struct = shift;
	my $p 	   = $self->{args};
	my $xml_no_attr = 1;

	#patch to intercept xml folding request with a '--xml_no_attr=0' on the cmd line
	if (defined $self->{args}{xml_no_attr}) {
		$xml_no_attr = ($self->{args}{xml_no_attr} eq 0) ? 0 : 1;
	}

	my @all_runs  = _load_runs($struct);
	my $info      = _load_info($self);

	$info = _remove_undefs($info);

	my $harness_uuid = _get_uuid(); 

	#put a frame around it all
	my $skel = {
			'version'	=> '1.0',
			'standalone'	=> '1',
			'encoding'	=> 'UTF-8',
			integrator_version	=>	{
       	               		'version'	=> '1.0', # XXX change key for 'format_version'
			},
			integrator_security	=> {
       	               		'project_code'	=> $cred->{integrator_project_code}{value},
			},
			integrator_question	=> {
				integrator_action	=> 'uploadTestResult',	
			},
			integrator_data	=> {
				'test_run'	=> \@all_runs,
				'integrator_test' => {
       	                		'lab_code'	=> $cred->{integrator_lab_code}{value},
       	                    		'harness_uuid'	=> $harness_uuid,
       		                	'signature'	=> '_TBD_MD5_HASH_',
       	#              		'version'	=> '1.0', # XXX change key for 'format_version'
       	                	},
				'integrator_harness_info'    => $info,
			}
		   };
	my %OUT_options = (
	    RootName        => 'xml',
	    NoAttr  	    => $xml_no_attr,
	    KeyAttr  	    => [],
	    ValueAttr       => [],
	);

	#serialise into xml
	my $xs  = XML::Simple->new();
#XXX put this in an eval block...
	my $xml;

# iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiio
#print Dumper $skel;
#exit;

	eval { $xml = $xs->XMLout($skel, %OUT_options)  };
	if ($@) {
		die "Error, problem loading malformed xml: $@";
	}
	
	# sign the document
	my $sum = md5_hex($xml);
	$xml =~ s/_TBD_MD5_HASH_/$sum/;
	
	return $xml;
}

sub _print_table_header {
	my $user = shift;
	my $date = shift;
	return <<"EOT";
				<tr>
					<th colspan="4" class="r">Test case run by $user, started on $date</th>
				</tr>
EOT
}

sub _get_integrator_credentials {
	my $self 	= shift;
	my $filter 	= shift;	#optional parameter to filter-in credentials to use
   	my $p    	= $self->{properties};
	my $cred	= {
			   integrator_project_code => {
				default	 => 'my_project',
				question => 'a project code',
				order	 => 10,
				regexp	 => qr{\w},
			   },
			   integrator_lab_code	=> {
				default	 => 'first',
				question => 'a lab id',
				order	 => 15,
				regexp	 => qr{\w},
			   },
			   integrator_user	=> {
				default	 => 'nobody',
				question => 'a username for the Integrator login',
				order	 => 20,
				regexp	 => qr{\w},
			   },
			   integrator_pwd	=> {
				default	 => 'nopwd',
				question => 'an api password for the Integrator login',
				order	 => 30,
				regexp	 => qr{\w},
								
				no_echo => 1,
			   },
			   integrator_url	=> {
				default	 => 'https://public1.partnerscydone.com',
				question => 'an Integrator web url',
				order	 => 40,
				regexp	 => qr{\w},
			   },
			   integrator_http_realm => {
				default	 => 'Integrator Demo',
				question => 'an Integrator realm for the web page authentication',
				order	 => 60,
				regexp	 => qr{\w},
			   },
			   integrator_http_user	=> {
				default	 => 'demo',
				question => 'an http user name',
				order	 => 70,
				regexp	 => qr{\w},
			   },
			   integrator_http_pwd	=> {
				default	 => 'okok',
				question => 'an http password',
				order	 => 80,
				regexp	 => qr{\w},

				no_echo  => 1,
			   },
			};

	#ask for values until match with regexp
	foreach my $key ( sort {$cred->{$a}{order} <=> $cred->{$b}{order}} keys %$cred ) {
		#filter-out non matching tags
		next if ((defined $filter) and ($key !~ $filter));
		
		#copy the value from the parameters, then fill-in the blanks
		$cred->{$key}{value} = $p->{$key} ||='';
		while ($cred->{$key}{value} !~ $cred->{$key}{regexp}) {
			print "\nThe value of '$cred->{$key}{value}' for parameter '$key' in Build.PL. is not valid.\n";
			print "\tPlease enter $cred->{$key}{question} "
			     ."(or press ENTER for default '$cred->{$key}{default}')\n";
			
			ReadMode( ($cred->{$key}{no_echo}) ? 'noecho' : 'restore' );
			my $answer = <STDIN>;
			ReadMode('restore');
			
			chomp($answer);
			print "\n" if ($cred->{$key}{no_echo});
		
			$cred->{$key}{value} = ($answer =~ /^$/) ? $cred->{$key}{default} : $answer; 
		}
		print "Credentials: '$key'\tis set to: $cred->{$key}{value}\n" unless ($cred->{$key}{no_echo});
	}

	return $cred;
}

sub _harness_post_url {
	my $cred = shift;
	my $xml  = shift;

	my $browser = LWP::UserAgent->new;

	# Create a user agent object
	$browser->agent("Integrator::Module::Build/$Integrator::Module::Build::VERSION");

	#this parameter has a default value and is no longer required from the user...
	$cred->{integrator_sync_page}{value} |= 'api/doapi';
	
	#clean-up the urls
	$cred->{integrator_url}{value}       =~ s/\/$//g;
	$cred->{integrator_sync_page}{value} =~ s/\/$//g;
	$cred->{integrator_sync_page}{value} =~ s/^\///g;
	$cred->{complete_url}{value} = $cred->{integrator_url}{value} .'/'. $cred->{integrator_sync_page}{value};

	if($cred->{integrator_http_realm}) {
		$browser->credentials(URI->new($cred->{integrator_url}{value})->host_port,   #yark !
				      $cred->{integrator_http_realm}{value}, 
				      $cred->{integrator_http_user}{value} => $cred->{integrator_http_pwd}{value});
	}

	# Pass request to the user agent and get a response back
	my $res = $browser->post( $cred->{complete_url}{value}, 
				[
				 'query'     => $xml,
		  		 'user_name' => $cred->{integrator_user}{value},
		  		 'password'  => $cred->{integrator_pwd}{value}
				]);
	# Check the status of the response
	unless ($res->is_success) {
		print $res->status_line, "\n";
	}
	return $res;
}

sub _test_definition_post_url {
	my $cred = shift;
	my $xml  = shift;

	my $browser = LWP::UserAgent->new;

	# Create a user agent object
	$browser->agent("Integrator::Module::Build/$Integrator::Module::Build::VERSION");

	#clean-up the urls
	$cred->{integrator_url}{value}       =~ s/\/$//g;
	$cred->{integrator_test_definition_post}{value} =~ s/\/$//g;
	$cred->{integrator_test_definition_post}{value} =~ s/^\///g;
	$cred->{complete_url}{value} = $cred->{integrator_url}{value}
				       .'/'. $cred->{integrator_test_definition_post}{value};

	if($cred->{integrator_http_realm}) {
		$browser->credentials(URI->new($cred->{integrator_url}{value})->host_port,   #yark !
				      $cred->{integrator_http_realm}{value}, 
				      $cred->{integrator_http_user}{value} => $cred->{integrator_http_pwd}{value});
	}

	# Pass request to the user agent and get a response back
	my $res = $browser->post( $cred->{complete_url}{value}, 
					[
					 'query'     => $xml,
			  		 'user_name' => $cred->{integrator_user}{value},
			  		 'password'  => $cred->{integrator_pwd}{value}
					]);

	# Check the outcome of the transaction
	unless ($res->is_success) {
		print $res->status_line, "\n";
	}
	return $res;
}

sub _log_results_with_look_up {
	my $IMB = shift;
	my $t   = shift;
	my $NL	= $NEW_LINE;
	my $SHRP= $POUND_SIGN;

	#load persistant regression object
	my $reg_log    = $IMB->config_data('regressions');
	
	#update regression data with a unique key, and other fields
	my $uuid  = _get_uuid();
	$reg_log->{$uuid}			= $t->structure;
	$reg_log->{$uuid}{integrator_status}	= 'NEW_INSERTION';
	$reg_log->{$uuid}{ran_by}		= "$ENV{USER}";

	#patch to assign a default value to the 'pos' fields, they appear as undef
	#if left untouched and it throws warnings under Test::TAP::Model reload...
	#Pos means 'position' and is related to 'pugs', a perl6 simulator ???
	######### From Test::TAP::Model pod page #################################
	# pugs auxillery stuff, from the <pos:> comment
        # pos    => # the place in the test file the case is in
	##########################################################################
	# multiple line entries are also "encoded"...
	foreach my $luuid (keys %{$reg_log}) {
		foreach my $run ( $reg_log->{$luuid}{test_files} ) {
			foreach my $file (@$run) {
				#line feed replacements
				$file->{pre_diag} =~ s/\n/$NL/g  if (defined $file->{pre_diag} );
				$file->{pre_diag} =~ s/#/$SHRP/g if (defined $file->{pre_diag} );
				foreach my $event ($file->{events}) {
					foreach my $step (@$event) {
						#measurement look-up, default values and line feed replacements
						_extract_measurement  ($step);
						_extract_configuration($step);
						_extract_config_file  ($step);
						$step->{pos}  ||= '';
						$step->{line} =~ s/\n/$NL/g  if (defined $step->{line}     );
						$step->{line} =~ s/#/$SHRP/g if (defined $step->{line}     );
						$step->{diag} =~ s/\n/$NL/g  if (defined $step->{diag}     );
						$step->{diag} =~ s/#/$SHRP/g if (defined $step->{diag}     );
					}
				}
			}
		}
	}

	#commit the data
	$IMB->config_data("regressions"	=> $reg_log);
}

#this internal function is used to extract measurement declarations from the TAP output
#and cast it in the attribute values of the event tag. Measurements are thus considered
#to be a special sort of events.
sub _extract_measurement {
	my $step = shift;

	#split on ; and assign default value of ''.
	if ($step->{line} =~ /integrator_measurement:\s*(.*)/) {
		my $line = $1;
		chomp($line);
		$line .= ';;;;;';	#patch to have map do its thing on all fields.
		( $step->{integrator_meas_name}  ,
		  $step->{integrator_meas_value} ,
		  $step->{integrator_meas_unit}  ,
		  $step->{integrator_meas_tol}   ,
		  $step->{integrator_meas_equip} ) = split (/\s*;\s*/,$line);
	}
	foreach my $key (keys %$step) {
		$step->{$key} ||= '';
	}
}

#this internal function is used to extract confirguration data that 
#was declared from the TAP output.
sub _extract_configuration {
	my $step = shift;

	#split on ; and assign default value of ''.
	if ($step->{line} =~ /integrator_component:\s*(.*)/) {
		my $line = $1;
		chomp($line);
		$line .= ';;;;;;';
		( $step->{integrator_cmp_name}        ,
		  $step->{integrator_cmp_serial}      ,
		  $step->{integrator_cmp_state_name}  ,
		  $step->{integrator_cmp_state_value} ) = split (/\s*;\s*/, $line);
	}
	foreach my $key (keys %$step) {
		$step->{$key} ||= '';
	}
}

#this internal function is used to extract config files that 
#are extracted from the TAP output.
sub _extract_config_file {
	my $step = shift;

	if (defined $step->{diag}
		and $step->{diag} =~ /integrator_config_data:\s*(.*)\s*;\s*(.*)\s*;(.*)\s*integrator_config_data_end:/s) {
		
		my $file_name = $1;
		my $size      = $2;
		my $content   = $3;
		chomp($file_name);

		$content =~ s/\#\s+//gm;
		$content =~ s/\n*//gm;
		$step->{diag} = "integrator_config_data: $file_name";
		push (@{$step->{integrator_config_file}}, { file_name    => $file_name,
							    file_size    => $size,
						            file_content => $content    } );
 	}
}

sub _load_xml {
	my $file = shift;
	my $struct;

	my $xs = XML::Simple->new();
	my %IN_options = (
	    NoAttr  	    => 0,
	    ForceArray 	    => 1,
	    KeyAttr  	    => [],
	);

	eval { $struct = $xs->XMLin($file ,%IN_options) };
	if ($@) {
		die "Error, problem loading malformed xml: $@";
	}

	return $struct;
}

sub _file_contains_text {
	my $file = shift;
	my $text = shift;

	if (-r $file) {
		open  FIN, "<$file" or die "Error, cannot open file $file for inspection, $?";
		my $content = join ('', <FIN>);
		close FIN	    or die "Error, cannot close file $file after inspection, $?";
	
		return 1 if ($content =~ /$text/);
		return 0;
	}
	#file is not readable, assume no.
	else {
		return 0;
	}
}

#function taken from the O'Reilly cookbook.
sub _is_rw_safe {
    my $path = shift;
    my $info = stat($path);    
    return unless $info;

    # owner neither superuser nor me 
    # the real uid is stored in the $< variable
    if (($info->uid != 0) && ($info->uid != $<)) {
        return 0;
    }

    # check whether group or other can write file.
    # use 066 to detect either reading or writing
    if ($info->mode & 066) {   # someone else can write this
        return 0 unless -d _;  # non-directories aren't safe
            # but directories with the sticky bit (01000) are
        return 0 unless $info->mode & 01000;        
    }

	return 1;
}

#crude... but portable
sub _get_uuid {
	return md5_hex(time + rand(10000));
}

=head1 AUTHOR

Francois Perron, Cydone Solutions Inc.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-integrator-module-build at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Integrator-Module-Build>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc or man commands.

    perldoc Integrator::Module::Build
    man Integrator::Module::Build

You can also look for information at: L<http://www.cpan.org> or L<http://www.cydone.com>

=head1 ACKNOWLEDGEMENTS

This module would not have been possible without the great contributions
by Ken Williams, Andy Lester, chromatic, Michael G Schwern and all folks
involved in the creation of Test::... , Module::Build, Module::Starter
and supporting modules.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Cydone Solutions Inc, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Integrator::Module::Build
