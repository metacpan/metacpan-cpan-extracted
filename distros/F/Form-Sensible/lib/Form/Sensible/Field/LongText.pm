package Form::Sensible::Field::LongText;

use Moose;
use namespace::autoclean;
extends 'Form::Sensible::Field::Text';

has '+maximum_length' => (
    default => 51200,
);

## provides a long text field (such as a 'text area' or 'notes' box)
## for now the only difference is a longer length.  that may change.

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Form::Sensible::Field::LongText - Field for representing large amounts of character-string data.

=head1 SYNOPSIS

    use Form::Sensible::Field::LongText;
    
    my $textfield = Form::Sensible::Field::LongText->new(
                                                    name => 'username',
                                                    maximum_length => 16,
                                                    should_truncate => 0
                                                  );


=head1 DESCRIPTION

L<Form::Sensible::Field> subclass for representing large amounts of
character-string based data. It has all the same attributes and behaviors as
Text, only is intended for larger amounts of text. It is separate from Text
fields only because arger-blocks of text will likely require additional
formatting and processing options.

=head1 ATTRIBUTES

=over 8

=item C<'maximum_length'>

The maximum length this text field should accept. Note that any size of string
can be placed in the field, it will simply fail validation if it is too large.
Defaults to 51200. Alternately if
L<should_truncate|Form::Sensible::Form::Text/"ATTRIBUTES"> is true, the value
will be truncated when it is set. (C<should_truncate> is false by default. )

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
