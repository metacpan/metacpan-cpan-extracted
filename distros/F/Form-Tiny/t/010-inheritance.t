use v5.10;
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use ChildForm;

my $meta = ChildForm->form_meta;

is scalar @{$meta->fields}, 3, 'fields count ok';
is scalar keys %{$meta->hooks}, 2, 'hooks categories count ok';
is scalar @{$meta->hooks->{cleanup}}, 2, 'cleanup hooks count ok';
is scalar @{$meta->hooks->{before_mangle}}, 1, 'before_mangle hooks categories count ok';
is scalar @{$meta->filters}, 2, 'filters count ok';

done_testing();
