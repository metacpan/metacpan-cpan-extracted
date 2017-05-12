# -*- cperl -*-

use Test::More;
BEGIN {
  our @files = qw!scripts/nat-lex2perl
                  scripts/nat-tmx2pair
                  scripts/nat-pair2tmx
                  scripts/nat-dumpDicts
                  scripts/nat-compareDicts
                  scripts/nat-rank
                  scripts/nat-sentence-align
                  scripts/nat-dict
                  scripts/nat-shell
                  scripts/nat-mkRealDict
                  scripts/nat-StarDict
                  scripts/nat-substDict
                  scripts/nat-examplesExtractor
                  scripts/nat-codify
                  scripts/nat-mkMakefile
                  scripts/nat-addDict
                  scripts/nat-makeCWB
                  scripts/nat-ngramsIdx
                  scripts/nat-create!;
  plan tests => 1 + 9 * scalar(@files);
}

## Check for scripts
my @scripts = grep {$_ !~ m!(README|~|\.in)$!} <scripts/*>;
my @missing;
my %scripts;
@scripts{@files}=@files;
for (@scripts) {
  push @missing, $_ unless exists $scripts{$_};
}
ok(!@missing, "Missing some scripts to be tested: ".join(",",@missing));

## Check each script at a time....

like(`$^X -c $_ 2>&1`, qr/syntax OK/, "$_ syntax is ok.") for @files;

for (@files) {
  m!(nat-.*)$!;
  my $script = $1;
  my $help = `$^X $_ -h 2>&1`;
  like($help, qr/^$script:/, "$_ supports help flag.");
  like($help, qr/For more help, please run 'perldoc $script'$/, "$_ mentions perldoc.");
}

for my $f (@files) {
  my $has_NAME = 0;
  my $has_AUTHOR = 0;
  my $has_SEEALSO = 0;
  my $has_SYNOPSIS = 0;
  my $has_COPYRIGHT = 0;
  my $has_DESCRIPTION = 0;


  open POD, $f;
  while(<POD>) {
    $has_NAME++ if m!^=head1 NAME!;
    $has_AUTHOR++ if m!^=head1 AUTHOR!;
    $has_SEEALSO++ if m!^=head1 SEE ALSO!;
    $has_SYNOPSIS++ if m!^=head1 SYNOPSIS!;
    $has_DESCRIPTION++ if m!^=head1 DESCRIPTION!;
    $has_COPYRIGHT++ if m!^=head1 COPYRIGHT AND LICENSE!;
  }
  close POD;

  ok($has_NAME, "$f POD includes a NAME section.");
  ok($has_AUTHOR, "$f POD includes an AUTHOR section.");
  ok($has_SEEALSO, "$f POD includes a SEE ALSO section.");
  ok($has_SYNOPSIS, "$f POD includes a SYNOPSIS section.");
  ok($has_DESCRIPTION, "$f POD includes a DESCRIPTION section.");
  ok($has_COPYRIGHT, "$f POD includes a COPYRIGHT AND LICENSE section.");
}


