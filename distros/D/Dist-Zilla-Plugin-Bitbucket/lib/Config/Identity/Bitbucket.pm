#
# This file is part of Dist-Zilla-Plugin-Bitbucket
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Config::Identity::Bitbucket;
$Config::Identity::Bitbucket::VERSION = '0.001';
our $AUTHORITY = 'cpan:APOCAL';

# ROKR++ I copied this from Config::Identity::GitHub
use Config::Identity 0.0018;
use Carp qw( croak );

our $STUB = 'bitbucket';
sub STUB { defined $_ and return $_ for $ENV{CI_BITBUCKET_STUB}, $STUB }

sub load {
	my $self = shift;
	return Config::Identity->try_best( $self->STUB );
}

sub check {
	my $self = shift;
	my %identity = @_;
	my @missing;
	defined $identity{$_} && length $identity{$_} or push @missing, $_ for qw/ login password /;
	croak( "Missing ", join ' and ', @missing ) if @missing;
}

sub load_check {
	my $self = shift;
	my %identity = $self->load;
	$self->check( %identity );
	return %identity;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse

=for Pod::Coverage STUB check load load_check

=head1 NAME

Config::Identity::Bitbucket

=head1 VERSION

  This document describes v0.001 of Config::Identity::Bitbucket - released November 03, 2014 as part of Dist-Zilla-Plugin-Bitbucket.

=head1 SYNOPSIS

	use Config::Identity::Bitbucket;
	my %identity = Config::Identity::Bitbucket->load;
	print "login: $identity{login} password: $identity{password}\n";

=head1 DESCRIPTION

This module is meant to be used as part of the L<Config::Identity> framework. Please refer to it for further details.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::Plugin::Bitbucket|Dist::Zilla::Plugin::Bitbucket>

=back

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
