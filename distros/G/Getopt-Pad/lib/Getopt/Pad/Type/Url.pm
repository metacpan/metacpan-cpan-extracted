use v5.26;
use Object::Pad;

use Getopt::Pad::Type;

class Getopt::Pad::Type::Url :isa(Getopt::Pad::Type) :strict(params) {
	use constant NAMES => ['url', 'uri'];

	our $VERSION = '0.06';

	method glSuffix() { return '=s' }

	method label() { return 'URL' }

	method check($value) {
		return undef if $value =~ m{\A[a-zA-Z][a-zA-Z0-9.+-]*://\S+\z};    # scheme://...
		return sprintf("'%s' is not a URL", $value);
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::Url - The url option type

=head1 SYNOPSIS

=for highlighter language=perl

    options => {
        endpoint => { type => 'url', default => 'https://api.example.com/' },
    },

=head1 DESCRIPTION

The type of options and args declared with C<< type => 'url' >> or
C<'uri'>. It accepts values of the form C<scheme://rest>: a scheme that
starts with a letter and continues with letters, digits, C<+>, C<.> or
C<->, then C<://>, then at least one character. The value must not contain
whitespace. C<https://example.com/x>, C<ssh://git@example.com/repo.git>
and C<file:///tmp/x> are accepted; C<example.com> and
C<mailto:me@example.com> are rejected with C<'VALUE' is not a URL>.

The value is returned as given. The help output labels the option
C<[URL]>. See L<Getopt::Pad/url>.

=head1 SEE ALSO

L<Getopt::Pad/TYPES>, L<Getopt::Pad::Type>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
