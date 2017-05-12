package Message::Stack::Message;
BEGIN {
  $Message::Stack::Message::VERSION = '0.22';
}
use Moose;

# ABSTRACT: Message!

use MooseX::Aliases;
use MooseX::Storage;

with 'MooseX::Storage::Deferred';


has msgid => (
    is => 'rw',
    isa => 'Maybe[Str]',
    predicate => 'has_msgid',
    alias => 'id'
);


has level => (
    is => 'rw',
    isa => 'Maybe[Str]',
    predicate => 'has_level'
);


has params => (
    is => 'rw',
    isa => 'ArrayRef',
    predicate => 'has_params'
);


has scope => (
    is => 'rw',
    isa => 'Maybe[Str]',
    predicate => 'has_scope'
);


has subject => (
    is => 'rw',
    isa => 'Maybe[Str]',
    predicate => 'has_subject'
);


has text => (
    is => 'rw',
    isa => 'Maybe[Str]',
    predicate => 'has_text'
);

sub has_id {
    my ($self) = @_;

    return $self->has_msgid;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
__END__
=pod

=head1 NAME

Message::Stack::Message - Message!

=head1 VERSION

version 0.22

=head1 SYNOPSIS

  my $stack = Message::Stack->new;

  $stack->add(
    Message::Stack::Message->new(
        msgid => 'I18NName',
        level => 'error',
        scope => 'loginform',
        subject => 'username',
        text => 'You forgot a password'
    )
  );

=head1 DESCRIPTION

The Message object formalizes the messages that are added to the stack.  None
of the fields are required, as it's up to the developer to decide what to use.

=head1 NOTES

=head2 Note About msgid

msgid used to be id.  It was renamed to be a bit more description.  All the
methods that existed for id still exist and the id attribute is now aliased
to msgid. In other words if you create an object using C<id> then the msgid
methods B<and> the C<id> methods will work, and vice versa.

=head1 ATTRIBUTES

=head2 msgid

String identifier for this message.  Intended for use with gettext or similar
I18N mechanisms wherein a message id is used to identity the translated
text for a message.

=head2 level

String attribute used to describe the level of this message.  Intended for use
with strings like 'error' or 'info'.

=head2 params

An optional ArrayRef of params.  This is provided for localization of messages,
where id may correspond to a Gettext style string and the params may
represent some placeholder values.

=head2 scope

String identitying the scope of a message.  Used for cases when multiple
subsystems might be emitting messages and a mechanism for grouping them is
necessary.  A common case would be a form with multiple fieldsets.

=head2 subject

String identifying the subject of a message.  Used to identify a particular
element to which this message is pertinent.  Common case is an individual
field in a form.

=head2 text

String containing the human readable form of the message.  Often used in
situations when I18N is not required.

=head1 METHODS

=head2 has_msgid

Returns true if this Message has a msgid.

=head2 has_level

Returns true if this Message has a level.

=head2 has_params

Returns true if this Message has params.

=head2 has_scope

Returns true if this Message has a scope.

=head2 has_subject

Returns true if this Message has a subject.

=head2 has_text

Returns true if this Message has text.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

