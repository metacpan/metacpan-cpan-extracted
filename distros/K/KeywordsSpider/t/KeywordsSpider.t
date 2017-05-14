use KeywordsSpider;
use Test::Spec;

describe "KeywordsSpider" => sub {
  it "loads ok" => sub {
    pass;
  };

  #spider will consider websites alerted
  local *KeywordsSpider::Core::spider_links;
  *KeywordsSpider::Core::spider_links = sub {return 1;};

  KeywordsSpider::run(
    outfile => "t/output_test",
    infile => "t/export_test",
    keyfile => "t/keywords_test",
    debug => 1,
    skip_ref_regexp => "(^http://trala.sk|^null\$|twig.html\$)",
    allowed_keywords => "t/allowed_test",
    web_depth => 5,
  );

  open FILE, "<t/output_test" || die "can not open testing file";

  # read file to scalar
  local $/;
  my $output = <FILE>;
  close(FILE);

  it "detects domain not matching referrer" => sub {
    like($output,
      qr/NOT matching referrer=http:\/\/domain2.sk, website=http:\/\/domain.sk/
    );
  };

  it "does not match referrer=null" => sub {
    unlike($output,
      qr/NOT matching referrer=null/
    );
  };

  it "does not match referrer which matches skip_ref_regexp" => sub {
    unlike($output,
      qr/NOT matching referrer=http:\/\/trala.sk/
    );
  };

  it "counts unique website domains" => sub {
    like($output,
      qr/spidered websites: 2/
    );
  };

  it "counts alerted websites" => sub {
    like($output,
      qr/alerted websites: 2/
    );
  };
};

runtests;
