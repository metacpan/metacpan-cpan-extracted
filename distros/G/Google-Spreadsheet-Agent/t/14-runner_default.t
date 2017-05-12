use FindBin;
use Test::More;
use Google::Spreadsheet::Agent;
use Google::Spreadsheet::Agent::Runner;

my $turn_off = {
        ready => undef,
        defaultrun => undef
};

my $turn_on = { ready => 1 };

my $conf_file = $FindBin::Bin.'/../config/agent.conf.yml';
if (-e $conf_file) {
  plan( tests => 18 );
}
else {
  plan( 
    skip_all => 'You must create a valid test Google Spreadsheet and a valid '
                .$conf_file
                .' configuration file pointing to it to run the tests. See README.txt file for more information on how to run the tests.'
      );
}

my $testing_default_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'defaultrun',
                  page_name => 'testing',
                  bind_key_fields => {'testentry' => 'testing.defaulttest'}
);

my $testing_default_no_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'defaultrun',
                  page_name => 'testing',
                  bind_key_fields => {'testentry' => 'testing.defaultnotest'}
);

my $skip_page_default_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'defaultrun',
                  page_name => 'skip_page',
                  bind_key_fields => {'testentry' => 'skip_page.defaulttest'}
);

my $skip_page_default_no_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'defaultrun',
                  page_name => 'skip_page',
                  bind_key_fields => {'testentry' => 'skip_page.defaultnotest'}
);

my $only_page_default_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'defaultrun',
                  page_name => 'only_page',
                  bind_key_fields => {'testentry' => 'only_page.defaulttest'}
);

my $only_page_default_no_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'defaultrun',
                  page_name => 'only_page',
                  bind_key_fields => {'testentry' => 'only_page.defaultnotest'}
);

my $page_rows = {
                  testing => {
                               header => ['testentry','ready', 'defaultrun'],
                               rows => [
                                         { testentry => 'testing.defaulttest'},
                                         { testentry => 'testing.defaultnotest'}
                                       ]
                             },
                  skip_page => {
                               header => ['testentry','ready', 'defaultrun'],
                               rows => [
                                         { testentry => 'skip_page.defaulttest'},
                                         { testentry => 'skip_page.defaultnotest'}
                                       ]
                             },
                  only_page => {
                               header => ['testentry','ready', 'defaultrun'],
                               rows => [
                                         { testentry => 'only_page.defaulttest'},
                                         { testentry => 'only_page.defaultnotest'}
                                       ]
                             },
};

setup_pages($page_rows);

my $agent_runner = Google::Spreadsheet::Agent::Runner->new();

my $agent_script = $FindBin::Bin.'/../agent_bin/defaultrun_agent.pl';
`chmod 600 ${agent_script}`;
if ($?) {
    die "Could not chmod $agent_script $!\n";
}

$agent_runner->run;
ok(!$testing_default_test_agent->get_entry()->content->{defaultrun}, 'Entry not ready: testing.defaulttest.deafultrun should not be true');
ok(!$testing_default_no_test_agent->get_entry->content->{defaultrun}, 'Entry not ready: testing.defaultnotest.defaultrun should not be true');
ok(!$skip_page_default_test_agent->get_entry()->content->{defaultrun}, 'Entry not ready: skip_page.defaulttest.defaultrun should not be true');
ok(!$skip_page_default_no_test_agent->get_entry()->content->{defaultrun}, 'Entry not ready: skip_page.defaultnotest.defaultrun should not be true');
ok(!$only_page_default_test_agent->get_entry()->content->{defaultrun}, 'Entry not ready: only_page.defaulttest.defaultrun should not be true');
ok(!$only_page_default_no_test_agent->get_entry()->content->{defaultrun}, 'Entry not ready: only_page.defaultnotest.defaultrun should not be true');

sleep 5;
$testing_default_test_agent->get_entry()->param($turn_on);
$skip_page_default_test_agent->get_entry()->param($turn_on);
$only_page_default_test_agent->get_entry()->param($turn_on);

$agent_runner->run;
ok(!$testing_default_test_agent->get_entry()->content->{defaultrun}, 'Agent not executable: testing.defaulttest.deafultrun should not be true');
ok(!$testing_default_no_test_agent->get_entry->content->{defaultrun}, 'Agent not executable: testing.defaultnotest.defaultrun should not be true');
ok(!$skip_page_default_test_agent->get_entry()->content->{defaultrun}, 'Agent not executable: skip_page.defaulttest.defaultrun should not be true');
ok(!$skip_page_default_no_test_agent->get_entry()->content->{defaultrun}, 'Agent not executable: skip_page.defaultnotest.defaultrun should not be true');
ok(!$only_page_default_test_agent->get_entry()->content->{defaultrun}, 'Agent not executable: only_page.defaulttest.defaultrun should not be true');
ok(!$only_page_default_no_test_agent->get_entry()->content->{defaultrun}, 'Agent not executable: only_page.defaultnotest.defaultrun should not be true');

`chmod 700 ${agent_script}`;
if ($?) {
    die "Could not chmod $agent_script $!\n";
}

sleep 5;
$agent_runner->run;
ok($testing_default_test_agent->get_entry()->content->{defaultrun}, 'testing.defaulttest.deafultrun should be true');
ok(!$testing_default_no_test_agent->get_entry->content->{defaultrun}, 'Entry not ready: testing.defaultnotest.defaultrun still should not be true');
ok($skip_page_default_test_agent->get_entry()->content->{defaultrun}, 'skip_page.defaulttest.defaultrun should be true');
ok(!$skip_page_default_no_test_agent->get_entry()->content->{defaultrun}, 'Entry not ready: skip_page.defaultnotest.defaultrun still should not be true');
ok($only_page_default_test_agent->get_entry()->content->{defaultrun}, 'only_page.defaulttest.defaultrun should be true');
ok(!$only_page_default_no_test_agent->get_entry()->content->{defaultrun}, 'Entry not ready: only_page.defaultnotest.defaultrun still should not be true');

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
      my $page = $testing_default_test_agent->google_db->worksheet({title => $page_name});
      foreach my $row ($page->rows) {
        $row->delete;
      }

      foreach my $header_val (@{ $page_rows{$page_name}->{header} }) {
        push @header_cells, {col => $colnum++, row => 1, input_value => ''};
      }
      $page->batchupdate_cell(@header_cells);
    }
    else {
      $testing_default_test_agent->google_db->worksheet({title => $page_name})->delete;
    }
  }
}

sub setup_pages {
  my $page_def = shift;
  my %page_rows = %{$page_def};

  foreach my $page_name (keys %page_rows) {
    my $page;
    if ($page_name eq 'testing') {
      $page = $testing_default_test_agent->google_db->worksheet({title=>$page_name});
      die "You must create a google spreadsheet with a testing page in it for these tests to work with.  See README.txt file for more information\n" unless($page);
    } 
    else { 
      $page = $testing_default_test_agent->google_db->add_worksheet({
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
