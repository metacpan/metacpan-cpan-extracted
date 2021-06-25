package LINE::Notify::Simple::Response;

use strict;
use warnings;
use utf8;
use feature qw(say);
use parent qw(Class::Accessor);

__PACKAGE__->mk_accessors(qw(status message status_line rate_limit_headers));

sub is_success {

	my $self = shift;
	return $self->status == 200 ? 1 : 0;
}

sub header_field_names {

	my $self = shift;
	my @names;
	if (ref($self->rate_limit_headers) eq "HASH") {
		@names = keys %{$self->rate_limit_headers};
	}
	return @names;
}

1;
