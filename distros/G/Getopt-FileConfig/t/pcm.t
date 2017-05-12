#!./perl -w

BEGIN
{
  use lib '../lib';
  chdir 't';
}

use Getopt::FileConfig;
# use Data::Dumper;

print "1..6\n";

# Test import into namespaces
{
  my $cfg = new Getopt::FileConfig(-defcfg=>"pcm.rc");

  # print Dumper($cfg->{-defcfg});

  # Use this instead of ARGV
  my @A = qw(-aref pepe -aref lojz -href drek=shit -href joska=boob);
  $cfg->parse(\@A);

  # When warnings are on and config entries are used just once:
  #   use vars qw($SIMPLE $AREF $Kazaan::HREF);
  # or just, as the above does not work with perl 5.6:
  no warnings;

  print (($SIMPLE eq 'blak') ? "" : "not ", "ok 1\n");
  print (($AREF->[0] eq 'pepe') ? "" : "not ", "ok 2\n");
  print (($Kazaan::HREF->{'drek'} eq 'shit') ? "" : "not ", "ok 3\n");
}

# Test import into hash-ref
{
  my $X = {};
  my $cfg_hash = new Getopt::FileConfig(-hash=>$X,
					-defcfg=>"pcm.rc");

  # print Dumper($cfg_hash->{-defcfg});

  # Use this instead of ARGV
  my @A = qw(-aref pepe -aref lojz -href drek=shit -href joska=boob);
  $cfg_hash->parse(\@A);

  # print Dumper($X);

  print (($X->{'SIMPLE'} eq 'blak') ? "" : "not ", "ok 4\n");
  print (($X->{'AREF'}[0] eq 'pepe') ? "" : "not ", "ok 5\n");
  print (($X->{'Kazaan'}{'HREF'}{'drek'} eq 'shit') ? "" : "not ", "ok 6\n");
}
