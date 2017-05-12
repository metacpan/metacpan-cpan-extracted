#!/usr/bin/perl

package Locale::Handle::Pluggable;
#use Moose::Role;
use Moose;

use Carp qw(croak);

#with qw(Locale::Handle::Pluggable::Maketext);

use MooseX::Types::VariantTable::Declare;

our $VERSION = "0.01";

variant_method loc => Item => sub {
    my ( $self, @args ) = @_;

    my $dump = eval { require Devel::PartialDump; 1 }
        ? \&Devel::PartialDump::dump
        : sub { return join $", map { overload::StrVal($_) } @_ };

    croak "Don't know how to localize ", $dump->(@args);
};

# all strings are considered message IDs and go to 'maketext' for handling
variant_method loc => Str => "loc_string";

sub loc_string {
    my ( $self, $str, @args ) = @_;
    $self->maketext($str, @args);
}

__PACKAGE__

__END__

=pod

=encoding utf8

=head1 NAME

Locale::Handle::Pluggable - L<MooseX::Types::VariantTable> based plugins for
L<Locale::Maketext>.

=head1 VERSION

This code B<WILL> change in the future.

Role support is still not available for L<MooseX::Types::VariantTable>, and
when that will be added (kinda tricky) everything will change from class based
to role based.

Once that is in this shouldn't involve much more than C<s/extends/with/>, but
be aware that your code may break.

=head1 SYNOPSIS

    # create the localization factory class
    # see Locale::Maketext for details

	package MyProgram::L10N;
    use Moose;

    # define the factory class normally
    extends qw(Locale::Maketext);
    # or
    use Locale::Maketext::Lexicon { ... };


    # load some additional roles... uh i mean classes with variants for the loc() method
    extends qw(
        Locale::Maktext
    
        Locale::Maketext::Pluggable
        Locale::Maketext::Pluggable::DateTime
        Locale::Maketext::Pluggable::Foo
    );




    # in your language definitions, use Locale::Maketext's syntax for entries
    # For instance, to create a localized greeting with a date, the entries
    # might look like the following example. the second argument to %loc() is
    # the DateTime::Locale format symbolic format name

    # English:
    'Hello, it is now [loc, _1, "full_time"]'
    # in gettext style:
    'Hello, it is now %loc(%1, "full_time")'

    # Hebrew:
    'שלום, השעה [loc, _1, "medium_time"]'


    # And then use it like this:
    $handle->loc( $message_id, $datetime_object ); # the datetime object is in %1


    # this also works, since %loc is a method call on the language handle:
    $handle->loc( $datetime_object, "short_date" );
    
=head1 DESCRIPTION

This class extends the L<Locale::Maketext> api to provide a C<loc> method, that
attempts to be able to localize "anything", where "anything" is defined in the
various plugin methods loaded.

The dispatch table for the various types is constructed using
L<MooseX::Types::VariantTable::Declare>, and each plugin can provide additional
L<Moose::Util::TypeConstraints> based extensions.

=head1 METHODS

=over 4

=item loc $thing, @args

The variant table method.

Has an entry for C<Str>.

=item loc_string $msgid, @args

Calls C<maketext>.

=back

=head1 TODO

This makes a lot more sense as roles, but L<Moose::Meta::Role> is unable to
support custom role merging of L<MooseX::Types::VariantTable> yet.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Infinity Interactive, Yuval Kogman. All rights
    reserved This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut

