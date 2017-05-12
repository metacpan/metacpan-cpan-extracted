package HTML::Notebook::Style;

use strict;
use warnings;
use utf8;

use Moose;
use namespace::autoclean;

=encoding utf-8

=head1 NAME

HTML::Notebook::Style - Notebook style

=head1 DESCRIPTION

This class allow customizing notebook appearance

=head1 METHODS

=cut

=head2 head

Returns the html for the head of the html

=cut

sub head {
    return '
<script src="https://code.jquery.com/jquery-3.1.1.slim.min.js"></script>
<link href="https://maxcdn.bootstrapcdn.com/bootswatch/3.3.7/readable/bootstrap.min.css" rel="stylesheet" integrity="sha384-Li5uVfY2bSkD3WQyiHX8tJd0aMF91rMrQP5aAewFkHkVSTT2TmD2PehZeMmm7aiL" crossorigin="anonymous">
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"></script>
<style>
#notebook-body    {padding-top: 25px;}
.cell    {padding-left: 5%; padding-right: 5%; padding-top: 25px; padding-botton: 25px}
</style>
';
}

=head2 header

Returns the html for the notebook header section

=cut

sub header {
    return '';
}

__PACKAGE__->meta()->make_immutable;

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

