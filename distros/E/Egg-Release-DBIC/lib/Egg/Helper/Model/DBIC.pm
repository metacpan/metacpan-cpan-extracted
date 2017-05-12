package Egg::Helper::Model::DBIC;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: DBIC.pm 352 2008-07-14 13:26:41Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use DBIx::Class::Schema::Loader qw/ make_schema_at /;

our $VERSION= '3.00';

sub _start_helper {
	my($self)= @_;
	my $c= $self->config;
	my $project= $self->project_name;
	$c->{helper_option}{project_root} || return $self->_helper_help
	   ('I want you to start from helper of the project.');
	my $schema_name= ucfirst( shift( @ARGV ) )
	   || return $self->_helper_help('I want component name.');
	$schema_name=~m{^^[A-Z][A-Za-z0-9\_]+$}
	   || return $self->_helper_help("Bad schema name '$schema_name'");
	my $o= $self->_helper_get_options;
	my $version= $self->helper_valid_version_number($o->{version}) || return 0;
	$o->{dsn}
	   || return $self->_helper_help(q{ '-d' Please give DSN by the option. });
	$o->{user}     ||= "";
	$o->{password} ||= "";
	$o->{dsn}.= ";host=$o->{host}"      if $o->{host};
	$o->{dsn}.= ";port=$o->{inet_port}" if $o->{inet_port};
	my $param= $self->helper_prepare_param({
	  module_version=> $version, dbi=> $o,
	  created=> __PACKAGE__. " v$VERSION",
	  });
	$self->helper_prepare_param_module
	   ($param, $self->project_name, qw/ Model DBIC /, $schema_name);
	my $lib_path   = "$param->{output_path}/lib/$param->{module_basedir}";
	my $schema_path= "$param->{output_path}/lib/$param->{module_filepath}";
	unless (-e $lib_path) {
		$self->helper_create_dir($lib_path);
	}
	-e $schema_path
	   and return $self->_helper_help("'$schema_path' already exists.");

	my $origin_code= <<END_CODE;
use base qw/ Egg::Model::DBIC::Schema /;

__PACKAGE__->config(

#  label_name   => 'mylabel',
#  label_source => {
#    moniker => 'mymoniker',
#    },

  dsn      => '$o->{dsn}',
  user     => '$o->{user}',
  password => '$o->{password}',
  options  => {
    AutoCommit => 1,
    RaiseError => 1,
    PrintError => 0,
    },

  );
END_CODE

	$self->helper_chdir($c->{root}) || return
	   $self->_helper_help('The root directory of the project cannot be changed.');
	eval {
		make_schema_at("${project}::Model::DBIC::$schema_name", {
		    debug => ($o->{debug} || 0),
		    relationships  => 1,
		    dump_directory => './lib',
		    },
		  [@{$o}{qw/ dsn user password /}],
		  );
		my $value= $self->helper_fread($schema_path);
		$value=~s{\n+(use\s+base\s+[^\;]+\;)\s*} [\n# $1\n\n${origin_code}\n]s;
		$self->helper_save_file( $schema_path => \$value );
	  };
	if (my $err= $@) {
		$self->helper_remove_file($schema_path);
		$schema_path=~s{\.pm$} [];
		$self->helper_remove_dir($schema_path);
		$self->_helper_help($err);
	} else {
		print <<END_INFO;
... done.

output of Schema: $schema_path

END_INFO
	}
}
sub _helper_get_options {
	$_[0]->next::method
	('d-dsn= u-user= p-password= s-host= i-inet_port=');
}
sub _helper_help {
	my $self= shift;
	my $msg = shift || "";
	$msg= "\nERROR: ${msg}\n\n" if $msg;
	print <<END_HELP;
${msg}% perl egg_helper.pl Model::DBIC [SCHEMA_NAME] [OPTIONS]

OPTIONS:  -d ... DSN.
          -u ... DB_USER.
          -p ... DB_PASSWORD.
          -s ... DB_HOST.
          -i ... DB_PORT.

Usage:
% perl @{[ lc $self->project_name ]}\_helper.pl Model:DBIC MySchema \\
>  -d dbi:Pg:dbname=mydb  \\
>  -u dbuser              \\
>  -p dbpassword

END_HELP
}

1;

__END__

=head1 NAME

Egg::Helper::Model::DBIC - Helper for Egg::Model::DBIC. 

=head1 SYNOPSIS

  % cd /path/to/MyApp/bin
  % ./myapp_helper.pl M::DBIC MySchema -d dbi:SQLite:dbname=dbfile
  ..........
  ......

=head1 DESCRIPTION

It is a helper who generates the control module of L<Egg::Model::DBIC> under the
 control of the project.

It starts specifying the 'Model::DBIC' mode and the generated module name for 
the helper script of the project to use it.

  % ./myapp_helper.pl Model::DBIC [SCHEMA_NAME]

The setting of DBI can be buried in passing the following options to the helper 
script.

  -d ... DNS.
  -s ... Host of data base.
  -i ... The Internet port of data base.
  -u ... User of data base.
  -p ... Password of data base.
  -v ... Version of generated component.

When all the options are specified, it becomes the following feeling.

  % ./myapp_helper.pl Model::DBIC MySchema \
  % -d dbi:Pg:dbname=dbfile \
  % -s localhost \
  % -i 5432 \
  % -u db_user \
  % -p db_password \
  % -v 0.01

=head1 CONFIGURATION

The configuration can be set as a controller who generates it.

  package MyApp::Model::DBIC::MySchema;
  use base ........
  .....
  
  __PACKAGE__->config(
    .......
    );

=head2 label_name

Label name when accessing it by 'model' method of project. 

It is 'dbic::myschema' revokable.

  __PACKAGE__->config(
    label_name => 'hoge',
    );
  
  my $schema= $e->model('hoge');

Please note that there are neither a label name of other models nor a collision
when setting it.

=head2 label_source

The label to access the source that belongs to Schema can be set with HASH.

It is 'dbic::myschema::moniker' revokable.

  __PACKAGE__->config(
    label_source => {
      hogehoge => 'MyMoniker',
      .....
      },
    );
  
  my $hoge= $e->model('hogehoge');

=head2 dsn

DSN

=head2 user

User of data base.

=head2 password

Password of data base.

=head2 options

Option to pass to DBI.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::DBIC>,
L<DBIx::Class::Schema::Loader>,
L<UNIVERSAL::require>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

