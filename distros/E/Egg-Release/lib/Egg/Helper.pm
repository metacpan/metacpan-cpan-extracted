package Egg::Helper;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Helper.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use base qw/ Egg::Helper::Util::Base /;

our $VERSION= '3.01';

$SIG{__DIE__}= sub { Egg::Error->throw(@_) };

my %A= (
  project => 'Build::Project',
  vtest   => 'Util::VirtualProject',
  tester  => 'Util::Tester',
  tools   => 'Util::Tools',
  );
my %Alias= (
  B => 'Build',
  C => 'Controller',
  D => 'Dispatch',
  H => 'Helper',
  L => 'Log',
  M => 'Model',
  P => 'Plugin',
  R => 'Response',
  U => 'Util',
  V => 'View',
  m => 'Module',
  r => 'Request',
  );
my($modenow, $contextnow);

sub run {
	my $class= shift;
	my $mode = ucfirst(shift) || croak q{ I want 'MODE'. };
	my $attr = shift || {};
	if (my $a= $A{lc $mode}) { $mode= $a }
	if ($mode=~m{^([A-Za-z])[\:\-]+}) {
		if (my $alias= $Alias{$1}) { $mode=~s{^[^\:\-]+} [$alias] }
	}
	$mode=~s{\-} [::]g;
	$mode=~s{([^\:])\:([^\:])} [$1.'::'.$2]eg;
	$mode=~s{\:([a-z])} [':'. ucfirst($1)]eg;
	($modenow and $modenow eq $mode)
	    and die qq{ '$modenow' mode is operating. };
	if ($contextnow) {
		my %conf= (
		  %{$contextnow->config},
		  project_name => ($attr->{project_name} || undef),
		  helper_option=> $attr,
		  );
		$contextnow->config(\%conf);
		return 	$contextnow->_start_helper;
	}
	my $pkg= "Egg::Helper::$mode";
	$pkg->require || return $class->_helper_help(
	  $@=~/^\s*Can\'t\s+locate/
	     ? qq{ Typing error of mode name. [$mode] }
	     : qq{ Script error: $@ }
	  );
	my $plugins;
	if (my $loads= $pkg->can('_helper_load_plugins')) {
		$plugins= $loads->() || [];
	} else {
		$plugins= [];
	}
	$contextnow= $class->_helper_context($pkg, $plugins, $attr);
	$contextnow->_start_helper;
}
sub helper_tools {
	my $class= shift;
	$class->_helper_context('Egg::Helper::Dummy', [], @_);
}
sub _helper_context {
	my($class, $pkg, $plugins)= splice @_, 0, 3;
	my $attr   = $_[1] ? {@_}: ($_[0] || {});
	my $handler= $ENV{EGG_HELPER_CLASS} || 'Egg::Helper::Project';
	$attr->{start_dir}= $class->helper_current_dir;
	$attr->{project_root} ||= $class->helper_tempdir || $attr->{start_dir};
	$attr->{root}= $attr->{project_root};
	$handler->__import($pkg, $plugins, {
	  project_name => ($attr->{project_name_orign} || 'EggHelper'),
	  root         => $attr->{project_root},
	  start_dir    => $attr->{start_dir},
	  helper_option=> $attr,
	  });
	$handler->new;
}
sub helper_script {
	print STDOUT <<SCRIPT;
#!@{[ Egg::Helper::Util::Base->helper_perl_path ]}
use Egg::Helper;
Egg::Helper->run( shift(\@ARGV) );
SCRIPT
}
*out= \&helper_script;

package Egg::Helper::Project;
use strict;
use warnings;
require Egg;

our @ISA= qw/ Egg::Helper::Util::Base /;
our $START_DIR;

sub __import {
	my($class, $pkg, $plugins, $attr)= @_;
	$ENV{"EGG::HELPER::PROJECT_DISPATCH_CLASS"}= 0;
	Egg->import(@$plugins);
	unshift @ISA, $pkg;
	__PACKAGE__->_startup($attr);
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	*{"${class}::namespace"}= sub { $_[0]->config->{project_name} };
	*{"${class}::project_name"}= $class->can('namespace');
	$START_DIR= $attr->{start_dir} || "";
	$class;
}
END { chdir($START_DIR) if $START_DIR };  ## no critic.

package Egg::Helper::Dummy;

1;

__END__

=head1 NAME

Egg::Helper - Helper module for Egg. 

=head1 DESCRIPTION

This module is started by the helper script.

=head2 Helper of standard appending.

=over 4

=item * L<Egg::Helper::Build::Module >.

The template of the Perl module is generated.

=item * L<Egg::Helper::Build::Plugin>.

The template of the plug-in module is generated.

=item * L<Egg::Helper::Build::Project>.

The project is constructed.

=item * L<Egg::Helper::Build::Prototype>.

'prototype.js' etc. are output.

=item * L<Egg::Helper::Config::YAML>.

The model of the configuration of the YAML form is generated.

=item * L<Egg::Helper::Util::Tester>.

Test of project application.

=item * L<Egg::Helper::Util::VirtualProject>.

Virtual project for package test.

=back

=head1 METHODS

=head2 run

When the helper script is started, this method is called.

=head2 helper_tools

Especially, nothing is done. Helper object is only returned.

The thing used to cause some actions as the file is made before the
L<Egg::Helper::Util::VirtualProject> object is acquired in the package
test etc. is assumed.

  use Egg::Helper;
  
  my $tool= Egg::Helper->helper_tools;
  
  $tool->helper_create_file(join '', <DATA>);
  .....

It is a project object that this method returns that succeeds to
L<Egg::Helper::Util::Base>.

=head2 helper_script

The code of the helper scripting to generate the project is returned.

To generate the helper script, as follows is done.

  % perl -MEgg::Helper -e 'Egg::Helper->helper_script' > /path/to/egg_helper.pl

I think that the generated script is convenient when it outputs to the place that
passing passed, and the execution attribute is given at the right time.

And, the project is generated as follows.

  % egg_helper.pl project [PROJECT_NAME] -o/path/to

=over 4

=item * Alias = out

=back

=head1 SEE ALSO

L<Egg>,
L<Egg::Release>,
L<Egg::Helper::Util::Base>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

