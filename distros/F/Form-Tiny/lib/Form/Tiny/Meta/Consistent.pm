package Form::Tiny::Meta::Consistent;

use v5.10;
use strict;
use warnings;

use Moo::Role;

our $VERSION = '2.03';

requires 'consistent_api';

around consistent_api => sub {
	return 1;
};

1;
