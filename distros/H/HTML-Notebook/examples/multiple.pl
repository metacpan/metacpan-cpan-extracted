use HTML::Notebook;
use HTML::Notebook::Multiple;
use HTML::Notebook::Cell;
use HTML::Show;

my $notebook_multiple = HTML::Notebook::Multiple->new();

$notebook_multiple->set_notebook( 'Primero' => GenerateNotebook(1) );
$notebook_multiple->set_notebook( 'Segundo' => GenerateNotebook(2) );

HTML::Show::show( $notebook_multiple->render() );

sub GenerateNotebook {
    my $index     = shift();
    my $notebook  = HTML::Notebook->new();
    my $text_cell = HTML::Notebook::Cell->new( content => 'Simple Notebook' );
    $notebook->add_cell($text_cell);
    my $data_cell = HTML::Notebook::Cell->new( content => 'Notebook ' . $index );
    $notebook->add_cell($data_cell);
    return $notebook;
}
