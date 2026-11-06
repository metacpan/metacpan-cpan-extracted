#!perl

use strict;
use warnings;

use Test::More;

use HTTP::Body;
use File::Temp qw/ tempdir /;
use Time::HiRes qw/ time /;

# While $basename_regexp holds its default, the suffix is found by a string
# search instead of by running the regexp.  The two must give the same
# result for every basename.

my $default = qr/[^.]+(\.[^\\\/]+)$/;

sub by_regexp { $_[0] =~ $default ? $1 : q{} }

sub show { my $s = shift; $s =~ s/([^\x21-\x7e])/sprintf '\\x%02x', ord $1/ge; "'$s'" }

can_ok( 'HTTP::Body::MultiPart', '_default_suffix' );
my $suffix = \&HTTP::Body::MultiPart::_default_suffix;

is( "$HTTP::Body::MultiPart::basename_regexp", "$default", 'default $basename_regexp is unchanged' );

for my $name (
    '', '.', '..', 'x.', '.bashrc', 'noext', 'a..b', '..a.b', 'a.b.',
    'foo.tar.gz', 'photo.jpeg', 'dir/x.png', 'a.b/c', 'a.b\\',
    'C:\\dir\\x.txt', 'C:\\a.d\\bar', 'dir\\.hidden', "f.txt\n", "f.\n",
    "\xc3\xa4rger.txt", ( 'a.' x 127 ) . "a\\",
) {
    is( $suffix->($name), by_regexp($name), 'suffix of ' . show($name) );
}

{
    srand 20261027;
    my @alpha = ( '.', '.', '.', 'a', 'b', '\\', '/', "\n", ' ', "\xff" );
    my ( $bad, $first ) = ( 0, undef );
    for ( 1 .. 100_000 ) {
        my $name = join '', map { $alpha[ rand @alpha ] } 1 .. int rand 12;
        next if $suffix->($name) eq by_regexp($name);
        $first = $name unless defined $first;
        $bad++;
    }
    is( $bad, 0, 'string search matches the regexp on 100000 random basenames' )
      or diag( 'first mismatch: ' . show($first) );
}

my $ct = 'multipart/form-data; boundary=x';

sub upload_tempname {
    my $filename = shift;
    my $raw  = qq{--x\r\nContent-Disposition: form-data; name="f"; filename="$filename"\r\n\r\nD\r\n--x--\r\n};
    my $body = HTTP::Body->new( $ct, length $raw );
    $body->tmpdir( tempdir( CLEANUP => 1 ) );
    $body->cleanup(1);
    $body->add($raw);
    return $body->upload->{f}{tempname};
}

{
    local $HTTP::Body::MultiPart::file_temp_suffix = undef;
    like( upload_tempname('C:\\photos\\holiday.tar.gz'), qr/\.tar\.gz$/, 'default suffix of an upload comes from the string search' );
}

{
    # A regexp of its own is still run, on the last 255 bytes of the basename.
    local $HTTP::Body::MultiPart::file_temp_suffix = undef;
    local $HTTP::Body::MultiPart::basename_regexp  = qr/(\.[^.]+)$/;
    like( upload_tempname('archive.tar.gz'), qr/\.gz$/, 'a custom $basename_regexp is still used' );
    unlike( upload_tempname('archive.tar.gz'), qr/\.tar\.gz$/, 'a custom $basename_regexp replaces the default rule' );
}

{
    # A copy of the default pattern is a regexp of its own and is run, so the
    # 255-byte limit is what keeps a hostile filename cheap.
    local $HTTP::Body::MultiPart::file_temp_suffix = undef;
    local $HTTP::Body::MultiPart::basename_regexp  = qr/[^.]+(\.[^\\\/]+)$/;
    my $t = time;
    upload_tempname( ( 'a.' x 16000 ) . 'a\\' ) for 1 .. 2;
    cmp_ok( time - $t, '<', 5, 'a hostile filename stays cheap with a custom $basename_regexp' );
}

done_testing;
