package Egg::Helper::Config::YAML;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: YAML.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use base qw/ Egg::Plugin::File::Rotate /;

our $VERSION= '3.00';

sub _start_helper {
	my($self)= @_;
	my $o= $self->_helper_get_options;
	$o->{help} and return $self->_helper_help;

	my $project= $self->project_name;
	my $param= $self->helper_prepare_param;
	$param->{yaml_name}= lc($project). '.yaml';
	if (my $basepath= $o->{output_path}) {
		$param->{yaml_path}= "$basepath/$param->{yaml_name}";
	} else {
		$param->{yaml_path}= $self->path_to('etc', $param->{yaml_name});
	}
	$self->rotate($param->{yaml_path});
	my $template= $self->helper_yaml_load(join '', <DATA>);
	eval { $self->helper_create_file($template, $param) };
	if (my $err= $@) {
		$self->rotate($param->{yaml_path}, reverse=> 1 );
		$self->_helper_help($err);
	} else {
		print <<END_EXEC;

... completed.

  output-path: $param->{yaml_path}

>>> Please edit the 'Controller' as follows.

  package $project;
  use Egg qw/  ...... /;
  
  __PACKAGE__->egg_startup(\\'$param->{yaml_path}');
  
  1;

* Passing YAML is given by the SCALAR reference.

END_EXEC
	}
}
sub _helper_help {
	my $self = shift;
	my $msg  = shift || "";
	my $pname= lc $self->project_name;
	$msg= "ERROR: ${msg}\n\n" if $msg;
	print <<END_HELP;
${msg}% perl ${pname}_helper.pl Config::YAML [-o OUTPUT_PATH]

END_HELP
}

1;

=head1 NAME

Egg::Helper::Config::YAML - The configuration of the YAML format is output.

=head1 SYNOPSIS

  % cd /path/to/MyApp/bin
  % ./myapp_helper.pl Config::YAML
  ......
  ...
  % vi ./etc/myapp.yaml
  .......
  ....

And, the controller is edited.

  % cd /path/to/MyApp
  % vi ./lib/myapp.pm
  package MyApp;
  ........
  ....
  
  __PACKAGE__->egg_startup(\'/path/to/MyApp/etc/myapp.yaml');

=head1 DESCRIPTION

It is a helper who output the sample of the configuration of YAML format.

The file is output to 'etc' directory of the project.

To pass passing this file to 'egg_startup' by the SCALAR reference after it
outputs it, the controller is edited.

When the project is started by this, the configuration of the YAML form comes to
be read.

It is L<Egg::Plugin::ConfigLoader> in the plugin. Please do not forget to specify.

If the great this file already exists when outputting it, the file rotation is done.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Helper>,
L<Egg::Plugin::ConfigLoader>,
L<Egg::Plugin::File::Rotate>, 

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut



__DATA__
filename: <e.yaml_path>
value: |
  #
  # <e.project_name> project - <e.yaml_name>
  #
  # output date: <e.gmtime_string> GMT
  #
  # $Id: YAML.pm 337 2008-05-14 12:30:09Z lushe $
  #
  
  title: <e.project_name>
  root: <e.project_root>
  static_uri: /
  
  dir:
    lib: \<e.root>/lib
    htdocs: \<e.root>/htdocs
    etc: \<e.root>/etc
    cache: \<e.root>/cache
    tmp: \<e.root>/tmp
    template: \<e.root>/root
    comp: \<e.root>/comp
  
  # Character code for processing.
  #  character_in: euc
  #  disable_encode_query: 0
  
  # Template.
  #  template_default_name: index
  #  template_extension: .tt
  template_path:
    - \<e.dir.template>
    - \<e.dir.comp>
  
  # Default content type and language.
  #  charset_out: euc-jp
  #  content_type: text/html
  #  content_language: ja
  
  # Regular expression of Content-Type that doesn't send Content-Length.
  #  no_content_length_regex: (?:^text/|/(?:rss\+)?xml)
  
  # Upper bound of request directory hierarchy.
  #  max_snip_deep: 10
  
  # Accessor to stash. * Do not overwrite a regular method.
  #  accessor_names:
  #    - hoge
  
  # Cookie default setup.
  #  cookie_default:
  #    domain: mydomain
  #    path: /
  #    expires: 0
  #    secure: 0
  #    },
  
  # MODEL:
  #   -
  #     - DBI
  #     - dsn: dbi:SQLite;dbname=\<e.dir.etc>/data.db
  #       user: 
  #       password: 
  #       options:
  #         AutoCommit: 1
  #         RaiseError: 1
  
  # VIEW:
  #   -
  #     - Mason
  #     - comp_root:
  #        -
  #          - main
  #          - \<e.dir.template>
  #        -
  #          - private
  #          - \<e.dir.comp>
  #      data_dir: \<e.dir.tmp>
  #   -
  #     - HT
  #     - path:
  #        - \<e.dir.template>
  #        - \<e.dir.comp>
  #       global_vars: 1
  #       die_on_bad_params: 0
  #       cache: 1
  
  # request:
  #   DISABLE_UPLOADS: 0
  #   TEMP_DIR: \<e.dir.tmp>
  #   POST_MAX: 10240
  
  # * For ErrorDocument plugin.
  # plugin_error_document:
  #   view_name: Mason
  #   template: error/document.tt
  
  # * For FillInForm plugin.
  # plugin_fillinform:
  #   ignore_fields:
  #     - ticket
  #   fill_password: 0

