use Test::More;
use Test::Deep;

use File::ArchivableFormats;
use File::Temp;
use File::Spec::Functions qw(catfile);

my $af = File::ArchivableFormats->new(
    driver => "DANS",
);
isa_ok($af, "File::ArchivableFormats");

{
    note "Supported file type for DANS";

    open my $file, '<', catfile(qw(t 100-fileformats.t));
    my $status = $af->identify_from_fh($file);

    my %expect = (
        DANS => {
            archivable => 1,
            allowed_extensions => [ '.asc', '.txt' ],
            types => [
                'Plain text (Unicode)',
                'Plain text (Non-Unicode)',
                'Statistical data (data (.csv) + setup)',
                'Raspter GIS (ASCII GRID)',
                'Raspter GIS (ASCII GRID)'
            ],
        },
        mime_type => 'text/plain',
    );

    is_deeply($status, \%expect, "Perl test file is archivable by DANS");
}

{
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

    is_deeply($status, \%expect, "ZTB test file is not archivable by DANS");
}

{
    note "File::Temp handling";
    my $tmp = File::Temp->new(UNLINK => 1);
    print $tmp "foo bar baz";
    $tmp->close();

    my $status = $af->identify_from_path($tmp->filename);

    is($status->{DANS}{archivable}, 1, "File::Temp handling goes well");

}

{
    note "docx handling";
    foreach (qw(Xential.docx Xential-2.docx)) {
        my $filename = catfile(qw(t data), $_);
        my $status = $af->identify_from_path($filename);
        is($status->{DANS}{archivable}, 1, "File::Temp handling goes well: $filename");
        is($status->{mime_type}, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', "$filename is a docx file");
    }


}
done_testing;
