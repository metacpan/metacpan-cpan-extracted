package HTTP::Response::Maker;
use strict;
use warnings;
use 5.008_001;
use Class::Load qw(load_class);

our $VERSION = '0.02';

our @DefaultHeaders = (
    'Content-Type' => 'text/html; charset=utf-8'
);

sub import {
    my ($class, $impl, @args) = @_;

    $impl = "HTTP::Response::Maker::$impl";
    load_class $impl;

    @_ = ($impl, @args);
    goto $impl->can('import');
}

1;

__END__

=head1 NAME

HTTP::Response::Maker - easy HTTP response object maker functions

=head1 SYNOPSIS

  use HTTP::Response::Maker 'HTTPResponse', (
      default_headers => [
          'Content-Type' => 'text/html; charset=utf-8'
      ],
      prefix => 'RESPOND_',
  );

  # now you can use functions like RESPOND_OK() or RESPOND_NOT_FOUND()

or

  use HTTP::Response::Maker::Exception prefix => 'throw_';

  throw_FOUND(Location => '/');

=head1 DESCRIPTION

HTTP::Response::Maker provides HTTP response object maker functions.
They are named as C<OK()> or C<NOT_FOUND()>, corresponding to
the L<HTTP::Status> constant names.

=head1 USAGE

=head2 use HTTP::Response::Maker I<$impl>, I<%args>;

Exports HTTP response maker functions to current package.

I<$impl> specifies what functions make. See IMPLEMENTATION.

I<%args> has these keys:

=over 4

=item prefix => ''

Prefix for exported functions names.

=item default_headers => \@HTTP::Response::Maker::DefaultHeaders

Default HTTP headers in arrayref.

=back

=head1 IMPLEMENTATION

C<import()>'s first argument specifies what type of objects functions generate.
Currently it is one of:

=over 4

=item L<HTTPResponse|HTTP::Response::Maker::HTTPResponse>

Generates an L<HTTP::Response> object.

=item L<PSGI|HTTP::Response::Maker::PSGI>

Generates an arrayref of L<PSGI response|PSGI/The_Response> format.

=item L<Plack|HTTP::Response::Maker::Plack>

Generates a L<Plack::Response> object.

You can specify subclass of L<Plack::Response> to generate:

  use HTTP::Response::Maker 'Plack', class => 'Your::Plack::Response';

=item L<Exception|HTTP::Response::Maker::Exception>

Throws an L<HTTP::Exception>.

=back

=head1 FUNCTION ARGS

Exported functions accept arguments in some ways:

  my $res = OK;
  my $res = OK $content;
  my $res = OK \@headers;
  my $res = OK \@headers, $content;

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 SEE ALSO

L<HTTP::Status>, L<PSGI>, L<HTTP::Response>, L<HTTP::Exception>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
