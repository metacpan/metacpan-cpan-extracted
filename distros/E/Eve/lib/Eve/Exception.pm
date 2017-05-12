package Eve::Exception;

use strict;
use warnings;

=head1 NAME

Eve::Exception - a module that defines a set of exception classes.

=head1 SYNOPSIS

To throw an exception:

    use Eve::Exception;

    Eve::Exception::Base->throw(message => 'Something bad happened.');

To catch an exception:

    use Eve::Exception;

    eval {
        # Code that throws an exception here
        something();
    };

    my $e;
    if ($e = Eve::Exception::Data->caught()) {
        # Do the thing
    } elsif ($e = Eve::Exception::Http->caught()) {
        # Do something else
    } elsif ($e = Exception::Class::Base->caught()) {
        $e->rethrow();
    }

It is conventional to catch Eve::Exception derivatives
only. Eve::Error derivatives are assumed to be uncatchable.

=head1 DESCRIPTION

=head2 Provided classes

=over 4

=item C<Eve::Error::Base>

=over 8

=item C<Eve::Error::Attribute>

=item C<Eve::Error::HttpDispatcher>

=item C<Eve::Error::NotImplemented>

=item C<Eve::Error::Program>

=item C<Eve::Error::Session>

=item C<Eve::Error::Template>

=item C<Eve::Error::Value>

=back

=item C<Eve::Exception::Base>

=over 8

=item C<Eve::Exception::Data>

=item C<Eve::Exception::Die>

=item C<Eve::Exception::Duplicate>

=item C<Eve::Exception::Http>

=over 12

=item C<Eve::Exception::Http::400BadRequest>

=item C<Eve::Exception::Http::401Unauthorized>

=item C<Eve::Exception::Http::404NotFound>

=item C<Eve::Exception::Http::403Forbidden>

=item C<Eve::Exception::Http::405MethodNotAllowed>

=back

=item C<Eve::Exception::InputOutput>

=item C<Eve::Exception::Privilege>

=back

=back

=cut

use Exception::Class (
    # Do not use ->caught() on this subtree of exceptions as they
    # assumed to be uncatchable
    'Eve::Error::Base',

        'Eve::Error::Attribute' => {
            isa => 'Eve::Error::Base'},

        'Eve::Error::HttpDispatcher' => {
            isa => 'Eve::Error::Base'},

        'Eve::Error::NotImplemented' => {
            isa => 'Eve::Error::Base'},

        'Eve::Error::Program' => {
            isa => 'Eve::Error::Base'},

        'Eve::Error::Session' => {
            isa => 'Eve::Error::Base'},

        'Eve::Error::Template' => {
            isa => 'Eve::Error::Base'},

        'Eve::Error::Value' => {
            isa => 'Eve::Error::Base'},

    # This assumed to be ->caught()
    'Eve::Exception::Base',

        'Eve::Exception::Data' => {
            isa => 'Eve::Exception::Base'},

            'Eve::Exception::Data::LanguageNotSet' => {
                isa => 'Eve::Exception::Data'},

            'Eve::Exception::Data::TemplateTextNotFound' => {
                isa => 'Eve::Exception::Data'},

        # Raises on die
        'Eve::Exception::Die' => {
            isa => 'Eve::Exception::Base'},

        'Eve::Exception::Duplicate' => {
            isa => 'Eve::Exception::Base'},

        'Eve::Exception::Http' => {
            isa => 'Eve::Exception::Base'},

            'Eve::Exception::Http::400BadRequest' => {
                isa => 'Eve::Exception::Http'},

            'Eve::Exception::Http::401Unauthorized' => {
                isa => 'Eve::Exception::Http'},

            'Eve::Exception::Http::403Forbidden' => {
                isa => 'Eve::Exception::Http'},

            'Eve::Exception::Http::404NotFound' => {
                isa => 'Eve::Exception::Http'},

            'Eve::Exception::Http::405MethodNotAllowed' => {
                isa => 'Eve::Exception::Http'},

        'Eve::Exception::InputOutput' => {
            isa => 'Eve::Exception::Base'},

        'Eve::Exception::Privilege' => {
            isa => 'Eve::Exception::Base'},
);

# Redefine __DIE__ signal handler so it throws Eve::Exception::Die
$SIG{__DIE__} = sub {
    unless (UNIVERSAL::isa($_[0], 'Exception::Class::Base')) {
        Eve::Exception::Die->throw(message => join('', @_));
    }
};

# Redefine standart exception messaging so it prints exception class
# name when no message specifien in throw()
no warnings;
*Exception::Class::Base::full_message = sub {
    my $self = shift;

    return
        (ref $self ? ref $self : $self).
        ($self->message() ? ': '.$self->message() : '');
};
use warnings;

# Turn the stack trace printing on and off where it is necessary
Eve::Exception::Base->Trace(0);
Eve::Exception::Die->Trace(1);
Eve::Error::Base->Trace(1);

=head1 SEE ALSO

=over 4

=item L<Exception::Class>

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
