use Test::More;
use strict; use warnings FATAL => 'all';
no warnings 'once';

require List::Objects::WithUtils;
$List::Objects::WithUtils::ImportMap{foo} = 'No::Such::Class';

my $warning;
$SIG{__WARN__} = sub { $warning = $_[0] };
eval {; List::Objects::WithUtils->import('foo') };
like $@, qr/Failed to import/, 'bad class failed to import';
like $warning, qr/INC/, 'failed import warned';

done_testing;
