package HTML::Notebook;

use utf8;

use Moose;
use Text::Template;
use HTML::Notebook::Style;
use namespace::autoclean;

our $VERSION = '0.004';    # VERSION

=encoding utf-8

=head1 NAME

HTML::Notebook - Compose HTML documents using notebook style

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Compose HTML documents using notebook style. Every notebook is composed of HTML::Notebook::Cell objects that you can add, update and remove.

=head1 METHODS

=cut

has 'cells' => ( traits  => ['Array'],
                 is      => 'rw',
                 isa     => 'ArrayRef[HTML::Notebook::Cell]',
                 default => sub { [] },
                 handles => { add_cell    => 'push',
                              get_cell    => 'get',
                              delete_cell => 'delete',
                 }
);

=head2 render

Render object to HTML

=cut

sub render {
    my $self   = shift();
    my %params = @_;
    my $style  = $params{'style'} // HTML::Notebook::Style->new();
    my $html   = <<'HTML';
<!DOCTYPE html>
<html>
<meta charset="utf-8" />
<head>
{$head}
</head>
<body>
<div id="notebook-header">
{$header}
</div>
</div>
<div id="notebook-body">
{$body}
</div>
</body>
</html>
HTML

    my $cell_template = <<'CELL';
<div class="cell" id="{$cell_id}">
{$content}
</div>
CELL

    my $body          = "";
    my $renderer      = Text::Template->new( TYPE => 'STRING', SOURCE => $html );
    my $cell_renderer = Text::Template->new( TYPE => 'STRING', SOURCE => $cell_template );
    for my $cell ( @{ $self->cells } ) {
        $body .= $cell_renderer->fill_in(
                                          HASH => { cell_id => $cell->id,
                                                    content => $cell->content
                                          }
        );
    }

    return $renderer->fill_in( HASH => { body => $body, head => $style->head, header => $style->header } );
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 AUTHOR

Pablo Rodríguez González

=head1 BUGS

Please report any bugs or feature requests via github: L<https://github.com/pablrod/p5-HTML-Notebook/issues>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Pablo Rodríguez González.

The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

