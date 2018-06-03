package JIP::DataPath;

use base qw(Exporter);

use strict;
use warnings;

use JIP::ClassField;
use Carp qw(croak);
use English qw(-no_match_vars);

our $VERSION = '0.03';

our @EXPORT_OK = qw(path);

has document => (get => q{+}, set => q{-});

sub path {
    my ($document) = @ARG;

    return __PACKAGE__->new(document => $document);
}

sub new {
    my ($class, %param) = @ARG;

    # Mandatory params
    croak q{Mandatory argument "document" is missing}
        unless exists $param{'document'};

    return bless({}, $class)->_set_document($param{'document'});
}

sub get {
    my ($self, $path_parts, $default_value) = @ARG;

    return $self->document
        if @{ $path_parts } == 0;

    my ($contains, $context) = $self->_accessor($path_parts);

    if ($contains) {
        my $last_part = $path_parts->[-1] // q{};
        my $type      = ref $context      // q{};

        if ($type eq 'HASH' && length $last_part) {
            return $context->{$last_part};
        }
        elsif ($type eq 'ARRAY' && $last_part =~ m{^\d+$}x) {
            return $context->[$last_part];
        }
    }

    return $default_value;
}

sub contains {
    my $self = shift;

    my ($contains) = $self->_accessor(@ARG);

    return $contains;
}

sub set {
    my ($self, $path_parts, $value) = @ARG;

    if (@{ $path_parts } == 0) {
        $self->_set_document($value);
        return 1;
    }

    my ($contains, $context) = $self->_accessor($path_parts);

    if ($contains) {
        my $last_part = $path_parts->[-1] // q{};
        my $type      = ref $context      // q{};

        if ($type eq 'HASH' && length $last_part) {
            $context->{$last_part} = $value;
            return 1;
        }
        elsif ($type eq 'ARRAY' && $last_part =~ m{^\d+$}x) {
            $context->[$last_part] = $value;
            return 1;
        }
    }

    return 0;
}

sub perform {
    my ($self, $method, $path_parts, @xargs) = @ARG;

    return $self->$method($path_parts, @xargs);
}

sub _accessor {
    my ($self, $path_parts) = @ARG;

    my $context    = $self->document;
    my $last_index = $#{ $path_parts };

    foreach my $part_index (0 .. $last_index) {
        my $part = $path_parts->[$part_index];
        my $type = ref $context // q{};
        my $last = $part_index == $last_index;

        if ($type eq 'HASH' && exists $context->{$part}) {
            return 1, $context if $last;

            $context = $context->{$part};
        }
        elsif ($type eq 'ARRAY' && $part =~ m{^\d+$}x && @{ $context } > $part) {
            return 1, $context if $last;

            $context = $context->[$part];
        }
        else {
            return 0, undef;
        }
    }

    return 1, $context;
}

1;

__END__

=head1 NAME

JIP::DataPath - provides a way to access data elements in a deep, complex and nested data structure.

=head1 VERSION

This document describes L<JIP::DataPath> version C<0.03>.

=head1 SYNOPSIS

    use JIP::DataPath qw(path);

    path({foo => 42})->get(['foo']); # 42

    path({foo => 42})->contains(['foo']); # True

    my $document = {foo => 42};
    if (path($document)->set(['foo'], 100500)) {
        path($document)->perform('get', ['foo']); # 100500
    }

=head1 ATTRIBUTES

L<JIP::DataPath> implements the following attributes.

=head2 document

    my $document = $data_path->document;

Data structure to be processed.

=head1 SUBROUTINES/METHODS

=head2 new

    my $data_path = JIP::DataPath->new(document => {foo => 'bar'});

Build new L<JIP::DataPath> object.

=head2 get

    # undef
    JIP::DataPath->new(document => undef)->get([]);

    # 42
    JIP::DataPath->new(document => 42)->get([]);

    # {foo => 'bar'}
    JIP::DataPath->new(document => {foo => 'bar'})->get([]);

    # 'bar'
    JIP::DataPath->new(document => {foo => 'bar'})->get(['foo']);

    # 'bar'
    JIP::DataPath->new(document => ['foo', 'bar'])->get([1]);

    # undef
    JIP::DataPath->new(document => ['foo', 'bar'])->get([2]);

    # 'default value'
    JIP::DataPath->new(document => ['foo', 'bar'])->get([2], 'default value');

Extract value from L</"document"> identified by the given path.

=head2 set

    # True
    JIP::DataPath->new(document => undef)->set([], {foo => undef});
    JIP::DataPath->new(document => {foo => undef})->set(['foo'], {bar => undef});
    JIP::DataPath->new(document => {foo => {bar => undef}})->set(['foo', 'bar'], []);
    JIP::DataPath->new(document => {foo => {bar => []}})->set(['foo', 'bar'], [undef]);
    JIP::DataPath->new(document => {foo => {bar => [undef]}})->set(['foo', 'bar', 0], 42);

Sets the value at the specified path.

=head2 contains

    # True
    JIP::DataPath->new(document => undef)->contains([]);
    JIP::DataPath->new(document => 42)->contains([]);
    JIP::DataPath->new(document => {foo => 'bar'})->contains([]);
    JIP::DataPath->new(document => {foo => 'bar'})->contains(['foo']);
    JIP::DataPath->new(document => ['foo', 'bar'])->contains([1]);

    # False
    JIP::DataPath->new(document => {foo => 'bar'})->contains(['wtf']);
    JIP::DataPath->new(document => ['foo', 'bar'])->contains([42]);

Check if L</"document"> contains a value that can be identified with the given path.

=head2 perform

    # 42
    JIP::DataPath->new(document => 42)->perform('get', []);

    # undef
    JIP::DataPath->new(document => 42)->perform('get', ['foo']);

    # 42
    JIP::DataPath->new(document => 42)->perform('get', ['foo'], 42);

    # True
    JIP::DataPath->new(document => 42)->perform('set', [], 100500);
    JIP::DataPath->new(document => 42)->perform('contains', []);

=head1 EXPORTABLE FUNCTIONS

These functions are exported only by request.

=head2 path

    use JIP::DataPath;

    JIP::DataPath::path({foo => 42})->get(['foo']);
    JIP::DataPath::path({foo => 42})->set(['foo'], 100500);
    JIP::DataPath::path({foo => 42})->contains(['foo']);
    JIP::DataPath::path({foo => 42})->perform('contains', ['foo']);

or exported on demand via

    use JIP::DataPath qw(path);

    path({foo => 42})->get(['foo']);
    path({foo => 42})->set(['foo'], 100500);
    path({foo => 42})->contains(['foo']);
    path({foo => 42})->perform('contains', ['foo']);

Alias of C<< JIP::DataPath->new(document => {}) >>. It creates a L<JIP::DataPath> object.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

L<JIP::DataPath> requires no configuration files or environment variables.

=head1 SEE ALSO

L<Data::Focus>, L<Data::PathSimple>, L<Data::SimplePath>

=head1 AUTHOR

Vladimir Zhavoronkov, C<< <flyweight at yandex.ru> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Vladimir Zhavoronkov.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


