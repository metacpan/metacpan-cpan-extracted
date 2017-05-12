package Fry::Obj;
use strict;
use base 'Fry::List';
use base 'Fry::Base';

my $list = {};
sub list { return $list }
sub defaultNew { shift->manyNewScalar('obj',@_)}

1;
__END__
	sub idToObj {
		my ($cls,@idOrObj) = @_;
		my @return;
		if (ref $idOrObj[0]) {
			@return = @idOrObj;
		}
		else { @return = map { $cls->obj->get($_,'obj') } @idOrObj }
		wantarray ? @return : $return[0];
	}
