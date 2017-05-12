use HTML::Notebook;
use HTML::Notebook::Cell;
use HTML::Show;

my $notebook = HTML::Notebook->new();
my $text_cell = HTML::Notebook::Cell->new( content => 'Simple linear regression models the relationship between a scalar variable y and another scalar variable x. For example:' );
$notebook->add_cell($text_cell);
my $data_cell = HTML::Notebook::Cell->new( content => '
 <table class="table table-striped table-hover">
 <thead>
  <tr>
    <th>X</th>
    <th>Y</th>
  </tr>
 </thead>
 <tbody>
  <tr>
    <td>1</td>
    <td>10.5</td>
  </tr>
  <tr>
    <td>2</td>
    <td>19</td>
  </tr>
  <tr>
    <td>3</td>
    <td>27</td>
  </tr>
  <tr>
    <td>4</td>
    <td>41</td>
  </tr>
 </tbody>
</table> 
' );
$notebook->add_cell($data_cell);

HTML::Show::show($notebook->render());
