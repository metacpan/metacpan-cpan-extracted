# vim: ts=4 sw=4
package LWP::Protocol::virtual;

use warnings;
use strict;

=head1 NAME

LWP::Protocol::virtual - Protocol to locate resources on groups of sites

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';
use LWP::Protocol;
use HTTP::Status qw( RC_BAD_REQUEST RC_FOUND       );
use Carp qw(confess);
use Data::Dumper;
use strict;

our (@ISA) = qw(LWP::Protocol);


=head1 SYNOPSIS

 #
## From shell, not perl.
cpan URI::virtual
echo 'CPAN http://cpan.mirror.com/pub/CPAN' > ~/.lwp_virt
GET virtual://CPAN/some/path/some-path-1.0.tgz > some-path-1.0.tgz
perl -MCPAN -e '
	my $CPAN = CPAN->new();
	CPAN::Config->load($CPAN);
	$CPAN::Config->{urllist} = [ qw(virtual://CPAN/) ];
	CPAN::Config->commit("MyConfig.pm");
'
## Move MyConfig to somewhere CPAN will find it.


=head1 FUNCTIONS

=head2 request

This processes a request, by calling $uri->resolve on the URI object
(which one would suspect is an instalnce of URI::virtual, and therefore
supports it) and returning a redirect to the uri returned.  Any URI
subclass which satisfies the conditions:

	$uri->can("resolve")->()->isa("URI")
	ref $uri->can("path") eq 'CODE'

will be acceptable.  How you would tell LWP to use this Protocol
for another scheme is anybody's guess.
	
see URI::virtual.

=cut

sub request {
	my ($self, $req, $res) = (shift,shift);
	$res = HTTP::Response->new(RC_FOUND);
	$res->header("Location" => $req->uri()->resolve());
	return $res;
};
1;

=head1 AUTHOR

Rich Paul, C<< <cpan@rich-paul.net> >>
Mail to this address bounces, but you'll think of something.
It's a poor man's Turing Test.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-lwp-protocol-virtual@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LWP-Protocol-virtual>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The guys who wrote LWP.  Nice job!

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rich Paul, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of LWP::Protocol::virtual
