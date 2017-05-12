package Eidolon::Core::Exception::Builder;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Core/Exception/Builder.pm - exception builder
#
# ==============================================================================

use warnings;
use strict;

our $VERSION = "0.02"; # 2009-05-12 06:24:56

# ------------------------------------------------------------------------------
# import($class, $data)
# create exceptions classes
# ------------------------------------------------------------------------------
sub import
{
    my ($self, $class, $data, $isa, $title, $code);

    $self = shift;

    while ($class = shift) 
    {
        $data  = ref $_[0] ? shift : {};
        $isa   = $data->{"isa"} || "Eidolon::Core::Exception";
        $title = $data->{"title"};

        # check if base class exists
        {
            no strict "refs";
            die "Base class doesn't exist: $isa" if (!keys %{"$isa\::"});
        }

        $code  = "package $class;\nuse base qw/$isa/;\n";
        $code .= "use constant TITLE => '$title';\n" if ($title);

        eval $code;
    }
}

1;

__END__

=head1 NAME

Eidolon::Core::Exception::Builder - exception builder for Eidolon.

=head1 SYNOPSIS

In one of your application files, for example C<lib/Example/Exceptions.pm>
you can write:

    use Eidolon::Core::Exception::Builder
    (
        "MyException" =>
        {
            "title" => "Something happened."
        },

        "MyException::Terrible" =>
        {
            "isa"   => "MyException",
            "title" => "Something terrble happened."
        },

        "MyException::Good" =>
        {
            "isa"   => "MyException",
            "title" => "Something good happened."
        }
    );

=head1 DESCRIPTION

The I<Eidolon::Core::Exception::Builder> class provides an easy way to create own
exceptions. It has no methods that you should call - all work is done during
package import.

=head1 METHODS

=head2 import($class, $data)

Creates exception C<$class> with C<$data> settings. C<$data> is a hashref,
containing inheritance information and exception message:

=over 4

=item * isa

Exception base class.

=item * title

Exception message.

=back

If no I<isa> information is specified, L<Eidolon::Core::Exception> will be used 
as a base exception class.

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Core::Exception>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
