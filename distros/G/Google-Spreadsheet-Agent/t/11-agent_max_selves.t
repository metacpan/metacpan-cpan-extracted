use strict;
use FindBin;
use Test::More;
use Google::Spreadsheet::Agent;
use IO::CaptureOutput qw/qxx/;

my $conf_file = $FindBin::Bin.'/../config/agent.conf.yml';
if (-e $conf_file) {
  plan( tests => 5 );
}
else {
  plan( 
    skip_all => 'You must create a valid test Google Spreadsheet and a valid '
                .$conf_file
                .' configuration file pointing to it to run the tests. See README.txt file for more information on how to run the tests.'
      );
}

my $agent_name = 'maxself';
my $test_name = 'test';
my $max_test_name = 'maxtest';
my $test_google_agent = Google::Spreadsheet::Agent->new(
                   agent_name => $agent_name,
                   debug => 1,
                   page_name => 'testing',
                   bind_key_fields => {'testentry' => $test_name}
                 );
my $maxtest_google_agent = Google::Spreadsheet::Agent->new(
                   agent_name => $agent_name,
                   debug => 1,
                   page_name => 'testing',
                   bind_key_fields => {'testentry' => $max_test_name}
                 );
my $page_rows = {
                  testing => {
                               header => ['testentry','ready', $agent_name],
                               rows => [
                                         { testentry => $test_name, ready => 1 },
                                         { testentry => $max_test_name, ready => 1 }
                                       ]
                             }
};

setup_pages($page_rows);

my $max_selves_agent = $FindBin::Bin.'/agent_bin/max_selves_agent.pl';
system(join(' ', 'perl', $max_selves_agent, $test_name, '> /dev/null', '2>&1', '&')); # run in background for 10 s
sleep 1;
my ($stdout, $stderr, $success) = IO::CaptureOutput::qxx( 'perl', $max_selves_agent, $max_test_name );
chomp $stderr;
is ($stderr, 'max_selves limit reached', 'stderr should say max_selves limit reached');
is ($success, 1, 'the script should have a non-zero exit status when max_selves limit reached'); 

my $max_test_entry = $maxtest_google_agent->get_entry;
ok (!($max_test_entry->content->{$agent_name}), 'The agent should not have set any value on the spreadsheet when max_selves limit reached');

sleep 20;
($stdout, $stderr, $success) = IO::CaptureOutput::qxx( 'perl', $max_selves_agent, $max_test_name );
chomp $stderr;
is ($stderr, 'All Complete', 'stderr should say All Complete');

$max_test_entry = $maxtest_google_agent->get_entry;
is ($max_test_entry->content->{$agent_name}, 1, 'The agent should have run and set the value on the spreadsheet to 1');

cleanup_pages($page_rows);
exit;

sub cleanup_pages {
  my $page_def = shift;
  my %page_rows = %{$page_def};

  my $colnum = 1;
  my @header_cells;
  foreach my $page_name (keys %page_rows) {
    if ($page_name eq 'testing') {
      my $page = $test_google_agent->google_db->worksheet({title => $page_name});
      foreach my $row ($page->rows) {
        $row->delete;
      }

      foreach my $header_val (@{ $page_rows{$page_name}->{header} }) {
        push @header_cells, {col => $colnum++, row => 1, input_value => ''};
      }
      $page->batchupdate_cell(@header_cells);
    }
    else {
      $test_google_agent->google_db->worksheet({title => $page_name})->delete;
    }
  }
}

sub setup_pages {
  my $page_def = shift;
  my %page_rows = %{$page_def};

  foreach my $page_name (keys %page_rows) {
    my $page;
    if ($page_name eq 'testing') {
      $page = $test_google_agent->google_db->worksheet({title=>$page_name});
      die "You must create a google spreadsheet with a testing page in it for these tests to work with.  See README.txt file for more information\n" unless($page);
    } 
    else { 
      $page = $test_google_agent->google_db->add_worksheet({
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
