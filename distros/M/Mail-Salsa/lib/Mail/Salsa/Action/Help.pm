#
# Mail/Salsa/Action/Help.pm
# Last Modification: Fri Jun 18 14:37:04 WEST 2004
#
# Copyright (c) 2004 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
package Mail::Salsa::Action::Help;

use 5.008000;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use Mail::Salsa::Logs qw(logs);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mail::Salsa ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.01';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {@_};
	bless ($self, $class);
	$self->process_msg();
	return($self);
}

sub process_msg {
	my $self = shift;

	my ($name, $domain) = split(/\@/, $self->{'list'});
	Mail::Salsa::Utils::tplsendmail(
		smtp_server => $self->{'smtp_server'},
		timeout     => $self->{'timeout'},
		label       => "HELP_MESSAGE",
		lang        => $self->{'config'}->{'language'},
		vars        => {
				from   => "$name\-master\@$domain",
				to     => $self->{'from'},
				name   => $name,
				domain => $domain,
		}
	);
	return();
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::Salsa::Action::Help - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Mail::Salsa::Action::Help;

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

Copyright (C) 2004 by Henrique M. Ribeiro Dias

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
