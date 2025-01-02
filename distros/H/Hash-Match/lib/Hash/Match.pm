package Hash::Match;

# ABSTRACT: match contents of a hash against rules

use v5.14;
use warnings;

our $VERSION = 'v0.8.1';

use Carp qw/ croak /;
use List::AllUtils qw/ natatime /;
use Ref::Util qw/ is_arrayref is_blessed_ref is_coderef is_hashref is_ref is_regexpref /;

# RECOMMEND PREREQ: List::SomeUtils::XS
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;


sub new {
    my ($class, %args) = @_;

    if (my $rules = $args{rules}) {

        my $root = is_hashref($rules) ? '-all' : '-any';
        my $self = _compile_rule( $root => $rules, $class );
        bless $self, $class;

    } else {

        croak "Missing 'rules' attribute";

    }
}

sub _compile_match {
    my ($value) = @_;

    if ( is_ref($value) ) {

        return sub { ($_[0] // '') =~ $value } if is_regexpref($value);

        return sub { $value->($_[0]) } if is_coderef($value);

        croak sprintf('Unsupported type: \'%s\'', ref $value);

    } else {

        return sub { ($_[0] // '') eq $value } if (defined $value);

        return sub { !defined $_[0] };

    }
}

sub _key2fn {
    my ($key, $is_hash) = @_;

    state $KEY2FN = {
        '-all'    => List::AllUtils->can('all'),
        '-and'    => List::AllUtils->can('all'),
        '-any'    => List::AllUtils->can('any'),
        '-notall' => List::AllUtils->can('notall'),
        '-notany' => List::AllUtils->can('none'),
        '-or'     => List::AllUtils->can('any'),
    };

    # TODO: eventually add a warning message about -not being
    # deprecated.

    if ($key eq '-not') {
        $key = $is_hash ? '-notall' : '-notany';
    }

    $KEY2FN->{$key} or croak "Unsupported key: '${key}'";
}

sub _compile_rule {
    my ( $key, $value, $ctx ) = @_;

    if ( is_ref($key) ) {

        if (is_regexpref($key)) {

            my $match = _compile_match($value);

            my $fn = _key2fn($ctx);

            return sub {
                my $hash = $_[0];
                $fn->( sub { $match->( $hash->{$_} ) },
                       grep { $_ =~ $key } (keys %{$hash}) );
            };

        } elsif (is_coderef($key)) {

            my $match = _compile_match($value);

            my $fn = _key2fn($ctx);

            return sub {
                my $hash = $_[0];
                $fn->( sub { $match->( $hash->{$_} ) },
                       grep { $key->($_) } (keys %{$hash}) );
            };

        } else {

            croak sprintf( "Unsupported key type: '\%s'", ref $key );

        }

    } else {

        if ( !is_blessed_ref($value) && ( is_arrayref($value) || is_hashref($value) ) ) {

            my $it = is_arrayref($value)
                ? natatime 2, @{$value}
                : sub { each %{$value} };

            my @codes;
            while ( my ( $k, $v ) = $it->() ) {
                push @codes, _compile_rule( $k, $v, $key );
            }

            my $fn = _key2fn($key, is_hashref($value));

            return sub {
                my $hash = $_[0];
                $fn->( sub { $_->($hash) }, @codes );
            };

        } elsif ( is_coderef($value) || is_regexpref($value) || !is_ref($value) ) {

            my $match = _compile_match($value);

            return sub {
                my $hash = $_[0];
                (exists $hash->{$key}) ? $match->($hash->{$key}) : 0;
            };

        } else {

            croak sprintf( "Unsupported type: '\%s'", ref $value );

        }

    }

    croak "Unhandled condition";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hash::Match - match contents of a hash against rules

=head1 VERSION

version v0.8.1

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
    -notany => $rules,
  }

None of the C<$rules> can match.

=item C<-and>

This is a (deprecated) synonym for C<-all>.

=item C<-or>

This is a (deprecated) synonym for C<-any>.

=item C<-not>

This is a (deprecated) synonym for C<-notall> and C<-notany>,
depending on the context.

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

=head1 SUPPORT FOR OLDER PERL VERSIONS

Since v0.8.0, the this module requires Perl v5.14 or later.

Future releases may only support Perl versions released in the last ten (10) years.

=head1 SEE ALSO

The following modules have similar functionality:

=over

=item L<Data::Match>

=item L<Data::Search>

=back

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Hash-Match>
and may be cloned from L<git://github.com/robrwo/Hash-Match.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Hash-Match/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head2 Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website.  Please see F<SECURITY.md> for instructions how to
report security vulnerabilities

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

Some development of this module was based on work for
Foxtons L<http://www.foxtons.co.uk>.

=head1 CONTRIBUTOR

=for stopwords Mohammad S Anwar

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2025 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
