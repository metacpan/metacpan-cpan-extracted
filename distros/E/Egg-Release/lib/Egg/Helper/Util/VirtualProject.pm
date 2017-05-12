package Egg::Helper::Util::VirtualProject;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: VirtualProject.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use base qw/ Class::Data::Inheritable /;

our $VERSION= '3.00';

sub _start_helper {
	my($self)= @_;
	my %option;
	{
		my $c= $self->config->{helper_option};
		%option= $c->{vtest_config} ? (%$c, %{$c->{vtest_config}}): %$c;
	  };
	my $project= $option{vtest_name} ||= 'Vtest';
	if ($option{helper_test}) {
		@ARGV= ();
		$self->config->{root}= Egg::Helper->helper_tempdir;
	}
	unless (__PACKAGE__->can('base_root')) {
		unshift @INC, $self->config->{start_dir}. "/lib";
		__PACKAGE__->mk_classdata('base_root');
		__PACKAGE__->base_root($self->config->{root});
	}
	if (my $scode= $option{start_code}) {
		eval $scode; $@ and die $@;  ## no critic.
		delete($option{start_code});
	}
	$option{project_root}= $option{root}=
	    $option{vtest_root} || __PACKAGE__->base_root. "/$project";
	$option{start_dir}= $self->helper_current_dir;
	$self->helper_create_dir($option{root}) unless -e $option{root};
	$self->helper_chdir($option{root});
	if (my $files= $option{create_files}) {
		$self->helper_create_files($files, $self->config);
	}
	$self->_create_project($project);
	unshift @INC, "$option{root}/lib";
	$project->_vtest_import(\%option);
	if (my $helper= $option{helper_test}) {
		$helper->require or die $@;
		no strict 'refs';  ## no critic.
		unshift @{"${project}::ISA"}, $helper;
	}
	if (my $methods= $option{create_methods}) {
		no strict 'refs';  ## no critic.
		no warnings 'redefine';
		while (my($method, $code)= each %$methods) {
			*{"${project}::$method"}= $code;
		}
	}
	$project->new;
}
sub _create_project {
	my $self= shift;
	my $p= shift || die q{I want project name.};
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	${"${p}::VERSION"}= '0.01';
	push @{"${p}::ISA"}, 'Egg::Helper::Util::Base';
	push @{"${p}::ISA"}, 'Egg::Helper::Util::VirtualProject';
	*{"${p}::_vtest_import"}= sub {
		my($class, $conf)= @_;
		my %c= %$conf;
		$c{project_name}= $p;
		my $pkg_uc= uc $p;
		$ENV{"${pkg_uc}_DISPATCH_CLASS"}= 0
		    unless defined($ENV{"${pkg_uc}_DISPATCH_CLASS"});
		$ENV{EGG_IMPORT_PROJECT}= $p;
		Egg->import(@{$c{vtest_plugins} || []});
		delete $c{dir};
		$p->egg_startup(\%c);
		$p->dispatch_map($c{vtest_dispatch_map} || {});
	  };
	*{"${p}::DESTROY"}= sub {
		my($proto)= @_;
		return $proto if $proto->{egg_startup};
		if (my $root= $proto->config->{root}) {
			$proto->helper_remove_dir($root);
		}
		$proto;
	  };
	$self;
}

1;

__END__

=head1 NAME

Egg::Helper::Util::VirtualProject - Virtual project for package test.

=head1 SYNOPSIS

  use Test::More tests=> 10;
  use Egg::Helper;
  
  my $e= Egg::Helper->run('vtest');

=head1 DESCRIPTION

It is a helper who offers the virtual project environment to use it in the package
test of the module.

The object of a virtual project is passed and 'Vtest' is passed to the 'run' method
of obtaining L<Egg::Helper>.

  my $e= Egg::Helper->run('vtest');

And, it is treated since the first argument as a configuration of the project.

The name of a virtual project is usual 'Vtest'.
'project_name' is set to the configuration and it is revokable.

  my $e= Egg::Helper->run( vtest => {
    project_name => 'MyProject',
    } );

The plug-in to want to load into a virtual project sets 'plugins' to the configuration.

  my $e= Egg::Helper->run( vtest => {
    plugins => [qw/ -Debug Encode Filter /],
    });

* The flag is specified in 'plugins'.

It is executed before the object is generated when the code reference is set in
'start_code'.

  my $e= Egg::Helper->run( vtest => {
    start_code => sub {
      ....................
      .........
      },
    });

The method that wants to be generated with 'create_methods' can be set.

  my $e= Egg::Helper->run( vtest => {
    create_methods => {
      hoo => sub {
           my($e)= @_;
           ........
        },
      boo => sub {
           my($e)= @_;
           ........
        },
      },
    });

The root directory of a virtual project is made from the project name in the place
obtained by 'helper_tempdir' of L<Egg::Helper>. Moreover, the work directory moves
to this root directory at the same time as generating the object.

Please set it in the configuration when 'dispatch_map' is necessary.
You may separately generate the Dispatch module of course and read.

Please intitule an individual project in 'project_name' when two or more virtual
projects are necessary.  When two or more virtual projects are generated with the
same name, the inconvenience of the redefine of the method etc. is generated.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Helper>,
L<Class::Data::Inheritable>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

