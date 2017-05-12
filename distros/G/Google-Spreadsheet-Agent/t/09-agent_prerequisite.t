use strict;
use FindBin;
use Test::More;
use Google::Spreadsheet::Agent;
use Sys::Hostname;

my $conf_file = $FindBin::Bin.'/../config/agent.conf.yml';
if (-e $conf_file) {
  plan( tests => 9 );
}
else {
  plan( 
    skip_all => 'You must create a valid test Google Spreadsheet and a valid '
                .$conf_file
                .' configuration file pointing to it to run the tests. See README.txt file for more information on how to run the tests.'
      );
}

my $agent_name = 'prerequisite';
my $prerequisite_cell_name = 'prerequisitecell';
my $page_name = 'testing';
my $bind_key_fields = { 'testentry' => 'test' };

my $google_agent = Google::Spreadsheet::Agent->new(
                   agent_name => $agent_name,
                   debug => 1,
                   page_name => $page_name,
                   bind_key_fields => $bind_key_fields,
                   prerequisites => [ $prerequisite_cell_name ],
                 );

my $page_rows = {
                  testing => {
                               header => ['testentry','ready', $agent_name, $prerequisite_cell_name],
                               rows => [
                                         { testentry => 'test', ready => 1 }
                                       ]
                             }
};

setup_pages($page_rows);

my $subroutine_ran;
my $return = $google_agent->run_my(sub { $subroutine_ran = 1; return 1; });

# this will actually return 1 since it is not runnable
is ($return, 1, 'run_my should return 1 when the prerequisite has not run');
ok (!$subroutine_ran, 'The subref should not have run at all when the prerequisite has not run');

my $entry = $google_agent->get_entry;
$entry->param({ $prerequisite_cell_name => 'r:'.Sys::Hostname::hostname });

$return = $google_agent->run_my(sub { $subroutine_ran = 1; return 1; });

# this will actually return 1 since it is not runnable
is ($return, 1, 'run_my should return 1 when the prerequisite is running');
ok (!$subroutine_ran, 'The subref should not have run at all when the prerequisite is running');

$entry = $google_agent->get_entry;
$entry->param({ $prerequisite_cell_name => 'F:'.Sys::Hostname::hostname });

$return = $google_agent->run_my(sub { $subroutine_ran = 1; return 1; });

# this will actually return 1 since it is not runnable
is ($return, 1, 'run_my should return 1 when the prerequisite has failed');
ok (!$subroutine_ran, 'The subref should not have run at all when the prerequisite has failed');

$entry = $google_agent->get_entry;
$entry->param({ $prerequisite_cell_name => 1 });

$return = $google_agent->run_my(sub { $subroutine_ran = 1; return 1; });

$entry = $google_agent->get_entry;
is ($return, 1, 'run_my should return 1 when the prerequisite has passed');
ok ($subroutine_ran, 'The subref should have run when the prerequisite has passed');
is ($entry->content->{$agent_name}, 1, $agent_name.' cell should have passed');

cleanup_pages($page_rows);
exit;

sub cleanup_pages {
  my $page_def = shift;
  my %page_rows = %{$page_def};

  my $colnum = 1;
  my @header_cells;
  foreach my $page_name (keys %page_rows) {
    if ($page_name eq 'testing') {
      my $page = $google_agent->google_db->worksheet({title => $page_name});
      foreach my $row ($page->rows) {
        $row->delete;
      }

      foreach my $header_val (@{ $page_rows{$page_name}->{header} }) {
        push @header_cells, {col => $colnum++, row => 1, input_value => ''};
      }
      $page->batchupdate_cell(@header_cells);
    }
    else {
      $google_agent->google_db->worksheet({title => $page_name})->delete;
    }
  }
}

sub setup_pages {
  my $page_def = shift;
  my %page_rows = %{$page_def};

  foreach my $page_name (keys %page_rows) {
    my $page;
    if ($page_name eq 'testing') {
      $page = $google_agent->google_db->worksheet({title=>$page_name});
      die "You must create a google spreadsheet with a testing page in it for these tests to work with.  See README.txt file for more information\n" unless($page);
    } 
    else { 
      $page = $google_agent->google_db->add_worksheet({
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
