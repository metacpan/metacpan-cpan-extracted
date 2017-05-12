package Egg::Response::Headers;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Headers.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use Carp qw/croak/;

our $VERSION = '3.00';

sub new {
	my $class= shift;
	tie my %headers, 'Egg::Response::Headers::TieHash', @_;
	bless \%headers, $class;
}
sub header {
	my $self= shift;
	my $key = shift || croak q{ I want key. };
	return $self->{$key} unless @_;
	$self->{$key}= shift;
}
sub remove {
	my $self= shift;
	my $key = shift || croak q{ I want key. };
	CORE::delete($self->{$key});
}
*delete= \&remove;
sub clear {
	my $self= shift;
	%{$self}= ();
	1;
}

package Egg::Response::Headers::TieHash;
use strict;
use Tie::Hash::Indexed;
use Tie::Hash;

our @ISA = 'Tie::ExtraHash';

my $ForwardRegex= qr{^(?:content_type|content_language|location|status)$};

sub TIEHASH {
	my($class, $response)= @_;
	tie my %param, 'Tie::Hash::Indexed';
	bless [\%param, $response], $class;
}
sub FETCH {
	my($self, $key, $org)= &_getkey;
	return $self->[1]->$key if $key=~m{$ForwardRegex};
	$self->[0]{$key};
}
sub STORE {
	my($self, $key, $org, $value)= &_getkey;
	return $self->[1]->$key($value) if $key=~m{$ForwardRegex};
	if ($value eq "") {
		delete($self->[0]{$key}) if exists($self->[0]{$key});
	} else {
		if ($self->[0]{$key}) {
			ref($self->[0]{$key}[0]) eq 'ARRAY'
			  ? do { push @{$self->[0]{$key}}, [$org, $value] }
			  : do { $self->[0]{$key}= [$self->[0]{$key}, [$org, $value]] };
		} else {
			$self->[0]{$key}= [$org, $value];
		}
	}
}
sub DELETE {
	my($self, $key)= &_getkey;
	delete($self->[0]{$key});
}
sub EXISTS {
	my($self, $key)= &_getkey;
	exists($self->[0]{$key});
}
sub _getkey {
	my($self, $org)= splice @_, 0, 2;
	   $org=~s{_} [-]g;
	my $key= lc($org);
	   $key=~s{-} [_]g;
	($self, $key, $org, @_);
}

1;

__END__

=head1 NAME

Egg::Response::Headers - Response header class for Egg. 

=head1 SYNOPSIS

  # The response header is set.
  $e->response->headers->{'X-Header'}= 'hoge';
  
  # The response header is set.
  $e->response->headers->header( 'X-Header' => 'hoge' );
  
  # The response header is deleted.
  $e->response->headers->remove('X-Header');
  
  # All the response headers are clear.
  $e->response->headers->clear;

=head1 DESCRIPTION

It is make a response a header class only for L<Egg::Response>.

=head1 METHODS

=head2 new

Constructor.
L<Egg::Response::Headers::TieHash> The object is returned drinking.

  my $headers= $e->response->headers;

The value becomes ARRAY reference of the following content.

=over 4

=item * Original name. Because lc is done as for the key, former name is preserved.

=item * Value of header.

=back

=head2 header ([KEY], [VALUE])

KEY is always necessary.

The value is set when VALUE is given, and the content corresponding to KEY is 
returned when omitting it.

  my $hoge= $headers->header('X-Hoge');
  
  $headers->header( 'X-Hoge' => 'foo' );

=head2 remove ([KEY])

The header corresponding to KEY is deleted. 

  $headers->remove('X-Hoge');

=over 4

=item * Alias = delete

=back

=head2 clear

All set headers are cleared.

  $headers->clear;

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Request>,
L<Tie::Hash>,
L<Tie::Hash::Indexed>,
L<Carp>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

