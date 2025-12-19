#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use lib './lib';
use open ':std' => 'utf8';
use Test::More;
use JSON ();

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
};

my $json = JSON->new->canonical->allow_nonref;

my $schema = 
{
    '$schema' => 'https://json-schema.org/draft/2020-12/schema',
    type      => 'object',
    '$comment'=> 'root comment',
    required  => [ 'x' ],
    properties => 
    {
        x => 
        {
            type => 'integer',
            '$comment' => 'x must be integer'
        }
    },
    additionalProperties => 0,
};

sub _validator
{
    return JSON::Schema::Validate->new( $schema,
        compile => 1,
        trace   => 1,
        trace_limit => 50,
        normalize_instance => 1,
    )->register_builtin_formats;
}

# 1) handler gets invoked with pointer and text
{
    my @got;
    my $js = _validator()->set_comment_handler(sub
    {
        my( $ptr, $text ) = @_;
        push( @got, [ $ptr, $text ] );
    });

    my $ok = $js->validate({ x => 1 });
    ok( $ok, 'validation passes' );

    ok( @got >= 2, 'handler called for at least two comments' );

    my $have_root = grep{ $_->[0] eq '#' && $_->[1] =~ /root comment/ } @got;
    ok( $have_root, 'saw root comment' );

    my $have_x = grep{ $_->[0] =~ m{#/properties~1x$} && $_->[1] =~ /x must be integer/ } @got;
    ok( $have_x, 'saw x comment' );
}

# 2) non-CODE handler is ignored with warning, and does not croak
{
    my $warn;
    local $SIG{__WARN__} = sub{ $warn = $_[0] };

    my $js = _validator()->set_comment_handler( 'not a code ref' );
    ok( $js->validate({ x => 2 }), 'still validates ok' );
    like( $warn // '', qr/Warning only: the handler provided is not a code reference\./,
        'warned about non-CODE handler' );
}

# 3) handler exceptions are swallowed (do not fail validation)
{
    my $js = _validator()->set_comment_handler(sub{ die "oops\n" });
    ok( $js->validate({ x => 3 }), 'validation still ok despite handler die' );
}

# 4) trace contains $comment entries when tracing is on
{
    my $js = _validator()->set_comment_handler(undef); # silence
    my $ok = $js->validate({ x => 4 });
    ok( $ok, 'validation ok' );

    my $trace = $js->get_trace;
    my $have_comment = grep{ $_->{keyword} && $_->{keyword} eq '$comment' } @$trace;
    ok( $have_comment, 'trace recorded $comment' );
}

# 5) comments do not affect failure logic
{
    my $js = _validator();
    ok( !$js->validate({}), 'missing required fails as usual' );

    my $err = $js->error;

    # Prefer checking the machine field if available:
    if( eval{ defined $err->keyword } )
    {
        is( $err->keyword, 'required', 'error keyword is "required"' );
    }
    else
    {
        # Fallback to a tolerant wording check:
        like( $err->message, qr/(?:missing required|required property)/i,
            'message mentions a required-property failure' );
    }

    # Optional: sanity checks that don't depend on phrasing
    like( $err->path // '', qr{^#$|^#/(?:.+)}, 'path looks like a JSON Pointer' );
}

done_testing();

__END__
