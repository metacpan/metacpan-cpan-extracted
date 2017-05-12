use HTML::Seamstress;

my $html_file = 'unroll_select.html';
my $tree = HTML::Seamstress->new_from_file($html_file);


my $player_list =
  [
   {id => 1, screen_name => 'bob'},
   {id => 2, screen_name => 'joe'},
   {id => 3, screen_name => 'jim'},
   {id => 4, screen_name => 'hal'}
  ];

$tree->unroll_select
      (
       select_label => 'player_select',
       option_data_iter => sub { shift @{$player_list} },
       option_value     => sub { my $row = shift; $row->{id} },
       option_content   => sub { my $row = shift; $row->{screen_name} },
       );

print $tree->as_HTML;
