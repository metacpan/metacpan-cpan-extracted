package Egg::Plugin::YAML;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: YAML.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use YAML;

our $VERSION= '3.00';

sub yaml_load {
	my $e   = shift;
	my $yaml= shift || return 0;
	$yaml=~/[\r\n]/ ? YAML::Load($yaml): YAML::LoadFile($yaml);
}
sub yaml_dump {
	shift;
	YAML::Dump(@_);
}

1;

__END__

=head1 NAME

Egg::Plugin::YAML - Plugin to treat data of YAML format. 

=head1 SYNOPSIS

  use Egg qw/ YAML /;
  
  my $data= $e->yaml_load($yaml_text);
  
  print $e->yaml_dump($data);

=head1 METHODS

=head2 yaml_load([YAML_DATA] or [YAML_FILE_PATH])

The data of the YAML form is made former data and it returns it.

When the character string that doesn't contain changing line is passed, it is
treated as passing to the YAML file.

  my $data= $e->yaml_load('/path/to/load_file.yaml');

=head2 yaml_dump ([DATA])

DATA is converted into the text of the YAML form and it returns it.

  my $yaml= $e->yaml_dump($data);

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::YAML>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
