package FIDO::Raw;
$FIDO::Raw::VERSION = '0.06';
use strict;
use warnings;
use Carp;

require XSLoader;
XSLoader::load ('FIDO::Raw', $FIDO::Raw::VERSION);

use FIDO::Raw::Assert;
use FIDO::Raw::Cred;
use FIDO::Raw::PublicKey::ES256;
use FIDO::Raw::PublicKey::RS256;
use FIDO::Raw::PublicKey::EDDSA;

sub AUTOLOAD
{
	# This AUTOLOAD is used to 'autoload' constants from the constant()
	# XS function.

	my $constname;
	our $AUTOLOAD;
	($constname = $AUTOLOAD) =~ s/.*:://;
	croak "&FIDO::Raw::_constant not defined" if $constname eq '_constant';
	my ($error, $val) = _constant ($constname);
	if ($error) { croak $error; }
	{
	no strict 'refs';
	*$AUTOLOAD = sub { $val };
	}
	goto &$AUTOLOAD;
}

1;

__END__

=for HTML
<a href="https://dev.azure.com/jacquesgermishuys/p5-FIDO-Raw/_build">
	<img src="https://dev.azure.com/jacquesgermishuys/p5-FIDO-Raw/_apis/build/status/jacquesg.p5-FIDO-Raw?branchName=master" alt="Build Status: Azure Pipeline" align="right" />
</a>
<a href="https://coveralls.io/r/jacquesg/p5-FIDO-Raw">
	<img src="https://coveralls.io/repos/github/jacquesg/p5-FIDO-Raw/badge.svg?branch=master" alt="coveralls" align="right" />
</a>
=cut

=head1 NAME

FIDO::Raw - Perl bindings to the libfido2 library

=head1 VERSION

version 0.06

=head1 DESCRIPTION

Provides library functionality for FIDO 2.0

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
