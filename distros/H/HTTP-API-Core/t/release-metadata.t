use strict;
use warnings;
use Test::More;

my $makefile = do {
    open my $fh, '<', 'Makefile.PL' or die "cannot open Makefile.PL: $!";
    local $/;
    <$fh>;
};

like $makefile, qr/ABSTRACT_FROM\s*=>\s*'lib\/HTTP\/API\/Core\.pm'/, 'abstract comes from the main module';
like $makefile, qr/LICENSE\s*=>\s*'perl_5'/, 'distribution license is declared';
like $makefile, qr/MIN_PERL_VERSION\s*=>\s*'5\.020'/, 'minimum Perl version is declared';
like $makefile, qr{https://github\.com/kawamurashingo/HTTP-API-Core}, 'repository metadata is declared';

open my $manifest_fh, '<', 'MANIFEST' or die "cannot open MANIFEST: $!";
my %manifest = map { chomp; $_ => 1 } <$manifest_fh>;
ok $manifest{'docs/RELEASING.md'}, 'release guide ships in the distribution';

ok -f 'docs/COMPATIBILITY.md', 'compatibility policy is present';
ok -f 'docs/RELEASING.md', 'release checklist is present';

done_testing;
