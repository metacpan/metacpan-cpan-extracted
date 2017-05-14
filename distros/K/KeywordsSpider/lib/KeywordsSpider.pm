package KeywordsSpider;

use KeywordsSpider::Core 'find_origin';
use Modern::Perl;
use Parallel::ForkManager;

my @unwanted_params = qw/
  referer
  ref
  sesid
  hash
  ssid
/;

my $spidered_websites = 0;
my %links = ();

my $old_origin = '';
my $old_origin_domain = '^$';

my $COUNT = 0;

sub debug {
  my ($string, $debug) = @_;

  if ($debug) {
    print "$string";
  }

  return;
}

sub _normalize_url {
  my $url = shift;

  chomp($url);
  $url =~ s/^\'//g;
  $url =~ s/\'$//g;

  if($url =~ /^null$/) {
    return $url;
  };

  if ( $url !~ /http/ ) {
    $url = 'http://' . $url;
  }

  return $url;
}

sub _remove_garbage {
  my $referrer = shift;
  foreach (@unwanted_params) {
    if ( $referrer =~ /$_/ ) {
      my $temp = $_;
      $referrer =~ s/${temp}=.*&//g;
      $referrer =~ s/${temp}=.*$//g;
    }
  }

  #probably a hash
  $referrer =~ s/=.{32}&/=&/g;
  $referrer =~ s/=.{32}$/=/g;

  return $referrer;
}

sub _get_domain {
  my $domain = shift;

  $domain =~ s/http(s)?:\/\///;
  $domain =~ s/\'//g;
  $domain =~ s/www\.//;
  $domain =~ s/\/.*$//;

  return $domain;
}

sub _match_referrer {
  my ($referrer, $website, $skip_ref_regexp, $fh) = @_;

  if ( $referrer !~ /${skip_ref_regexp}/ ) {
    $referrer = _remove_garbage($referrer);

    $links{$referrer} = { depth => 0 };

    my $domain = _get_domain($website);

    if ( $referrer !~ /$domain/i ) {
      print $fh "NOT matching referrer=$referrer, website=$website\n";
    }
  }
}

sub _get_initial_origin_domain {
  my ($line) = @_;

  my ($website) = split(/,/, $line);

  $website = _normalize_url($website);
  my($origin, $origin_domain) = find_origin($website);

  return $origin_domain;
}

sub load_keywords {
  my($keyfile) = shift;

  open KEYWORDS, "<$keyfile" or die "problem opening file \'$keyfile\' for reading\n$!";
  my @keywords = <KEYWORDS>;
  close(KEYWORDS);

  foreach (@keywords) {
    $_ =~ s/[\r\n]+//g;
  }

  return @keywords;
}

my $pm = Parallel::ForkManager->new(10);
$pm->run_on_finish( sub {
    my ($pid, $exit_code) = @_;
    $COUNT += $exit_code;
});

sub run {
  my %args = @_;

  my $skip_ref_regexp = $args{skip_ref_regexp} // '^null$';
  my $infile = $args{infile} // 'export';
  my $outfile = $args{outfile} // 'output.log';
  my $keyfile = $args{keyfile} // 'keywords';
  my $allowed_keywords_file = $args{allowed_keywords} // '';
  my $debug = $args{debug};
  my $web_depth = $args{web_depth};

  open FILE, "<$infile" or die "problem opening file \'$infile\' for reading\n$!";
  my @input = <FILE>;
  close(FILE);

  my @keywords = load_keywords($keyfile);

  my @allowed_keywords_arr;
  if ($allowed_keywords_file) {
    @allowed_keywords_arr = load_keywords($allowed_keywords_file);
  }

  my %allowed_keywords = map { $_ => 1 } @allowed_keywords_arr;

  my $fh;
  open $fh, ">$outfile" or die "problem opening file \'$outfile\' for writing\n$!";
  select($fh);
  $| = 1;
  binmode $fh, ":utf8";

  select(STDOUT);
  binmode STDOUT, ":utf8";

  my $db_records_amount = scalar @input;

  my $first_line = $input[0];
  $old_origin_domain = _get_initial_origin_domain($first_line);

  foreach (@input) {
    my ($website, $referrer) = split(/,/, $_);

    print $fh "DB: $website $referrer\n";

    $website = _normalize_url($website);
    $referrer = _normalize_url($referrer);

    my ($origin, $origin_domain) = find_origin($website);

    if ( $origin_domain !~ /^${old_origin_domain}$/i ) {
      $spidered_websites++;

      $pm->start and goto CONTINUE;

      my $spider = KeywordsSpider::Core->new(
        output_file => $fh,
        links => \%links,
        keywords => \@keywords,
        allowed_keywords => \%allowed_keywords,
        debug_enabled => $debug,
        web_depth => $web_depth,
      );
      my $count = $spider->spider_links();

      $pm->finish($count);

CONTINUE:
      %links = ();
    }

    if ($website =~ / /) {
      foreach my $website_to_add (split(/ /, $website)) {
        $website_to_add = _normalize_url($website_to_add);
        $links{$website_to_add} = { depth => 0, want_spider => 1 };
      }
    }
    else {
      $links{$website} = { depth => 0, want_spider => 1 };
    }
    debug("\n", $debug);

    _match_referrer($referrer, $website, $skip_ref_regexp, $fh);

    $old_origin = $origin;
    $old_origin_domain = $origin_domain;
  }

  $spidered_websites++;
  $pm->start and goto END;

  my $spider = KeywordsSpider::Core->new(
    output_file => $fh,
    links => \%links,
    keywords => \@keywords,
    allowed_keywords => \%allowed_keywords,
    debug_enabled => $debug,
    web_depth => $web_depth,
  );
  my $count = $spider->spider_links();

  $pm->finish($count);

END:
  debug("waiting for children\n", $debug);
  $pm->wait_all_children;

  print $fh "number of DB records: $db_records_amount\n";
  print $fh "number of spidered websites: $spidered_websites\n";
  print $fh "number of alerted websites: $COUNT\n";

  close($fh);
}

1;


=head1 NAME

KeywordsSpider - web spider searching for keywords

=head1 SYNOPSIS

  use KeywordsSpider;
  KeywordsSpider::run(
    outfile => "output_test",
    infile => "export.sql",
    keyfile => "keywords_new",
    debug => 1,
    skip_ref_regexp => "(^http://trala|^null|twig.html\$)",
    allowed_keywords => "allowed_keywords",
    web_depth => 5
  );

=head1 DESCRIPTION

KeywordsSpider is web spider, which takes urls and keywords from file and outputs urls matching the keywords to another file.

Referers can be specified in input file. Their domain is matched to website's domain.

It spiders in 10 parallel processes.
It takes files as arguments and prepares attributes for KeywordsSpider::Core.


=head1 ARGUMENTS

=over 4

=item infile

file with website and referer urls within. Like:

  'domain.sk/twig.html','null'
  domain.sk,domain2.sk
  another-domain.sk/twig.html,null
  another-domain.sk/twig.html,http://trala.sk

no space after comma, apostrophes not necessary

=item keyfile

file with newline separates keywords. Like:

  word1
  wuord2
  wiaord3

=item allowed_keywords

file with newline separated keywords, which do not trigger ALERT to output file. Like:

  wuord2

=item outfile

output file

=item debug

do you want debug to standard output ? It's turned off by default.

=item skip_ref_regexp

you can specify various referers for the same website. If you don't want to crawl specific domain,
or any part of url, you put the regular expression here. Like:

  (^http://trala|^null|twig.html\$)

=back

=head1 METHODS

=over 4

=item run ARGS

runs

=back

=head1 SEE ALSO

L<KeywordsSpider::Core> -- core spidering and matching module

=head1 COPYRIGHT

Copyright 2013 Katarina Durechova

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
