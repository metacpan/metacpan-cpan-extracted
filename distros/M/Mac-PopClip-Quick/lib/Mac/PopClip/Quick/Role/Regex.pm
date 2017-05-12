package Mac::PopClip::Quick::Role::Regex;
use Moo::Role;

requires '_plist_action_key_values';

our $VERSION = '1.000001';

=head1 NAME

Mac::PopClip::Quick::Role::Regex - regex controlling when extension is available

=head1 SYNOPSIS

    package Mac::PopClip::Quick::Generator;
    use Moo;
    with 'Mac::PopClip::Quick::Role::Regex';
    ...

=head1 DESCRIPTION

Configure the Before and After actions

=cut

around '_plist_action_key_values' => sub {
    my $orig = shift;
    my $self = shift;
    my @ret  = $orig->( $self, @_ );
    push @ret, 'Regular Expression' => $self->regex if defined $self->regex;
    return @ret;
};

=head1 ATTRIBUTES

=head2 regex

A string containing the regex that controls when the extension will be
triggered.  Note that this is not a Perl regex, but rather a string that PopClip
can execute as a PCRE.

By default this is undefined, meaning no regex is used.

=cut

has 'regex' => (
    is => 'ro',
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
