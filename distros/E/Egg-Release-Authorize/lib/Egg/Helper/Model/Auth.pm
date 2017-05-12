package Egg::Helper::Model::Auth;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Auth.pm 347 2008-06-14 18:57:53Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.01';

sub _start_helper {
	my($self)= @_;
	my $c= $self->config;
	$c->{helper_option}{project_root} || return $self->_helper_help
	   ('I want you to start from helper of the project.');
	my $comp_name= ucfirst( shift( @ARGV ) )
	   || return $self->_helper_help('I want component name.');
	$comp_name=~m{^[A-Z][A-Za-z0-9\_]+$}
	   || return $self->_helper_help('Bad format of component name.');
	my $o= $self->_helper_get_options;
	my $version= $self->helper_valid_version_number($o->{version}) || return 0;
	my $param= $self->helper_prepare_param({
	  module_version=> $version,
	  created=> __PACKAGE__. " v$VERSION",
	  });
	$self->helper_prepare_param_module
	   ($param, $self->project_name, qw/ Model Auth /, $comp_name);
	my $comp_path= $param->{module_output_filepath}=
	   "$param->{output_path}/lib/$param->{module_filepath}";
	-e $comp_path
	   and return $self->_helper_help("'$comp_path' already exists.");
	$self->helper_generate_files(
	  param        => $param,
	  chdir        => [$param->{output_path}],
	  create_files => [$self->helper_yaml_load(join '', <DATA>)],
	  errors       => { unlink=> [$comp_path] },
	  complete_msg => "\nAuth component generate is completed.\n\n"
	               .  "output path : $comp_path\n\n"
	  );
	$self;
}
sub _helper_help {
	my $self = shift;
	my $msg  = shift || "";
	my $pname= lc $self->project_name;
	$msg= "ERROR: ${msg}\n\n" if $msg;
	print <<END_HELP;
${msg}% perl ${pname}_helper.pl M::Auth [COMPONENT_NAME]

END_HELP
	0;
}

=head1 NAME

Egg::Helper::Model::Session - Helper who generates AUTH controller module.

=head1 SYNOPSIS

  % cd /path/to/MyApp/bin
  % ./myapp_helper.pl M::Auth MyAuth
  ..........
  ......

=head1 DESCRIPTION

It is a helper who generates the controller module to use it with L<Egg::Model::Auth>
under the control of 'lib' directory of the project.

It starts specifying the Model::Auth mode and the generated module name for the 
helper script of the project to use it.

  % ./myapp_helper.pl Model::Auth [MODULE_NAME]

Then, '/path/to/MyApp/lib/MyApp/Model/Auth/[MODULE_NAME].pm' is generated.

The configuration and the component module of this session module are additionally
corrected to the application after it generates it and it uses it.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Auth>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

__DATA__
filename: <e.module_output_filepath>
value: |
  package <e.module_distname>;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Auth::Base /;
  
  __PACKAGE__->config(
    label_name => 'auth_label',
    file=> {
  #   path   => <e.project_name>->path_to(qw/ etc members /),
  #   fields => [qw/ uid psw active a_group age /],
  #   id_field       => 'uid',
  #   password_field => 'psw',
  #   active_field   => 'active',
  #   group_field    => 'a_group',
  #   separator      => qr{ *\t *},
      },
    );
  
  # __PACKAGE__->setup_plugin(qw/ Keep /);
  
  __PACKAGE__->setup_session( FileCache => 'Bind::Cookie' );
  
  __PACKAGE__->setup_api('File');
  
  1;
  
  __END__
  <e.document>
