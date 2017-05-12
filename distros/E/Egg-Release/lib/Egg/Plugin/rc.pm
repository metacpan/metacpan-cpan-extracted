package Egg::Plugin::rc;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: rc.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use YAML;

our $VERSION = '3.00';

sub load_rc {
	my($e, $dir)= @_;
	my $rc_name= $ENV{EGG_RC_NAME} || 'egg_releaserc';
	my($rc_file, $conf);
	if ($rc_file= $dir and -e "$rc_file/.$rc_name") {
		$rc_file.= "/.$rc_name";
	} elsif ($conf= $e->config
	       and $rc_file= $conf->{root} and -e "$rc_file/.$rc_name") {
		$rc_file.= "/.$rc_name";
	} elsif (-e "~/.$rc_name") {
		$rc_file = "~/.$rc_name";
	} elsif (-e "/etc/$rc_name") {
		$rc_file = "/etc/$rc_name";
	} else {
		return 0;
	}
	YAML::LoadFile($rc_file) || 0;
}

1;

__END__

=head1 NAME

Egg::Plugin::rc - Loading the resource code file for Egg is supported. 

=head1 SYNOPSIS

  use Egg qw/ rc /;
  
  my $rc= $e->load_rc;

=head1 DESCRIPTION

This plugin supports loading the resource code file for Egg.

Please prepare the resource code file in the following places.

  ./.egg_releaserc
  /project_root/.egg_releaserc
  ~/.egg_releaserc
  /etc/egg_releaserc

* The content of the resource code file is a thing that is the YAML form for HASH.

If file name is changed, environment variable EGG_RC_NAME is set.
Default is egg_releaserc.

It tries to read the EGG_RC_NAME name like the miso when it evaluates under the
control of '/etc'.  EGG_RC_NAME that puts '.' on the head is read usually.

The key used with L<Egg::Helper> is as follows.

=over 4

=item * author     ..... Writer's data.

=item * copywright ..... Mark of copyright.

=item * headcopy   ..... It inserts it in the header of the generation module.

=item * license    ..... License form. Perl and GPL, etc.

=back

=head1 METHODS

=head2 load_rc ([ATTR_HASH])

If the rc file is found, YAML::LoadFile. Goes and returns the result.

PATH can be set in 'current_dir' of ATTR_HASH and the rc file of an arbitrary
place be read.

  my $rc= $e->load_rc('/path/to');

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
