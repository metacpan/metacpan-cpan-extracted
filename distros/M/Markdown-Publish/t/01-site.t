use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Cwd qw(getcwd);
use Markdown::Publish::MkDocs;

my $site_or=Markdown::Publish::MkDocs->new();
my $pages_hr=$site_or->split('guide.md', "# Z {#z}\n\n[Next](#a)\n\n~~~~\n# not a heading\n[Next](#a)\n~~~~\n\n# A {#a}\n\nEnd.\n");
is(scalar(keys %{$pages_hr}), 2, 'headings in fences do not split chapters');
is_deeply($site_or->{'page_order'}, ['guide--z.md', 'guide--a.md'], 'chapter order preserved');
like($pages_hr->{'guide--z.md'}, qr/\[Next\]\(guide--a.md\)/, 'cross-chapter link repaired');
like($pages_hr->{'guide--z.md'}, qr/\[Next\]\(#a\)/, 'code example not rewritten');
eval { $site_or->split('bad.md', "# One {#same}\n# Two {#same}\n") };
like($@, qr/duplicate/, 'ambiguous chapter IDs rejected');

my $cwd=getcwd();
my $dir=tempdir(CLEANUP => 1);
chdir($dir) or die $!;
make_path('doc');
open(my $doc_fh, '>', 'doc/guide.md') or die $!;
print {$doc_fh} "# Example\n\nHello.\n";
close($doc_fh);
my $config_fn=$site_or->prepare();
ok(-f $config_fn, 'configuration generated');

make_path('doc/mkdocs');
open(my $project_config_fh, '>', 'doc/mkdocs/mkdocs.yml') or die $!;
print {$project_config_fh} "site_name: Project preview\ntheme:\n  name: material\n";
close($project_config_fh) or die $!;
my $preview_config_fn=$site_or->prepare(1);
open(my $preview_config_fh, '<', $preview_config_fn) or die $!;
local $/;
my $preview_config=<$preview_config_fh>;
close($preview_config_fh) or die $!;
like($preview_config, qr/^INHERIT: .*doc\/mkdocs\/mkdocs\.yml/m,
    'preview inherits project MkDocs configuration');
like($preview_config, qr/^docs_dir: /m,
    'preview supplies its assembled Markdown directory');
like($preview_config, qr/^plugins:\n  - search$/m,
    'preview uses locally available search plugin');
SKIP: {
    skip 'set MKDOCS_TEST=1 to run external build and Git tests', 6 unless $ENV{'MKDOCS_TEST'};
    my $site_dn=$site_or->build();
    ok(-f "$site_dn/guide/index.html", 'real MkDocs HTML generated');
    ok(-f "$site_dn/index.html", 'site has a working home page');
    $site_or->command('git', 'init', '-b', 'main');
    $site_or->command('git', 'config', 'user.name', 'Test');
    $site_or->command('git', 'config', 'user.email', 'test@example.invalid');
    $site_or->command('git', 'add', 'doc');
    $site_or->command('git', 'commit', '-m', 'Initial');
    is($site_or->publish_gh(), 'gh-pages', 'local publication branch created');
    is($site_or->command('git', 'branch', '--show-current'), "main\n", 'current branch preserved');
    my $head=$site_or->command('git', 'rev-parse', 'gh-pages');
    $site_or->publish_gh();
    is($site_or->command('git', 'rev-parse', 'gh-pages'), $head, 'unchanged site produces no commit');
    like($site_or->command('git', 'ls-tree', '-r', '--name-only', 'gh-pages'), qr/\.nojekyll/, 'static-site marker published');
}
chdir($cwd) or die $!;
done_testing();
