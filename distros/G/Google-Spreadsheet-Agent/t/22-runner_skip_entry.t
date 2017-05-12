use strict;
use FindBin;
use Test::More;
use Google::Spreadsheet::Agent;
use Google::Spreadsheet::Agent::Runner;

my $turn_off = { ready => undef, entryprocessed => undef, skipthisentry => undef };
my $turn_on = { ready => 1 };
my $signal_skip = { skipthisentry => 1};
my $signal_no_skip = { skipthisentry => undef};

my $conf_file = $FindBin::Bin.'/../config/agent.conf.yml';
if (-e $conf_file) {
  plan( tests => 52 );
}
else {
  plan( 
    skip_all => 'You must create a valid test Google Spreadsheet and a valid '
                .$conf_file
                .' configuration file pointing to it to run the tests. See README.txt file for more information on how to run the tests.'
      );
}

my @test_entries = ();
my %expected_entries_processed = ();
my %actual_entries_processed = ();

my ($testing_rows, $skip_page_rows, $only_page_rows);
foreach my $num (1..5) {
    push @{$testing_rows}, { testentry => "testing.entry${num}" };
    push @{$skip_page_rows}, { testentry => "skip_page.entry${num}" };
    push @{$only_page_rows}, { testentry => "only_page.entry${num}" };
}

my $page_rows = {
                  testing => {
                               header => ['testentry','ready', 'skipthisentry', 'entryprocessed'],
                               rows => $testing_rows
                             },
                  skip_page => {
                               header => ['testentry','ready', 'skipthisentry', 'entryprocessed'],
                               rows => $skip_page_rows
                             },
                  only_page => {
                               header => ['testentry','ready', 'skipthisentry', 'entryprocessed'],
                               rows => $only_page_rows
                             },
};


# this will skip every single entry even if they are ready
my $agent_runner = Google::Spreadsheet::Agent::Runner->new(
   process_entries_with => sub {
      my ($entry_content, $updateable_entry) = @_;
      $actual_entries_processed{$entry_content->{testentry}} = 1;
   },
   skip_entry => sub { 1; }
);

setup_pages($page_rows, $agent_runner->google_db);

foreach my $worksheet ($agent_runner->google_db->worksheets) {
  foreach my $entry ($worksheet->rows) {
    push @test_entries, $entry->content->{testentry};
    $entry->param($turn_on);
  }
}

%actual_entries_processed = ();
$agent_runner->run;

# 1-15
foreach my $entry_name (@test_entries) {
  is($actual_entries_processed{$entry_name},
     $expected_entries_processed{$entry_name},
     'All entries should be skipped'
  );
}

$agent_runner->skip_entry(sub { my $entry = shift; my $skip_this_entry = $entry->content->{skipthisentry}; return $skip_this_entry; });

%expected_entries_processed = ();
foreach my $worksheet ($agent_runner->google_db->worksheets) {
  my $iter = 0;
  foreach my $entry ($worksheet->rows) {
    $entry->param($turn_off);
    if ($iter % 2) {
      $entry->param($signal_skip);
      $expected_entries_processed{$entry->content->{testentry}} = undef;
    }
    else {
      $entry->param($signal_no_skip);
      $expected_entries_processed{$entry->content->{testentry}} = 1;
    }
    $iter++;
  }
}

%actual_entries_processed = ();
$agent_runner->run;

# 16-30
foreach my $entry_name (@test_entries) {
  is($actual_entries_processed{$entry_name},
     $expected_entries_processed{$entry_name},
     'Only skip_this_entry undef entries should be processed'
  );
}

%expected_entries_processed = ();
foreach my $worksheet ($agent_runner->google_db->worksheets) {
  my $iter = 0;
  foreach my $entry ($worksheet->rows) {
    $entry->param($turn_off);
    if ($iter % 2) {
      $entry->param($signal_no_skip);
      $expected_entries_processed{$entry->content->{testentry}} = 1;
    }
    else {
      $entry->param($signal_skip);
      $expected_entries_processed{$entry->content->{testentry}} = undef;
    }
    $iter++;
  }
}

# 31-45
foreach my $runnable_entry ($agent_runner->get_runnable_entries) {
    my $entry_name = $runnable_entry->content->{testentry};
    ok($expected_entries_processed{$entry_name}, "${entry_name} should be returneed by get_runnable_entries");
}

%actual_entries_processed = ();
$agent_runner->run;

# 46-60
foreach my $entry_name (@test_entries) {
  is(
     $actual_entries_processed{$entry_name},
     $expected_entries_processed{$entry_name},
     'Only skip_this_entry undef entries should be processed'
    );
}

foreach my $worksheet ($agent_runner->google_db->worksheets) {
  my $iter = 0;
  foreach my $entry ($worksheet->rows) {
    $entry->param($signal_skip);
  }
}

my $count = $agent_runner->get_runnable_entries;
is($count, 0, 'there should not be any runnable_entries when everything is skip_this_entry 1');

cleanup_pages($page_rows, $agent_runner->google_db);
exit;

sub cleanup_pages {
  my $page_def = shift;
  my $google_db = shift;
  my %page_rows = %{$page_def};

  my $colnum = 1;
  my @header_cells;
  foreach my $page_name (keys %page_rows) {
    if ($page_name eq 'testing') {
      my $page = $google_db->worksheet({title => $page_name});
      foreach my $row ($page->rows) {
        $row->delete;
      }

      foreach my $header_val (@{ $page_rows{$page_name}->{header} }) {
        push @header_cells, {col => $colnum++, row => 1, input_value => ''};
      }
      $page->batchupdate_cell(@header_cells);
    }
    else {
      $google_db->worksheet({title => $page_name})->delete;
    }
  }
}

sub setup_pages {
  my $page_def = shift;
  my $google_db = shift;

  my %page_rows = %{$page_def};

  foreach my $page_name (keys %page_rows) {
    my $page;
    if ($page_name eq 'testing') {
      $page = $google_db->worksheet({title=>$page_name});
      die "You must create a google spreadsheet with a testing page in it for these tests to work with.  See README.txt file for more information\n" unless($page);
    } 
    else { 
      $page = $google_db->add_worksheet({
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
