use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Dist::Zilla::Tester;

sub build_tzil {
  my (%opt) = @_;
  my @ini = @{ $opt{ini} || [] }; my $files = $opt{files} || {};
  Dist::Zilla::Tester->from_config(
    { dist_root => 't/does-not-exist' },
    { add_files => {
        'source/dist.ini' => join("\n",
          'name = AC-Test','author = Test <test@example.com>','license = Perl_5',
          'copyright_holder = Test','version = 0.001','','[GatherAgentContext]',@ini,''),
        'source/lib/AC/Test.pm' => "package AC::Test;\n# ABSTRACT: t\nour \$VERSION='0.001';\n1;\n",
        %$files,
      } },
  );
}
sub plugin { my $t = shift; (grep { $_->isa('Dist::Zilla::Plugin::GatherAgentContext') } @{ $t->plugins })[0] }
sub gathered { my $t = shift; sort map { $_->name } grep { index($_->name,'misc/agent-context/')==0 } @{ $t->files } }

# CLAUDE.md wird gesammelt
{
  my $tzil = build_tzil( files => { 'source/CLAUDE.md' => "hi\n" } );
  plugin($tzil)->gather_files;
  ok( ( grep { $_ eq 'misc/agent-context/CLAUDE.md' } gathered($tzil) ),
      'CLAUDE.md is gathered' );
}

# missing_ok default: kein Kontext vorhanden -> kein Tod, nichts gesammelt
{
  my $tzil = build_tzil();
  ok eval { plugin($tzil)->gather_files; 1 },
     'missing_ok default tolerates an absent context';
  is_deeply [ gathered($tzil) ], [], 'nothing gathered when nothing is present';
}

# missing_ok = 0 + explizit fehlendes dir -> fatal. Default-Dateien
# (CLAUDE.md/AGENTS.md) vorhanden, damit nur das .claude-Verzeichnis fehlt und
# in der Meldung benannt wird (bei missing_ok=0 waere sonst schon die fehlende
# Default-Datei zuerst fatal).
{
  my $tzil = build_tzil(
    ini   => [ 'missing_ok = 0', 'dir = .claude' ],
    files => { 'source/CLAUDE.md' => "c\n", 'source/AGENTS.md' => "a\n" },
  );
  ok !eval { plugin($tzil)->gather_files; 1 },
     'missing_ok=0 dies on an absent configured dir';
  like $@, qr/\.claude/, 'the fatal message names the missing dir';
}

done_testing;
