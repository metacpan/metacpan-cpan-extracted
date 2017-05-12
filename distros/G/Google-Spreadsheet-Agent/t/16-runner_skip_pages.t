use FindBin;
use Test::More;
use Google::Spreadsheet::Agent;
use Google::Spreadsheet::Agent::Runner;

my $initialize = {
        ready => 1,
        skippage => undef
};

my $conf_file = $FindBin::Bin.'/../config/agent.conf.yml';
if (-e $conf_file) {
  plan( tests => 15 );
}
else {
  plan( 
    skip_all => 'You must create a valid test Google Spreadsheet and a valid '
                .$conf_file
                .' configuration file pointing to it to run the tests. See README.txt file for more information on how to run the tests.'
      );
}

my $testing_skippage_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'skippage',
                  page_name => 'testing',
                  bind_key_fields => {'testentry' => 'testing.skippagetest'}
);

my $skip_page_skippage_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'skippage',
                  page_name => 'skip_page',
                  bind_key_fields => {'testentry' => 'skip_page.skippagetest'}
);

my $only_page_skippage_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'skippage',
                  page_name => 'only_page',
                  bind_key_fields => {'testentry' => 'only_page.skippagetest'}
);

my $page_rows = {
                  testing => {
                               header => ['testentry','ready', 'skippage'],
                               rows => [
                                         { testentry => 'testing.skippagetest', ready => 1 }
                                       ]
                             },
                  skip_page => {
                               header => ['testentry','ready', 'skippage'],
                               rows => [
                                         { testentry => 'skip_page.skippagetest', ready => 1 }
                                       ]
                             },
                  only_page => {
                               header => ['testentry','ready', 'skippage'],
                               rows => [
                                         { testentry => 'only_page.skippagetest', ready => 1 }
                                       ]
                             },
};

setup_pages($page_rows);

my $agent_runner = Google::Spreadsheet::Agent::Runner->new(
     skip_pages => ['skip_page']
);

my $agent_script = $FindBin::Bin.'/../agent_bin/skippage_agent.pl';

`chmod 700 ${agent_script}`;
if ($?) {
    die "Could not chmod $agent_script $!\n";
}

$agent_runner->run;
ok($testing_skippage_test_agent->get_entry()->content->{skippage}, 'testing.skippagetest.skippage should be true');
ok(!$skip_page_skippage_test_agent->get_entry()->content->{skippage}, 'skip_page.skippagetest.skippage should not be true');
ok($only_page_skippage_test_agent->get_entry()->content->{skippage}, 'only_page.skippagetest.skippage should be true');

sleep 5;

$testing_skippage_test_agent->get_entry()->param($initialize);
$skip_page_skippage_test_agent->get_entry()->param($initialize);
$only_page_skippage_test_agent->get_entry()->param($initialize);

$agent_runner->skip_pages(['skip_page','testing']);
$agent_runner->run;
ok(!$testing_skippage_test_agent->get_entry()->content->{skippage}, 'testing.skippagetest.skippage should be not true');
ok(!$skip_page_skippage_test_agent->get_entry()->content->{skippage}, 'skip_page.skippagetest.skippage should not be true');
ok($only_page_skippage_test_agent->get_entry()->content->{skippage}, 'only_page.skippagetest.skippage should be true');

sleep 5;

$testing_skippage_test_agent->get_entry()->param($initialize);
$skip_page_skippage_test_agent->get_entry()->param($initialize);
$only_page_skippage_test_agent->get_entry()->param($initialize);

$agent_runner->no_skip_pages;
$agent_runner->run;
ok($testing_skippage_test_agent->get_entry()->content->{skippage}, 'testing.skippagetest.skippage should be true after no_skip_page');
ok($skip_page_skippage_test_agent->get_entry()->content->{skippage}, 'skip_page.skippagetest.skippage should be true after no_skip_page');
ok($only_page_skippage_test_agent->get_entry()->content->{skippage}, 'only_page.skippagetest.skippage should be true after no_skip_page');

sleep 5;

$testing_skippage_test_agent->get_entry()->param($initialize);
$skip_page_skippage_test_agent->get_entry()->param($initialize);
$only_page_skippage_test_agent->get_entry()->param($initialize);

$agent_runner->skip_pages_if(sub {
  my $page = shift;
  return 1 if ($page->title =~ m/page$/);
  return undef;
});

$agent_runner->run;
ok($testing_skippage_test_agent->get_entry()->content->{skippage}, 'testing.skippagetest.skippage should be true after skip_pages_if');
ok(!$skip_page_skippage_test_agent->get_entry()->content->{skippage}, 'skip_page.skippagetest.skippage should not be true after skip_pages_if');
ok(!$only_page_skippage_test_agent->get_entry()->content->{skippage}, 'only_page.skippagetest.skippage should not be true after skip_pages_if');

sleep 5;

$testing_skippage_test_agent->get_entry()->param($initialize);
$skip_page_skippage_test_agent->get_entry()->param($initialize);
$only_page_skippage_test_agent->get_entry()->param($initialize);

$agent_runner->no_skip_pages_if;
$agent_runner->run;
ok($testing_skippage_test_agent->get_entry()->content->{skippage}, 'testing.skippagetest.skippage should be true after no_skip_pages_if');
ok($skip_page_skippage_test_agent->get_entry()->content->{skippage}, 'skip_page.skippagetest.skippage should be true after no_skip_pages_if');
ok($only_page_skippage_test_agent->get_entry()->content->{skippage}, 'only_page.skippagetest.skippage should be true after no_skip_pages_if');

`chmod 600 ${agent_script}`;
if ($?) {
    die "Could not chmod $agent_script $!\n";
}
cleanup_pages($page_rows);
exit;

sub cleanup_pages {
  my $page_def = shift;
  my %page_rows = %{$page_def};

  my $colnum = 1;
  my @header_cells;
  foreach my $page_name (keys %page_rows) {
    if ($page_name eq 'testing') {
      my $page = $testing_skippage_test_agent->google_db->worksheet({title => $page_name});
      foreach my $row ($page->rows) {
        $row->delete;
      }

      foreach my $header_val (@{ $page_rows{$page_name}->{header} }) {
        push @header_cells, {col => $colnum++, row => 1, input_value => ''};
      }
      $page->batchupdate_cell(@header_cells);
    }
    else {
      $testing_skippage_test_agent->google_db->worksheet({title => $page_name})->delete;
    }
  }
}

sub setup_pages {
  my $page_def = shift;
  my %page_rows = %{$page_def};

  foreach my $page_name (keys %page_rows) {
    my $page;
    if ($page_name eq 'testing') {
      $page = $testing_skippage_test_agent->google_db->worksheet({title=>$page_name});
      die "You must create a google spreadsheet with a testing page in it for these tests to work with.  See README.txt file for more information\n" unless($page);
    } 
    else { 
      $page = $testing_skippage_test_agent->google_db->add_worksheet({
           'title' => $page_name,
           'col_count' => scalar(@{ $page_rows{$page_name}->{header} }),
           'row_count' => scalar(@{ $page_rows{$page_name}->{rows} })
      });
    }

    my $colnum = 1;
    my @header_cells = ();
    foreach my $header_val (@{ $page_rows{$page_name}->{header} }) {
      push @header_cells, {col => $colnum++, row => 1, input_value => $header_val};
    }
    $page->batchupdate_cell(@header_cells);

    foreach my $row (@{ $page_rows{$page_name}->{rows} }) {
      $page->add_row($row);
    }
  }
}
