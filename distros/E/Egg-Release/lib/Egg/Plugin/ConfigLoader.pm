package Egg::Plugin::ConfigLoader;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: ConfigLoader.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION = '3.00';

sub _load_config {
	my $class= shift;
	my $conf = $_[0] ? ($_[1] ? {@_}: $_[0]): 0;
	if ($conf and ref($conf) eq 'SCALAR') {
		my $path= $$conf;
		   $path=~s{/+$} [];
		my $name_lc= $class->lc_namespace;
		my $yaml= $path=~m{\.ya?ml$}i       ? $path
		   : -e "$path/etc/${name_lc}.yaml" ? "$path/etc/${name_lc}.yaml"
		   : -e "$path/etc/${name_lc}.yml"  ? "$path/etc/${name_lc}.yml"
		   : -e "$path/${name_lc}.yaml"     ? "$path/${name_lc}.yaml"
		   : -e "$path/${name_lc}.yml"      ? "$path/${name_lc}.yml"
		   : die q{ Configuration is not found. };
		require YAML;
		$conf= YAML::LoadFile($yaml);
		$conf->{root} ||= $path unless $path=~m{\.yaml$};
	} elsif (! $conf) {
		$class= ref($class) if ref($class);
		"${class}::config"->require or die $@;
		$conf= "${class}::config"->out;
	}
	$class->_check_config($conf);
	$class->egg_var_deep($conf, $conf->{dir});
	$class->egg_var_deep($conf, $conf);
	$conf;
}

1;

__END__

=head1 NAME

Egg::Plugin::ConfigLoader - An external configuration for Egg is loaded.

=head1 SYNOPSIS

  use Egg qw/ ConfigLoader /;

=head1 DESCRIPTION

When this plugin is used, it comes to take the configuration from the outside
though L<Egg> treats it as a configuration when HASH is passed to the method
of '_startup'.

This plugin comes to be loaded beforehand in the default of Egg and config.pm
in the library of the project is taken as a configuration. In this case,
the argument is not given to the method of '_startup'.

If it wants to do the configuration by the YAML format, passing to the YAML file
is passed to '_startup' by the SCALAR reference.

  # Controller - /path/to/MyApp/lib/MyApp.pm
  
  __PACKAGE__->_startup(\"/path/to/MyApp/etc/MyApp.yaml");

[project_name_lc].yaml or [project_name_lc].yml ties and it looks for the file
without the file name in passing.

  # It looks for myapp.yaml or myapp.yml
  
  __PACKAGE__->_startup(\"/path/to/MyApp/etc");

Please make the configuration of the YAML format beforehand.

  % cd /path/to/MyApp
  
  % vi myapp.yaml
  or
  % vi etc/myapp.yaml
  
  title: MyApp
  root:  /path/to/MyApp
  dir:
     ..........
     ....

=head1 SEE ALSO

L<Egg::Release>,
L<YAML>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
