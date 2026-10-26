use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Archive::Tar;

use Dist::Zilla::Plugin::Docker::API::Client;

# Below the seam: the build context handed to the engine must keep what
# Dist::Zilla wrote into the build root -- modes, symlinks, dotfiles and
# empty directories. Calls _create_tar directly.

my $ctx = Path::Tiny->tempdir;
$ctx->child('Dockerfile')->spew("FROM scratch\n");
$ctx->child('bin')->mkpath;
my $exe = $ctx->child('bin', 'entry.sh');
$exe->spew("#!/bin/sh\necho hi\n");
chmod 0755, "$exe";
$ctx->child('.dockerignore')->spew("x\n");
$ctx->child('empty')->mkpath;
symlink 'bin/entry.sh', $ctx->child('link.sh')->stringify or die "symlink: $!";
symlink 'does/not/exist', $ctx->child('dangling')->stringify or die "symlink: $!";

my $client = Dist::Zilla::Plugin::Docker::API::Client->new(
    logger       => sub {},
    logger_fatal => sub { die @_ },
);

my $tarref = $client->_create_tar("$ctx");
open my $fh, '<', $tarref or die $!;
my $tar = Archive::Tar->new($fh);
my %entry = map { my $n = $_->full_path; $n =~ s{/\z}{}; ($n => $_) } $tar->get_files;

ok $entry{'Dockerfile'}, 'Dockerfile is in the context';
ok $entry{'.dockerignore'}, 'top-level dotfile is kept';

ok $entry{'bin/entry.sh'}, 'nested executable is in the context';
is sprintf('%04o', $entry{'bin/entry.sh'}->mode & 07777), '0755',
    'executable keeps its mode';
ok !$entry{'bin/entry.sh'}->is_symlink, 'executable is a regular file';
is $entry{'bin/entry.sh'}->get_content, "#!/bin/sh\necho hi\n", 'content intact';

ok $entry{'link.sh'}, 'symlink is in the context';
ok $entry{'link.sh'}->is_symlink, 'symlink is stored as a symlink entry';
is $entry{'link.sh'}->linkname, 'bin/entry.sh', 'symlink keeps its target';

ok $entry{'dangling'}, 'dangling symlink is in the context';
ok $entry{'dangling'}->is_symlink, 'dangling symlink is a symlink entry';
is $entry{'dangling'}->linkname, 'does/not/exist', 'dangling symlink keeps its target';

ok $entry{'empty'}, 'empty directory is in the context';
ok $entry{'empty'}->is_dir, 'empty directory is a directory entry';

done_testing;
