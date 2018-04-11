#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Differences;
use Data::Dumper::OneLine qw/Dumper/;
use DateTime;

BEGIN {
    use_ok( 'MarpaX::ESLIF::URI' ) || print "Bail out!\n";
}

my $DateTime1999     = DateTime->new(year => '1999',                             time_zone => 'UTC');
my $DateTime2001     = DateTime->new(year => '2001',                             time_zone => 'UTC');
my $DateTime2002     = DateTime->new(year => '2002',                             time_zone => 'UTC');
my $DateTime200405   = DateTime->new(year => '2004', month => '05',              time_zone => 'UTC');
my $DateTime20010915 = DateTime->new(year => '2001', month => '09', day => '15', time_zone => 'UTC');
my %DATA =
  (
   #
   # Adapted from http://www.faqs.org/rfcs/rfc4151.html
   #
   "tAg:timothy\@hpl.hp.COM,2001:web/external%25Home" => {
       scheme    => { origin => "tAg",                                       decoded => "tAg",                                        normalized => "tag" },
       entity    => { origin => "timothy\@hpl.hp.COM,2001",                  decoded => "timothy\@hpl.hp.COM,2001",                   normalized => "timothy\@hpl.hp.com,2001"},
       authority => { origin => "timothy\@hpl.hp.COM",                       decoded => "timothy\@hpl.hp.COM",                        normalized => "timothy\@hpl.hp.com"},
       date      => { origin => "$DateTime2001",                             decoded => "$DateTime2001",                              normalized => "$DateTime2001"},
       year      => { origin => '2001',                                      decoded => '2001',                                       normalized => '2001'},
       month     => { origin => undef,                                       decoded => undef,                                        normalized => undef},
       day       => { origin => undef,                                       decoded => undef,                                        normalized => undef},
       dnsname   => { origin => undef,                                       decoded => undef,                                        normalized => undef},
       email     => { origin => "timothy\@hpl.hp.COM",                       decoded => "timothy\@hpl.hp.COM",                        normalized => "timothy\@hpl.hp.com"},
       host      => { origin => undef,                                       decoded => undef,                                        normalized => undef },
       path      => { origin => "web/external%25Home",                       decoded => "web/external%Home",                          normalized => "web/external%25Home" },
   },
   "tag:sandro\@w3.org,2004-05:Sandro" => {
       scheme    => { origin => "tag",                                       decoded => "tag",                                        normalized => "tag" },
       entity    => { origin => "sandro\@w3.org,2004-05",                    decoded => "sandro\@w3.org,2004-05",                     normalized => "sandro\@w3.org,2004-05"},
       authority => { origin => "sandro\@w3.org",                            decoded => "sandro\@w3.org",                             normalized => "sandro\@w3.org"},
       date      => { origin => "$DateTime200405",                           decoded => "$DateTime200405",                            normalized => "$DateTime200405"},
       year      => { origin => '2004',                                      decoded => '2004',                                       normalized => '2004'},
       month     => { origin => '05',                                        decoded => '05',                                         normalized => '05'},
       day       => { origin => undef,                                       decoded => undef,                                        normalized => undef},
       dnsname   => { origin => undef,                                       decoded => undef,                                        normalized => undef},
       email     => { origin => "sandro\@w3.org",                            decoded => "sandro\@w3.org",                             normalized => "sandro\@w3.org"},
       host      => { origin => undef,                                       decoded => undef,                                        normalized => undef },
       path      => { origin => "Sandro",                                    decoded => "Sandro",                                     normalized => "Sandro" },
   },
   "tag:my-ids.Com,2001-09-15:TimKindberg:presentations:UBath2004-05-19" => {
       scheme    => { origin => "tag",                                       decoded => "tag",                                        normalized => "tag" },
       entity    => { origin => "my-ids.Com,2001-09-15",                     decoded => "my-ids.Com,2001-09-15",                      normalized => "my-ids.Com,2001-09-15"},
       authority => { origin => "my-ids.Com",                                decoded => "my-ids.Com",                                 normalized => "my-ids.Com"},
       date      => { origin => "$DateTime20010915",                         decoded => "$DateTime20010915",                          normalized => "$DateTime20010915"},
       year      => { origin => '2001',                                      decoded => '2001',                                       normalized => '2001'},
       month     => { origin => '09',                                        decoded => '09',                                         normalized => '09'},
       day       => { origin => '15',                                        decoded => '15',                                         normalized => '15'},
       dnsname   => { origin => "my-ids.Com",                                decoded => "my-ids.Com",                                 normalized => "my-ids.Com"},
       email     => { origin => undef,                                       decoded => undef,                                        normalized => undef},
       host      => { origin => undef,                                       decoded => undef,                                        normalized => undef },
       path      => { origin => "TimKindberg:presentations:UBath2004-05-19", decoded => "TimKindberg:presentations:UBath2004-05-19",  normalized => "TimKindberg:presentations:UBath2004-05-19" },
   },
   "tag:blogger.com,1999:blog-555" => {
       scheme    => { origin => "tag",                                       decoded => "tag",                                        normalized => "tag" },
       entity    => { origin => "blogger.com,1999",                          decoded => "blogger.com,1999",                           normalized => "blogger.com,1999"},
       authority => { origin => "blogger.com",                               decoded => "blogger.com",                                normalized => "blogger.com"},
       date      => { origin => "$DateTime1999",                             decoded => "$DateTime1999",                              normalized => "$DateTime1999"},
       year      => { origin => '1999',                                      decoded => '1999',                                       normalized => '1999'},
       month     => { origin => undef,                                       decoded => undef,                                        normalized => undef},
       day       => { origin => undef,                                       decoded => undef,                                        normalized => undef},
       dnsname   => { origin => "blogger.com",                               decoded => "blogger.com",                                normalized => "blogger.com"},
       email     => { origin => undef,                                       decoded => undef,                                        normalized => undef},
       host      => { origin => undef,                                       decoded => undef,                                        normalized => undef },
       path      => { origin => "blog-555",                                  decoded => "blog-555",                                   normalized => "blog-555" },
   },
   "tag:yaml.org,2002:int" => {
       scheme    => { origin => "tag",                                       decoded => "tag",                                        normalized => "tag" },
       entity    => { origin => "yaml.org,2002",                             decoded => "yaml.org,2002",                              normalized => "yaml.org,2002"},
       authority => { origin => "yaml.org",                                  decoded => "yaml.org",                                   normalized => "yaml.org"},
       date      => { origin => "$DateTime2002",                             decoded => "$DateTime2002",                              normalized => "$DateTime2002"},
       year      => { origin => '2002',                                      decoded => '2002',                                       normalized => '2002'},
       month     => { origin => undef,                                       decoded => undef,                                        normalized => undef},
       day       => { origin => undef,                                       decoded => undef,                                        normalized => undef},
       dnsname   => { origin => "yaml.org",                                  decoded => "yaml.org",                                   normalized => "yaml.org"},
       email     => { origin => undef,                                       decoded => undef,                                        normalized => undef},
       host      => { origin => undef,                                       decoded => undef,                                        normalized => undef },
       path      => { origin => "int",                                       decoded => "int",                                        normalized => "int" },
   },
  );

foreach my $origin (sort keys %DATA) {
  my $uri = MarpaX::ESLIF::URI->new($origin);
  isa_ok($uri, 'MarpaX::ESLIF::URI::tag', "\$uri = MarpaX::ESLIF::URI->new('$origin')");
  my $methods = $DATA{$origin};
  foreach my $method (sort keys %{$methods}) {
    foreach my $type (sort keys %{$methods->{$method}}) {
      my $got = $uri->$method($type);
      my $expected = $methods->{$method}->{$type};
      my $test_name = "\$uri->$method('$type')";
      if (ref($expected)) {
        eq_or_diff($got, $expected, "$test_name is " . (defined($expected) ? Dumper($expected) : "undef"));
      } else {
        is(defined($got) ? "$got" : undef, defined($expected) ? "$expected" : undef, "$test_name is " . (defined($expected) ? "'$expected'" : "undef"));
      }
    }
  }
}

done_testing();
