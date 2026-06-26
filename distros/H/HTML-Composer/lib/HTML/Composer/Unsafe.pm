# MIT License
#
# Copyright (c) 2026  Rawley Fowler <rawleyfowler@proton.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

package HTML::Composer::Unsafe;

=head1 NAME

HTML::Composer::Unsafe - Wrapper for Unsafe text in HTML::Composer, typically created via an HTML::Composer instance.
These objects aren't escaped by HTML::Composer when JSON is rendered.

=head1 SYNOPSIS

  use HTML::Composer;
  
  my $h = HTML::Composer->new;
  my $unsafe_text = $h->unsafe(q[document.body.addEventListener('htmx:configRequest', (event) => {})]);
  
  ref($unsafe_text) # HTML::Composer::Unsafe
  
  my $html = $h->html([
    head => [
      title => ["My Site!"],
      script => [$unsafe_text]
    ],
    body => [
      div => [
        "Hello World!"
      ]
    ]
  ]);

=cut

use strict;
use warnings;

use overload '""' => \&to_string;

sub new {
    my ( $class, $str ) = @_;
    return bless { str => $str }, $class;
}

sub to_string {
    return shift->{str};
}

1;
