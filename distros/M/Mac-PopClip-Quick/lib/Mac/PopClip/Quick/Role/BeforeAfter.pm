package Mac::PopClip::Quick::Role::BeforeAfter;
use Moo::Role;

requires '_plist_action_key_values';

our $VERSION = '1.000001';

=head1 NAME

Mac::PopClip::Quick::Role::BeforeAfter - add before and after actions

=head1 SYNOPSIS

    package Mac::PopClip::Quick::Generator;
    use Moo;
    with 'Mac::PopClip::Quick::Role::BeforeAfter';
    ...

=head1 DESCRIPTION

Configure the Before and After actions

=cut

around '_plist_action_key_values' => sub {
    my $orig = shift;
    my $self = shift;
    my @ret  = $orig->( $self, @_ );
    push @ret, Before => $self->before_action if $self->before_action;
    push @ret, After  => $self->after_action  if $self->after_action;
    return @ret;
};

=head2 after_action

What the extension should do after it's executed.  By default it is a undefined
value, indicating that it does nothing.  If your script produces output you'll
probably want to set this to C<paste-result>.  A full range of options that
PopClip supports can be found at
L<https://github.com/pilotmoon/PopClip-Extensions#user-content-before-and-after-keys>

=cut

has 'after_action' => (
    is      => 'ro',
    default => undef,
);

=head2 before_action

What the extension should do before it's executed.  By default it is a undefined
value, indicating that it does nothing. A full range of options that PopClip
supports can be found at
L<https://github.com/pilotmoon/PopClip-Extensions#user-content-before-and-after-keys>

=cut

has 'before_action' => (
    is      => 'ro',
    default => undef,
);

1;

__END__

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Mark Fowler.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

L<Mac::PopClip::Quick> is the main public interface to this module.

This role is consumed by L<Mac::PopClip::Quick::Generator>.
