package View::table;

use base qw(HTML::Seamstress);

my $file = 'html/table.html';

sub new {
  
  __PACKAGE__->new_from_file($file);

}

sub render {

  my $tree = shift;
  my $data = shift;

  $tree->table2
    (
     table_data => $data,
     td_proc => sub {
       my ($tr, $data) = @_;
       my @td = $tr->look_down('_tag' => 'td');
       for my $i (0..$#td) {
	 $td[$i]->splice_content(0, 1, $data->[$i]);
       }
     }
    )

      ;

  return $tree;
}

1;

