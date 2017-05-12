package Unicornify::URL;

use strict;
use warnings;

our $VERSION = '1.07';

use Gravatar::URL qw(gravatar_url);

use parent 'Exporter';
our @EXPORT = qw(
    unicornify_url
);

my $Unicornify_Base = "http://unicornify.appspot.com/avatar/";


=head1 NAME

Unicornify::URL - OMG UNICORN AVATAR!

=head1 SYNOPSIS

    use Unicornify::URL;

    my $url = unicornify_url( email => 'larry@wall.org' );

=head1 DESCRIPTION

Now you can have your very own generated Unicorn avatar! OMG! SQUEE!

See L<http://unicornify.appspot.com/use-it> for more information. *heart*

=head1 Functions

=head3 B<unicornify_url>

    my $url = unicornify_url( email => $email, %options );

Constructs a URL to fetch the unicorn avatar for the given $email address.

C<%options> are optional.  C<unicornify_url> will accept all the
options of L<Gravatar::URL/gravatar_url> but as of this time only
C<size> has any effect.

=head4 size

Specifies the desired width and height of the avatar (they are square)
in pixels.

As of this writing, valid values are from 32 to 128.  The default is
32.

=head1 SEE ALSO

L<Gravatar::URL>

L<Acme::Pony>

"The Last Unicorn"

=cut

my %defaults = (
    base       => $Unicornify_Base,
    short_keys => 1,
);
sub unicornify_url {
    my %args = @_;

    Gravatar::URL::_apply_defaults(\%args, \%defaults);
    return gravatar_url(%args);
}

"OMG! UNICORNS!";
