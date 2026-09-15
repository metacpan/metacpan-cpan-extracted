package Linux::Event::HTTP::_ClientAuth;
use v5.36;
use strict;
use warnings;

use Scalar::Util qw(blessed);
use Uniform::HTTP::Auth 0.02 ();

sub validate_manager ($value, $where, $name) {
    return undef if !defined $value;
    die "$where: $name must be a Uniform::HTTP::Auth object"
        if !blessed($value) || !$value->isa('Uniform::HTTP::Auth');
    return $value;
}

sub prepare_retry (%arg) {
    my $manager = $arg{manager} or return undef;
    my $challenge = $arg{response}->header_values($arg{challenge_header});
    return undef if !@$challenge;

    my $request = $arg{request};
    my %prepare = (
        challenge_headers => $challenge,
        origin            => $arg{origin},
        request           => $request,
    );

    # Uniform can read a complete buffered scalar body from the Request itself.
    # A locally constructed bodyless Request has no body buffer, but its Digest
    # auth-int entity is still the known empty byte string. Streaming producers
    # remain deliberately unconsumed and non-replayable.
    if (!$request->has_buffered_body && !$request->_has_incremental_body) {
        $prepare{entity_body} = '';
    }

    my $result;
    my $ok = eval {
        $result = $manager->prepare_authentication(%prepare);
        1;
    };
    if (!$ok) {
        my $error = "$@";
        $error =~ s/\s+\z//;
        return {
            error => "$arg{label} authentication preparation failed: $error",
        };
    }

    return undef if !$result;

    if ($request->_has_incremental_body) {
        return {
            error => "cannot automatically retry $arg{status} $arg{label} authentication for a streaming Request body because the producer is not replayable",
        };
    }

    return {
        scheme => $result->{scheme},
        value  => $result->{value},
    };
}

1;
