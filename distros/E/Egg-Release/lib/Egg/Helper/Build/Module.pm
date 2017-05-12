package Egg::Helper::Build::Module;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Module.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;

our $VERSION= '3.02';

sub build_script {
	require Egg::Helper::Util::Base;
	print STDOUT <<SCRIPT;
#!@{[ Egg::Helper::Util::Base->helper_perl_path ]}
use Egg::Helper;
Egg::Helper->run('Build::Module');
SCRIPT
}
sub helper_mod_name_split {
	my $self= shift;
	my $mod_name= shift || croak 'I want module name.';
	my @parts;
	for (split /(?:\:+|\-)/, $mod_name) {
		$_= ucfirst $_;
		/^[A-Z][A-Za-z0-9_]+$/ || return (undef);
		push @parts, $_;
	}
	\@parts;
}
sub helper_mod_template {
	my $self = shift;
	[ $self->helper_yaml_load(join '', <DATA>) ];
}
sub _start_helper {
	my($self)= @_;
	my $c= $self->config;
	my $mod_name= shift(@ARGV)
	   || return $self->_helper_help('I want module name.');
	my $parts= $self->helper_mod_name_split($mod_name)
	   || return $self->_helper_help('Bad format of plugin name.');
	my $o= $self->_helper_get_options;
	my $version= $self->helper_valid_version_number($o->{version}) || return 0;
	my $param  = $self->helper_prepare_param({
	   output_path      => ($o->{output} || $self->helper_current_dir),
	   module_version   => $version,
	   module_generator => __PACKAGE__,
	   created          => __PACKAGE__. " v$VERSION",
	   });
	$self->helper_prepare_param_module($param, $parts);
	-e $param->{target_path} and
	   return $self->_helper_help("$param->{target_path} A already exists.");
	$param->{module_output_filepath}=
	   "$param->{lib_dir}/$param->{module_filepath}";
	$self->helper_generate_files(
	  param        => $param,
	  chdir        => [$param->{target_path}, 1],
	  create_files => $self->helper_mod_template,
	  makemaker_ok => ($o->{unmake} ? 0: 1),
	  errors       => { rmdir=> [$param->{target_path}] },
	  complete_msg => "\nModule generate is completed.\n\n"
	               .  "output path : $param->{target_path}\n"
	  );
	$self;
}
sub _helper_get_options {
	shift->next::method(' v-version= m-unmake ');
}
sub _helper_help {
	my $self = shift;
	my $msg  = shift || "";
	$msg= "ERROR: ${msg}\n\n" if $msg;
	print <<END_HELP;
${msg}% egg_module_builder.pl [MODULE_NAME] [-o OUTPUT_PATH] [-v VERSION]

END_HELP
	0;
}

1;

=head1 NAME

Egg::Helper::Build::Module - The module file complete set is generated.

=head1 SYNOPSIS

  % perl -MEgg::Helper::Build::Module \
    -e 'Egg::Helper::Build::Module->build_script' \
     > /path/to/egg_module_builder.pl

  % perl egg_module_builder.pl MyModule

=head1 DESCRIPTION

It is a helper who generates the module file complete set.

This helper generates the file complete set that L<ExtUtils::MakeMaker> outputs.

The thing that starts specifying the mode of the helper script can be done,
and the thing that generates a special script from 'build_script' method and
uses it can be done.

The file complete set is generated when starting specifying the module name made
for the generated script.

  % perl egg_module_builder.pl [MODULE_NAME]

The file that this module outputs is as follows.

  Build.PL
  Changes
  Makefile.PL
  MANIFEST
  README
  t/00_use.t
  t/89_pod.t
  t/98_perlcritic.t
  t/99_pod_coverage.t~

=head1 METHODS

=head2 build_script

The start script only for this helper is returned and the code is returned.

  % perl -MEgg::Helper::Build::Module -e 'Egg::Helper::Build::Module->build_script'

=head2 helper_mod_name_split ([MODULE_NAME])

The ARRAY reference into which MODULE_NAME is divided by ':' and '-' is returned.

Undefined is returned if there is suitably no divided each value as a module name
of Perl. 

  my $parts= $self->helper_mod_name_split($module_name) || return 0;

=head2 helper_mod_template

Each template of the output file is settled by the ARRAY reference and it 
returns it.

Each value of ARRAY is HASH form to pass it to 'helper_create_files' method.

  my $files= $self->helper_mod_template;

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Helper>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut



__DATA__
---
filename: <e.module_output_filepath>
filetype: module
value: |
  package <e.module_distname>;
  #
  # Copyright (C) <e.year> <e.headcopy>.
  # <e.author>
  #
  # <e.revision>
  #
  use strict;
  use warnings;
  
  our $VERSION = '<e.module_version>';
  
  # ... Let's write the perl code here.
  
  # Please refer to L<<e.module_generator>> for hook of Egg.
  
  1;
  
  __END__
  <e.document>
  
---
filename: Makefile.PL
value: |
  use inc::Module::Install;
  
  name          '<e.module_name>';
  all_from      'lib/<e.module_filepath>';
  version_from  'lib/<e.module_filepath>';
  abstract_from 'lib/<e.module_filepath>';
  author        '<e.author>';
  license       '<e.license>';
  
  requires 'Egg::Release' => <e.egg_release_version>;
  
  build_requires 'Test::More';
  build_requires 'Test::Pod';
  # build_requires 'Test::Perl::Critic';
  # build_requires 'Test::Pod::Coverage';
  
  use_test_base;
  auto_include;
  WriteAll;
  
---
filename: t/00_use.t
value: |
  # Before `make install' is performed this script should be runnable with
  # `make test'. After `make install' it should work as `perl test.t'
  
  #########################
  
  # change 'tests => 1' to 'tests => last_test_to_print';
  
  use Test::More tests => 1;
  BEGIN { use_ok('<e.module_distname>') };
  
  #########################
  
  # Insert your test code below, the Test::More module is use()ed here so read
  # its man page ( perldoc Test::More ) for help writing this test script.
  
---
filename: t/89_pod.t
value: |
  use Test::More;
  eval "use Test::Pod 1.00";
  plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
  all_pod_files_ok();
  
---
filename: t/98_perlcritic.t
value: |
  use strict;
  use Test::More;
  eval q{ use Test::Perl::Critic };
  plan skip_all => "Test::Perl::Critic is not installed." if $@;
  all_critic_ok("lib");
  
---
filename: t/99_pod_coverage.t~
value: |
  use Test::More;
  eval "use Test::Pod::Coverage 1.00";
  plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
  all_pod_coverage_ok();
  
---
filename: Changes
value: |
  Revision history for Perl extension <$e.distname>.
  
  <e.module_version>  <e.gmtime_string>
  	- original version; created by <e.created>
  	   with module name <e.module_distname>
  
---
filename: README
value: |
  <e.module_distname>.
  =================================================
  
  The README is used to introduce the module and provide instructions on
  how to install the module, any machine dependencies it may have (for
  example C compilers and installed libraries) and any other information
  that should be provided before the module is installed.
  
  A README file is required for CPAN modules since CPAN extracts the
  README file from a module distribution so that people browsing the
  archive can use it get an idea of the modules uses. It is usually a
  good idea to provide version information here so that people can
  decide whether fixes for the module are worth downloading.
  
  INSTALLATION
  
  To install this module type the following:
  
     perl Makefile.PL
     make
     make test
     make install
  
  AUTHOR
  
  <e.author>
  
  COPYRIGHT AND LICENCE
  
  Put the correct copyright and licence information here.
  
  Copyright (C) <e.year> by <e.copyright>.
  
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version 5.8.6 or,
  at your option, any later version of Perl 5 you may have available.
  
---
filename: MANIFEST.SKIP
value: |
  \bRCS\b
  \bCVS\b
  ^blib/
  ^_build/
  ^MANIFEST\.
  ^Makefile$
  ^pm_to_blib
  ^MakeMaker-\d
  ^t/9\d+_.*\.t
  Build$
  \.cvsignore
  \.?svn*
  ^\%
  (~|\-|\.(old|save|back|gz))$
