package Mac::PopClip::Quick::Role::Apps;
use Moo::Role;

our $VERSION = '1.000001';

requires '_plist_action_key_values';

=head1 NAME

Mac::PopClip::Quick::Role::Apps - App list controlling when extension is available

=head1 SYNOPSIS

    package Mac::PopClip::Quick::Generator;
    use Moo;
    with 'Mac::PopClip::Quick::Role::Apps';
    ...

=head1 DESCRIPTION

Configure which Apps the extension will / will not be available in.

=cut

around '_plist_action_key_values' => sub {
    my $orig = shift;
    my $self = shift;
    my @ret  = $orig->( $self, @_ );
    push @ret, 'Required Apps' => $self->required_apps
        if @{ $self->required_apps };
    push @ret, 'Blocked Apps' => $self->blocked_apps
        if @{ $self->blocked_apps };
    return @ret;
};

=head1 ATTRIBUTES

=head2 blocked_apps

Array of bundle identifier strings (e.g. C<com.apple.TextEdit>) of applications
for which this extension's actions should not appear.

By default it contains an empty array, meaning no value will be set in the
plist.

=cut

has 'blocked_apps' => (
    is => 'ro',
    default => sub { [] },
);

=head2 required_apps

Array of bundle identifier strings of applications (e.g. C<com.apple.TextEdit>)
that this extension's actions will appear in.

By default it contains an empty array, meaning no value will be set in the
plist.

=cut

has 'required_apps' => (
    is => 'ro',
    default => sub { [] },
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
