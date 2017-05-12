# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use Path::Tiny;
use Test::DZil;
use Git::Wrapper;
use File::Temp qw( tempfile );

use Test::File::ShareDir -share => {
  -module => { 'Dist::Zilla::MintingProfile::Author::RWSTAUNER' => 'share/profiles' },
};

(my $tmpfile, $ENV{GIT_CONFIG}) = tempfile( 'git-config.XXXXXX', TMPDIR => 1, UNLINK => 1, );
print $tmpfile <<'CONFIG';
[user]
  name  = Reinhold Messner
  email = magic.mess@example.com
[github]
  user  = narcolepsy
CONFIG
close $tmpfile;

{
  my $user = 'rwstauner';
  my $dist_name = 'DZT-Minty';
  (my $mod_name = $dist_name) =~ s/-/::/g;
  (my $mod_path = $dist_name . '.pm') =~ s!-!/!g;

  my $tzil = Minter->_new_from_profile(
    [ 'Author::RWSTAUNER' => 'default' ],
    { name    => $dist_name ,},
    { global_config_root => path(qw( corpus global ))->absolute },
  );

  $tzil->mint_dist();

  my $mint_dir = path($tzil->tempdir)->child('mint');
  my $dir = $mint_dir->child('t');

  ok -d $dir, 'created t in mint dir';

  is_deeply [$dir->children], [], 'dir is empty but exists';

  file_like( $tzil, "lib/$mod_path",
    qr/\A# vim: .+:/, 'module vim modeline',
    qr/^package $mod_name;/m,     'module package declaration',
    qr/^# ABSTRACT: /m,           'module abstract',
    qr/\n=head1 SYNOPSIS\n\n=head1 DESCRIPTION\n\n=cut\n/, 'module pod',
    '!', qr/copyright/,           'copyright not prepended to module',
  );

  file_like( $tzil, 'Changes',
    qr/\ARevision history for $dist_name/, 'minted change log',
    qr/\n\{\{\$NEXT\}\}\n/,                'change log has NEXT token',
  );

  file_like( $tzil, 'dist.ini',
    qr/\Aname\s+=\s+$dist_name/, 'dist.ini name',
    qr/\n\[\@Author::RWSTAUNER\]\n/, 'dist.ini uses author bundle',
  );

  file_like( $tzil, 'README.mkdn',
    qr/\A# NAME\n\n$mod_name - /,   'README intialized',
  );

  file_like( $tzil, '.gitignore',
    qr!\A/$dist_name\*!,   'dist name ignored',
    qr!\n/cover_db/?\n!,   'ignore cover_db',
    qr!\n/tags\n!,         'ignore vim tags',
  );

  my $git = Git::Wrapper->new($mint_dir->stringify);

  file_like( $tzil, '.mailmap',
    qr!^Reinhold Messner <$user\@cpan\.org> <magic\.mess\@example\.com>$!,
      'mailmap git email to pause email',
  );

  git_like($git, config => ['branch.master.remote'],
    qr/^origin$/,                            'configured git branch remote');
  git_like($git, config => ['branch.master.merge'],
    qr/^refs\/heads\/master$/,               'configured git branch merge');
  git_like($git, remote => ['-v'],
    qr/git\@github\.com:narcolepsy\/$dist_name\.git/, 'configured git remote');

  {
    my @log = $git->log;
    is scalar @log, 1, 'one commit';
    like $log[0]->message, qr/initial commit/, 'initial commit';
  }
}

done_testing;

sub file_like {
  my ($tzil, $file, @tests) = @_;
  my $content = $tzil->slurp_file("mint/$file");
  while( @tests ){
    my $negate = $tests[0] eq '!' ? shift(@tests) : 0;
    my $re     = shift @tests;
    my $desc   = shift @tests;
    $negate
      ? unlike($content, $re, $desc)
      :   like($content, $re, $desc);
  }
  like $content, qr/\S\n\z/, "$file ends with a single newline";
}

sub git_like {
  my ($git, $cmd, $args, $re, $desc) = @_;
  like [$git->$cmd(@$args)]->[0], $re, $desc;
}
