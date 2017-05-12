package HTML::Notebook::Cell;

use strict;
use warnings;
use utf8;

use Moose;
use UUID::Tiny ':std';
use namespace::autoclean;

=encoding utf-8

=head1 NAME

HTML::Notebook::Cell - Notebook Cell

=head1 SYNOPSIS

	use HTML::Notebook::Cell;
	my $cell = HTML::Notebook::Cell->new(content => 'This is a generic cell');
     
=head1 DESCRIPTION

Notebook cell

=head1 METHODS

=cut

has 'content' => ( is => 'rw', );

has 'id' => ( is      => 'ro',
              default => sub { return create_uuid_as_string(UUID_TIME) } );

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

