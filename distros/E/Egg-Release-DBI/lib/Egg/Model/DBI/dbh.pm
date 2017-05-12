package Egg::Model::DBI::dbh;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: dbh.pm 233 2008-01-31 09:46:42Z lushe $
#
use strict;
use warnings;
use base qw/ Class::Accessor::Fast /;

our $VERSION= '0.01';
our $AUTOLOAD;

__PACKAGE__->mk_accessors(qw/ dbh pid tid /);

sub _new {
	my($class, $dbh)= @_;
	bless {
	  dbh=> $dbh, pid=> $$,
	  tid=> ($INC{'threads.pm'} ? threads->tid: 0),
	  AutoCommit=> $dbh->{AutoCommit},
	  }, $class;
}
sub _connected {
	my($self)= @_;
	return 0 if ($self->tid and $self->tid ne threads->tid);
	my $dbh= $self->dbh || die q{Data base handler is empty.};
	return CORE::do { $dbh->{InactiveDestroy}= 1; 0 } if $self->pid ne $$;
	_connected_active($dbh);
}
sub _disconnect {
	my $dbh= $_[0]->dbh || return 0;
	_connected_active($dbh) || return 0;
	eval{ $dbh->rollback unless $dbh->{AutoCommit} };
	$@ and warn $@;
	$dbh->disconnect;
	1;
}
sub _connected_active {
	($_[0] and $_[0]->{Active} and $_[0]->ping) ? 1: 0;
}
sub AUTOLOAD {
	my $self= shift;
	my($method)= $AUTOLOAD=~/([^\:]+)$/;
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{__PACKAGE__."::$method"}=
	(($method eq 'commit' or $method eq 'rollback') and $self->{AutoCommit})
	   ? sub { 1 } : sub { shift->dbh->$method(@_) };
	$self->$method(@_);
}
sub DESTROY {}

1;

__END__

=head1 NAME

Egg::Model::DBI::dbh - Data base handler. 

=head1 DESCRIPTION

It is a data base handler that L<Egg::Model::DBI> returns.

  my $dbh= $e->model('dbi::data_label');

This module operates as Wrapper of the DBI module.

=head1 METHODS

Please refer to the document of the DBI module for the method that can be used.

=head2 dbh

An original data base handler of DBI or Ima::DBI is returned.

Especially, it is necessary to refer to the original because the attribute of an
original data base handler doesn't have the object of this module.

  if ($dbh->dbh->{Active}) {
     .......
  }

=head2 pid

Process ID under operation is returned.

  my $process_id = $dbh->pid;

=head2 tid

When operating by the thread, the thread ID is returned.

  my $thread_id = $dbh->tid;

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model>,
L<Egg::Model::DBI>,
L<Egg::Model::DBI::Base>,
L<Class::Accessor::Fast>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

