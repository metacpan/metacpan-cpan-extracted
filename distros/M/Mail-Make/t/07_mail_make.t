#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - t/07_mail_make.t
## Test suite for Mail::Make top-level API
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use Module::Generic::File qw( tempfile );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'Mail::Make' ) or BAIL_OUT( 'Unable to load Mail::Make' );
};

# NOTE: fluent: basic plain text message
subtest 'fluent: basic plain text message' => sub
{
    my $mail = Mail::Make->new( ( $DEBUG ? ( debug => $DEBUG ) : () ) )
        ->from(    'sender@example.com' )
        ->to(      'recipient@example.com' )
        ->subject( 'Test Subject' )
        ->plain(   "Hello, plain text!\n" );
    ok( defined( $mail ), 'fluent construction succeeds' );
    my $str = $mail->as_string;
    ok( defined( $str ) && !ref( $str ), 'as_string returns string' );
    like( $str, qr/From: sender\@example\.com/,  'From header present' );
    like( $str, qr/To: recipient\@example\.com/, 'To header present' );
    like( $str, qr/Subject: Test Subject/,       'Subject header present' );
    like( $str, qr/MIME-Version: 1\.0/,          'MIME-Version header present' );
    like( $str, qr/Content-Type: text\/plain/,   'text/plain Content-Type present' );
    like( $str, qr/Hello, plain text!/,          'body content present' );
};

# NOTE: fluent: method chaining returns $self
subtest 'fluent: method chaining returns $self' => sub
{
    my $mail = Mail::Make->new;
    my $rv   = $mail->from( 'a@a.com' );
    is( ref( $rv ), 'Mail::Make', 'from() returns $self' );
    $rv = $mail->to( 'b@b.com' );
    is( ref( $rv ), 'Mail::Make', 'to() returns $self' );
    $rv = $mail->subject( 'test' );
    is( ref( $rv ), 'Mail::Make', 'subject() returns $self' );
    $rv = $mail->plain( "body" );
    is( ref( $rv ), 'Mail::Make', 'plain() returns $self' );
};

# NOTE: fluent: multiple To recipients
subtest 'fluent: multiple To recipients' => sub
{
    my $mail = Mail::Make->new
        ->from( 'a@example.com' )
        ->to( 'b@example.com' )
        ->to( 'c@example.com' )
        ->subject( 's' )
        ->plain( "x" );
    my $str = $mail->as_string;
    like( $str, qr/To: b\@example\.com, c\@example\.com/, 'multiple recipients joined' );
};

# NOTE: fluent: CC and BCC
subtest 'fluent: CC and BCC' => sub
{
    my $mail = Mail::Make->new
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->cc(      'c@example.com' )
        ->bcc(     'd@example.com' )
        ->subject( 'cc-bcc test' )
        ->plain(   "body" );
    my $str = $mail->as_string;
    like( $str, qr/Cc: c\@example\.com/,  'Cc header present' );
    like( $str, qr/Bcc: d\@example\.com/, 'Bcc header present' );
};

# NOTE: fluent: plain + html creates multipart/alternative
subtest 'fluent: plain + html creates multipart/alternative' => sub
{
    my $mail = Mail::Make->new
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'alt test' )
        ->plain(   "plain version" )
        ->html(    "<p>html version</p>" );
    my $str = $mail->as_string;
    like( $str, qr/multipart\/alternative/, 'multipart/alternative created for plain+html' );
    like( $str, qr/plain version/,          'plain part present' );
    like( $str, qr/html version/,           'html part present' );
};

# NOTE: fluent: attach_inline with CID
subtest 'fluent: attach_inline with CID' => sub
{
    my $path = tempfile( cleanup => 1, open => 1 );
    $path->print( "PNG data" );
    $path->close;

    my $mail = Mail::Make->new
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'inline test' )
        ->html(    '<img src="cid:logo@example.com">' )
        ->attach_inline(
            type => 'image/png',
            path => $path,
            id   => 'logo@example.com',
        );
    ok( defined( $mail ), 'attach_inline() succeeds' );
    my $str = $mail->as_string;
    ok( defined( $str ), 'as_string succeeds' );
    like( $str, qr/Content-ID: <logo\@example\.com>/, 'Content-ID present' );
    like( $str, qr/Content-Disposition: inline/,      'inline disposition present' );
};

# NOTE: fluent: attach_inline requires cid
subtest 'fluent: attach_inline requires cid' => sub
{
    my $path = tempfile( cleanup => 1, open => 1 );
    $path->close;
    my $mail = Mail::Make->new;
    # Silence warnings output
    no warnings 'Mail::Make';
    # local $SIG{__WARN__} = sub{};
    my $rv   = $mail->attach_inline( type => 'image/png', path => $path );
    ok( !defined( $rv ), 'attach_inline() without cid returns error' );
    like( $mail->error, qr/'id' or 'cid' is required/i, 'error message correct' );
};

# NOTE: fluent: attach requires data or path
subtest 'fluent: attach requires data or path' => sub
{
    my $mail = Mail::Make->new;
    # Silence warnings output
    # local $SIG{__WARN__} = sub{};
    no warnings 'Mail::Make';
    my $rv   = $mail->attach( type => 'image/png' );
    ok( !defined( $rv ), 'attach() without data/path returns error' );
    like( $mail->error, qr/'data' or 'path' is required/i, 'error message correct' );
};

# NOTE: fluent: extra header via header()
subtest 'fluent: extra header via header()' => sub
{
    my $mail = Mail::Make->new
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'header test' )
        ->header(  'X-Mailer', 'Mail::Make v0.1.0' )
        ->plain(   "body" );
    my $str = $mail->as_string;
    like( $str, qr/X-Mailer: Mail::Make v0\.1\.0/, 'extra header present' );
};

# NOTE: fluent: no parts returns error from as_string
subtest 'fluent: no parts returns error from as_string' => sub
{
    my $mail = Mail::Make->new->from( 'a@example.com' )->to( 'b@example.com' );
    # Silence warnings output
    # local $SIG{__WARN__} = sub{};
    no warnings 'Mail::Make';
    my $str  = $mail->as_string;
    ok( !defined( $str ), 'as_string fails with no body parts' );
    like( $mail->error, qr/No body parts/i, 'error mentions No body parts' );
};

# NOTE: build: basic usage
subtest 'build: basic usage' => sub
{
    my $mail = Mail::Make->build(
        from    => 'a@example.com',
        to      => 'b@example.com',
        subject => 'Build test',
        plain   => "Build method body\n",
    );
    ok( defined( $mail ), 'build() returns object' );
    my $str = $mail->as_string;
    ok( defined( $str ), 'as_string succeeds' );
    like( $str, qr/Build method body/, 'body content present' );
};

# NOTE: build: to as array ref
subtest 'build: to as array ref' => sub
{
    my $mail = Mail::Make->build(
        from    => 'a@example.com',
        to      => [ 'b@example.com', 'c@example.com' ],
        subject => 's',
        plain   => "x",
    );
    ok( defined( $mail ), 'build() with to arrayref succeeds' );
    my $str = $mail->as_string;
    like( $str, qr/b\@example\.com/, 'first recipient present' );
    like( $str, qr/c\@example\.com/, 'second recipient present' );
};

# NOTE: build: extra headers hash
subtest 'build: extra headers hash' => sub
{
    my $mail = Mail::Make->build(
        from    => 'a@example.com',
        to      => 'b@example.com',
        subject => 's',
        plain   => "x",
        headers => { 'X-Custom' => 'hello' },
    );
    ok( defined( $mail ), 'build() with extra headers succeeds' );
    my $str = $mail->as_string;
    like( $str, qr/X-Custom: hello/, 'extra header present in output' );
};

# NOTE: build: reply_to and sender
subtest 'build: reply_to and sender' => sub
{
    my $mail = Mail::Make->build(
        from     => 'a@example.com',
        reply_to => 'reply@example.com',
        sender   => 'sender@example.com',
        to       => 'b@example.com',
        subject  => 's',
        plain    => "x",
    );
    my $str = $mail->as_string;
    like( $str, qr/Reply-To: reply\@example\.com/, 'Reply-To present' );
    like( $str, qr/Sender: sender\@example\.com/,  'Sender present' );
};

# NOTE: build: attach single scalar shorthand
subtest 'build: attach single scalar shorthand' => sub
{
    my $path = tempfile( extension => 'pdf', cleanup => 1, open => 1 );
    $path->print( "%PDF-1.4 fake pdf content" );
    $path->close;

    my $mail = Mail::Make->build(
        from    => 'a@example.com',
        to      => 'b@example.com',
        subject => 'attach scalar test',
        plain   => "See attached.\n",
        attach  => $path,
    );
    ok( defined( $mail ), 'build() with attach scalar shorthand succeeds' );
    my $str = $mail->as_string;
    ok( defined( $str ), 'as_string succeeds' );
    like( $str, qr/Content-Disposition: attachment/, 'attachment disposition present' );
    like( $str, qr/multipart\/mixed/, 'multipart/mixed structure assembled' );
};

# NOTE: build: attach arrayref of scalars
subtest 'build: attach arrayref of scalars' => sub
{
    my $path1 = tempfile( extension => 'pdf', cleanup => 1, open => 1 );
    $path1->print( "%PDF-1.4 first" );
    $path1->close;
    my $path2 = tempfile( extension => 'pdf', cleanup => 1, open => 1 );
    $path2->print( "%PDF-1.4 second" );
    $path2->close;

    my $mail = Mail::Make->build(
        from    => 'a@example.com',
        to      => 'b@example.com',
        subject => 'attach arrayref test',
        plain   => "See attached.\n",
        attach  => [ $path1, $path2 ],
    );
    ok( defined( $mail ), 'build() with attach arrayref of scalars succeeds' );
    my $str = $mail->as_string;
    ok( defined( $str ), 'as_string succeeds' );
    like( $str, qr/multipart\/mixed/, 'multipart/mixed structure assembled' );
    my $attachment_count = () = $str =~ /Content-Disposition: attachment/g;
    is( $attachment_count, 2, 'two attachment parts present' );
};

# NOTE: build: attach arrayref of hashrefs
subtest 'build: attach arrayref of hashrefs' => sub
{
    my $path1 = tempfile( extension => 'pdf', cleanup => 1, open => 1 );
    $path1->print( "%PDF-1.4 first" );
    $path1->close;
    my $path2 = tempfile( extension => 'pdf', cleanup => 1, open => 1 );
    $path2->print( "%PDF-1.4 second" );
    $path2->close;

    my $mail = Mail::Make->build(
        from    => 'a@example.com',
        to      => 'b@example.com',
        subject => 'attach arrayref of hashrefs test',
        plain   => "See attached.\n",
        attach  => [
            { path => $path1, filename => 'Q4 Report.pdf' },
            { path => $path2, filename => 'Access Log.pdf' },
        ],
    );
    ok( defined( $mail ), 'build() with attach arrayref of hashrefs succeeds' );
    my $str = $mail->as_string;
    ok( defined( $str ), 'as_string succeeds' );
    like( $str, qr/Q4 Report\.pdf/,   'first custom filename present' );
    like( $str, qr/Access Log\.pdf/,  'second custom filename present' );
    my $attachment_count = () = $str =~ /Content-Disposition: attachment/g;
    is( $attachment_count, 2, 'two attachment parts present' );
};

# NOTE: build: attach mixed arrayref
subtest 'build: attach mixed arrayref' => sub
{
    my $path1 = tempfile( extension => 'pdf', cleanup => 1, open => 1 );
    $path1->print( "%PDF-1.4 first" );
    $path1->close;
    my $path2 = tempfile( extension => 'pdf', cleanup => 1, open => 1 );
    $path2->print( "%PDF-1.4 second" );
    $path2->close;

    my $mail = Mail::Make->build(
        from    => 'a@example.com',
        to      => 'b@example.com',
        subject => 'attach mixed arrayref test',
        plain   => "See attached.\n",
        attach  => [
            $path1,
            { path => $path2, filename => 'Custom Name.pdf' },
        ],
    );
    ok( defined( $mail ), 'build() with mixed attach arrayref succeeds' );
    my $str = $mail->as_string;
    ok( defined( $str ), 'as_string succeeds' );
    like( $str, qr/Custom Name\.pdf/, 'custom filename from hashref present' );
    my $attachment_count = () = $str =~ /Content-Disposition: attachment/g;
    is( $attachment_count, 2, 'two attachment parts present' );
};

# NOTE: as_entity returns Mail::Make::Entity
subtest 'as_entity returns Mail::Make::Entity' => sub
{
    my $mail = Mail::Make->new
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'entity test' )
        ->plain(   "content" );
    my $entity = $mail->as_entity;
    ok( defined( $entity ), 'as_entity() returns object' );
    ok( $entity->isa( 'Mail::Make::Entity' ), 'returned object is Mail::Make::Entity' );
};

done_testing();

__END__
