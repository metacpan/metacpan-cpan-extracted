package Egg::Helper::Model::DBI;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: DBI.pm 258 2008-02-15 13:53:28Z lushe $
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
	my $attr= {
	  dsn      => ($o->{dsn}      || 'dbi:SQLite:dbname=dbfile'),
	  user     => ($o->{user}     || ''),
	  password => ($o->{password} || ''),
	  };
	$attr->{dsn}.= ";host=$o->{host}" if $o->{host};
	$attr->{dsn}.= ";port=$o->{inet_port}" if $o->{inet_port};
	my $param= $self->helper_prepare_param({
	  module_version=> $version, dbi=> $attr,
	  created=> __PACKAGE__. " v$VERSION",
	  });
	$self->helper_prepare_param_module
	   ($param, $self->project_name, qw/ Model DBI /, $comp_name);
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
sub _helper_get_options {
	shift->next::method
	(' d-dsn= u-user= p-password= s-host= i-inet_port= v-version= ');
}
sub _helper_help {
	my $self = shift;
	my $msg  = shift || "";
	my $pname= lc $self->project_name;
	$msg= "ERROR: ${msg}\n\n" if $msg;
	print <<END_HELP;
${msg}% perl ${pname}_helper.pl M::DBI [COMPONENT_NAME] [OPTIONS]

OPTIONS:  -d ... DNS.
          -s ... DB_HOST.
          -i ... DB_PORT.
          -u ... DB_USER.
          -p ... DB_PASSWORD.
          -v ... Module version.

END_HELP
	0;
}

1;

=head1 NAME

Egg::Helper::Model::DBI - Helper who generates component of model DBI.

=head1 SYNOPSIS

  % cd /path/to/MyApp/bin
  % ./myapp_helper.pl M::DBI MyDBI -d dbi:SQLite:dbname=dbfile
  ..........
  ......

=head1 DESCRIPTION

It is a helper who generates the component to use it with L<Egg::Model::DBI>
under the control of the project.

It starts specifying the L<Model::DBI> mode and the generated module name for
the helper script of the project to use it.

  % ./myapp_helper.pl Model::DBI [COMPONENT]

The setting of L<DBI> can be buried in passing the following options to the
helper script.

  -d ... DNS.
  -s ... Host of data base.
  -i ... The Internet port of data base.
  -u ... User of data base.
  -p ... Password of data base.
  -v ... Version of generated component.

When all the options are specified, it becomes the following feeling.

  % ./myapp_helper.pl Model::DBI MyComp \
  % -d dbi:Pg:dbname=dbfile \
  % -s localhost \
  % -i 5432 \
  % -u db_user \
  % -p db_password \
  % -v 0.01

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::DBI>,

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
  use base qw/ Egg::Model::DBI::Base /;
  
  our $VERSION = '<e.module_version>';
  
  # $ENV{DBI_TRACE}= 3;
  
  __PACKAGE__->config(
  
    # label_name => 'my_label',
  
    default  => 0,
    dsn      => '<e.dbi.dsn>',
    user     => '<e.dbi.user>',
    password => '<e.dbi.password>',
    options  => {
      AutoCommit => 1,
      RaiseError => 1,
      PrintError => 0,
      },
  
    );
  
  1;
  
  __END__
  <e.document>

