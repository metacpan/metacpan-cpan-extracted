use FindBin;
use Test::More;
use Google::Spreadsheet::Agent;
use Google::Spreadsheet::Agent::Runner;

my $initialize = {
        ready => 1,
        onlypage => undef
};

my $cleanup = {
      ready => undef,
      onlypage => undef
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

my $testing_onlypage_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'onlypage',
                  page_name => 'testing',
                  bind_key_fields => {'testentry' => 'testing.onlypagetest'}
);

my $skip_page_onlypage_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'onlypage',
                  page_name => 'skip_page',
                  bind_key_fields => {'testentry' => 'skip_page.onlypagetest'}
);

my $only_page_onlypage_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'onlypage',
                  page_name => 'only_page',
                  bind_key_fields => {'testentry' => 'only_page.onlypagetest'}
);

my $page_rows = {
                  testing => {
                               header => ['testentry','ready', 'onlypage'],
                               rows => [
                                         { testentry => 'testing.onlypagetest', ready => 1 }
                                       ]
                             },
                  skip_page => {
                               header => ['testentry','ready', 'onlypage'],
                               rows => [
                                         { testentry => 'skip_page.onlypagetest', ready => 1 }
                                       ]
                             },
                  only_page => {
                               header => ['testentry','ready', 'onlypage'],
                               rows => [
                                         { testentry => 'only_page.onlypagetest', ready => 1 }
                                       ]
                             },
};

setup_pages($page_rows);

my $agent_runner = Google::Spreadsheet::Agent::Runner->new(
     only_pages => ['testing','only_page']
);

my $agent_script = $FindBin::Bin.'/../agent_bin/onlypage_agent.pl';

`chmod 700 ${agent_script}`;
if ($?) {
    die "Could not chmod $agent_script $!\n";
}

$agent_runner->run;
ok($testing_onlypage_test_agent->get_entry()->content->{onlypage}, 'testing.onlypagetest.onlypage should be true');
ok(!$skip_page_onlypage_test_agent->get_entry()->content->{onlypage}, 'skip_page.onlypagetest.onlypage should not be true');
ok($only_page_onlypage_test_agent->get_entry()->content->{onlypage}, 'only_page.onlypagetest.onlypage should be true');

sleep 5;
$testing_onlypage_test_agent->get_entry()->param($initialize);
$skip_page_onlypage_test_agent->get_entry()->param($initialize);
$only_page_onlypage_test_agent->get_entry()->param($initialize);

$agent_runner->only_pages(['only_page']);
$agent_runner->run;
ok(!$testing_onlypage_test_agent->get_entry()->content->{onlypage}, 'testing.onlypagetest.onlypage should be not true');
ok(!$skip_page_onlypage_test_agent->get_entry()->content->{onlypage}, 'skip_page.onlypagetest.onlypage should not be true');
ok($only_page_onlypage_test_agent->get_entry()->content->{onlypage}, 'only_page.onlypagetest.onlypage should be true');

sleep 5;
$testing_onlypage_test_agent->get_entry()->param($initialize);
$skip_page_onlypage_test_agent->get_entry()->param($initialize);
$only_page_onlypage_test_agent->get_entry()->param($initialize);

$agent_runner->no_only_pages;
$agent_runner->run;
ok($testing_onlypage_test_agent->get_entry()->content->{onlypage}, 'testing.onlypagetest.onlypage should be true after no_only_pages');
ok($skip_page_onlypage_test_agent->get_entry()->content->{onlypage}, 'skip_page.onlypagetest.onlypage should be true after no_only_pages');
ok($only_page_onlypage_test_agent->get_entry()->content->{onlypage}, 'only_page.onlypagetest.onlypage should be true after no_only_pages');

sleep 5;
$testing_onlypage_test_agent->get_entry()->param($initialize);
$skip_page_onlypage_test_agent->get_entry()->param($initialize);
$only_page_onlypage_test_agent->get_entry()->param($initialize);

$agent_runner->only_pages_if(sub {
  my $page = shift;
  return 1 if ($page->title =~ m/page$/);
  return;
});

$agent_runner->run;
ok(!$testing_onlypage_test_agent->get_entry()->content->{onlypage}, 'testing.onlypagetest.onlypage should be not true with only_pages_if');
ok($skip_page_onlypage_test_agent->get_entry()->content->{onlypage}, 'skip_page.onlypagetest.onlypage should be true with only_pages_if');
ok($only_page_onlypage_test_agent->get_entry()->content->{onlypage}, 'only_page.onlypagetest.onlypage should be true with only_pages_if');

sleep 5;
$testing_onlypage_test_agent->get_entry()->param($initialize);
$skip_page_onlypage_test_agent->get_entry()->param($initialize);
$only_page_onlypage_test_agent->get_entry()->param($initialize);

$agent_runner->no_only_pages_if;
$agent_runner->run;
ok($testing_onlypage_test_agent->get_entry()->content->{onlypage}, 'testing.onlypagetest.onlypage should be not true with no_only_pages_if');
ok($skip_page_onlypage_test_agent->get_entry()->content->{onlypage}, 'skip_page.onlypagetest.onlypage should be true with no_only_pages_if');
ok($only_page_onlypage_test_agent->get_entry()->content->{onlypage}, 'only_page.onlypagetest.onlypage should be true with no_only_pages_if');

sleep 5;

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
      my $page = $testing_onlypage_test_agent->google_db->worksheet({title => $page_name});
      foreach my $row ($page->rows) {
        $row->delete;
      }

      foreach my $header_val (@{ $page_rows{$page_name}->{header} }) {
        push @header_cells, {col => $colnum++, row => 1, input_value => ''};
      }
      $page->batchupdate_cell(@header_cells);
    }
    else {
      $testing_onlypage_test_agent->google_db->worksheet({title => $page_name})->delete;
    }
  }
}

sub setup_pages {
  my $page_def = shift;
  my %page_rows = %{$page_def};

  foreach my $page_name (keys %page_rows) {
    my $page;
    if ($page_name eq 'testing') {
      $page = $testing_onlypage_test_agent->google_db->worksheet({title=>$page_name});
      die "You must create a google spreadsheet with a testing page in it for these tests to work with.  See README.txt file for more information\n" unless($page);
    } 
    else { 
      $page = $testing_onlypage_test_agent->google_db->add_worksheet({
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
