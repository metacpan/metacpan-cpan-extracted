#!/usr/bin/perl -w

use strict;
use HTML::Mason::Tests;
use File::Spec;
use File::Path;

eval { require MasonX::Request::WithApacheSession; };

if ($@) { 
	print "1..0 # Skip You don't have installed MasonX::Request::WithApacheSession module";
	exit;
 }

my $tests = &make_tests();
$tests->run;

sub make_tests() {

	my $group = HTML::Mason::Tests->new(
									name => 'HTMLTemplate',
									description => 
													'Basic tests for Request::HTMLTemplate subclass',
									pre_test_cleanup => 0,
									);
	my %params = (
					request_class 	=> 'MasonX::Request::HTMLTemplate::WithApacheSession',
					session_class	=> 'File',
				);

	foreach ( 	[session_directory => 'sessions'] ,
				[session_lock_directory => 'session_locks']
			)
	{
		my $dir = File::Spec->catfile ($group->data_dir , $_->[1]);
		mkpath($dir);

		$params { $_->[0] } = $dir;
	}

	use Apache::Session::File;

	my %session;
	
	tie %session , 'Apache::Session::File', undef ,
		{ 	Directory 		=> $params{session_directory},
			LockDirectory	=> $params{session_lock_directory} };
	
	untie %session;

	$group->add_test(
							name 			=> 'can_session',
							description 	=> 'make sure that exists session method',
							interp_params 	=> \%params,
							component 		=> <<'							EOF',
								I <% $m->can('session') ? 'can' : 'cannot' %> session 
							EOF
							expect 			=><<'							EOF',
								I can session
							EOF
					);

	return $group;
	

	$group->add_support(
							path 			=> 'simple_test.htt',
							component 		=> <<'							EOF',
								I love %myscript%!
							EOF
						);

	$group->add_test(
							name 			=> 'simple_test.mpl',
							description 	=> 'make sure that htt template works',
							interp_params 	=> \%params,
							call_args 		=> {myscript => 'MASON'},
							component 		=> <<'							EOF',
								<%init>
									$m->print_template();
								</%init>
							EOF
							expect 			=><<'							EOF',
								I love MASON!
							EOF
					);

	$group->add_support(
							path 			=> 'add_args.htt',
							component 		=> <<'							EOF',
								%every% %word% %of% %this% <TMPL_VAR NAME="component">
								<TMPL_VAR NAME="is">placeholder</TMPL_VAR> %dynamic%
							EOF
						);
	$group->add_test(
							name 			=> 'add_args.mpl',
							description 	=> 'make sure that add_template_args method works',
							interp_params 	=> \%params,
							component 		=> <<'							EOF',
								<%init>
									$m->add_template_args( every => 'every' , word => 'word' );
									$m->add_template_args( of => 'of' , this => 'this' );
									$m->add_template_args( component => 'component' , is => 'is' );
									$m->add_template_args( dynamic => 'dynamic' );
									$m->print_template();
								</%init>
							EOF
							expect 			=><<'							EOF',
								every word of this component
								is dynamic
							EOF
					);

	$group->add_support(
							path 			=> 'lang_test.htt',
							component 		=> <<'							EOF',
								I love %myscript%!
							EOF
						);
	$group->add_support(
							path 			=> 'lang_test.it.htt',
							component 		=> <<'							EOF',
								Io amo %myscript%!
							EOF
						);
	$group->add_test(
							name 			=> 'lang_test.mpl',
							description 	=> 'make sure that language support works',
							interp_params 	=> \%params,
							call_args 		=> {myscript => 'MASON'},
							component 		=> <<'							EOF',
								<%init>
									$m->print_template();
									$m->add_template_args( 'lang' => 'it' );
									$m->print_template();
								</%init>
							EOF
							expect 			=><<'							EOF',
								I love MASON!
								Io amo MASON!
							EOF
					);



return $group;
}
