package MySchemaRS::User;
use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub is_name_available {
	my ($self, $name, $row_id) = @_;

	my $user = $self->find( {name => $name} );
	return 0 if $user && $row_id && $user->id != $row_id; # found user with same name, and not user on stash

	## do extra special-case testing
# 	my $name_reserved = $self->result_source->schema->resultset('NameReserved')->find( {name => $name} );
# 	return 0 if $name_reserved;

	return 0 if $name eq 'xxx';

	return 1;
}


1;

