#!perl -w

use strict;
use Test::More;
use Test::Fatal;

use LWP::MediaTypes;

my $url1 = URI->new('http://www/foo/test.gif?search+x#frag');
my $url2 = URI->new('http:test');

my $file = "./README";

my $nocando = TestNoCanDo->new();
my $fh = TestFileTemp->new();

my @tests = (
    ["/this.dir/file.html" => "text/html",],
    ["test.gif.htm"        => "text/html",],
    ["test.txt.gz"         => "text/plain", "gzip"],
    ["gif.foo"             => "application/octet-stream",],
    ["lwp-0.03.tar.Z"      => "application/x-tar", "compress"],
    [$file                 => "text/plain",],
    ["/random/file"        => "application/octet-stream",],
    [($^O eq 'VMS' ? "nl:" : "/dev/null") => "text/plain",],
    [$url1 => "image/gif",],
    [$url2 => "application/octet-stream",],
    ["x.ppm.Z.UU" => "image/x-portable-pixmap", "compress", "x-uuencode",],
    [$fh          => "text/plain",],
    [$nocando     => "text/plain",],
);

if ($ENV{HOME} and -f "$ENV{HOME}/.mime.types") {
   warn "
The MediaTypes test might fail because you have a private ~/.mime.types file
If you get a failed test, try to move it away while testing.
";
}


for (@tests) {
    my($file, $expectedtype, @expectedEnc) = @$_;
    my $type1 = guess_media_type($file);
    my($type, @enc) = guess_media_type($file);
    is($type1, $type);
    is($type, $expectedtype);
    is("@enc", "@expectedEnc");
}

like(
    exception {
        guess_media_type({});
    },
    qr/Unable to determine filetype on unblessed refs/,
    "Cannot pass unblessed refs"
);

my @imgSuffix = media_suffix('image/*');
note "Image suffixes: @imgSuffix";
ok(grep $_ eq "gif", @imgSuffix);

my @audioSuffix = media_suffix('AUDIO/*');
note "Audio suffixes: @audioSuffix";
ok(grep $_ eq 'oga', @audioSuffix);
is(media_suffix('audio/OGG'), 'oga');

my $r = Headers->new;
guess_media_type("file.tar.gz.uu", $r);
is($r->header("Content-Type"), "application/x-tar");

my @enc = $r->header("Content-Encoding");
is("@enc", "gzip x-uuencode");

#
use LWP::MediaTypes qw(add_type add_encoding);
add_type("x-world/x-vrml", qw(wrl vrml));
add_encoding("x-gzip" => "gz");
add_encoding(rot13 => "r13");

my @x = guess_media_type("foo.vrml.r13.gz");
#print "@x\n";
is("@x", "x-world/x-vrml rot13 x-gzip");

#print LWP::MediaTypes::_dump();

done_testing();

BEGIN {
    # mockups
    package URI;
    sub new {
	my($class, $str) = @_;
	bless \$str, $class;
    }

    sub path {
	my $self = shift;
	my $p = $$self;
	$p =~ s/[\?\#].*//;
	return $p;
    }

    package Headers;
    sub new {
	my $class = shift;
	return bless {}, $class;
    }

    sub header {
	my $self = shift;
	my $k = lc(shift);
	my $old = $self->{$k};
	if (@_) {
	    $self->{$k} = shift;
	}
	if (ref($old) eq "ARRAY") {
	    return @$old if wantarray;
	    return join(", ", @$old)
	}
	return $old;
    }

    package TestNoCanDo;

    sub new {
        my $class = shift;
        return bless {}, $class;
    }

    sub to_string {
        return "./README"
    }

    use overload '""' => 'to_string';

    package TestFileTemp;

    sub new {
        my $class = shift;
        return bless {}, $class;
    }

    sub filename {
        return "./README"
    }

}

