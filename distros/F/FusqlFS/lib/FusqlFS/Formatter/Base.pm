use strict;
use 5.010;

package FusqlFS::Formatter::Base;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;

=head1 NAME

FusqlFS::Formatter::Base - base formatter class

=head1 SYNOPSIS

    package FusqlFS::Formatter::Native;
    use parent 'FusqlFS::Formatter::Base';

    sub Dump
    {
        return $_[0];
    }

    sub Load
    {
        return $_[0];
    }

=head1 DESCRIPTION

This is a base class for different built-in formatter classes used to dump and load
database data by different backends.

You can choose formatter with L<--format|fusqlfs/--format, -f> option by class name,
e.g. to choose L<FusqlFS::Formatter::Native> formatter use C<--format native> option.

=head1 METHODS

=over

=item Dump

Format input value into a string.
Abstract, should be implemented in child classes.

Input: $mixed_value
Output: $string

=item Load

Parse string value into original value.
Abstract, should be implemented in child classes.

Input: $string
Output: $mixed_value

=back

=cut

sub Dump {}

sub Load {}

1;
