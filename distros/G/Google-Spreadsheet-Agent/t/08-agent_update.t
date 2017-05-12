use strict;
use FindBin;
use Test::More;
use Google::Spreadsheet::Agent;
use Sys::Hostname;

my $conf_file = $FindBin::Bin.'/../config/agent.conf.yml';
if (-e $conf_file) {
  plan( tests => 8 );
}
else {
  plan( 
    skip_all => 'You must create a valid test Google Spreadsheet and a valid '
                .$conf_file
                .' configuration file pointing to it to run the tests. See README.txt file for more information on how to run the tests.'
      );
}

my $agent_name = 'update';
my $updated_cell_name = 'updatevalue';
my $updated_cell_value = 'iamupdated';
my $page_name = 'testing';
my $bind_key_fields = { 'testentry' => 'test' };

my $google_agent = Google::Spreadsheet::Agent->new(
                   agent_name => $agent_name,
                   debug => 1,
                   page_name => $page_name,
                   bind_key_fields => $bind_key_fields
                 );

my $page_rows = {
                  testing => {
                               header => ['testentry','ready', $agent_name, $updated_cell_name],
                               rows => [
                                         { testentry => 'test', ready => 1 }
                                       ]
                             }
};

setup_pages($page_rows);

my $subroutine_ran;
ok $google_agent->run_my(sub { $subroutine_ran = 1; return (1, {$updated_cell_name => $updated_cell_value}); });

my $entry = $google_agent->get_entry;
is ($entry->content->{$agent_name}, 1, "agent ${agent_name} passed");
ok($subroutine_ran, 'The subroutine should have actually run');
is ($entry->content->{$updated_cell_name}, $updated_cell_value, $updated_cell_name.' should have been updated by agent');

$subroutine_ran = undef;
$entry = $google_agent->get_entry;
$entry->param({
      $agent_name => undef,
      $updated_cell_name => undef
});

my $expected_failure = 'F:'.Sys::Hostname::hostname;
ok !$google_agent->run_my(sub { $subroutine_ran = 1; return (undef, {$updated_cell_name => $updated_cell_value}); });
$entry = $google_agent->get_entry;
is ($entry->content->{$agent_name}, $expected_failure, "agent ${agent_name} failed");
ok($subroutine_ran, 'The subroutine should have actually run');
is ($entry->content->{$updated_cell_name}, $updated_cell_value, $updated_cell_name.' should have been updated by agent');

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
