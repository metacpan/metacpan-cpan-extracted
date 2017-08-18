
package JSON::PP::Monkey;
$JSON::PP::Monkey::VERSION = '0.1.0';
# ABSTRACT: JSON::PP with encoding fallbacks
use 5.10.1;
use strict;
use warnings;

use JSON::PP 2.94;
use parent qw(JSON::PP);

use Carp ();
use Scalar::Util qw(blessed refaddr reftype);

BEGIN { *P_ALLOW_UNKNOWN = *JSON::PP::P_ALLOW_UNKNOWN }
BEGIN { *_is_bignum = *JSON::PP::_is_bignum }
BEGIN { *_looks_like_number = *JSON::PP::_looks_like_number }

sub add_fallback {
    my ($self, $case, $cb) = @_;
    push @{$self->{fallbacks}{$case}}, $cb;
    return $self;
}

sub remove_fallback {
    my ($self, $case, $cb) = @_;

    if ($cb) {
        $self->{fallbacks}{$case} = [grep { $cb ne $_ } @{$self->{fallbacks}{$case}}];
        delete $self->{fallbacks}{$case} unless @{$self->{fallbacks}{$case}};
    }

    return $self;
}

sub _emit_fallback_to_json {
    my ($self, $case, $value) = @_;

    if (my $s = $self->{fallbacks}{$case}) {
        for my $cb (@$s) {
            if (my ($r) = $self->$cb($value, $case)) {

                if ( defined $r and ref( $r ) ) {
                    if ( refaddr( $value ) eq refaddr( $r ) ) {
                        encode_error( sprintf(
                            "'%s' fallback (%s) returned same object as was passed instead of a new one",
                            $case, $cb
                        ) );
                    }
                }

                return $self->object_to_json($r);
            }
        }
    }
    return 'null' if $self->_get_collapse_to_null($case);
    return;
}

# $json->_collapse_to_null($case, $enable);
sub _collapse_to_null { $_[0]->{"collapse_$_[1]"} = @_ > 2 ? !!$_[2] : !!1; $_[0] }
sub _get_collapse_to_null { $_[0]->{"collapse_$_[1]"} // !!1 }

sub collapse_blessed { shift->_collapse_to_null( 'blessed', @_ ) }
sub get_collapse_blessed { $_[0]->_get_collapse_to_null('blessed') }

sub collapse_unknown { shift->_collapse_to_null( 'unknown', @_ ) }
sub get_collapse_unknown { $_[0]->_get_collapse_to_null('unknown') }

# Helpful fallbacks

sub _convert_bignum {
    return unless _is_bignum($_[1]);
    return "$_[1]";
}

sub _convert_as_nonblessed {    # Based on JSON::PP::blessed_to_json
    my $obj = $_[1];
    my $reftype = reftype($obj) || '';
    if ($reftype eq 'HASH') {
        return {%$obj};
    }
    elsif ($reftype eq 'ARRAY') {
        return [@$obj];
    }
    else {
        return undef;
    }
}

sub _convert_with_to_json {
    return unless $_[1]->can('TO_JSON');
    return $_[1]->TO_JSON;
}

# Methods 'convert_bignum' and 'convert_as_nonblessed'

BEGIN {
   my @hidden_properties = qw( allow_bignum as_nonblessed );
   for my $name (@hidden_properties) {
       no strict 'refs';
       *{$name} = *{"get_$name"} =  sub { ... };
   }
}

sub convert_blessed {
    my $self = shift->SUPER::convert_blessed(@_);
    my $meth = $self->SUPER::get_convert_blessed ? 'add_fallback' : 'remove_fallback';
    $self->$meth('blessed', '_convert_with_to_json');
}

sub get_convert_bignum { shift->SUPER::get_allow_bignum }

sub convert_bignum {
    my $self = shift->SUPER::allow_bignum(@_);
    my $meth = $self->SUPER::get_allow_bignum ? 'add_fallback' : 'remove_fallback';
    $self->$meth('blessed', '_convert_bignum');
}

sub get_convert_as_nonblessed { shift->SUPER::get_as_nonblessed }

sub convert_as_nonblessed {
    my $self = shift->SUPER::as_nonblessed(@_);
    my $meth = $self->SUPER::get_as_nonblessed ? 'add_fallback' : 'remove_fallback';
    $self->$meth('blessed', '_convert_as_nonblessed');
}

###

{
    sub object_to_json {
        my ($self, $obj) = @_;
        my $type = ref($obj);

        if($type eq 'HASH'){
            return $self->hash_to_json($obj);
        }
        elsif($type eq 'ARRAY'){
            return $self->array_to_json($obj);
        }
        elsif ($type) { # blessed object?
            if (blessed($obj)) {

                return $self->value_to_json($obj) if ( $obj->isa('JSON::PP::Boolean') );

                my $allow_blessed = $self->get_allow_blessed;
                if ($allow_blessed) {
                    if (my ($r) = $self->_emit_fallback_to_json('blessed', $obj)) {
                        return $r;
                    }
                    else {
                        encode_error( sprintf("encountered object '%s', but no fallback "
                            . "for 'blessed' was matched", $obj )
                        );
                    }
                }
                encode_error( sprintf("encountered object '%s', but allow_blessed "
                    . "setting is not enabled", $obj)
                );
            }
            else {
                return $self->value_to_json($obj);
            }
        }
        else{
            return $self->value_to_json($obj);
        }
    }

    sub value_to_json {
        my ($self, $value) = @_;

        return 'null' if(!defined $value);

        my $type = ref($value);

        if (!$type) {
            if (_looks_like_number($value)) {
                return $value;
            }
            return $self->string_to_json($value);
        }
        elsif( blessed($value) and  $value->isa('JSON::PP::Boolean') ){
            return $$value == 1 ? 'true' : 'false';
        }
        else {
            if ((overload::StrVal($value) =~ /=(\w+)/)[0]) {
                return $self->value_to_json("$value");
            }

            if ($type eq 'SCALAR' and defined $$value) {
                return 'true'  if $$value eq '1';
                return 'false' if $$value eq '0';
            }

            if ( $self->{PROPS}->[ P_ALLOW_UNKNOWN ] ) {
                if (my ($r) = $self->_emit_fallback_to_json('unknown', $value)) {
                    return $r;
                }
                else {
                    encode_error( sprintf("encountered reference '%s', but no fallback "
                       . "for 'unknown' was matched", $value )
                    );
                }
            }
            {
                if ( $type eq 'SCALAR' or $type eq 'REF' ) {
                    encode_error("cannot encode reference to scalar");
                }
                else {
                    encode_error("encountered $value, but JSON can only represent references to arrays or hashes");
                }
            }

        }
    }

    BEGIN { *encode_error = *JSON::PP::encode_error }
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use JSON::PP::Monkey;
#pod
#pod     my $json = JSON::PP::Monkey->new->utf8->pretty
#pod                  ->allow_blessed->add_fallback('blessed', sub { +{ __BLESSED_ => "$_[1]" } })
#pod                  ->allow_unknown->add_fallback('unknown', sub { +{ __UNKNOWN_ => "$_[1]" } })
#pod
#pod     $json->encode({ active => \1, io => \*STDOUT, foo => bless({}, 'foo')});
#pod     # {
#pod     #    "foo" : {
#pod     #       "__BLESSED_" : "foo=HASH(0x7fda11bc0fc8)"
#pod     #    },
#pod     #    "active" : true,
#pod     #    "io" : {
#pod     #       "__UNKNOWN_" : "GLOB(0x7fda11029518)"
#pod     #    }
#pod     # }
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is an experiment with a JSON encoder that can
#pod apply fallback conversions to blessed objects and unknowns.
#pod
#pod The primary reason it has been created was to allow
#pod dumping arbitrary Perl data into JSON.
#pod
#pod =head1 CAVEATS
#pod
#pod =head2 REVISED API
#pod
#pod Unlike C<JSON::PP>, C<JSON::XS>, C<Cpanel::JSON::XS>, L</"allow_blessed">
#pod must be enabled before blessed objects can be converted to JSON
#pod by invoking C<TO_JSON> or stringifying bignums.
#pod
#pod     # { "x": <JSON encoding of $foo->TO_JSON> }
#pod     JSON::PP::Monkey->new->allow_blessed->convert_blessed->encode({x => $foo});
#pod
#pod     # dies - allow_blessed is not enabled
#pod     JSON::PP::Monkey->new->convert_blessed->encode({x => $foo});
#pod
#pod     # { "x": "999" }
#pod     JSON::PP::Monkey->new->allow_blessed->convert_bignum->encode({x => Math::BigInt->new('999')});
#pod
#pod     # dies - allow_blessed is not enabled
#pod     JSON::PP::Monkey->new->convert_bignum->encode({x => $foo});
#pod
#pod Another difference is that the fallback conversion of objects into C<'null'>
#pod must be disabled explicitly (with L</"collapse_blessed">) if it is unwanted. So
#pod
#pod     JSON::PP::Monkey->new->allow_blessed->collapse_blessed(0)->convert_blessed;
#pod
#pod is the equivalent of
#pod
#pod     JSON::PP->new->convert_blessed;
#pod
#pod in the sense they will convert objects with C<TO_JSON> methods into JSON
#pod and bail on everything else.
#pod
#pod The behavior of L</"allow_unknown"> and L</"collapse_unknown"> is analogous.
#pod
#pod These API changes have been made to provide a more consistent behavior.
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod if objects will be encoded, C<allow_blessed> must be enabled before any
#pod fallback (installed with L</"add_fallback">, L</"convert_blessed">, or
#pod L</"convert_bignum">) can be applied.
#pod
#pod =item *
#pod
#pod if objects will be encoded but the fallback conversion into C<"null">
#pod is unwanted, it should be disabled with L</"collapse_blessed">.
#pod
#pod =item *
#pod
#pod if unknowns will be encoded, C<allow_unknown> must be enabled before any
#pod fallback can be applied
#pod
#pod =item *
#pod
#pod if unknowns will be encoded but the fallback conversion into C<"null">
#pod is unwanted, it should be disabled with L</"collapse_unknown">.
#pod
#pod =back
#pod
#pod =head2 FALLBACK ORDER
#pod
#pod Notice that the order of fallbacks is important:
#pod
#pod     $json = JSON::PP->new->utf8->allow_blessed->convert_bignum->convert_blessed;
#pod
#pod will apply stringification to bignums before trying to check for C<TO_JSON>
#pod methods. While
#pod
#pod     $json = JSON::PP->new->utf8->allow_blessed->convert_blessed->convert_bignum;
#pod
#pod will check for C<TO_JSON> methods (and apply them) before considering the
#pod stringification of bignums.
#pod
#pod =head1 METHODS
#pod
#pod =head2 allow_blessed
#pod
#pod     $json = $json->allow_blessed;
#pod     $json = $json->allow_blessed($enable);
#pod
#pod If enabled, allows to encode blessed references (or objects)
#pod via the current C<'blessed'> fallbacks or into C<'null'>
#pod (if L</"collapse_blessed"> is enabled).
#pod
#pod Defaults to disabled.
#pod
#pod =head2 allow_unknown
#pod
#pod     $json = $json->allow_unknown;
#pod     $json = $json->allow_unknown($enable);
#pod
#pod If enabled, allows to encode unknown references
#pod via the current C<'unknown'> fallbacks or into C<'null'>
#pod (if L</"collapse_unknown"> is enabled).
#pod
#pod Defaults to disabled.
#pod
#pod =head2 collapse_blessed
#pod
#pod     $json = $json->collapse_blessed;
#pod     $json = $json->collapse_blessed($enable);
#pod
#pod If L</"allow_blessed"> is enabled, an object is encoded into
#pod C<'null'> if no C<'blessed'> fallback applied.
#pod
#pod Defaults to enabled. Only has effect if C<"allow_blessed"> is enabled.
#pod
#pod =head2 collapse_unknown
#pod
#pod     $json = $json->collapse_unknown;
#pod     $json = $json->collapse_unknown($enable);
#pod
#pod If L</"allow_unknown"> is enabled, an unknown is encoded into
#pod C<'null'> if no C<'unknown'> fallback applied.
#pod
#pod Defaults to enabled. Only has effect if C<"allow_unknown"> is enabled.
#pod
#pod =head2 convert_blessed
#pod
#pod     $json = $json->convert_blessed;
#pod
#pod Add a C<"blessed"> fallback which applies to objects which
#pod have a C<"TO_JSON"> method. Equivalent to
#pod
#pod    $json = $json->add_fallback('blessed', sub {
#pod        return unless $_[1]->can('TO_JSON');
#pod        return $_[1]->TO_JSON;
#pod    });
#pod
#pod Only has effect if C<"allow_blessed"> is enabled.
#pod
#pod =head2 convert_bignum
#pod
#pod     $json = $json->convert_bignum;
#pod
#pod Add a C<"blessed"> fallback which applies to objects which
#pod are L<Math::BigInt> or L<Math::BigFloat>. Equivalent to
#pod
#pod    $json = $json->add_fallback('blessed', sub {
#pod        return unless $_[1]->isa('Math::BigInt') || $_[1]->isa('Math::BigFloat');
#pod        return "$_[1]"
#pod    });
#pod
#pod Only has effect if C<"allow_blessed"> is enabled.
#pod
#pod =head2 add_fallback
#pod
#pod     $json = $json->add_fallback('blessed', $cb);
#pod     $json = $json->add_fallback('unknown', $cb);
#pod
#pod Add fallback conversions to be applied if:
#pod
#pod     a blessed ref is found and "allow_blessed" is enabled
#pod     an unknown is found and "allow_unknown" is enabled
#pod
#pod C<$case> should be one of C<'blessed'> or C<'unknown'>.
#pod
#pod C<$cb> is a subroutine which expects two arguments
#pod
#pod     sub {
#pod         my ($json, $item, $case) = (shift, shift);
#pod         ...
#pod     }
#pod
#pod Fallback subroutines are evaluated in list context.
#pod Their return is interpreted as below.
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod a non-empty list means the first element converted to JSON
#pod will be the encoding result
#pod
#pod =item *
#pod
#pod an empty list means the fallback did not match,
#pod and the next one should be tried
#pod
#pod =back
#pod
#pod =head1 remove_fallback
#pod
#pod     $json = $json->remove_fallback($case, $cb);
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::PP::Monkey - JSON::PP with encoding fallbacks

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

    use JSON::PP::Monkey;

    my $json = JSON::PP::Monkey->new->utf8->pretty
                 ->allow_blessed->add_fallback('blessed', sub { +{ __BLESSED_ => "$_[1]" } })
                 ->allow_unknown->add_fallback('unknown', sub { +{ __UNKNOWN_ => "$_[1]" } })

    $json->encode({ active => \1, io => \*STDOUT, foo => bless({}, 'foo')});
    # {
    #    "foo" : {
    #       "__BLESSED_" : "foo=HASH(0x7fda11bc0fc8)"
    #    },
    #    "active" : true,
    #    "io" : {
    #       "__UNKNOWN_" : "GLOB(0x7fda11029518)"
    #    }
    # }

=head1 DESCRIPTION

This is an experiment with a JSON encoder that can
apply fallback conversions to blessed objects and unknowns.

The primary reason it has been created was to allow
dumping arbitrary Perl data into JSON.

=head1 CAVEATS

=head2 REVISED API

Unlike C<JSON::PP>, C<JSON::XS>, C<Cpanel::JSON::XS>, L</"allow_blessed">
must be enabled before blessed objects can be converted to JSON
by invoking C<TO_JSON> or stringifying bignums.

    # { "x": <JSON encoding of $foo->TO_JSON> }
    JSON::PP::Monkey->new->allow_blessed->convert_blessed->encode({x => $foo});

    # dies - allow_blessed is not enabled
    JSON::PP::Monkey->new->convert_blessed->encode({x => $foo});

    # { "x": "999" }
    JSON::PP::Monkey->new->allow_blessed->convert_bignum->encode({x => Math::BigInt->new('999')});

    # dies - allow_blessed is not enabled
    JSON::PP::Monkey->new->convert_bignum->encode({x => $foo});

Another difference is that the fallback conversion of objects into C<'null'>
must be disabled explicitly (with L</"collapse_blessed">) if it is unwanted. So

    JSON::PP::Monkey->new->allow_blessed->collapse_blessed(0)->convert_blessed;

is the equivalent of

    JSON::PP->new->convert_blessed;

in the sense they will convert objects with C<TO_JSON> methods into JSON
and bail on everything else.

The behavior of L</"allow_unknown"> and L</"collapse_unknown"> is analogous.

These API changes have been made to provide a more consistent behavior.

=over 4

=item *

if objects will be encoded, C<allow_blessed> must be enabled before any
fallback (installed with L</"add_fallback">, L</"convert_blessed">, or
L</"convert_bignum">) can be applied.

=item *

if objects will be encoded but the fallback conversion into C<"null">
is unwanted, it should be disabled with L</"collapse_blessed">.

=item *

if unknowns will be encoded, C<allow_unknown> must be enabled before any
fallback can be applied

=item *

if unknowns will be encoded but the fallback conversion into C<"null">
is unwanted, it should be disabled with L</"collapse_unknown">.

=back

=head2 FALLBACK ORDER

Notice that the order of fallbacks is important:

    $json = JSON::PP->new->utf8->allow_blessed->convert_bignum->convert_blessed;

will apply stringification to bignums before trying to check for C<TO_JSON>
methods. While

    $json = JSON::PP->new->utf8->allow_blessed->convert_blessed->convert_bignum;

will check for C<TO_JSON> methods (and apply them) before considering the
stringification of bignums.

=head1 METHODS

=head2 allow_blessed

    $json = $json->allow_blessed;
    $json = $json->allow_blessed($enable);

If enabled, allows to encode blessed references (or objects)
via the current C<'blessed'> fallbacks or into C<'null'>
(if L</"collapse_blessed"> is enabled).

Defaults to disabled.

=head2 allow_unknown

    $json = $json->allow_unknown;
    $json = $json->allow_unknown($enable);

If enabled, allows to encode unknown references
via the current C<'unknown'> fallbacks or into C<'null'>
(if L</"collapse_unknown"> is enabled).

Defaults to disabled.

=head2 collapse_blessed

    $json = $json->collapse_blessed;
    $json = $json->collapse_blessed($enable);

If L</"allow_blessed"> is enabled, an object is encoded into
C<'null'> if no C<'blessed'> fallback applied.

Defaults to enabled. Only has effect if C<"allow_blessed"> is enabled.

=head2 collapse_unknown

    $json = $json->collapse_unknown;
    $json = $json->collapse_unknown($enable);

If L</"allow_unknown"> is enabled, an unknown is encoded into
C<'null'> if no C<'unknown'> fallback applied.

Defaults to enabled. Only has effect if C<"allow_unknown"> is enabled.

=head2 convert_blessed

    $json = $json->convert_blessed;

Add a C<"blessed"> fallback which applies to objects which
have a C<"TO_JSON"> method. Equivalent to

   $json = $json->add_fallback('blessed', sub {
       return unless $_[1]->can('TO_JSON');
       return $_[1]->TO_JSON;
   });

Only has effect if C<"allow_blessed"> is enabled.

=head2 convert_bignum

    $json = $json->convert_bignum;

Add a C<"blessed"> fallback which applies to objects which
are L<Math::BigInt> or L<Math::BigFloat>. Equivalent to

   $json = $json->add_fallback('blessed', sub {
       return unless $_[1]->isa('Math::BigInt') || $_[1]->isa('Math::BigFloat');
       return "$_[1]"
   });

Only has effect if C<"allow_blessed"> is enabled.

=head2 add_fallback

    $json = $json->add_fallback('blessed', $cb);
    $json = $json->add_fallback('unknown', $cb);

Add fallback conversions to be applied if:

    a blessed ref is found and "allow_blessed" is enabled
    an unknown is found and "allow_unknown" is enabled

C<$case> should be one of C<'blessed'> or C<'unknown'>.

C<$cb> is a subroutine which expects two arguments

    sub {
        my ($json, $item, $case) = (shift, shift);
        ...
    }

Fallback subroutines are evaluated in list context.
Their return is interpreted as below.

=over 4

=item *

a non-empty list means the first element converted to JSON
will be the encoding result

=item *

an empty list means the fallback did not match,
and the next one should be tried

=back

=head1 remove_fallback

    $json = $json->remove_fallback($case, $cb);

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Adriano Ferreira

Adriano Ferreira <a.r.ferreira@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
