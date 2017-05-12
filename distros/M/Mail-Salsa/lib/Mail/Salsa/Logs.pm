#
# Mail/Salsa/Logs.pm
# Last Modification: Wed Apr  6 16:13:12 WEST 2005
#
# Copyright (c) 2005 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
package Mail::Salsa::Logs;

use 5.008000;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use Mail::Salsa::Utils;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mail::Salsa::Logs ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(&logs &debug);

our $VERSION = '0.02';

sub logs {
	my $self = shift;
	my $string = shift;
	my $type = shift || "error";

	my ($name, $domain) = split(/\@/, $self->{'list'});
	my $dir = join("/", $self->{'logs_dir'}, $domain, $name);
	unless(-d $dir) {
		Mail::Salsa::Utils::make_dir_rec($dir, 0755);
		(-d $dir) or die("$!");
	}
	my $today = Mail::Salsa::Utils::string_date();
	$string .= "\n" unless($string =~ /\n+$/);
	if($string eq "error") {
		my $package = caller();
		$string = "$package $string";
	}
	my $file = join("/", $dir, "$type\.log");
	open(LOGS, ">>", $file) or die("$!");
	print LOGS "$today $string";
	close(LOGS);

	my $mode = 0600;
	chmod($mode, $file);

	return();
}

sub debug {
	my $self = shift;
	my $string = shift;

	$string .= "\n" unless($string =~ /\n+$/);
	open(DEBUG, ">>", "/tmp/salsa.debug") or die("$!");
	print DEBUG $string;
	close(DEBUG);

	return();
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::Salsa::Logs - Perl extension for debugging and logging the mailing
lists

=head1 SYNOPSIS

  use Mail::Salsa::Logs;

=head1 DESCRIPTION

Stub documentation for Mail::Salsa, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Henrique M. Ribeiro Dias, E<lt>hdias@aesbuc.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Henrique M. Ribeiro Dias

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
