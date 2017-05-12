package Egg::Dispatch::Fast;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Fast.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use base qw/ Egg::Dispatch /;

our $VERSION= '3.02';

sub dispatch {
	$_[0]->{Dispatch} ||= Egg::Dispatch::Fast::handler->new(@_);
}

package Egg::Dispatch::Fast::handler;
use strict;
use base qw/Egg::Dispatch::handler/;

__PACKAGE__->mk_accessors(qw/ mode_now _action_code /);

sub _initialize {
	my($self)= @_;
	$self->mode( $self->e->_get_mode || $self->e->snip->[0] || "" );
	$self->SUPER::_initialize;
}
sub _start {
	my($self)= @_;
	my $map= $self->e->dispatch_map;
	my($code, $mode, $label);
	if ($code= $map->{$self->mode}) {
		$mode= $self->mode_now($self->mode);
		$self->action([$mode]);
	} elsif ($code= $map->{$self->default_mode}) {
		$mode= $self->mode_now($self->default_mode);
		$self->action([$self->default_name]);
	} else {
		$code= sub {};
		$mode= $self->mode_now($self->default_mode);
		$self->action([$self->default_name]);
	}
	if (ref($code) eq 'HASH') {
		$self->label([ $code->{label} || $self->action->[0] ]);
		$self->page_title( $self->label->[0] );
		$self->_action_code( $code->{action} || sub {} );
	} else {
		$self->label([ $self->action->[0] ]);
		$self->page_title( $self->label->[0] );
		$self->_action_code( $code );
	}
}
sub _action {
	my($self)= @_;
	my $action= $self->_action_code
	   || return $self->e->finished('404 Not Found');
	$action->($self->e, $self);
	1;
}
sub _finish { 1 }

sub _example_code {
	my($self)= @_;
	my $a= { project_name=> $self->e->namespace };

	<<END_OF_EXAMPLE;
#
# Example of controller and dispatch.
#
package $a->{project_name}::Dispatch;
use strict;
use warnings;
use $a->{project_name}::Members;
use $a->{project_name}::BBS;

our $VERSION= '0.01';

$a->{project_name}-&gt;dispatch_map(

  # HASH can be used for the value.
  # Please define not HASH but CODE if you do not use the label.
  _default => {
    label  => 'index page.',
    action => sub {},
    },

  # If it is a setting only of the label, 'action' is omissible.
  # Empty CODE tries to be set in action when omitting it, and to use
  # 'help.tt' for the template.
  help => { label => 'help page.' },

  members        => &yen;&$a->{project_name}::Members::default,
  members_login  => &yen;&$a->{project_name}::Members::login,
  members_logout => &yen;&$a->{project_name}::Members::logout,

  bbs      => &yen;&$a->{project_name}::BBS::article_view,
  bbs_post => &yen;&$a->{project_name}::BBS::article_post,
  bbs_edit => &yen;&$a->{project_name}::BBS::article_edit,

  );

1;
END_OF_EXAMPLE
}

1;

__END__

=head1 NAME

Egg::Dispatch::Fast - Another dispatch class. 

=head1 SYNOPSIS

  package MyApp::Dispatch;
  use base qw/ Egg::Dispatch::Fast /;
  
  Egg->dispatch_map(
  
    _default => {
      label=> 'index page.',
      action => sub { ... },
      },
  
    # When only the label is set, an empty CODE reference is set to action.
    # And, hooo.tt was set in the template.
    hooo => { label => 'hooo page.' },
  
    hoge => {
      label => 'hoge page',
      action => sub { ... },
      },
  
    boo => sub { ... },
  
    );

=head1 DESCRIPTION

L<EggDispatch::Standard> it is a plugin to do more high-speed Dispatch.

As for 'dispatch_map', only a single hierarchy is treatable.

The regular expression etc. cannot be used for the key.

The value to the key should be CODE reference.

The argument passed for the CODE reference is L<Egg::Dispatch::Standard>.
It is similar.

=head1 METHODS

L<Egg::Dispatch> has been succeeded to.

=head2 dispatch

The Egg::Dispatch::Fast::handler object is returned.

  my $d= $e->dispatch;

=head1 HANDLER METHODS

=head2 mode_now

The action matched with 'dispatch_map' is returned as a mode.

* The value of 'default_mode' method is returned when failing in the match.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Dispatch>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

