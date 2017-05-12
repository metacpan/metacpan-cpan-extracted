package Egg::Helper::Model::Cache;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Cache.pm 293 2008-02-28 11:00:55Z lushe $
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
	   ($param, $self->project_name, qw/ Model Cache /, $comp_name);
	my $comp_path= $param->{module_output_filepath}=
	   "$param->{output_path}/lib/$param->{module_filepath}";
	-e $comp_path
	   and return $self->_helper_help("'$comp_path' already exists.");
	$self->helper_generate_files(
	  param        => $param,
	  chdir        => [$param->{output_path}],
	  create_files => [$self->helper_yaml_load(join '', <DATA>)],
	  errors       => { unlink=> [$comp_path] },
	  complete_msg => "\nCache controller generate is completed.\n\n"
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
${msg}% perl ${pname}_helper.pl M::Cache

END_HELP
	0;
}

1;

=head1 NAME

Egg::Helper::Model::Cache - Helper to generate CACHE controller. 

=head1 SYNOPSIS

  % cd /path/to/MyApp/bin
  % ./myapp_helper.pl M::Cache
  ..........
  ......

=head1 DESCRIPTION

It is a helper who generates the controller to use it with L<Egg::Model::Cache>
 under the control of the project.

It starts specifying the Model::Cache mode for the helper script of the project
to use it. 

  % ./myapp_helper.pl Model::Cache

Especially, there is no option needing.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Cache>,
L<Egg::Model::Cache::Base>,

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
  use base qw/ Egg::Model::Cache::Base /;
  
  our $VERSION= '<e.module_version>';
  
  __PACKAGE__->config(
  #  label_name  => 'cache_name',
    cache_root => <e.project_name>->path_to('cache'),
    namespace  => 'ModelCache',
    );
  
  __PACKAGE__->setup_cache('Cache::FileCache');
  
  1;
  
  __END__
  <e.document>
