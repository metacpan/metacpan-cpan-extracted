package # hide from PAUSE
	Hopkins::Plugin::HMI::Catalyst::View::TT;
BEGIN {
  $Hopkins::Plugin::HMI::Catalyst::View::TT::VERSION = '0.900';
}

use strict;
use warnings;

=head1 NAME

Hopkins::Plugin::HMI::Catalyst::View::TT - Catalyst TT View

=cut

use base 'Catalyst::View::TT';

use JSON;

__PACKAGE__->config({
	PRE_PROCESS			=> 'bootstrap.tt',
	WRAPPER				=> 'wrapper.tt',
	TEMPLATE_EXTENSION	=> '.tt',
	TIMER				=> 0,
	static_root			=> '/static',
	static_build		=> 0
});

$Template::Stash::SCALAR_OPS->{printf} = sub { sprintf $_[1], $_[0] };

$Template::Stash::LIST_OPS->{to_json} = sub { return to_json(shift, { allow_barekey => 1, allow_singlequote => 1} ) };

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
