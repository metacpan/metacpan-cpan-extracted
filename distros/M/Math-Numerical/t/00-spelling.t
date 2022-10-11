use strict;
use warnings;

use Test2::V0;

# use Cwd 'abs_path';
use IPC::Run3 'run3';
use File::Find 'find';
use File::Spec::Functions 'abs2rel'; # 'rel2abs', ;
use FindBin;

my $aspell = `which aspell 2> /dev/null`;

my $root = $FindBin::Bin.'/..';

my $mode = (@ARGV && $ARGV[0] eq '--interactive') ? 'interactive' : 'list';

my @base_cmd = ('aspell', '--encoding=utf-8', "--home-dir=${root}",
                '--lang=en_GB-ise',  '--mode=perl', '-p',  '.aspelldict');

if (not $aspell) {
   my $msg = 'The aspell program is required in the path to check the spelling.';
   skip_all($msg);
}

if (!$ENV{TEST_AUTHOR} && $mode eq 'list') {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    skip_all($msg);
}

sub list_bad_words {
  my ($file) = @_;
  my $bad_words;
  my @cmd = (@base_cmd, 'list');
  run3(\@cmd, $file, \$bad_words) or die "Can’t run aspell: $!";
  return $bad_words;
}

sub interactive_check {
  my ($file) = @_;
  my @cmd = (@base_cmd, 'check', $file);
  return system @cmd;
}

# Note: while strings in Perl modules are checked, the POD content is ignored
# unfortunately.

sub wanted {
  # We should do something more generic to not recurse in Git sub-modules.
  $File::Find::prune = 1 if -d && $_ =~ m/^(blib)$/;
  if (-f $_ && m/\.(pm|pod)$/) {
    my $file_from_root = abs2rel($File::Find::name, $root);
    if ($mode eq 'list') {
      like(list_bad_words($_), qr/^\s*$/, "Spell-checking ${file_from_root}");
    } elsif ($mode eq 'interactive') {
      is(interactive_check($_), 0, "Interactive spell-checking for ${file_from_root}");
    } else {
      die "Unknown operating mode: '${mode}'";
    }
  }
}

find(\&wanted, $root);
done_testing();

#    \taspell --encoding=utf-8 --home-dir="\$(shell pwd)" --mode=markdown -l en_GB-ise-w_accents -p .aspelldict check *.md documentation/*.md
