#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Langertha::Holmgang::Sim::Linux::Git ();
use Holmgang::TestSim qw( run_command clone need_parts );

# git auf dem Linux-Simulator. Behauptet wird: cd gilt bis zum
# Ende der Befehlszeile und macht Pfade relativ; add/commit/amend/rm --cached
# arbeiten auf Index und Arbeitsbaum (.gitignore beachtet); push ueberträgt
# neue Commits zum Server, lehnt Nicht-Fast-Forward ab (fetch first), prueft
# die Regeln des pre-receive-Hooks (nur, wenn die Hook-Datei fuer git
# ausfuehrbar ist) und den Schutz gegen Force-Push; pull ohne Vorgabe bei
# auseinanderlaufenden Zweigen bricht ab wie git 2.39, pull --rebase setzt die
# eigenen Commits linear oben auf; Tags (annotiert, auf einen Commit) gehen
# einzeln zum Server; eine gescheiterte Aenderung hinterlaesst nichts.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my %c1 = ( parents => [], message => "SHOP-1: Anfang", author => 'Ana <ana@example.com>', date => 1792800000, tree => { 'README.md' => "# Shop\n", 'app.py' => "print('v1')\n", '.gitignore' => "*.log\n" } );
my $id1 = Langertha::Holmgang::Sim::Linux::Git::_cid( \%c1 );
my %c2 = ( parents => [$id1], message => "SHOP-2: Kasse", author => 'Ana <ana@example.com>', date => 1792800600, tree => { %{ $c1{tree} }, 'kasse.py' => "pay()\n" } );
my $id2 = Langertha::Holmgang::Sim::Linux::Git::_cid( \%c2 );
my %c3 = ( parents => [$id2], message => "SHOP-3: Kollege", author => 'Ben <ben@example.com>', date => 1792801200, tree => { %{ $c2{tree} }, 'lager.py' => "stock()\n" } );
my $id3 = Langertha::Holmgang::Sim::Linux::Git::_cid( \%c3 );

my $start = {
    dev1 => {
        type => 'linux', hostname => 'dev1',
        users => { dev => { uid => 1000, groups => ['dev'] } },
        files => { '/home/dev/shop/README.md' => "# Shop\n", '/home/dev/shop/app.py' => "print('v1')\n", '/home/dev/shop/kasse.py' => "pay()\n",
            '/home/dev/shop/.gitignore' => "*.log\n" },
        git => { config => { 'user.name' => 'Dev', 'user.email' => 'dev@example.com' }, repos => { '/home/dev/shop' => {
            branch => 'main', remotes => { origin => { url => 'git@git.example.com:shop/shop.git', host => 'git1', repo => 'shop/shop' } },
            refs => { heads => { main => $id2 }, remotes => { 'origin/main' => $id2 }, tags => {} },
            commits => { $id1 => { %c1, seq => 1 }, $id2 => { %c2, seq => 2 } } } } },
    },
    git1 => {
        type => 'linux', hostname => 'git1',
        users => { git => { uid => 115, groups => ['git'] } },
        files => { '/var/lib/forgejo/hooks/policy' => { content => "#!/bin/sh\n# Ticket in jeder Nachricht\n", owner => 'git', group => 'git', mode => '0755' } },
        services => { forgejo => { active => JSON::MaybeXS::true() } },
        forgejo => { repos => { 'shop/shop' => {
            refs => { heads => { main => $id3 }, tags => {} },
            commits => { $id1 => { %c1, seq => 1 }, $id2 => { %c2, seq => 2 }, $id3 => { %c3, seq => 3 } },
            hook => '/var/lib/forgejo/hooks/policy',
            policy => [ { kind => 'message', regex => '\A[A-Z]+-\d+: ', text => "Commit {commit} \"{subject}\": Nachricht ohne Ticket (z. B. SHOP-123: …)" },
                { kind => 'path', regex => '(?:\A|/)\.env\z', text => 'Commit {commit} enthält .env — Zugangsdaten gehören nicht ins Repo' } ],
            protected => { main => {} } } } },
    },
};

sub run {
    my ( $s, $cmd, $host ) = @_;
    my ( $o, $ok ) = run_command( $s, $host // 'dev1', $cmd );
    return wantarray ? ( $o, $ok ) : $o;
}
my $R = sub { $_[0]{dev1}{git}{repos}{'/home/dev/shop'} };
my $S = sub { $_[0]{git1}{forgejo}{repos}{'shop/shop'} };

subtest 'cd, status, add, commit' => sub {
    my $s = clone($start);
    like( run( $s, 'cd /home/dev/shop && git status' ), qr/On branch main\nYour branch is up to date with 'origin\/main'\.\n\nnothing to commit, working tree clean/, 'sauber' );
    my ( $o, $ok ) = run( $s, 'git status' );
    ok( !$ok && $o =~ /not a git repository/, 'ohne cd: kein Repo' );
    run( $s, q{cd /home/dev/shop && echo "print('v2')" > app.py && echo x > debug.log && echo neu > neu.py} );
    is( $s->{dev1}{files}{'/home/dev/shop/app.py'}, "print('v2')\n", 'relativer Pfad nach cd' );
    run( $s, 'cd /home/dev/shop && echo app.py > liste.txt' );
    is( $s->{dev1}{files}{'/home/dev/shop/liste.txt'}, "app.py\n", 'Text von echo bleibt Text' );
    delete $s->{dev1}{files}{'/home/dev/shop/liste.txt'};
    is( run( $s, 'grep -r pay /home/dev/shop' ), "/home/dev/shop/kasse.py:pay()", 'grep -r ueber ein Verzeichnis, mit Dateinamen' );
    is( run( $s, 'grep -r pay /home/dev/shop/kasse.py' ), "pay()", 'grep -r auf eine Datei: ohne Dateinamen' );
    is( run( $s, 'grep -rl Shop /home/dev/shop' ), "/home/dev/shop/README.md", 'grep -rl' );
    $s->{dev1}{files}{'/tmp/x.ini'} = "A = 1\nB = github\n";
    ok( ( run( $s, q{sed -i 's/^A = 1$/A = 2/; s|^B = github$|B = https://code.example.com|' /tmp/x.ini} ) )[1], 'sed mit zwei Befehlen und anderem Trenner' );
    is( delete $s->{dev1}{files}{'/tmp/x.ini'}, "A = 2\nB = https://code.example.com\n", 'beide angewandt' );
    like( run( $s, 'git -C /home/dev/shop status -s' ), qr/\A M app\.py\n\?\? neu\.py\z/, 'status -s, .log ignoriert' );
    run( $s, 'cd /home/dev/shop && git add app.py && git commit -m "SHOP-4: v2"' );
    my $r = $R->($s);
    my $h = $r->{refs}{heads}{main};
    is( $r->{commits}{$h}{tree}{'app.py'}, "print('v2')\n", 'Commit mit Aenderung' );
    ok( !exists $r->{commits}{$h}{tree}{'neu.py'}, 'ohne nicht hinzugefuegte Datei' );
    is( $r->{commits}{$h}{author}, 'Dev <dev@example.com>', 'Autor aus der Konfiguration' );
    like( run( $s, 'cd /home/dev/shop && git status' ), qr/ahead of 'origin\/main' by 1 commit/, 'voraus' );
    run( $s, 'cd /home/dev/shop && git commit --amend -m "SHOP-4: Version 2"' );
    is( $R->($s)->{commits}{ $R->($s)->{refs}{heads}{main} }{message}, 'SHOP-4: Version 2', 'amend ersetzt die Nachricht' );
    is( $R->($s)->{commits}{ $R->($s)->{refs}{heads}{main} }{parents}[0], $id2, 'mit demselben Elter' );
    like( run( $s, 'cd /home/dev/shop && git log --oneline' ), qr/\A\w{7} SHOP-4: Version 2\n\w{7} SHOP-2: Kasse\n\w{7} SHOP-1: Anfang\z/, 'log --oneline' );
};

subtest 'push: fetch first, pull, rebase, Hook' => sub {
    my $s = clone($start);
    run( $s, q{cd /home/dev/shop && echo "print('v2')" > app.py && git commit -am "SHOP-4: v2"} );
    my ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git push' );
    ok( !$ok && $o =~ /\[rejected\]\s+main -> main \(fetch first\)/, 'Server hat mehr: fetch first' ) or diag $o;
    ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git pull' );
    ok( !$ok && $o =~ /Need to specify how to reconcile divergent branches/, 'pull ohne Vorgabe bricht ab' ) or diag $o;
    is( $R->($s)->{refs}{remotes}{'origin/main'}, $id3, 'aber geholt' );
    like( run( $s, 'cd /home/dev/shop && git log --all --oneline' ), qr/\A\w{7} SHOP-4: v2\n\w{7} SHOP-3: Kollege\n\w{7} SHOP-2: Kasse\n\w{7} SHOP-1: Anfang\z/, 'log --all: neueste zuerst' );
    ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git pull --rebase' );
    ok( $ok, 'pull --rebase' ) or diag $o;
    my $h = $R->($s)->{refs}{heads}{main};
    is( $R->($s)->{commits}{$h}{parents}[0], $id3, 'eigener Commit oben auf dem des Kollegen' );
    is( $s->{dev1}{files}{'/home/dev/shop/lager.py'}, "stock()\n", 'Arbeitsbaum nachgezogen' );
    ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git push origin main' );
    ok( $ok, 'push' ) or diag $o;
    is( $S->($s)->{refs}{heads}{main}, $h, 'Server auf dem neuen Stand' );
    # Hook: Nachricht ohne Ticket
    run( $s, q{cd /home/dev/shop && echo "print('v3')" > app.py && git commit -am "fix"} );
    ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git push' );
    ok( !$ok && $o =~ /remote: Commit \w{7} "fix": Nachricht ohne Ticket/ && $o =~ /pre-receive hook declined/, 'Hook lehnt ab' ) or diag $o;
    is( $S->($s)->{refs}{heads}{main}, $h, 'Server unveraendert' );
    ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git push --no-verify' );
    ok( !$ok, '--no-verify hilft nicht gegen Server-Hooks' );
    $s->{git1}{files}{'/var/lib/forgejo/hooks/policy'}{mode} = '0644';
    ok( ( run( $s, 'cd /home/dev/shop && git push' ) )[1], 'nicht ausfuehrbarer Hook: keine Pruefung' );
};

subtest 'Force-Push, .env, Tags' => sub {
    my $s = clone($start);
    run( $s, q{cd /home/dev/shop && echo "print('v2')" > app.py && git commit -am "SHOP-4: v2"} );
    my ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git push --force' );
    ok( !$ok && $o =~ /protected from force push/, 'geschuetzter Zweig: kein Force-Push' ) or diag $o;
    delete $S->($s)->{protected};
    ok( ( run( $s, 'cd /home/dev/shop && git push -f' ) )[1], 'ungeschuetzt: Force-Push geht' );
    ok( !exists $S->($s)->{commits}{ $S->($s)->{refs}{heads}{main} }{tree}{'lager.py'}, 'und der Commit des Kollegen ist weg' );

    $s = clone($start);
    run( $s, 'cd /home/dev/shop && git pull --rebase && echo TOKEN=geheim > .env && git add .env && git commit -m "SHOP-5: Konfiguration"' );
    ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git push' );
    ok( !$ok && $o =~ /enthält \.env/, '.env abgelehnt' ) or diag $o;
    run( $s, q{cd /home/dev/shop && git rm --cached .env && echo .env >> .gitignore && git add .gitignore && git commit --amend --no-edit} );
    is( $s->{dev1}{files}{'/home/dev/shop/.env'}, "TOKEN=geheim\n", 'rm --cached laesst die Datei' );
    ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git push' );
    ok( $ok, 'ohne .env geht es' ) or diag $o;
    unlike( run( $s, 'cd /home/dev/shop && git status -s' ), qr/\.env/, '.env ist ignoriert' );

    run( $s, "cd /home/dev/shop && git tag -a v1.0.0 -m 'Release 1.0.0' $id2 && git tag tmp" );
    ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git push origin v1.0.0' );
    ok( $ok, 'Tag einzeln' ) or diag $o;
    is( $S->($s)->{refs}{tags}{'v1.0.0'}{commit}, $id2, 'auf dem genannten Commit' );
    ok( $S->($s)->{refs}{tags}{'v1.0.0'}{annotated}, 'annotiert' );
    ok( !$S->($s)->{refs}{tags}{tmp}, 'tmp nicht mitgeschickt' );
    like( run( $s, 'cd /home/dev/shop && git show v1.0.0 --stat' ), qr/tag v1\.0\.0\nTagger: Dev <dev\@example\.com>\n\nRelease 1\.0\.0/, 'show eines Tags' );
};

subtest 'cherry-pick, remote set-url' => sub {
    my $s = clone($start);
    run( $s, 'cd /home/dev/shop && git fetch && git checkout -b release origin/main~1' );
    my ( $o, $ok ) = run( $s, "cd /home/dev/shop && git cherry-pick -x $id3" );
    ok( $ok, 'cherry-pick' ) or diag $o;
    my $h = $R->($s)->{refs}{heads}{release};
    like( $R->($s)->{commits}{$h}{message}, qr/\ASHOP-3: Kollege\n\n\(cherry picked from commit $id3\)\z/, 'Nachricht mit -x' );
    is( $R->($s)->{commits}{$h}{parents}[0], $id2, 'auf dem Zweig' );
    is( $s->{dev1}{files}{'/home/dev/shop/lager.py'}, "stock()\n", 'Datei im Arbeitsbaum' );
    $R->($s)->{remotes}{origin} = { url => 'git@git1.lan:shop/shop.git', host => 'git1.lan', repo => 'shop/shop' };
    ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git fetch' );
    ok( !$ok && $o =~ /Could not resolve hostname git1\.lan/, 'alter Name geht nicht' ) or diag $o;
    $s->{dev1}{git}{hosts} = { 'git.example.com' => 'git1' };
    ok( ( run( $s, 'cd /home/dev/shop && git remote set-url origin git@git.example.com:shop/shop.git && git fetch' ) )[1], 'set-url, dann geht es' );
    is( $R->($s)->{remotes}{origin}{host}, 'git1', 'Server ueber den Namen' );
};

subtest 'Bare-Repo auf dem Server' => sub {
    my $s = clone($start);
    $s->{git1}{files}{'/var/lib/forgejo/data/forgejo-repositories/shop/shop.git/hooks/pre-receive'} = { content => "#!/bin/sh\n", owner => 'git', mode => '0755' };
    like( run( $s, 'cd /var/lib/forgejo/data/forgejo-repositories/shop/shop.git && git log --oneline -1', 'git1' ), qr/\A\w{7} SHOP-3: Kollege\z/, 'log im Bare-Repo' );
    my ( $o, $ok ) = run( $s, 'git -C /var/lib/forgejo/data/forgejo-repositories/shop/shop.git status', 'git1' );
    ok( !$ok && $o =~ /must be run in a work tree/, 'status geht dort nicht' );
    ok( ( run( $s, "git -C /var/lib/forgejo/data/forgejo-repositories/shop/shop.git tag -a v9 -m 'Release 9' $id2", 'git1' ) )[1], 'tag im Bare-Repo' );
    is( $S->($s)->{refs}{tags}{v9}{commit}, $id2, 'Tag auf dem Server' );
    like( run( $s, 'ls -l /usr/bin/git', 'dev1' ), qr{-rwxr-xr-x .* /usr/bin/git\z}, 'ls auf ein Programm wie which' );
    is( run( $s, 'cat /home/dev/shop/.git/HEAD' ), "ref: refs/heads/main", '.git/HEAD' );
    is( run( $s, 'cd /home/dev/shop && git ls-tree -r --name-only HEAD' ), ".gitignore\nREADME.md\napp.py\nkasse.py", 'ls-tree -r --name-only' );
    like( run( $s, 'git -C /var/lib/forgejo/data/forgejo-repositories/shop/shop.git ls-tree main', 'git1' ), qr/^100644 blob [0-9a-f]{40}\tlager\.py$/m, 'ls-tree im Bare-Repo' );
    like( run( $s, 'find /home/dev/shop -name "*.py" -exec grep -l pay {} \;' ), qr{\A/home/dev/shop/kasse\.py\z}, 'find -exec' );
    like( run( $s, 'cd /home/dev/shop && git cat-file -p HEAD' ), qr/\Atree [0-9a-f]{40}\nparent $id1\nauthor Ana <ana\@example\.com> \d+ \+0200\n.*\n\nSHOP-2: Kasse\z/s, 'cat-file -p eines Commits' );
    is( run( $s, 'cd /home/dev/shop && git cat-file -p HEAD:kasse.py' ), 'pay()', 'cat-file rev:pfad' );
    like( run( $s, 'env' ), qr/^HOME=\/root$/m, 'env auf dem Rechner' );
    like( run( $s, 'file /usr/bin/git /home/dev/shop/README.md' ), qr{/usr/bin/git: ELF.*\n/home/dev/shop/README\.md: ASCII text}, 'file' );
    like( run( $s, 'cd /home/dev/shop && cat .git/config' ), qr/\[remote "origin"\]\n\turl = git\@git\.example\.com:shop\/shop\.git/, '.git/config' );
    like( run( $s, 'ls -a /home/dev/shop' ), qr/(?:^|\s)\.git\s/, 'ls zeigt .git' );
    like( run( $s, 'ls /var/lib/forgejo/data/forgejo-repositories/shop/shop.git', 'git1' ), qr/\AHEAD\s+config\s+description\s+hooks\s+info\s+objects\s+refs\z/, 'Bare-Repo als Verzeichnis' );
    is( run( $s, 'cat /var/lib/forgejo/data/forgejo-repositories/shop/shop.git/refs/heads/main', 'git1' ), $id3, 'refs im Bare-Repo' );
    $s->{git1}{forgejo}{root_url} = 'https://git.example.com/';
    like( run( $s, 'curl -s http://127.0.0.1:3000/api/v1/repos/shop/shop/branches', 'git1' ), qr/"name":"main","protected":true/, 'Forgejo-API: Zweige' );
    like( run( $s, 'curl -s -w "%{http_code}" http://localhost:3000/api/v1/repos/shop/shop/branch_protections', 'git1' ), qr/token is required.*401\z/, '... Schutzregeln brauchen Token' );
};

subtest 'revert, forgejo-runner register' => sub {
    my $s = clone($start);
    run( $s, 'cd /home/dev/shop && git pull --rebase' );
    my ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git revert HEAD' );
    ok( !$ok, 'revert ohne --no-edit braucht den Editor' );
    ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git revert --no-edit HEAD' );
    ok( $ok, 'revert --no-edit' ) or diag $o;
    my $h = $R->($s)->{refs}{heads}{main};
    like( $R->($s)->{commits}{$h}{message}, qr/\ARevert "SHOP-3: Kollege"\n\nThis reverts commit $id3\./, 'Nachricht wie git' );
    ok( !exists $R->($s)->{commits}{$h}{tree}{'lager.py'} && !exists $s->{dev1}{files}{'/home/dev/shop/lager.py'}, 'Aenderung zurueckgenommen' );
    is( $R->($s)->{commits}{$h}{parents}[0], $id3, 'als neuer Commit oben drauf' );

    $s->{runner1} = { type => 'linux', hostname => 'runner1', users => { runner => { uid => 999, groups => ['runner'], home => '/var/lib/forgejo-runner' } }, files => {}, dirs => { '/var/lib/forgejo-runner' => {} } };
    $s->{git1}{forgejo}{root_url} = 'https://git.example.com/';
    $s->{git1}{forgejo}{runner_tokens} = ['AbC123'];
    ( $o, $ok ) = run( $s, 'cd /var/lib/forgejo-runner && forgejo-runner register --no-interactive --instance https://git.example.com --token falsch --name r1', 'runner1' );
    ok( !$ok && $o =~ /registration token not found/, 'falsches Token' );
    ( $o, $ok ) = run( $s, 'cd /var/lib/forgejo-runner && forgejo-runner register --no-interactive --instance https://git.example.com --token AbC123 --name r1 --labels docker:docker://node:20', 'runner1' );
    ok( $ok, 'register als root' ) or diag $o;
    is( $s->{runner1}{files}{'/var/lib/forgejo-runner/.runner'}{owner}, 'root', '.runner gehoert root (0600)' );
    ok( $s->{git1}{forgejo}{runners}{r1}, 'am Server angemeldet' );
    delete $s->{runner1}{files}{'/var/lib/forgejo-runner/.runner'};
    ( $o, $ok ) = run( $s, q{su runner -s /bin/sh -c 'cd /var/lib/forgejo-runner && forgejo-runner register --no-interactive --instance https://git.example.com --token AbC123 --name r2'}, 'runner1' );
    ok( $ok, 'register als runner' ) or diag $o;
    is( $s->{runner1}{files}{'/var/lib/forgejo-runner/.runner'}{owner}, 'runner', 'dann gehoert die Datei runner' );
};

# stash legt Aenderungen an verfolgten Dateien beiseite (unverfolgte nur mit -u)
# und spielt sie mit pop/apply zurueck; pull --rebase --autostash tut beides selbst.
subtest 'stash und autostash' => sub {
    my $s = clone($start);
    my $f = '/home/dev/shop/app.py';
    my ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git stash' );
    like( $o, qr/No local changes to save/, 'nichts zu sichern' );
    run( $s, qq{cd /home/dev/shop && echo "print('halb')" > app.py && echo neu > neu.py} );
    ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git pull --rebase' );
    ok( !$ok && $o =~ /cannot pull with rebase: You have unstaged changes/, 'pull --rebase mit Aenderungen bricht ab' );
    ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git stash push -m halb' );
    ok( $ok, 'stash push' ) or diag $o;
    like( $o, qr/Saved working directory and index state On main: halb/, 'Meldung wie git' );
    is( $s->{dev1}{files}{$f}, "print('v1')\n", 'Arbeitsbaum zurueck auf HEAD' );
    is( $s->{dev1}{files}{'/home/dev/shop/neu.py'}, "neu\n", 'unverfolgte Datei bleibt' );
    like( run( $s, 'cd /home/dev/shop && git stash list' ), qr/\Astash\@\{0\}: On main: halb\z/, 'stash list' );
    like( run( $s, 'cd /home/dev/shop && git stash show -p' ), qr/\+print\('halb'\)/, 'stash show -p' );
    ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git pull --rebase' );
    ok( $ok, 'pull --rebase nach stash' ) or diag $o;
    is( $R->($s)->{refs}{heads}{main}, $id3, 'auf dem Stand des Servers' );
    ( $o, $ok ) = run( $s, 'cd /home/dev/shop && git stash pop' );
    ok( $ok, 'stash pop' ) or diag $o;
    is( $s->{dev1}{files}{$f}, "print('halb')\n", 'Aenderung wieder da' );
    is( $s->{dev1}{files}{'/home/dev/shop/lager.py'}, "stock()\n", 'neuer Stand bleibt' );
    ok( !@{ $R->($s)->{stash} || [] }, 'pop entfernt den Eintrag' );
    like( run( $s, 'cd /home/dev/shop && git status' ), qr/modified:\s+app\.py/, 'wieder als geaendert' );

    my $t = clone($start);
    run( $t, qq{cd /home/dev/shop && echo "print('halb')" > app.py} );
    ( $o, $ok ) = run( $t, 'cd /home/dev/shop && git pull --rebase --autostash' );
    ok( $ok, 'pull --rebase --autostash' ) or diag $o;
    like( $o, qr/Created autostash: [0-9a-f]{7}.*Applied autostash\./s, 'Meldung wie git' );
    is( $t->{dev1}{files}{$f}, "print('halb')\n", 'Aenderung bleibt' );
    is( $R->($t)->{refs}{heads}{main}, $id3, 'Stand des Servers' );
    ok( !@{ $R->($t)->{stash} || [] }, 'kein Eintrag bleibt' );

    my $u = clone($start);
    run( $u, qq{cd /home/dev/shop && echo "print('halb')" > app.py} );
    run( $u, 'cd /home/dev/shop && git config rebase.autoStash true' );
    ( $o, $ok ) = run( $u, 'cd /home/dev/shop && git pull --rebase' );
    ok( $ok && $u->{dev1}{files}{$f} eq "print('halb')\n", 'rebase.autoStash aus der Konfiguration' ) or diag $o;

    my $v = clone($start);
    run( $v, qq{cd /home/dev/shop && echo neu > neu.py} );
    run( $v, 'cd /home/dev/shop && git stash -u' );
    ok( !exists $v->{dev1}{files}{'/home/dev/shop/neu.py'}, 'stash -u nimmt unverfolgte Dateien mit' );
    run( $v, 'cd /home/dev/shop && git stash apply' );
    is( $v->{dev1}{files}{'/home/dev/shop/neu.py'}, "neu\n", 'apply bringt sie zurueck' );
    is( scalar @{ $R->($v)->{stash} }, 1, 'apply behaelt den Eintrag' );
    run( $v, 'cd /home/dev/shop && git stash drop' );
    ok( !@{ $R->($v)->{stash} }, 'drop' );

    my $w = clone($start);
    run( $w, qq{cd /home/dev/shop && echo "print('halb')" > app.py && echo "pay(2)" > kasse.py} );
    ( $o, $ok ) = run( $w, 'cd /home/dev/shop && git stash push -m nur-app -- app.py' );
    ok( $ok, 'stash push -- PFAD' ) or diag $o;
    is( $w->{dev1}{files}{$f}, "print('v1')\n", 'gewaehlte Datei zurueck auf HEAD' );
    is( $w->{dev1}{files}{'/home/dev/shop/kasse.py'}, "pay(2)\n", 'andere Aenderung bleibt' );
    run( $w, 'cd /home/dev/shop && git checkout -- kasse.py' );
    run( $w, 'cd /home/dev/shop && git stash pop' );
    is( $w->{dev1}{files}{$f}, "print('halb')\n", 'pop bringt nur die gewaehlte Datei zurueck' );
    is( $w->{dev1}{files}{'/home/dev/shop/kasse.py'}, "pay()\n", 'die andere bleibt, wie sie ist' );
};

subtest 'xargs und diff' => sub {
    my $s = clone($start);
    is( run( $s, q{find /home/dev/shop -name '*.py' | xargs grep -l pay} ), '/home/dev/shop/kasse.py', 'ls | xargs grep -l' );
    is( run( $s, q{find /home/dev/shop -name '*.py' | xargs -I{} echo datei {}} ), "datei /home/dev/shop/app.py\ndatei /home/dev/shop/kasse.py", 'xargs -I{}' );
    is( ( run( $s, 'true | xargs -r echo leer' ) )[0], '', 'xargs -r ohne Eingabe' );
    SKIP: {
        # cp lives in the Backup part
        my $why = need_parts(q{Backup});
        skip $why, 2 if $why;
        run( $s, 'cp /home/dev/shop/app.py /tmp/app.orig' );
        my ( $o, $ok ) = run( $s, 'diff /tmp/app.orig /home/dev/shop/app.py' );
        ok( $ok && $o eq '', 'diff gleich' );
        run( $s, q{echo "print('v2')" > /home/dev/shop/app.py} );
        ( $o, $ok ) = run( $s, 'diff -u /tmp/app.orig /home/dev/shop/app.py' );
        ok( !$ok && $o =~ m{\A--- /tmp/app\.orig\n\+\+\+ /home/dev/shop/app\.py\n.*-print\('v1'\)\n\+print\('v2'\)}s, 'diff -u mit Unterschied' ) or diag $o;
    }
};

# ls / zeigt die obersten Verzeichnisse; find kennt Verzeichnisse, -type d,
# -o zwischen Bedingungen und -maxdepth/-mindepth.
subtest 'ls / und find' => sub {
    my $s = clone($start);
    like( run( $s, 'ls /' ), qr/^home$/m, 'ls / mit den Dateipfaden (und den Verzeichnissen eines Debian)' );
    like( run( $s, 'ls -la /' ), qr/^drwx\S+ .* home$/m, 'ls -la /' );
    is( run( $s, 'find /home/dev -maxdepth 1' ), "/home/dev\n/home/dev/shop", 'find mit Verzeichnissen und -maxdepth' );
    is( run( $s, 'find /home -type d' ), "/home\n/home/dev\n/home/dev/shop", 'find -type d' );
    is( run( $s, q{find /home -name '*.py' -o -name '*.md'} ), "/home/dev/shop/README.md\n/home/dev/shop/app.py\n/home/dev/shop/kasse.py", 'find -o' );
    is( run( $s, q{find / -maxdepth 4 -name 'app*' -o -maxdepth 4 -name 'k*'} ), "/home/dev/shop/app.py\n/home/dev/shop/kasse.py", 'find -o mit -maxdepth je Zweig' );
    is( run( $s, q{find /home \( -name '*.py' -o -name '.gitignore' \) -type f} ), "/home/dev/shop/.gitignore\n/home/dev/shop/app.py\n/home/dev/shop/kasse.py", 'Klammern' );
    is( run( $s, 'find /home/dev/shop -mindepth 1 -maxdepth 1 -type f -name "*.py"' ), "/home/dev/shop/app.py\n/home/dev/shop/kasse.py", '-mindepth' );
    like( run( $s, 'find /home/dev/shop -name "*.py" -exec grep -l pay {} \;' ), qr{\A/home/dev/shop/kasse\.py\z}, '-exec weiter' );
};

# Lesendes rund um git: rev-list, reflog, remote show, ssh -T zum Forgejo-Server,
# dirname/basename/md5sum/readlink -f
subtest 'rev-list, reflog, remote show, ssh -T, Hilfen' => sub {
    my $s = clone($start);
    $s->{dev1}{git}{hosts} = { 'git.example.com' => 'git1' };
    $s->{git1}{forgejo}{root_url} = 'https://git.example.com/';
    is( run( $s, 'cd /home/dev/shop && git rev-list HEAD' ), "$id2\n$id1", 'rev-list' );
    is( run( $s, 'cd /home/dev/shop && git rev-list --count HEAD' ), 2, 'rev-list --count' );
    run( $s, 'cd /home/dev/shop && git fetch' );
    is( run( $s, 'cd /home/dev/shop && git rev-list HEAD..origin/main' ), $id3, 'rev-list A..B' );
    is( run( $s, 'cd /home/dev/shop && git merge-base HEAD origin/main' ), $id2, 'merge-base' );
    ok( ( run( $s, 'cd /home/dev/shop && git merge-base --is-ancestor HEAD origin/main' ) )[1], 'merge-base --is-ancestor' );
    like( run( $s, 'cd /home/dev/shop && git reflog -n1' ), qr/\A[0-9a-f]{7} HEAD\@\{0\}: commit: SHOP-2: Kasse\z/, 'reflog' );
    like( run( $s, 'cd /home/dev/shop && git remote show origin' ), qr/Fetch URL: git\@git\.example\.com:shop\/shop\.git.*main pushes to main \(local out of date\)/s, 'remote show' );
    my ( $o, $ok ) = run( $s, 'ssh -T git@git.example.com' );
    ok( $ok && $o =~ /does not provide shell access/, 'ssh -T git@ zum Forgejo-Server' ) or diag $o;
    ( $o, $ok ) = run( $s, 'ssh root@git1 uptime' );
    ok( $ok && $o =~ /load average/, 'ssh zu einem anderen Geraet: Befehl laeuft dort (wie in main)' ) or diag $o;
    ( $o, $ok ) = run( $s, 'ssh nirgends.example.com' );
    ok( defined( ( run_command( $s, 'dev1', 'ssh nirgends.example.com' ) )[2] ), 'unbekannter Name: Luecke (wie in main)' );
    ( $o, $ok, my $gap ) = run_command( $s, 'dev1', 'ssh git@git.example.com echo hallo' );
    ok( $gap, 'ssh git@forgejo mit Befehl bleibt eine Luecke' );
    ( $o, $ok ) = run( $s, 'curl -s https://git.example.com/api/v1/version' );
    ok( $ok && $o =~ /"version"/, 'curl von dev1 ueber den oeffentlichen Namen zur API' ) or diag $o;
    ( $o, $ok ) = run( $s, 'wget -qO- https://git.example.com/api/v1/version' );
    ok( $ok && $o =~ /"version"/, 'wget -qO-' ) or diag $o;
    ( $o, $ok ) = run( $s, 'curl -s http://10.40.0.10:3000/' );
    ok( !$ok && $o =~ /Couldn't connect/, 'Forgejo lauscht nur auf 127.0.0.1' ) or diag $o;
    ( $o, $ok ) = run( $s, 'curl -s https://git1.lan/' );
    ok( !$ok && $o =~ /Could not resolve host: git1\.lan/, 'unbekannter Name bei curl' ) or diag $o;
    my $d = clone($start);
    $d->{dev1}{files}{'/var/run/docker.sock'} = { content => '', owner => 'root', group => 'docker', mode => '0660' };
    $d->{dev1}{services}{docker} = { active => JSON::MaybeXS::true() };
    like( run( $d, 'docker pull python:3.12-bookworm' ), qr{Downloaded newer image for docker\.io/library/python:3\.12-bookworm}, 'docker pull' );
    like( run( $d, 'docker run --rm hello-world' ), qr/Hello from Docker!/, 'docker run hello-world' );
    like( run( $s, 'free -m' ), qr/\A\s+total\s+used/, 'free' );
    is( run( $s, 'dirname /home/dev/shop/app.py' ), '/home/dev/shop', 'dirname' );
    is( run( $s, 'basename /home/dev/shop/app.py .py' ), 'app', 'basename mit Endung' );
    like( run( $s, 'cd /home/dev/shop && md5sum app.py' ), qr/\A[0-9a-f]{32}  \/home\/dev\/shop\/app\.py\z/, 'md5sum' );
    is( run( $s, 'cd /home/dev/shop && readlink -f ./x/../app.py' ), '/home/dev/shop/app.py', 'readlink -f' );
};

done_testing;
