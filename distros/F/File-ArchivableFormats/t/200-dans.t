use Test::More;
use Test::Deep;

use Capture::Tiny qw(capture_stderr);
use File::ArchivableFormats;
use File::Spec::Functions qw(catfile);
use File::Temp;
use Path::Tiny;
use File::MimeInfo::Magic;

my $af = File::ArchivableFormats->new(
    driver => "DANS",
);
isa_ok($af, "File::ArchivableFormats");

my $skip_file_mimeinfo_tests = 0;
my $stderr = capture_stderr \&File::MimeInfo::Magic::rehash;
if ($stderr =~ /^WARNING: You don't seem to have a mime-info database/) {
    $skip_file_mimeinfo_tests = 1;
}

{
    note "Supported file type for DANS";

    open my $file, '<', catfile(qw(t data README.md));
    my $status = $af->identify_from_fh($file);

    my %expect = (
        DANS => {
            archivable => 1,
            preferred_extension => '.txt',
            allowed_extensions => [ '.asc', '.txt' ],
            types => [
                'Plain text (Unicode)',
                'Plain text (Non-Unicode)',
                'Statistical data (data (.csv) + setup)',
                'Raspter GIS (ASCII GRID)',
            ],
        },
        mime_type => 'text/plain',
    );

    is_deeply($status, \%expect, "Perl test file is archivable by DANS");
}

{
    note "File::Temp handling";
    my $tmp = File::Temp->new(UNLINK => 1);
    print $tmp "foo bar baz";
    $tmp->close();

    my $status = $af->identify_from_path($tmp->filename);

    is($status->{DANS}{archivable}, 1, "File::Temp handling goes well");

}


SKIP: {
    skip "shared-mime-info missing", 1 if $skip_file_mimeinfo_tests;

    note "Unsupported file type for DANS";

    open my $file, '<', catfile(qw(t data 16_Zorginstituut.ztb));
    my $status = $af->identify_from_fh($file);

    my %expect = (
        DANS => {
            archivable => 0,
            allowed_extensions => [ ],
            types => [ ],
        },
        mime_type => 'application/zip',
    );

    cmp_deeply($status, \%expect, "ZTB test file is not archivable by DANS");
}

SKIP: {
    skip "shared-mime-info missing", 2 if $skip_file_mimeinfo_tests;

    note "docx handling";
    foreach (qw(Xential.docx Xential-2.docx)) {
        my $filename = catfile(qw(t data), $_);
        my $status = $af->identify_from_path($filename);
        is($status->{DANS}{archivable},
            1, ".docx goes well: $filename");
        is(
            $status->{mime_type},
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            "$filename is a docx file"
        );
    }
}


SKIP: {
    skip "shared-mime-info missing", 8 if $skip_file_mimeinfo_tests;

    note "Path::Tiny";
    foreach (qw(Xential.docx Xential-2.docx)) {
        my $filename = catfile(qw(t data), $_);
        my $path = Path::Tiny->new($filename);

        my $status = $af->identify_from_path("$path");
        is($status->{DANS}{archivable},
            1, "Path::Tiny goes well: $filename");
        is(
            $status->{mime_type},
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            "$filename is a docx file"
        );

        $status = $af->identify_from_path($path);
        is($status->{DANS}{archivable},
            1, "Path::Tiny  handling goes well with a filehandle: $path");
        is(
            $status->{mime_type},
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            "$filename is a docx file"
        );
    }
}


done_testing;
