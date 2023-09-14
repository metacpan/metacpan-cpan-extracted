use strict;
use warnings;

use Test2::V0;

use Test::DZil;

my $tzil = Builder->from_config( { dist_root => "t/corpus" },);

$tzil->build;

is grep( { $_->name =~ /\.pod/ } @{ $tzil->files } ), 1, 'pod files with associated pm files are removed';

my ($foo) = grep { $_->name =~ /Foo/ } @{ $tzil->files };

like $foo->content, qr/^=head1 DESCRIPTION/m, 'pod added to pm file';

my ($data) = grep { $_->name =~ /Data/ } @{ $tzil->files };

like $data->content, qr/=head1 DESCRIPTION.*__DATA__/s, 'pod before __DATA__';

like $data->content, qr/__DATA__\nthis/s, 'no added CRs after __DATA__';

done_testing();
