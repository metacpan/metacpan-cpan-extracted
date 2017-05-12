package Egg::Dispatch;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Dispatch.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;

our $VERSION= '3.00';

sub import {
	my($class)= @_;
	my($project)= $class=~m{^([^\:]+)};
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{"${class}::code"}= sub {
		shift if ref($_[0]);
		my $pkg= shift || croak q{ I want include package name. };
		   $pkg= "${project}::$pkg";
		my $method= shift || croak q{ I want method name. };
		$pkg->require or die $@;
		$pkg->can($method) || croak qq{ '$method' method is not found. };
	  };
	*{"${class}::mode_param"}= sub {
		my $proto= shift;  return 0 if ref($proto);
		my $pname= shift || croak(q{ I want param name. });
		my $name_uc= uc $project;
		*{"${proto}::_get_mode"}= sub {
			$ENV{"${name_uc}_REQUEST_PARTS"}
			  || $_[0]->request->param($pname)
			  || return (undef);
		  };
	  };
	$class;
}

sub dispatch_map {
	my $e= shift;
	return $e->_dispatch_map unless @_;
	my $hash= $_[0] ? ($_[1] ? {@_}: $_[0]): return 0;
	$e->_dispatch_map( $e->_dispatch_map_check($hash, (ref($e) || $e)) );
}
*run_modes= \&dispatch_map;

sub _dispatch_map_check { $_[1] || {} }
sub _get_mode           { 0 }

package Egg::Dispatch::handler;
use strict;
use warnings;
use base qw/ Egg::Base /;

__PACKAGE__->mk_accessors(qw/ mode label default_mode default_name /);

sub new        { shift->SUPER::new(@_)->_initialize }
sub action     { shift->e->action(@_) }
sub stash      { $_[0]->e->stash }
sub config     { $_[0]->e->config }
sub page_title { shift->e->page_title(@_) }

sub target_action {
	my($self)= @_;
	my $action= $self->action || return "";
	@$action ? '/'. join('/', @$action): "";
}
sub _initialize {
	my($self)= @_;
	my $cf= $self->e->config;
	$self->{label} = [];
	$self->{action}= [];
	$self->{page_title}= "";
	$self->{default_name}= $cf->{template_default_name} || 'index';
	$self->{default_mode}= $cf->{deispath_default_name} || '_default';
	$self;
}
sub _example_code { 'none.' }

1;

__END__

=head1 NAME

Egg::Dispatch - Base class for dispatch.

=head1 DESCRIPTION

It is a base class for dispatch.

To do the function as Dispatch, necessary minimum method is offered.

L<Egg::Dispatch::Standard>, L<Egg::Dispatch::Fast>,

=head1 METHODS

=head2 dispatch_map ([DISPATCH_HASH])

The setting of dispatch is returned.

When DISPATCH_HASH is given, it is set as dispatch.

  Egg->dispatch_map (
    _default => sub {},
    hoge     => sub { ... },
    );

=over 4

=item * Alias = run_modes 

=back

=head1 HANDLER METHODS

L<Egg::Base> has been succeeded to.

=head2 new

Constructor.

=head2 action

$e-E<gt>action is returned.

=head2 stash

$e-E<gt>stash is returned.

=head2 config

$e-E<gt>config is returned.

=head2 page_title

$e-E<gt>page_title is returned.

=head2 target_action

The URI passing to decided action is assembled and it returns it.

=head2 mode

Accessor to treat mode.

=head2 label

Accessor to treat label.

=head2 default_mode

The mode of default is returned.

It is revokable in 'deispath_default_name' of the configuration.
Default is '_default'.

=head2 default_name

The template name of default is returned.

It is revokable in 'template_default_name' of the configuration.
Default is 'index'.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Base>,
L<Egg::Dispatch::Standard>,
L<Egg::Dispatch::Fast>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

