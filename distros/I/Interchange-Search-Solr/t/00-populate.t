#!perl

use strict;
use warnings;
use Interchange::Search::Solr;
use Interchange::Search::Solr::UpdateIndex;
use File::Spec;
use YAML qw/LoadFile/;
use Data::Dumper;
use Test::More;
use DateTime;

my ($solr, $ui);
if (my $solr_url = $ENV{SOLR_TEST_URL}) {
    diag "Using solr instance at $solr_url";
    $solr = Interchange::Search::Solr->new(
                                           solr_url => $solr_url,
                                          );
    $ui = Interchange::Search::Solr::UpdateIndex->new(url => $solr_url);
}
else {
    my $doc = <<'DOC';
Test can run only if there is a test solr instance running. Tests are
going to clear up the existing node, store some data, and test some searches.

Download the tarball from http://lucene.apache.org/solr/ and unpack it
in /opt/, symlinking it to /opt/solr.

Then symlink /opt/solr/bin/solr to /usr/local/bin/solr.

This is going to give you a solr executable in your $PATH.

So create a dedicated directory under $HOME and do:

 mkdir -p $HOME/solr/{solr,pids,logs}
 cp /opt/solr/server/solr/solr.xml $HOME/solr/solr
 export SOLR_LOGS_DIR=$HOME/solr/logs
 export SOLR_PID_DIR=$HOME/solr/pids
 export SOLR_HOME=$HOME/solr/solr
 export SOLR_PORT=9999
 solr start
 solr status

Then create a core:

 solr create_core -c icsearch -d sample_techproducts_configs -p 9999

Copy the example/schema.xml found in this distribution to
$HOME/solr/solr/icsearch/conf/schema.xml

 cp examples/schema.xml $HOME/solr/solr/icsearch/conf/schema.xml
 solr restart

And export SOLR_TEST_URL with the path:

 export SOLR_TEST_URL=http://localhost:9999/solr/icsearch

Beware that 9999 is now exposed to the internet, so firewall that.

DOC
    diag $doc;
    plan skip_all => "Please set environment variable SOLR_TEST_URL.";
}

my $data = LoadFile(File::Spec->catfile(qw/examples data.yaml/));
my $days = 0;
foreach my $doc (@$data) {
    my $now = DateTime->now;
    $doc->{created_date} = $now . 'Z';
    $now->add(days => ++$days);
    $doc->{updated_date} = $now . 'Z';
}
# print Dumper($data);
ok $solr;
$solr->maintainer_update('clear');
my $res = $solr->maintainer_update(add => $data);
if ($res->solr_status) {
    die "Failed to update Solr index for " . Dumper($data)
      . $res->{content}->{error}->{msg} . "\n";
}

done_testing;


