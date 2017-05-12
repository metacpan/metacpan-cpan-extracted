package Egg::Model::DBI::Base;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Base.pm 302 2008-03-05 07:45:10Z lushe $
#
use strict;
use warnings;
use base qw/ Egg::Model /;
use Egg::Model::DBI::dbh;

our $VERSION= '0.02';

sub dbi {
	$_[0]->{dbi} ||= do {
		my $e= $_[0]->e || return 0;
		$e->model('dbi');
	  };
}
sub dbh {
	my($self)= @_;
	my $dbh;
	if (my $handlers= $self->dbi->handlers) {
		if ($dbh= $handlers->{$self->label_name}) {
			$dbh= $self->connect unless $dbh->_connected;
		}
	}
	$dbh || $self->connect;
}
sub connect {
	my($self)= @_;
	my $dbh;
	eval{ $dbh= $self->connect_db };
	$@ and die "Database Connect NG!! '@{[ $self->label_name ]}' at $@";
	my $handlers= $self->dbi->handlers || $self->dbi->handlers({});
	$handlers->{$self->label_name}= Egg::Model::DBI::dbh->_new($dbh);
}
sub disconnect {
	my($self)= @_;
	my $dbi= $self->dbi || return 0;
	my $handlers= $dbi->handlers || return 0;
	my $dbh= $handlers->{$self->label_name} || return 0;
	$dbh->_disconnect || return 0;
	delete $handlers->{$self->label_name};
	$self;
}
sub DESTROY {
	shift->disconnect;
}

1;

__END__

=head1 NAME

Egg::Model::DBI::Base - Base class for DBI model component. 

=head1 DESCRIPTION

It is a base class to use it from the component of L<Egg::Model::DBI>.

The object of this module is only the one internally used when
$e-E<gt>model([LABEL_NAME]) is called.
It is not necessary to consider it because of the application usually.

=head1 METHODS

=head2 dbi

The L<Egg::Model::DBI> object is returned.

=head2 dbh

The data base handler is returned.

The connection still calls the connect method.

=head2 connect

It connects with the data base and L<Egg::Model::dbh>. The object is returned.

=head2 disconnect

The database connectivility is cut.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model>,
L<Egg::Model::DBI>,
L<Egg::Model::DBI::dbh>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

