package HTML::Notebook::Multiple;

use utf8;

use Moose;
use Text::Template;
use HTML::Notebook::Style;
use Path::Tiny;
use namespace::autoclean;

our $VERSION = '0.004';    # VERSION

=encoding utf-8

=head1 NAME

HTML::Notebook::Multiple - Notebook composed of multiple Notebooks in different HTML files

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Notebook composed of multiple Notebooks in different HTML files

=head1 METHODS

=cut

has 'notebooks' => ( traits  => ['Hash'],
                     is      => 'rw',
                     isa     => 'HashRef[HTML::Notebook]',
                     default => sub { {} },
                     handles => { set_notebook    => 'set',
                                  get_notebook    => 'get',
                                  delete_notebook => 'delete',
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
<div id="multiple-notebook-header">
{$header}
</div>
</div>
<div id="multiple-notebook-body">
<div id="multiple-notebook-leftnav" style="width:10%;height:100%;float:left;">
<div id="notebook-header"></div>
<div id="notebook-body">
{$leftnav}
</div>
</div>
<div style="width:90%;height:100%;float:right;">
<iframe id="content-frame" name="content" style="width:100%;height:1080px;border:none;"></iframe>
</div>
</div>
<script>
window.onload=function()\{
    var links = document.getElementById("notebook-body").getElementsByTagName("a");
    document.getElementById("content-frame").setAttribute("src", links[0].href);
    \}
</script>
</body>
</html>
HTML

    my $cell_template = <<'CELL';
<div class="cell" id="{$cell_id}">
{$content}
</div>
CELL

    my $leftnav = "";
    my $renderer = Text::Template->new( TYPE => 'STRING', SOURCE => $html );
    for my $name ( sort keys %{ $self->notebooks } ) {
        my $notebook = $self->notebooks->{$name};
        my $html_file = Path::Tiny::tempfile( UNLINK => 0, SUFFIX => '.html' );
        $html_file->spew_utf8( $notebook->render( style => $style ) );
        $leftnav .= '<a href="' . $html_file->canonpath() . "\" target=content>$name</a><br>";
    }

    return $renderer->fill_in( HASH => { leftnav => $leftnav, head => $style->head, header => "" } );
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

