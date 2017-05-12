package JSON::Types::Flexible;
use strict;
use warnings;
use utf8;

our $VERSION = "0.03";

use JSON::Types ();
use List::MoreUtils qw/uniq/;
use Sub::Install;

use constant {
    SUB_ALIAS => {
        number  => 'number',
        string  => 'string',
        bool    => 'bool',
        boolean => 'bool',
    },
    STRICT_SUBS => [qw/
        number
        string
        boolean
    /],
    LOOSE_SUBS  => [qw/
        bool
    /],
};

BEGIN {
    for (keys %{SUB_ALIAS()}) {
        Sub::Install::install_sub({
          code => SUB_ALIAS->{$_},
          from => 'JSON::Types',
          into => __PACKAGE__,
          as   => $_,
        });
    }
}

sub import {
    my ($pkg, @args) = @_;
    my $class = caller;

    my @subs;
    if (@args == 0) {
        push @subs, @{STRICT_SUBS()};
    }
    elsif ($args[0] eq ':loose' || $args[0] eq ':all') {
        push @subs, @{STRICT_SUBS()}, @{LOOSE_SUBS()};
    }
    else {
        push @subs, @args;
    }

    for (uniq @subs) {
        Sub::Install::install_sub({
          code => SUB_ALIAS->{$_},
          from => 'JSON::Types',
          into => $class,
          as   => $_,
        });
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::Types::Flexible - Yet another L<JSON::Types> module

=head1 SYNOPSIS

    # Strict mode
    use JSON::Types::Flexible;

    # Loose mode
    use JSON::Types::Flexible ':loose';

=head1 DESCRIPTION

JSON::Types::Flexible is yet another L<JSON::Types> module.

=head2 WHY ?

    $ node
    > typeof(1)
    'number'

    > typeof("1")
    'string'

    > typeof(true)
    'boolean'

=head2 MODE

=head3 Strict mode

Export C<number>, C<string> and C<boolean> methods.

=head3 Loose mode

Export C<number>, C<string>, C<boolean> and C<bool> methods.

=head2 METHODS

=head3 number

=head3 string

=head3 bool

See also L<JSON::Types>.

=head3 boolean

Alias for C<bool>.

=head1 LICENSE

(The MIT license)

Copyright (c) 2016 Pine Mizune E<lt>pinemz@gmail.comE<gt>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

Pine Mizune E<lt>pinemz@gmail.comE<gt>

=cut

