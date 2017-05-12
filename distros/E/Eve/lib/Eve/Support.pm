package Eve::Support;

use strict;
use warnings;

use Contextual::Return;
use PadWalker ();
use Tie::IxHash;

use Eve::Exception;

=head1 NAME

B<Eve::Support> - an utility class that houses various helper functions

=head1 SYNOPSIS

    use Eve::Support;

    Eve::Support::arguments(\%arg_hash,
        my $required_argument, my $optional_argument = 'default value'
    );

=head1 SUBROUTINES

=head2 B<arguments()>

The C<arguments()> method makes it easier to specify a list of required
and optional arguments in any other method. It can be used in both
class method calls and usual subroutine calls.

Here is an example in a usual subroutine:

    sub usual_subroutine {
        my (%arg_hash) = @_;
        Eve::Support::arguments(\%arg_hash,
            my ($required_argument, $another_required_argument),
            my ($optional_argument, $optional_empty_argument) = (1, \undef)
        );
    }

The same may be done in a class method call:

    sub class_method {
        my ($self, %arg_hash) = @_;
        Eve::Support::arguments(\%arg_hash,
            my ($required_argument, $another_required_argument),
            my ($optional_argument, $optional_empty_argument)
                = ('default', \undef)
        );
    }

If the function is called in the RVALUE context it skips the
redundancy check and returns the rest of arguments that have not been
processed as a hash reference.

    sub foo {
        my (%arg_hash) = @_;
        my $rest_hash = Eve::Support::arguments(
            \%arg_hash, my $bar);

        return $rest_hash;
    }

Here the call C<foo(bar => 1, baz => 2, bad => 3)> will return the
hash C<{'baz' => 2, 'bad' => 3}>.

=head3 Arguments

=over 4

=item C<\%arg_hash>

A reference to a hash of arguments that has been passed into the
current method.

=item C<@variable_list>

A list of variables that have to be filled by values from the
incoming C<\%arg_hash>.

=back

=head3 Throws

=over 4

=item C<Eve::Error::Attribute>

could not get a variable for a named argument, an argument is required
or an argument is redundant.

=back

=cut

sub arguments : lvalue {
    my $arg_hash = shift;

    foreach my $var (@_) {
        my $name = PadWalker::var_name(1, \$var);
        if (not defined($name)) {
            Eve::Error::Attribute->throw(
                message => 'Could not get a variable for a named argument');
        }

        $name =~ s/^\$//;

        if (exists($arg_hash->{$name})) {
            $var = $arg_hash->{$name};
            delete($arg_hash->{$name});
        } else {
            if (defined($var)) {
                if ($var eq \undef) {
                    # Work around default undef value
                    $var = undef;
                } else {
                    # Leave the value that was assigned
                }
            } else {
                Eve::Error::Attribute->throw(
                    message => 'Required argument: '.$name);
            }
        }
    }

    NVALUE {
        my @keys = keys(%$arg_hash);
        if (@keys) {
            Eve::Error::Attribute->throw(
                message => 'Redundant argument(s): '.join(', ', sort(@keys)));
        }
    }
    RVALUE {
        $arg_hash;
    }
}

=head2 B<unique()>

=head3 Arguments

=over 4

=item C<list>

=back

=head3 Returns

A list containing only unique elements of the passed list.

=cut

sub unique {
    my %arg_hash = @_;
    Eve::Support::arguments(\%arg_hash, my $list);

    my $unique_list = [];
    my $seen_hash = {};
    for my $item (@{$list}) {
        if (not exists $seen_hash->{$item}) {
            push(@{$unique_list}, $item);
            $seen_hash->{$item} = 1;
        }
    }

    return $unique_list;
}

=head2 B<open()>

=head3 Arguments

=over 4

=item C<mode>

=item C<file>

=back

=head3 Returns

A filehandle.

=head3 Throws

=over 4

=item C<Eve::Exception::InputOutput>

in case of a file open error.

=back

=cut

sub open {
    my %arg_hash = @_;
    Eve::Support::arguments(\%arg_hash, my ($mode, $file));

    open(my $filehandle, $mode, $file) or
        Eve::Exception::InputOutput->throw(
            message => "Error occured when opening the file '$file': ".$!);

    return $filehandle;
}

=head2 B<indexed_hash()>

=head3 Arguments

Key-value pair list.

=head3 Returns

A hash tied to L<Tie::IxHash>.

=cut

sub indexed_hash {
    tie(my %hash, 'Tie::IxHash', @_);

    return \%hash;
}

=head2 B<trim()>

=head3 Arguments

A string.

=head3 Returns

Trimmed string.

=head3 Throws

=over 4

=item C<Eve::Exception::Value>

if the triming value is undefined.

=back

=cut

sub trim {
    my %arg_hash = @_;
    Eve::Support::arguments(\%arg_hash, my $string);

    if (not defined $string) {
        Eve::Error::Value->throw(
            message => 'Trimming value must be defined');
    }

    $string =~ s/^\s+//;
    $string =~ s/\s+$//;

    return $string;
}

=head1 SEE ALSO

=over 4

=item L<Eve::Exception>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=back

=cut

1;
