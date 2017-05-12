package Egg::Plugin::Session;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Session.pm 303 2008-03-05 07:47:05Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use Digest::SHA1 qw/ sha1_hex /;

our $VERSION= '0.02';

sub _setup {
	my($e)= @_;
	$e->is_model('session')
	    || die q{I want setup of 'Egg::Model::Session'.};
	$e->next::method;
}
sub session {
	my $e= shift;
	my $pkg= $e->project_name. '::Model::Session';
	return $e->{session_default}
	   ||= $e->model_manager->context($pkg->default) unless @_;
	my $name= shift || croak q{I want session label name.};
	my $label= $pkg->labels->{$name}            ? $name
	         : $pkg->labels->{"session::$name"} ? "session::$name"
	         : croak q{Session of the label of '$name' is not found.};
	$label eq $pkg->default
	  ? do { $e->{session_default}  ||= $e->model_manager->context($label) }
	  : do { $e->{"session_$label"} ||= $e->model_manager->context($label) };
}

1;

__END__

=head1 NAME

Egg::Plugin::Session - Plugin for session.

=head1 SYNOPSIS

  package MyApp
  use Egg qw/ Session /;

  # The session object of default is acquired.
  my $session= $e->session;
  
  # The object is acquired specifying the label of the session.
  my $session= $e->session('session_label');

=head1 DESCRIPTION

It is a plugin that conveniently makes L<Egg::Model::Session> available only a 
little.

=head1 METHODS

=head2 session ([LABEL_NAME])

The session object is returned.

The one that default with L<Egg::Model::Session> when LABEL_NAME is omitted and
has been treated is returned.

  my $s= $e->session;

When LABEL_NAME is specified, the object of correspondence is returned.

  my $s= $e->session('label_name');

If it is a label name that starts by 'session::', the first part can be omitted.

  # For instance, if it is 'Session::myname' ...
  my $s= $e->session('myname');

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

