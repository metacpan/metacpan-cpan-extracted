package Finance::Edgar;

use strict;
use vars qw(@EXPORT_OK $VERSION $DEBUG);

use LWP 5.64;

@EXPORT_OK = qw(match_ciks);
$VERSION   = "0.01"; # $Date: 2003/01/02 20:24:08 PST $
$DEBUG     = 0;

sub cli {
  print "Company search term: ";
    my $cnm = <STDIN>;
    chomp $cnm;
  my %cik = &match_ciks($cnm);
  my $cik = &ppick_cik(\%cik);
  my @lss = &list_filings($cik);
  my $frc = &cl_pick(\@lss);
  my $fdt = &get_filing($frc);
}

sub match_ciks {
  my $browser = LWP::UserAgent->new;
  my $url = 'http://www.sec.gov/cgi-bin/cik.pl.c';
  my $company_name = shift;
print "Searching for $company_name ...\n";

  my $response = $browser->post( $url, ['company' => $company_name] );
    die "Can't get $url -- ", $response->status_line
     unless $response->is_success;
    die "Hey, I was expecting HTML, not ", $response->content_type
     unless $response->content_type eq 'text/html';

  my %c;
  foreach (split /\n/, $response->content) {
    if(m/([0-9]+)   ([A-Z][A-Z ]+[A-Z])/) {
      $c{$1} = $2;
    }
  }

  return %c;
}

sub ppick_cik {
  my $browser = LWP::UserAgent->new;
  my $cikr = shift;
  my $cki;
  my %ck;
  my $i = 0;
  foreach (keys %$cikr) {
    $ck{++$i} = $_;
    print "$i: $cikr->{$_} ($_)\n";
  }
  if ($i > 1) {
    print "\nPlease select one of the above CIKs: ";
    $cki = <STDIN>;
    chomp $cki;
  } else { $cki = 1 }
  return $ck{$cki};
}

sub list_filings {
  my $browser = LWP::UserAgent->new;
  my $cik = shift;
  my $url = "http://www.sec.gov/cgi-bin/browse-edgar?company=&CIK=$cik"
               . "&State=&SIC=&action=getcompany";
  my $response = $browser->get( $url );
    die "Can't get $url -- ", $response->status_line
     unless $response->is_success;
    die "Hey, I was expecting HTML, not ", $response->content_type
     unless $response->content_type eq 'text/html';
  my @listing = ({'Filing' => 0,'Date' => 1,'Descr' => 2,'Path_txt' => 3,
                    'Path_html' => 4});
  my @tag; my $path_txt; my $path_html; my $fi_type; my $fi_descr; my $fi_date;
  my $ls_html = $response->content;
  $ls_html =~ s!</?[bi]>!!ig;
  foreach (split(/<\/tr>/, $ls_html)) {
    @tag = split(/>\s*</, $_);
    if(defined($tag[6]) && ($tag[6] =~ m/href=\"(.+)\">\[text\]/)) {
      $path_txt = $1;
      if($tag[2] =~ m/href=\"(.+)\">([^<]+)</) {
        $path_html = $1;
        $fi_type   = $2;
      } else { print "!!! #2 !~ $tag[2]\n"; }
      if($tag[9] =~ m/>(\d+-\d+-\d+)</) {
        $fi_date = $1;
      } else { print "!!! #9 !~ $tag[9]\n"; }
      if($tag[8] =~ m/>([^<]+)</) {
        $fi_descr= $1;
      } else { print "!!! #8 !~ $tag[8]\n"; }
      push @listing, [$fi_type,$fi_date,$fi_descr,$path_txt,$path_html];
    }
  }
  return(@listing);
}

sub cl_pick {
  my $oplist = shift;
  my $i = 0; my $selection = 0;
  foreach (@$oplist) {
    if(0<$i++){
      print --$i .": $_->[0], $_->[1] ($_->[2])\n"; $i++;
    }
  }
  if ($i > 1) {
    print "\nPlease enter the number of your choice: ";
    $selection = <STDIN>; chomp $selection;
  } else { $selection = 1 }
  return $oplist->[$selection];
}

sub get_filing {
  my $browser = LWP::UserAgent->new;
  my $fr  = shift;
  my $url = "http://www.sec.gov" . $fr->[3];
print "Downloading $fr->[3]...\n";
  my $response = $browser->get( $url );
    die "Can't get $url -- ", $response->status_line
     unless $response->is_success;
    die "Hey, I was expecting TEXT, not ", $response->content_type
     unless $response->content_type eq 'text/plain';
  open (FILING, ">$fr->[0].txt");
  print FILING  $response->content;
  return($response->content);
}

1;

__END__
