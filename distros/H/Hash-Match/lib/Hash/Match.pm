package Hash::Match;

use v5.10.0;

use strict;
use warnings;

use version 0.77; our $VERSION = version->declare('v0.5.3');

use Carp qw/ croak /;
use List::MoreUtils qw/ natatime /;

use namespace::autoclean;

=head1 NAME

Hash::Match - match contents of a hash against rules

=begin readme

=head1 REQUIREMENTS

This module requires Perl v5.10 or newer, and the following non-core
modules:

=over

=item L<List::MoreUtils>

=item L<namespace::autoclean>

=back

=end readme

=head1 SYNOPSIS

  use Hash::Match;

  my $m = Hash::Match->new( rules => { key => qr/ba/ } );

  $m->( { key => 'foo' } ); # returns false
  $m->( { key => 'bar' } ); # returns true
  $m->( { foo => 'bar' } ); # returns false

  my $n = Hash::Match->new( rules => {
     -any => [ key => qr/ba/,
               key => qr/fo/,
             ],
  } )

  $n->( { key => 'foo' } ); # returns true

=head1 DESCRIPTION

This module allows you to specify complex matching rules for the
contents of a hash.

=head1 METHODS

=head2 C<new>

  my $m = Hash::Match->new( rules => $rules );

Returns a function that matches a hash reference against the
C<$rules>, e.g.

  if ( $m->( \%hash ) ) { ... }

=head3 Rules

The rules can be a hash or array reference of key-value pairs, e.g.

  {
    k_1 => 'string',    # k_1 eq 'string'
    k_2 => qr/xyz/,     # k_2 =~ qr/xyz/
    k_3 => sub { ... }, # k_3 exists and sub->($hash->{k_3}) is true
  }

For a hash reference, all keys in the rule must exist in the hash and
match the criteria specified by the rules' values.

For an array reference, some (any) key must exist and match the
criteria specified in the rules.

You can specify more complex rules using special key names:

=over

=item C<-all>

  {
    -all => $rules,
  }

All of the C<$rules> must match, where C<$rules> is an array or hash
reference.

=item C<-any>

  {
    -any => $rules,
  }

Any of the C<$rules> must match.

=item C<-notall>

  {
    -notall => $rules,
  }

Not all of the C<$rules> can match (i.e., at least one rule must
fail).

=item C<-notany>

  {
    -any => $rules,
  }

None of the C<$rules> can match.

=for readme stop

=item C<-and>

This is a (deprecated) synonym for C<-all>.

=item C<-or>

This is a (deprecated) synonym for C<-any>.

=item C<-not>

This is a (deprecated) synonym for C<-notall> and C<-notany>,
depending on the context.

=for readme continue

=back

Note that rules can be specified arbitrarily deep, e.g.

  {
    -any => [
       -all => { ... },
       -all => { ... },
    ],
  }

or

  {
    -all => [
       -any => [ ... ],
       -any => [ ... ],
    ],
  }

=for readme stop

The values for special keys can be either a hash or array
reference. But note that hash references only allow strings as keys,
and that keys must be unique.

You can use regular expressions for matching keys. For example,

  -any => [
    qr/xyz/ => $rule,
  ]

will match if there is any key that matches the regular expression has
a corresponding value which matches the C<$rule>.

You can also use

  -all => [
    qr/xyz/ => $rule,
  ]

to match if all keys that match the regular expression have
corresponding values which match the C<$rule>.

You can also use functions to match keys. For example,

  -any => [
    sub { $_[0] > 10 } => $rule,
  ]

=for readme continue

=cut

sub new {
    my ($class, %args) = @_;

    if (my $rules = $args{rules}) {

        my $root = ((ref $rules) eq 'HASH') ? '-all' : '-any';
        my $self = _compile_rule( $root => $args{rules}, $class );
        bless $self, $class;

    } else {

        croak "Missing 'rules' attribute";

    }
}

sub _compile_match {
    my ($value) = @_;

    if ( my $match_ref = ( ref $value ) ) {

        return sub { ($_[0] // '') =~ $value } if ( $match_ref eq 'Regexp' );

        return sub { $value->($_[0]) } if ( $match_ref eq 'CODE' );

        croak "Unsupported type: '${match_ref}'";

    } else {

        return sub { ($_[0] // '') eq $value } if (defined $value);

        return sub { !defined $_[0] };

    }
}

my %KEY2FN = (
    '-all'	=> List::MoreUtils->can('all'),
    '-and'	=> List::MoreUtils->can('all'),
    '-any'	=> List::MoreUtils->can('any'),
    '-notall'	=> List::MoreUtils->can('notall'),
    '-notany'	=> List::MoreUtils->can('none'),
    '-or'	=> List::MoreUtils->can('any'),
);

sub _key2fn {
    my ($key, $ctx) = @_;

    # TODO: eventually add a warning message about -not being
    # deprecated.

    if ($key eq '-not') {
	$ctx //= '';
	$key = ($ctx eq 'HASH') ? '-notall' : '-notany';
    }

    $KEY2FN{$key} or croak "Unsupported key: '${key}'";
}

sub _compile_rule {
    my ( $key, $value, $ctx ) = @_;

    if ( my $key_ref = ( ref $key ) ) {

        if ( $key_ref eq 'Regexp' ) {

            my $match = _compile_match($value);

            my $fn = _key2fn($ctx);

            return sub {
                my $hash = $_[0];
                $fn->( sub { $match->( $hash->{$_} ) },
                       grep { $_ =~ $key } (keys %{$hash}) );
            };

        } elsif ( $key_ref eq 'CODE' ) {

            my $match = _compile_match($value);

            my $fn = _key2fn($ctx);

            return sub {
                my $hash = $_[0];
                $fn->( sub { $match->( $hash->{$_} ) },
                       grep { $key->($_) } (keys %{$hash}) );
            };

        } else {

            croak "Unsupported key type: '${key_ref}'";

        }

    } else {

        my $match_ref = ref $value;

	if ( $match_ref =~ /^(?:ARRAY|HASH)$/ ) {

            my $it = ( $match_ref eq 'ARRAY' )
		? natatime 2, @{$value}
	        : sub { each %{$value} };

            my @codes;
            while ( my ( $k, $v ) = $it->() ) {
                push @codes, _compile_rule( $k, $v, $key );
            }

            my $fn = _key2fn($key, $match_ref);

            return sub {
                my $hash = $_[0];
                $fn->( sub { $_->($hash) }, @codes );
            };

        } elsif ( $match_ref =~ /^(?:Regexp|CODE|)$/ ) {

            my $match = _compile_match($value);

            return sub {
                my $hash = $_[0];
                (exists $hash->{$key}) ? $match->($hash->{$key}) : 0;
            };

        } else {

            croak "Unsupported type: '${match_ref}'";

        }

    }

    croak "Unhandled condition";
}

1;

=head1 SEE ALSO

The following modules have similar functionality:

=over

=item L<Data::Match>

=item L<Data::Search>

=back

=head1 AUTHOR

Robert Rothenberg, C<< <rrwo at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=over

=item Foxtons, Ltd.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Robert Rothenberg.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=for readme stop

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=for readme continue

=cut
