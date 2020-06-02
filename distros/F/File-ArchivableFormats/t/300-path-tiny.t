use Test::More;
use Test::Deep;

use Capture::Tiny qw(capture_stderr);
use File::ArchivableFormats;
use File::Spec::Functions qw(catfile);
use Path::Tiny;
use File::MimeInfo::Magic;

my $stderr = capture_stderr \&File::MimeInfo::Magic::rehash;
if ($stderr =~ /^WARNING: You don't seem to have a mime-info database/) {
    plan skip_all => 'Test irrelevant without mime-info database';
}


my $af = File::ArchivableFormats->new(
    driver => "DANS",
);
isa_ok($af, "File::ArchivableFormats");

my $path = Path::Tiny->new(catfile(qw(t data README.md)));

my $status = $af->identify_from_path("$path");
is($status->{DANS}{archivable},
    1, "Path::Tiny goes well: $filename");
is(
    $status->{mime_type},
    'text/markdown',
    "$filename is a plain text file"
);

$status = $af->identify_from_path($path);
is($status->{DANS}{archivable},
    1, "Path::Tiny  handling goes well with a filehandle: $path");
is(
    $status->{mime_type},
    'text/markdown',
    "$filename is a plain text file"
);

{
    my $path = Path::Tiny->new(catfile(qw(t data README)));

    my $status = $af->identify_from_path("$path");
    is($status->{DANS}{archivable},
        1, "Path::Tiny goes well: $filename");
    is(
        $status->{mime_type},
        'text/x-readme',
        "$filename is a README text file"
    );

    $status = $af->identify_from_path($path);
    is($status->{DANS}{archivable},
        1, "Path::Tiny  handling goes well with a filehandle: $path");
    is(
        $status->{mime_type},
        'text/x-readme',
        "$filename is a README text file"
    );
}

done_testing;
