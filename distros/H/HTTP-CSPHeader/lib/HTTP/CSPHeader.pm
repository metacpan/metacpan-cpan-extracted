package HTTP::CSPHeader;

# ABSTRACT: manage dynamic content security policy headers

use v5.10;

use Moo;

use Fcntl qw/ O_NONBLOCK O_RDONLY /;
use List::Util 1.29 qw/ pairmap pairs /;
use Math::Random::ISAAC;
use Types::Standard qw/ ArrayRef is_ArrayRef Bool HashRef Str /;

# RECOMMEND PREREQ: Math::Random::ISAAC::XS
# RECOMMEND PREREQ: Type::Tiny::XS

use namespace::autoclean;

our $VERSION = 'v0.1.3';


has _base_policy => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
    init_arg => 'policy',
);

has policy => (
    is       => 'lazy',
    isa      => HashRef,
    clearer  => '_clear_policy',
    init_arg => undef,
);

sub _build_policy {
    my ($self) = @_;
    my %policy = %{ $self->_base_policy };
    if ( my @dirs = @{ $self->nonces_for } ) {
        my $nonce = "'nonce-" . $self->nonce . "'";
        for my $dir (@dirs) {
            if ( defined $policy{$dir} ) {
                $policy{$dir} .= " " . $nonce;
            }
            else {
                $policy{$dir} = $nonce;
            }
        }
        $self->_changed(1);
    }
    return \%policy;
}

has _changed => (
    is       => 'rw',
    isa      => Bool,
    lazy     => 1,
    default  => 0,
    init_arg => undef,
);


has nonces_for => (
    is      => 'lazy',
    isa     => ArrayRef [Str],
    builder => sub { return [] },
    coerce  => sub { my $val = is_ArrayRef( $_[0] ) ? $_[0] : [ $_[0] ] },
);


has nonce => (
    is       => 'lazy',
    isa      => Str,
    clearer  => '_clear_nonce',
    unit_arg => undef,
);

sub _build_nonce {
    my ($self) = @_;

    state $rng = do {
        sysopen( my $fh, '/dev/urandom', O_NONBLOCK | O_RDONLY ) or die $!;
        sysread( $fh, my $data, 16 )                             or die $!;
        close $fh;

        Math::Random::ISAAC->new( unpack( "C*", $data ) );
    };

    return sprintf( '%x', $rng->irand ^ $$ );
}


has header => (
    is       => 'lazy',
    isa      => Str,
    clearer  => '_clear_header',
    init_arg => undef,
);

sub _build_header {
    my ($self) = @_;
    my $policy = $self->policy;
    return join( "; ", pairmap { $a . " " . $b } %$policy );
}


sub reset {
    my ($self) = @_;
    return unless $self->_changed;
    $self->_clear_nonce;
    $self->_clear_policy;
    $self->_clear_header;
    $self->_changed(0);
}


sub amend {
    my ($self, @args) = @_;
    my $policy = $self->policy;

    if (@args) {

        for my $pol ( pairs @args ) {

            my ( $dir, $val ) = @$pol;

            if ( $dir =~ s/^\+// ) {    # append to directive
                if ( exists $policy->{$dir} ) {
                    $policy->{$dir} .= " " . $val;
                }
                elsif ( defined $val ) {
                    $policy->{$dir} = $val;
                }

            }
            else {
                if ( defined $val ) {
                    $policy->{$dir} = $val;
                }
                else {
                    delete $policy->{$dir};
                }
            }
        }

        $self->_clear_header;
        $self->_changed(1);
    }

    return $policy;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::CSPHeader - manage dynamic content security policy headers

=head1 VERSION

version v0.1.3

=head1 SYNOPSIS

  use HTTP::CSPheader;

  my $csp = HTTP::CSPheader->new(
    policy => {
       "default-src" => q['self'],
       "script-src"  => q['self' cdn.example.com],
    },
    nonces_for => [qw/ script-src /],
  );

  ...

  use HTTP::Headers;

  my $h = HTTP::Headers->new;

  $csp->reset;

  $h->amend(
    "+script-src" => "https://captcha.example.com",
    "+style-src"  => "https://captcha.example.com",
  );

  my $nonce = $csp->nonce;
  $h->header( 'Content-Security-Policy' => $csp->header );

  my $body = ...

  $body .= "<script nonce="${nonce}"> ... </script>";

=head1 DESCRIPTION

This module allows you to manage Content-Security-Policy (CSP) headers.

It supports dynamic changes to headers, for example, adding a source
for a specific page, or managing a random nonce for inline scripts or
styles.

It also supports caching, so that the header will only be regenerated
if there is a change.

=head1 ATTRIBUTES

=head2 policy

This is a hash reference of policies.  The keys a directives, and the
values are sources.

There is no validation of these values.

=head2 nonces_for

This is an array reference of the directives to add a random L</nonce>
to when the L</policy> is regenerated.

Note that the same nonce will be added to all of the directives, since
using separate nonces does not improve security.

It is emply by default.

A single value will be coerced to an array.

This does not validate the values.

Note that if a directive allows C<'unsafe-inline'> then a nonce may
cancel out that value.

=head2 nonce

This is the random nonce that is added to directives in L</nonces_for>.

The nonce is a hex string based on a random 32-bit number, which is generated
from L<Math::Random::ISAAC>.  The RNG is seeded by F</dev/urandom>.

If you do not have F</dev/urandom> or you want to change how it is generated,
you can override the C<_build_nonce> method in a subclass.

=head2 header

This is the value of the header, generated from the L</policy>.

This is a read-only accessor.

=head1 METHODS

=head2 reset

This resets any changes to the L</policy> and clears the L</nonce>.
It should be run at the start of each HTTP request.

If you never make use of the nonce, and never L</amend> the headers,
then you do not need to run this method.

=head2 amend

  $csp->amend( $directive1 => $value1, $directive2 => $value2, ... );

This amends the L</policy>.

If the C<$directive> starts with a C<+> then the value will be
appended to it.  Otherwise the change will overwrite the value.

If the value is C<undef>, then the directive will be deleted.

=head1 EXAMPLES

=head2 Mojolicious

You can use this with L<Mojolicious>:

  use HTTP::CSPHeader;

  use feature 'state';

  $self->hook(
    before_dispatch => sub ($c) {

      state $csp = HTTP::CSPHeader->new(
          policy => {
              'default-src' => q['self'],
              'script-src'  => q['self'],
          },
          nonces_for => 'script-src',
      );

      $csp->reset;

      $c->stash( csp_nonce => $csp->nonce );

      $c->res->headers->content_security_policy( $csp->header );
    }
  );

and in your templates, you can use the following for inline scripts:

  <script nonce="<%= $csp_nonce %>"> ... </script>

If you do not need the nonce, then you might consider using L<Mojolicious::Plugin::CSPHeader>.

=head1 SEE ALSO

L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy>

L<HTTP::SecureHeaders>

L<Plack::Middleware::CSP>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-HTTP-CSPHeader>
and may be cloned from L<git://github.com/robrwo/perl-HTTP-CSPHeader.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-HTTP-CSPHeader/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
