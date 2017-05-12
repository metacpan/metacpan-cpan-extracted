package Form::Sensible::Field::FileSelector;

use File::Basename;
use Moose;
use namespace::autoclean;
extends 'Form::Sensible::Field';


has 'filename' => (
    is          => 'rw',
    isa         => 'Str',
    lazy        => 1,
    default     => sub {
                        return scalar fileparse(shift->full_path);
                   }
);

has 'full_path' => (
    is          => 'rw',
    isa         => 'Str',
    lazy        => 1,
    default     => sub {
                        return shift->value();
                   }
);

has 'valid_extensions' => (
    is          => 'rw',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { return [] },
);

has 'maximum_size' => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 0,
    lazy        => 1,
);

has 'must_exist' => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 1,
    default     => 1,
    lazy        => 1,
);

has 'must_be_readable' => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 1,
    default     => 1,
    lazy        => 1,
);

sub get_additional_configuration {
    my ($self) = @_;

    return { map { $_ => $self->$_ }
                qw(maximum_size valid_extensions must_exist must_be_readable)
           };
}

around 'validate' => sub {
    my $orig = shift;
    my $self = shift;

    my @errors;

    push @errors, $self->$orig(@_);

    # file must exist.
    if (defined($self->filename)) {
        if ($self->must_exist && ! -e $self->full_path) {
            push @errors, "_FIELDNAME_ does not exist.";
        }
        if ($#{$self->valid_extensions} != -1) {
            if ( ! grep { $self->filename =~ /\.$_$/ } @{$self->valid_extensions} )
            {
                push @errors, "_FIELDNAME_ is not a valid file type";
            }
        }

        if ($self->must_be_readable && ! -r $self->full_path ) {
            push @errors, "_FIELDNAME_ is not readable";
        }
        if ($self->maximum_size) {
            if (-s $self->full_path > $self->maximum_size) {
                push @errors, "_FIELDNAME_ is too large";
            }
        }
    }
    return @errors;
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Form::Sensible::Field::FileSelector - Field used for file selection

=head1 SYNOPSIS

    use Form::Sensible::Field::FileSelector;
    
    my $object = Form::Sensible::Field::FileSelector->new({
        name => 'upload_file',
        valid_extensions => [ "jpg", "gif", "png" ],
        maximum_size => 262144,
    });

=head1 DESCRIPTION

L<Form::Sensible::Field> subclass field that represents a File.  When the
FileSelector field type is used, the user will be prompted to select a file.
Depending on the user interface, it may be prompting for a local file or a
file upload.

=head1 ATTRIBUTES

=over 8

=item C<value>

The local filename of the file selected.

=item C<full_path>

The full local path to the file selected.  B<NOTE> that in the case that the
filename provided by the user is different from the actual file on the local
filesystem (such as when using Catalyst file upload) the filename portion of
C<full_path> may be different than the result of C<filename>.  File based
validation (such as file size, etc.) is performed on C<full_path>.

=item C<filename>

The filename of the file as provided by the user.  By default, this is the
filename only portion L</full_path>. Extension based validation is performed
on C<filename>.

=item C<maximum_size>

The maximum file size allowed for the file.

=item C<valid_extensions>

An array ref containing the valid extensions for this file.

=item C<must_exist>

A true / false indicating whether the file must exist by the time the field is
validated.  Defaults to true.

=item C<must_be_readable>

A true / false indicating whether the file must be readable by the time the
field is validated.  Defaults to true.

=back

=head1 METHODS

=head2 get_additional_configuration

A convenience method to return the following attributes in a hashref:

=over 8

=item * maximum_size

=item * valid_extensions

=item * must_exist

=item * must_be_readable

=back

=head1 AUTHOR

Jay Kuri - E<lt>jayk@cpan.orgE<gt>

=head1 SPONSORED BY

Ionzero LLC. L<http://ionzero.com/>

=head1 SEE ALSO

L<Form::Sensible>

=head1 LICENSE

Copyright 2009 by Jay Kuri E<lt>jayk@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
