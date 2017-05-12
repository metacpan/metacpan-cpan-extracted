use Test::More tests => 36;

use Debian::Copyright;

# replace by Test::File::Contents?
use Perl6::Slurp;
use Test::LongString; 
use Test::Deep;
use Test::Exception;

my $copyright = Debian::Copyright->new;
isa_ok($copyright, 'Debian::Copyright');
$copyright->read('t/data/copyright');
like($copyright->header, qr{\AFormat:\s}xms, 'Header stanza');
is($copyright->files->Length, 2, 'files length');
is($copyright->files->Keys(0), '*', 'key files(0)');
is($copyright->files->Values(0)->Files, '*', 'files(0)->Files');
is($copyright->files->Values(0)->Copyright, "\n 2010-2011, Nicholas Bamber <nicholas\@periapt.co.uk>", 'files(0)->Copyright');
is($copyright->files->Values(0)->License, 'Artistic or GPL-2+', 'files(0)->License');
is($copyright->files->Keys(1), 'lib/Debian/Copyright*', 'key files(1)');
is($copyright->files->Values(1)->Files, 'lib/Debian/Copyright*', 'files(1)->Files');
is($copyright->files->Values(1)->Copyright."\n", <<'EOF',

 2011, Nicholas Bamber <nicholas@periapt.co.uk>
 2009, Damyan Ivanov <dmn@debian.org> [Portions]
EOF
 'files(1)->Copyright');
is($copyright->files->Values(1)->License, 'GPL-2+', 'files(1)->License');
is($copyright->licenses->Length, 2, 'licenses length');
is($copyright->licenses->Keys(0), 'Artistic', 'key licenses(0)');
like($copyright->licenses->Values(0)->License, qr/\AArtistic\s+This\sprogram/xms, 'licenses(0)->Files');

my $contents = slurp 't/data/copyright';
my $data = undef;
$copyright->write(\$data);
is_string($data, $contents, "file contents");

my $copyright2 = Debian::Copyright->new;
isa_ok($copyright2, 'Debian::Copyright');
$copyright2->read(\$contents);
cmp_deeply($copyright, $copyright2, "file versus string");

$copyright->read('t/data/add1');
$copyright->write(\$data);
is($copyright->files->Length, 3, 'files length');
is($copyright->files->Keys(0), '*', 'key files(0)');
is($copyright->files->Values(0)->Files, '*', 'files(0)->Files');
is($copyright->files->Values(0)->Copyright, "\n 2010-2011, Nicholas Bamber <nicholas\@periapt.co.uk>", 'files(0)->Copyright');
is($copyright->files->Values(0)->License, 'Artistic or GPL-2+', 'files(0)->License');
is($copyright->files->Keys(1), 'lib/Debian/Copyright*', 'key files(1)');
is($copyright->files->Values(1)->Files, 'lib/Debian/Copyright*', 'files(1)->Files');
is($copyright->files->Values(1)->Copyright."\n", <<'EOF',

 2011, Nicholas Bamber <nicholas@periapt.co.uk>
 2009, Damyan Ivanov <dmn@debian.org> [Portions]
EOF
 'files(1)->Copyright');
is($copyright->files->Values(1)->License, 'GPL-2+', 'files(1)->License');
is($copyright->licenses->Length, 3, 'licenses length');
is($copyright->licenses->Keys(0), 'Artistic', 'key licenses(0)');
like($copyright->licenses->Values(0)->License, qr/\AArtistic\s+This\sprogram/xms, 'licenses(0)->Files');
is($copyright->files->Keys(2), 'test/*', 'key files(2)');
is($copyright->files->Values(2)->Files, 'test/*', 'files(2)->Files');
is($copyright->licenses->Keys(2), 'BSD', 'key licenses(2)');

my $copyright3 = Debian::Copyright->new;
isa_ok($copyright3, 'Debian::Copyright');
throws_ok { $copyright3->read('t/data/invalid') } qr/Invalid field given \(Blah\)/;

my $copyright4 = Debian::Copyright->new;
isa_ok($copyright4, 'Debian::Copyright');
throws_ok { $copyright4->read('t/data/invalid2') } qr/Got copyright stanza with unrecognised field/;


