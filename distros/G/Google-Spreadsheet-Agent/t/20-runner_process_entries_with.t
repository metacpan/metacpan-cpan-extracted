use FindBin;
use Test::More;
use Google::Spreadsheet::Agent;
use Google::Spreadsheet::Agent::Runner;

my $turn_off = { ready => undef, entryprocessed => undef };
my $turn_on = { ready => 1 };

my $conf_file = $FindBin::Bin.'/../config/agent.conf.yml';
if (-e $conf_file) {
  plan( tests => 120 );
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
foreach my $num (1..10) {
    push @{$testing_rows}, { testentry => "testing.entry${num}" };
    push @{$skip_page_rows}, { testentry => "skip_page.entry${num}" };
    push @{$only_page_rows}, { testentry => "only_page.entry${num}" };
}

my $agent_runner = Google::Spreadsheet::Agent::Runner->new(
   process_entries_with => sub {
      my ($entry_content, $updateable_entry) = @_;
      $actual_entries_processed{$entry_content->{testentry}} = 1;      
   }
);

my $page_rows = {
                  testing => {
                               header => ['testentry','ready', 'entryprocessed'],
                               rows => $testing_rows
                             },
                  skip_page => {
                               header => ['testentry','ready', 'entryprocessed'],
                               rows => $skip_page_rows
                             },
                  only_page => {
                               header => ['testentry','ready', 'entryprocessed'],
                               rows => $only_page_rows
                             },
};

setup_pages($page_rows, $agent_runner->google_db);

foreach my $worksheet ($agent_runner->google_db->worksheets) {
  foreach my $entry ($worksheet->rows) {
    push @test_entries, $entry->content->{testentry};
    $entry->param($turn_off);
  }
}

%actual_entries_processed = ();
$agent_runner->run;

# 1-30
foreach my $entry_name (@test_entries) {
  is($actual_entries_processed{$entry_name},
     $expected_entries_processed{$entry_name},
     'No entries are ready, so no entries should be processed'
  );
}

foreach my $worksheet ($agent_runner->google_db->worksheets) {
  my $iter = 0;
  foreach my $entry ($worksheet->rows) {
    if ($iter % 2) {
      $entry->param($turn_off);
      $expected_entries_processed{$entry->content->{testentry}} = undef;
    }
    else {
      $entry->param($turn_on);
      $expected_entries_processed{$entry->content->{testentry}} = 1;
    }
    $iter++;
  }
}

%actual_entries_processed = ();
$agent_runner->run;

# 31-60
foreach my $entry_name (@test_entries) {
  is($actual_entries_processed{$entry_name},
     $expected_entries_processed{$entry_name},
     'Only ready entries should be processed'
  );
}

foreach my $worksheet ($agent_runner->google_db->worksheets) {
  my $iter = 0;
  foreach my $entry ($worksheet->rows) {
    if ($iter % 2) {
      $entry->param($turn_on);
      $expected_entries_processed{$entry->content->{testentry}} = 1;
    }
    else {
      $entry->param($turn_off);
      $expected_entries_processed{$entry->content->{testentry}} = undef;
    }
    $iter++;
  }
}

$agent_runner->process_entries_with(sub {
      my ($entry_content, $updateable_entry) = @_;
      $actual_entries_processed{$entry_content->{testentry}} = 1;
      $updateable_entry->param({'entryprocessed' => 1});      
});

%actual_entries_processed = ();
$agent_runner->run;

# 61-90
foreach my $entry_name (@test_entries) {
  is(
     $actual_entries_processed{$entry_name},
     $expected_entries_processed{$entry_name},
     'Only ready entries should be processed'
    );
}

my %actual_entries_updated = ();
$agent_runner->process_entries_with(sub {
      my ($entry_content, $updateable_entry) = @_;
      $actual_entries_updated{$entry_content->{testentry}} = $entry_content->{entryprocessed};
});
$agent_runner->run;

#91-120
foreach my $entry_name (@test_entries) {
  is(
      $actual_entries_updated{$entry_name},
      $expected_entries_processed{$entry_name},
      'Only ready entries should have true entryprocessed value'
    );
}

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
