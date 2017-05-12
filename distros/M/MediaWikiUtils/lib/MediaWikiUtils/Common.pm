#
# This file is part of MediaWikiUtils
#
# This software is copyright (c) 2014 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MediaWikiUtils::Common;
{
  $MediaWikiUtils::Common::VERSION = '0.141410';
}

use strict;
use warnings;

use Moo;
use MooX::Options;

use Types::Standard qw( Object );

use MediaWiki::API;
use LWP::UserAgent;

option 'username' => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'The username to login on the mediawiki'
);

option 'password' => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'The password to login on the mediawiki'
);

option 'url' => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'The url of the mediawiki'
);

has '_mediawiki' => (
    is       => 'lazy',
    isa      => Object,
    init_arg => undef
);

has '_user_agent' => (
    is       => 'lazy',
    isa      => Object,
    init_arg => undef
);

sub _build__mediawiki {
    my ( $self ) = @_;

    my $mediawiki = MediaWiki::API->new({
        api_url => $self->url
    });
    $mediawiki->login({
        lgname     => $self->username,
        lgpassword => $self->password
    }) || croak $mediawiki->{error}->{code} . ':' . $mediawiki->{error}->{details};

    return $mediawiki;
}

sub _build__user_agent {
    return LWP::UserAgent->new();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MediaWikiUtils::Common

=head1 VERSION

version 0.141410

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
