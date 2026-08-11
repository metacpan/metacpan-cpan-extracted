#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

my $HOME = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $HOME;
delete local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS};

chdir $HOME or die "Unable to chdir to $HOME: $!";
mkdir File::Spec->catdir( $HOME, '.developer-dashboard' )
  or die "Unable to seed the home runtime layer: $!";

use Developer::Dashboard::Auth;
use Developer::Dashboard::Codec;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;

my $paths = Developer::Dashboard::PathRegistry->new;
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $app   = Developer::Dashboard::Web::App->new(
    auth     => Developer::Dashboard::Auth->new( files => $files, paths => $paths ),
    pages    => Developer::Dashboard::PageStore->new( paths => $paths ),
    sessions => Developer::Dashboard::SessionStore->new( paths => $paths ),
    runtime  => Developer::Dashboard::PageRuntime->new( paths => $paths ),
);

my $MARKER = 'TRANSIENT-TOKEN-EXECUTED';
my $TOKEN  = Developer::Dashboard::Codec::encode_payload(qq{print "$MARKER\\n";});

# _executed_output($response)
# Drains a streaming Ajax response so the test can prove whether the tokenized
# payload actually ran.
# Input: response array reference as returned by the web application.
# Output: concatenated stream output, or the empty string for a plain body.
sub _executed_output {
    my ($response) = @_;
    return '' if ref( $response->[2] ) ne 'HASH';
    my $out = '';
    $response->[2]{stream}->( sub { $out .= defined $_[0] ? $_[0] : '' } );
    return $out;
}

# The negative control. Without this passing, a 403 on the bypass cases below
# would prove nothing about the policy actually being consulted.
my $plain = $app->legacy_ajax_response(
    query       => "token=$TOKEN",
    remote_addr => '127.0.0.1',
    headers     => {},
);
is( $plain->[0], 403, 'control: a bare tokenized /ajax request is denied while transient URLs are disabled' );
unlike( _executed_output($plain), qr/\Q$MARKER\E/, 'control: the denied bare token payload never executes' );

my $with_file = $app->legacy_ajax_response(
    query       => "file=anything&token=$TOKEN",
    remote_addr => '127.0.0.1',
    headers     => {},
);
is( $with_file->[0], 403, 'a file parameter does not lift the transient token denial on /ajax' );
unlike( _executed_output($with_file), qr/\Q$MARKER\E/, 'the file-parameter token payload never executes' );

my $file_route = $app->legacy_ajax_file_response(
    ajax_file   => 'somefile',
    query       => "token=$TOKEN",
    remote_addr => '127.0.0.1',
    headers     => {},
);
is( $file_route->[0], 403, 'an /ajax/<file> path segment does not lift the transient token denial' );
unlike( _executed_output($file_route), qr/\Q$MARKER\E/, 'the path-segment token payload never executes' );

my $skill_route = $app->skill_ajax_file_response(
    skill_name  => 'demo',
    ajax_file   => 'handler',
    query       => "token=$TOKEN",
    remote_addr => '127.0.0.1',
    headers     => {},
);
is( $skill_route->[0], 403, 'a tokenized /ajax/<skill>/<file> request is denied too' );
unlike( _executed_output($skill_route), qr/\Q$MARKER\E/, 'the skill-route token payload never executes' );

# Tokenless traffic must stay unaffected: the policy governs tokens only.
my $tokenless = $app->legacy_ajax_file_response(
    ajax_file   => 'missing-handler',
    query       => 'type=text',
    remote_addr => '127.0.0.1',
    headers     => {},
);
isnt( $tokenless->[0], 403, 'tokenless saved-handler requests are still resolved rather than denied' );

{
    local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = '1';
    my $opted_in = $app->legacy_ajax_response(
        query       => "file=anything&token=$TOKEN",
        remote_addr => '127.0.0.1',
        headers     => {},
    );
    is( $opted_in->[0], 200, 'the explicit opt-in still permits tokenized execution' );
    like( _executed_output($opted_in), qr/\Q$MARKER\E/, 'the opted-in token payload executes as before' );
}

done_testing();

__END__

=head1 NAME

t/132-transient-token-file-bypass.t - contract test for the transient token default-deny policy

=head1 PURPOSE

A regression contract test for DD-425. It pins that the default-deny policy on
tokenized transient web execution cannot be lifted by adding a file parameter or
an C</ajax/E<lt>fileE<gt>> path segment to the request.

C<Developer::Dashboard::Web::App> refuses tokenized C<?token=> execution unless
C<DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS> opts in, because such a token is
decoded and run as Perl by the page runtime. This test proves the refusal covers
every route that reaches the tokenized code path, not only the bare C</ajax>
form.

=head1 WHY IT EXISTS

The allow check used to return early as soon as a file value was present, while
the request handler it guards gives the token strict precedence over that same
file value. The two disagreed about which parameter wins, so the gate protected
a branch the handler never took and C</ajax?file=x&token=...> executed arbitrary
Perl with the policy switched off. This file locks the two back together.

=head1 WHEN TO USE

Run it whenever the C</ajax> routing, the transient URL policy, or the ordering
inside the older Ajax request handler changes.

=head1 HOW TO USE

  prove -lv t/132-transient-token-file-bypass.t

=head1 WHAT USES IT

The repository test suite, through C<prove -lr t>, and the coverage gate that
requires every branch of the policy check to be exercised.

=head1 EXAMPLES

Run the whole contract:

  prove -lv t/132-transient-token-file-bypass.t

Run it together with the neighbouring web application contracts:

  prove -lv t/126-attribute-escaping.t t/130-csrf-origin-defense.t t/132-transient-token-file-bypass.t

Run it under the coverage harness while checking the web application module:

  HARNESS_PERL_SWITCHES=-MDevel::Cover=-blib,0 prove -l t/132-transient-token-file-bypass.t

=cut
