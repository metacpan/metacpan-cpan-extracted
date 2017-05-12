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

my $conflicting_agent_name = 'conflicting';
my $conflicting_test_name = 'test';
my $conflicting_google_agent = Google::Spreadsheet::Agent->new(
                   agent_name => $conflicting_agent_name,
                   debug => 1,
                   page_name => 'testing',
                   bind_key_fields => {'testentry' => $conflicting_test_name}
                 );

my $conflicted_agent_name = 'conflicted';
my $conflicted_test_name = 'conflicttest';
my $conflicted_google_agent = Google::Spreadsheet::Agent->new(
                   agent_name => $conflicted_agent_name,
                   debug => 1,
                   page_name => 'testing',
                   bind_key_fields => {'testentry' => $conflicted_test_name}
                 );

my $page_rows = {
                  testing => {
                               header => ['testentry','ready', $conflicting_agent_name, $conflicted_agent_name],
                               rows => [
                                         { testentry => $conflicting_test_name, ready => 1 },
                                         { testentry => $conflicted_test_name, ready => 1 }
                                       ]
                             }
};

setup_pages($page_rows);

my $conflicting_agent = $FindBin::Bin.'/agent_bin/conflicting_agent.pl';
my $conflicted_agent = $FindBin::Bin.'/agent_bin/conflicted_agent.pl';

system(join(' ', 'perl', $conflicting_agent, $conflicting_test_name, '> /dev/null', '2>&1', '&')); # run in background for 10 s
sleep 5;

my ($stdout, $stderr, $success) = IO::CaptureOutput::qxx( 'perl', $conflicted_agent, $conflicted_test_name );
chomp $stderr;
is ($stderr, 'conflicts with '.$conflicting_agent_name, 'stderr should say conflicts with conflicting');
is ($success, 1, 'the script should have a non-zero exit status when a conflict is encountered'); 

my $conflict_test_entry = $conflicted_google_agent->get_entry;
ok (!($conflict_test_entry->content->{$conflicted_agent_name}), 'The agent should not have set any value on the spreadsheet when a conflict is encountered');

sleep 15;
($stdout, $stderr, $success) = IO::CaptureOutput::qxx( 'perl', $conflicted_agent, $conflicted_test_name );
chomp $stderr;
is ($stderr, 'All Complete', 'stderr should say All Complete');

$conflict_test_entry = $conflicted_google_agent->get_entry;
is ($conflict_test_entry->content->{$conflicted_agent_name}, 1, 'The agent should have run and set the value on the spreadsheet to 1');

cleanup_pages($page_rows);
exit;

sub cleanup_pages {
  my $page_def = shift;
  my %page_rows = %{$page_def};

  my $colnum = 1;
  my @header_cells;
  foreach my $page_name (keys %page_rows) {
    if ($page_name eq 'testing') {
      my $page = $conflicting_google_agent->google_db->worksheet({title => $page_name});
      foreach my $row ($page->rows) {
        $row->delete;
      }

      foreach my $header_val (@{ $page_rows{$page_name}->{header} }) {
        push @header_cells, {col => $colnum++, row => 1, input_value => ''};
      }
      $page->batchupdate_cell(@header_cells);
    }
    else {
      $conflicting_google_agent->google_db->worksheet({title => $page_name})->delete;
    }
  }
}

sub setup_pages {
  my $page_def = shift;
  my %page_rows = %{$page_def};

  foreach my $page_name (keys %page_rows) {
    my $page;
    if ($page_name eq 'testing') {
      $page = $conflicting_google_agent->google_db->worksheet({title=>$page_name});
      die "You must create a google spreadsheet with a testing page in it for these tests to work with.  See README.txt file for more information\n" unless($page);
    } 
    else { 
      $page = $conflicting_google_agent->google_db->add_worksheet({
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
