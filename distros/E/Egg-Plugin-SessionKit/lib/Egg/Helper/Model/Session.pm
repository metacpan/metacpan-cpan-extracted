package Egg::Helper::Model::Session;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Session.pm 303 2008-03-05 07:47:05Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.02';

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
	   ($param, $self->project_name, qw/ Model Session /, $comp_name);
	my $comp_path= $param->{module_output_filepath}=
	   "$param->{output_path}/lib/$param->{module_filepath}";
	-e $comp_path
	   and return $self->_helper_help("'$comp_path' already exists.");
	$self->helper_generate_files(
	  param        => $param,
	  chdir        => [$param->{output_path}],
	  create_files => [$self->helper_yaml_load(join '', <DATA>)],
	  errors       => { unlink=> [$comp_path] },
	  complete_msg => "\nDBI component generate is completed.\n\n"
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
${msg}% perl ${pname}_helper.pl M::Session [COMPONENT_NAME]

END_HELP
	0;
}

1;

=head1 NAME

Egg::Helper::Model::Session - Helper who generates session module.

=head1 SYNOPSIS

  % cd /path/to/MyApp/bin
  % ./myapp_helper.pl M::Session MySession
  ..........
  ......

=head1 DESCRIPTION

It is a helper who generates the session module to use it with L<Egg::Model::Session>
under the control of 'lib' directory of the project.

It starts specifying the Model::Session mode and the generated module name for
the helper script of the project to use it.

  % ./myapp_helper.pl Model::Session [MODULE_NAME]

Then, /path/to/MyApp?/lib/MyApp/Model/Session/[MODULE_NAME].pm  is generated.

The configuration and the component module of this session module are additionally
corrected to the application after it generates it and it uses it.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut


__DATA__
filename: <e.module_output_filepath>
value: |
  package <e.module_distname>;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::Base /;
  
  our $VERSION= '<e.module_version>';
  
  __PACKAGE__->config(
  #  label_name => 'session_label',
    param_name => 'ss',
    );
  
  __PACKAGE__->startup qw/
    Base::FileCache
    Bind::Cookie
    ID::SHA1
    /;
  
  package <e.module_distname>::TieHash;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::TieHash /;
  
  1;
  
  __END__
  <e.document>
  
