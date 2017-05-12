#!/usr/bin/env perl -w

use strict;
use Test::More;
use MIME::Lite;
use MIME::Lite::HTML;
use Cwd;
{
  require URI::URL;
  URI::URL->strict(1);
}


# For create ref file, use perl -Iblib/lib t/50generic.t 1

my $t = "/var/tmp/mime-lite-html-tests";
my $p = cwd;

my $o=(system("ln -s $p/t $t")==0);
my @files_to_test = glob("$t/docs/*.html");
if ($o) {  plan tests => (($#files_to_test+1)* 9 * 3)+1; }
else { plan skip_all => "Error on link ".$p."/t!"; }

foreach my $it ('cid', 'location', 'extern') {
  foreach my $f (@files_to_test) {
    my $ref = $f;
    $ref=~s/\.html/\.eml\.$it/; $ref=~s/docs\//ref\//;
    my $mailHTML = new MIME::Lite::HTML
      (
       From     => 'MIME-Lite@alianwebserver.com',
       To       => 'MIME-Lite@alianwebserver.com',
       Subject  => 'Mail in HTML with images',
       Debug    => 1,
       IncludeType => $it
      );
    my $url_file = "file://$f";
    print $url_file,"\n";
    my $rep = $mailHTML->parse($url_file, "A text message");
    $rep = $rep->as_string;
    $rep =~s/^Date: .*$//gm;
    my @bound;
    while ($rep=~m!boundary="(.*)"!gm) { push(@bound, $1);  }
    foreach (@bound) { $rep=~s/$_/alian-mime-lite-html/g; }

    if (!$ARGV[0]) {
      open(PROD,">$f.created_by_test")
	or die "Can't create $f.created_by_test:$!";
      print PROD $rep;
      close(PROD);
    my $r = `diff $ref $f.created_by_test`;
      cmp_ok($mailHTML->size, ">", (stat($ref))[7], "Same size");
      cmp_ok($mailHTML->size*0.945, "<", (stat($ref))[7], "Same size");
      is($r, "", $ref);
      unlink("$f.created_by_test");
    }
    # for create ref file
    elsif ($ARGV[0]) {
      ok(open(F,">$ref"),"Create $ref");
      print F $rep;
      close(F);
    }
  }
}

foreach my $it ('cid', 'location', 'extern') {
  foreach my $f (@files_to_test) {
    my $ref = $f;
    $ref=~s/\.html/\.eml2\.$it/; $ref=~s/docs\//ref\//;
    my $mailHTML = new MIME::Lite::HTML
      (
       From     => 'MIME-Lite@alianwebserver.com',
       To       => 'MIME-Lite@alianwebserver.com',
       Subject  => 'Mail in HTML with images',
       Debug    => 1,
       IncludeType => $it
      );
    my $url_file = "file://$f";
    print $url_file,"\n";
    my $rep = $mailHTML->parse($url_file);
    $rep = $rep->as_string;
    $rep =~s/^Date: .*$//gm;
    my @bound;
    while ($rep=~m!boundary="(.*)"!gm) { push(@bound, $1);  }
    foreach (@bound) { $rep=~s/$_/alian-mime-lite-html/g; }

    if (!$ARGV[0]) {
      open(PROD,">$f.created_by_test")
	or die "Can't create $f.created_by_test:$!";
      print PROD $rep;
      close(PROD);
    my $r = `diff $ref $f.created_by_test`;
      cmp_ok($mailHTML->size, ">", (stat($ref))[7], "Same size");
      cmp_ok($mailHTML->size*0.945, "<", (stat($ref))[7], "Same size");
      is($r, "", $ref);
      unlink("$f.created_by_test");
    }
    # for create ref file
    elsif ($ARGV[0]) {
      ok(open(F,">$ref"),"Create $ref");
      print F $rep;
      close(F);
    }
  }
}

foreach my $it ('cid', 'location', 'extern') {
  foreach my $f (@files_to_test) {
    my $ref = $f;
    $ref=~s/\.html/\.eml3\.$it/; $ref=~s/docs\//ref\//;
    my $mailHTML = new MIME::Lite::HTML
      (
       From     => 'MIME-Lite@alianwebserver.com',
       To       => 'MIME-Lite@alianwebserver.com',
       Subject  => 'Mail in HTML with images',
       Debug    => 1,
       IncludeType => $it
      );
    my $url_file = "file://$f";
    print $url_file,"\n";
    my $rep = $mailHTML->parse($url_file, 'file://'.$t.'/docs/Readme.txt');
#    print $mailHTML->errstr;
    $rep = $rep->as_string;
    $rep =~s/^Date: .*$//gm;
    my @bound;
    while ($rep=~m!boundary="(.*)"!gm) { push(@bound, $1);  }
    foreach (@bound) { $rep=~s/$_/alian-mime-lite-html/g; }

    if (!$ARGV[0]) {
      open(PROD,">$f.created_by_test")
	or die "Can't create $f.created_by_test:$!";
      print PROD $rep;
      close(PROD);
    my $r = `diff $ref $f.created_by_test`;
      cmp_ok($mailHTML->size, ">", (stat($ref))[7], "Same size");
      cmp_ok($mailHTML->size*0.945, "<", (stat($ref))[7], "Same size");
      is($r, "", $ref);
      unlink("$f.created_by_test");
    }
    # for create ref file
    elsif ($ARGV[0]) {
      ok(open(F,">$ref"),"Create $ref");
      print F $rep;
      close(F);
    }
  }
}

my $mailHTML = new MIME::Lite::HTML
  (
   From     => 'MIME-Lite@alianwebserver.com',
   To       => 'MIME-Lite@alianwebserver.com',
   Subject  => 'Mail in HTML with images',
   Debug    => 1,
  );

my %vars = ( 'perl' => 'fast', 'lng' => 'Ruby');
cmp_ok($mailHTML->fill_template('Perl is <? $perl ?>, <? $lng ?> suck',\%vars),
       'eq', 'Perl is fast, Ruby suck',"Call of fill_template do his job");
unlink($t);
