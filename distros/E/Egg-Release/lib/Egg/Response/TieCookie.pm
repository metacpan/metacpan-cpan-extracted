package Egg::Response::TieCookie;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: TieCookie.pm 338 2008-05-19 11:22:55Z lushe $
#
use strict;
use Tie::Hash;

our $VERSION = '3.01';

our @ISA = 'Tie::ExtraHash';

my $COOKIE  = 0;
my $SECURE  = 1;
my $DEFAULT = 2;

sub TIEHASH {
	my($class, $e)= @_;
	bless [{}, $e->request->secure,
	  ($e->config->{cookie_default} || {}) ], $class;
}
sub STORE {
	my $self= shift;
	my $key = shift || return 0;
	my $hash= $_[0] ? do {
		ref($_[0]) ? do {
			ref($_[0]) eq 'HASH' ? $_[0]: return do {
				my $add= { obj=> $_[0] };
				if (my $tmp= $self->[$COOKIE]{$key}) {
					ref($tmp) eq 'ARRAY' ? do { push @$tmp, $add }
					  : do { $self->[$COOKIE]{$key}= [$tmp, $add] };
				} else {
					$self->[$COOKIE]{$key}= $add;
				}
			  };
		  }: { value=> $_[0] };
	  }: { value => 0 };

	$hash->{value}= "" unless exists($hash->{value});
	$hash->{name} ||= $key;

	$hash->{$_} ||= $self->[$DEFAULT]{$_} || undef
	  for qw/ domain expires path /;

	if (! defined($hash->{secure}) and $self->[$SECURE]) {
		$hash->{secure}= defined($self->[$DEFAULT]{secure})
		   ? $self->[$DEFAULT]{secure}: 1;
	}
	$self->[$COOKIE]{$key}= Egg::Response::FetchCookie->new($hash);
}
sub _clear { $_[0]->[$COOKIE]= {} }

package Egg::Response::FetchCookie;
use strict;
use base qw/ Class::Accessor::Fast /;

__PACKAGE__->mk_accessors
  (qw/ name value path domain expires secure max_age httponly /);

sub new { bless $_[1], $_[0] }

1;

__END__

=head1 NAME

Egg::Response::TieCookie? - A class that preserves set Cookie. 

=head1 SYNOPSIS

  $e->cookies->{hoge}= 'boo';
  
  $e->cookies->{hoge}= {
    value   => 'boo',
    path    => '/home',
    domain  => 'mydomain',
    expires => '+1d',
    secure  => 1,
    };

=head1 DESCRIPTION

It is a class returned by the cookies method of L<Egg::Response>.

Information to generate the Set-Cookie header is preserved.

The set value is L<Egg::Response::FetchCookie> of the HASH reference base.
It is an object.

The key shown in name, value, and the configuration is used to refer to the set
value.

  my $cookies= $e->response->cookies;
  
  $cookies->name    or $cookies->{name}   # cookie 名の参照
  $cookies->value   or $cookies->{value}  # 設定値の参照
  $cookies->path    or $cookies->{path}
  $cookies->domain  or $cookies->{domain}
  $cookies->expires or $cookies->{expires}
  $cookies->secure  or $cookies->{secure}

=head1 CONFIGURATION

Cookie_default of the configuration of the project is assumed to be a default value.

  cookie_default=> {
    path    => '/',
    domain  => 'mydomain',
    expires => '+1M',
    secure  => 1,
    },

=head2 path

It is passing that enables the reference to Cookie.

=head2 domain

It is a domain that enables the reference to Cookie.

=head2 expires

It is validity term of Cookie. It specifies it by the form that expires of
L<CGI::Util> accepts.

  expires => '+1m'    # 1 minute
  expires => '+1h'    # 1 hour
  expires => '+1d'    # 1 day
  expires => '+1M'    # 1 month
  expires => '+1y'    # 1 year

Please note the desire that there is a thing not accepted either when lengthening
it too much by the specification of Cookie.
Cookie comes always to be annulled because past time will be given when giving it
by the minus.

=head2 secure

It makes it to Cookie with the secure flag.

However, if it is a usual access in SSL without, this setting is disregarded.
When Cookie is issued only when it is accessed with SSL, it is necessary to process
it on own code side.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Response>,
L<Tie::Hash>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

