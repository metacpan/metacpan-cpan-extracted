use strict;
use warnings;
use Test::More 0.90;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use IPC::Open3;
use Symbol qw(gensym);
use lib 'lib';
use FixMP3Tags::Processor;

sub write_empty_file
{
    my ($path) = @_;
    open my $fh, '>', $path or die "Cannot create $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}

sub capture_stdout
{
    my ($callback) = @_;
    my $output = '';
    open my $capture, '>', \$output or die "Cannot capture STDOUT: $!";
    my $previous = select($capture);
    my $ok = eval {
        $callback->();
        1;
    };
    my $error = $@;
    select($previous);
    close $capture;
    die $error unless $ok;
    return $output;
}

my @warnings;
my $temp_dir = tempdir(CLEANUP => 1);
my $artist_dir = File::Spec->catdir($temp_dir, 'Artist Name');
my $dated_album = File::Spec->catdir($artist_dir, q{2025.11'New Album});
make_path($dated_album);
my $track_file = write_empty_file(
    File::Spec->catfile($dated_album, '01.Hit_Single.mp3')
);
my $plain_album = File::Spec->catdir($artist_dir, 'Unsorted Album');
make_path($plain_album);
my $plain_track = write_empty_file(
    File::Spec->catfile($plain_album, '02.Second.Track.mp3')
);
my $bad_name = write_empty_file(
    File::Spec->catfile($dated_album, 'cover-art.mp3')
);
write_empty_file(
    File::Spec->catfile($plain_album, '04.Uppercase_Extension.MP3')
);

# Directory-name recognition and path discovery.
ok(FixMP3Tags::Processor->is_cd_directory('CD1'), 'recognizes CD1');
ok(FixMP3Tags::Processor->is_cd_directory('Disc 2'), 'recognizes Disc 2');
ok(FixMP3Tags::Processor->is_cd_directory('2'), 'recognizes numeric CD directory');
ok(FixMP3Tags::Processor->is_cd_directory('2 Disc'), 'recognizes a number before the CD marker');
ok(!FixMP3Tags::Processor->is_cd_directory('Deluxe Edition'), 'does not mistake an ordinary directory for a CD directory');
ok(!FixMP3Tags::Processor->is_cd_directory(undef), 'handles an undefined directory name');

my ($album_dir, $found_artist, $cd_dir) =
    FixMP3Tags::Processor->find_album_dir($track_file);
is($album_dir, abs_path($dated_album), 'finds the album directory');
is($found_artist, abs_path($artist_dir), 'finds the artist directory');
ok(!defined $cd_dir, 'no CD directory is reported for a standard layout');

my $cd_album = File::Spec->catdir($artist_dir, '2024-03 Live Album');
my $cd_dir_path = File::Spec->catdir($cd_album, 'CD 1');
make_path($cd_dir_path);
my $cd_track = write_empty_file(
    File::Spec->catfile($cd_dir_path, '03.Live_Track.mp3')
);
my ($cd_album_found, $cd_artist_found, $cd_found) =
    FixMP3Tags::Processor->find_album_dir($cd_track);
is($cd_album_found, abs_path($cd_album), 'steps up from a CD directory to the album');
is($cd_artist_found, abs_path($artist_dir), 'finds the artist for a CD layout');
is($cd_found, 'CD 1', 'returns the CD directory name');

@warnings = ();
my @missing_album_path;
{
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    @missing_album_path = FixMP3Tags::Processor->find_album_dir(
        File::Spec->catfile($temp_dir, 'missing.mp3')
    );
}
ok(!defined $missing_album_path[0], 'path discovery rejects a missing file');
like(join('', @warnings), qr/Cannot get absolute path/, 'path discovery warns when a file is missing');

my ($empty_year, $empty_month, $empty_album) =
    FixMP3Tags::Processor->extract_album_info(undef, undef);
is_deeply(
    [$empty_year, $empty_month, $empty_album],
    [undef, undef, ''],
    'empty album input is handled safely'
);
my ($bad_year, $bad_month, $bad_album) =
    FixMP3Tags::Processor->extract_album_info('2025', undef);
is_deeply(
    [$bad_year, $bad_month, $bad_album],
    [undef, undef, '2025'],
    'year without a month remains an unparsed album name'
);

my $missing_result;
{
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $missing_result = FixMP3Tags::Processor->process_file(
        File::Spec->catfile($temp_dir, 'does-not-exist.mp3'),
        { quiet => 1, dry_run => 1, pattern => undef }
    );
}
ok(!defined $missing_result, 'missing file is rejected');
like(join('', @warnings), qr/Invalid file path/, 'missing file emits a useful warning');

@warnings = ();
my $bad_name_result;
{
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $bad_name_result = FixMP3Tags::Processor->process_file(
        $bad_name,
        { quiet => 1, dry_run => 1, pattern => undef }
    );
}
ok(!defined $bad_name_result, 'filename without a track number is rejected');
like(join('', @warnings), qr/doesn't match pattern NN\.SongName/, 'bad filename reports the expected format');

my $dry_run_result = FixMP3Tags::Processor->process_file(
    $track_file,
    { quiet => 1, dry_run => 1, pattern => undef }
);
ok($dry_run_result, 'valid file succeeds in dry-run mode');

# Mock MP3::Tag so these tests verify frame selection without writing MP3 files.
{
    no warnings qw(redefine once);
    local *MP3::Tag::new = sub {
        my ($class, $path) = @_;
        return Local::MockMP3->new($path);
    };

    my $before_dry_run = $Local::MockMP3::CREATED;
    FixMP3Tags::Processor->process_directory(
        $temp_dir,
        { quiet => 1, dry_run => 1, pattern => undef }
    );
    is($Local::MockMP3::CREATED, $before_dry_run, 'directory dry-run never opens files for writing');

    $Local::MockMP3::FAIL_WRITE = 0;
    my $write_result = FixMP3Tags::Processor->process_file(
        $track_file,
        { quiet => 1, dry_run => 0, pattern => undef }
    );
    ok($write_result, 'valid file writes tags successfully through the mock');
    is_deeply(
        $Local::MockMP3::LAST->{ID3v2}->{frames},
        [
            ['TPE1', 'Artist Name'],
            ['TALB', 'New Album'],
            ['TIT2', 'Hit Single'],
            ['TRCK', '01'],
            ['TYER', '2025'],
        ],
        'writes artist, album, title, track, and year frames'
    );
    ok($Local::MockMP3::LAST->{ID3v2}->{written}, 'writes the new ID3v2 tag');
    ok($Local::MockMP3::LAST->{closed}, 'closes the MP3 after writing');
    ok(!exists $Local::MockMP3::LAST->{ID3v2}->{legacy}, 'the mocked old tag is replaced');

    $Local::MockMP3::FAIL_WRITE = 0;
    my $plain_result = FixMP3Tags::Processor->process_file(
        $plain_track,
        { quiet => 1, dry_run => 0, pattern => undef }
    );
    ok($plain_result, 'album without a date is still processed');
    my @plain_frame_ids = map { $_->[0] } @{$Local::MockMP3::LAST->{ID3v2}->{frames}};
    ok(!grep($_ eq 'TYER', @plain_frame_ids), 'year frame is omitted when no year is detected');

    $Local::MockMP3::FAIL_WRITE = 1;
    @warnings = ();
    my $failed_write;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $failed_write = FixMP3Tags::Processor->process_file(
            $track_file,
            { quiet => 1, dry_run => 0, pattern => undef }
        );
    }
    ok(!defined $failed_write, 'tag-writing failure is returned as failure');
    like(join('', @warnings), qr/Failed to update tags.*simulated write failure/s, 'tag-writing failure is reported');
    $Local::MockMP3::FAIL_WRITE = 0;

    my $created_before_scan = $Local::MockMP3::CREATED;
    my $scan_output = capture_stdout(sub {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        FixMP3Tags::Processor->process_directory(
            $temp_dir,
            { quiet => 1, dry_run => 0, pattern => undef }
        );
    });
    is(
        $Local::MockMP3::CREATED - $created_before_scan,
        4,
        'directory processing recurses and processes only valid MP3 files, including uppercase extensions'
    );
    like($scan_output, qr/Processing complete with errors: 4 files updated, 1 errors/, 'directory run summarizes invalid files');

    my $created_before_cancel = $Local::MockMP3::CREATED;
    my $input = "n\n";
    open my $input_fh, '<', \$input or die "Cannot create mock input: $!";
    my $cancel_output = capture_stdout(sub {
        local *STDIN = $input_fh;
        FixMP3Tags::Processor->process_directory(
            $temp_dir,
            { quiet => 0, dry_run => 0, pattern => undef }
        );
    });
    like($cancel_output, qr/Proceed with processing\?/, 'directory mode asks for confirmation before writing');
    like($cancel_output, qr/Processing cancelled/, 'directory mode honors cancellation');
    is($Local::MockMP3::CREATED, $created_before_cancel, 'cancelled directory run does not write tags');

    my $clean_root = File::Spec->catdir($temp_dir, 'clean-tree');
    my $clean_album = File::Spec->catdir($clean_root, 'Another Artist', '2020-05 Clean Album');
    make_path($clean_album);
    write_empty_file(File::Spec->catfile($clean_album, '01.Clean_Track.mp3'));
    write_empty_file(File::Spec->catfile($clean_album, 'notes.txt'));
    my $clean_created_before = $Local::MockMP3::CREATED;
    my $yes_output;
    my $yes_input = "\n";
    open my $yes_input_fh, '<', \$yes_input or die "Cannot create mock input: $!";
    $yes_output = capture_stdout(sub {
        local *STDIN = $yes_input_fh;
        FixMP3Tags::Processor->process_directory(
            $clean_root,
            { quiet => 0, dry_run => 0, pattern => undef }
        );
    });
    like($yes_output, qr/Proceed with processing\?/, 'directory mode prompts before processing');
    like($yes_output, qr/Processing complete: 1 files updated, 0 errors/, 'directory mode reports successful completion');
    is($Local::MockMP3::CREATED - $clean_created_before, 1, 'directory mode ignores non-MP3 files');
}

# Exercise the public command-line interface in a child process.
sub run_cli
{
    my (@args) = @_;
    my $script = File::Spec->catfile('bin', 'fix-mp3-tags');
    local $ENV{PERL5OPT} = $ENV{PERL5OPT} || '';
    $ENV{PERL5OPT} .= ' -MDevel::Cover' if $ENV{COVERAGE_CHILDREN};

    my $stderr = gensym();
    my $pid = open3(undef, my $stdout, $stderr, $^X, $script, @args);
    my $output = do {
        local $/;
        <$stdout>;
    };
    my $error_output = do {
        local $/;
        <$stderr>;
    };
    close $stdout;
    close $stderr;
    waitpid($pid, 0) == $pid or die "Cannot wait for CLI process: $!";
    my $status = $? >> 8;
    $output = '' unless defined $output;
    $error_output = '' unless defined $error_output;
    return ($status, $output . $error_output);
}

my ($help_status, $help_output) = run_cli('--help');
is($help_status, 0, '--help exits successfully');
like($help_output, qr/Usage: fix-mp3-tags/, '--help prints usage');
my ($version_status, $version_output) = run_cli('--version');
is($version_status, 0, '--version exits successfully');
like($version_output, qr/\Q$FixMP3Tags::VERSION\E/, '--version prints the distribution version');
my ($missing_directory_status, $missing_directory_output) = run_cli(
    '--directory', File::Spec->catdir($temp_dir, 'missing-directory')
);
isnt($missing_directory_status, 0, 'CLI rejects a missing directory');
like($missing_directory_output, qr/Directory does not exist/, 'CLI reports the missing directory');

my ($missing_file_status, $missing_file_output) = run_cli(
    '--file', File::Spec->catfile($temp_dir, 'missing-file.mp3')
);
isnt($missing_file_status, 0, 'CLI rejects a missing file');
like($missing_file_output, qr/File does not exist/, 'CLI reports the missing file');

my ($cli_dry_run_status, $cli_dry_run_output) = run_cli(
    '--file', $track_file, '--dry-run'
);
is($cli_dry_run_status, 0, 'CLI single-file dry-run exits successfully');
like($cli_dry_run_output, qr/Track: 01, Title: 'Hit Single'/, 'CLI single-file mode reports parsed track information');

# Test doubles used above; no on-disk MP3 tag is ever changed.
package Local::MockMP3;
our $CREATED = 0;
our $LAST;
our $FAIL_WRITE = 0;

sub new
{
    my ($class, $path) = @_;
    $CREATED++;
    $LAST = bless {
        path  => $path,
        ID3v2 => { legacy => 1 },
    }, $class;
    return $LAST;
}

sub get_tags { return 1; }

sub new_tag
{
    my ($self, $name) = @_;
    die "Unexpected tag type: $name" unless $name eq 'ID3v2';
    $self->{ID3v2} = bless { frames => [] }, 'Local::MockID3v2';
    return $self->{ID3v2};
}

sub close
{
    my ($self) = @_;
    $self->{closed} = 1;
    return 1;
}

package Local::MockID3v2;

sub add_frame
{
    my ($self, $frame, $value) = @_;
    push @{$self->{frames}}, [$frame, $value];
    return 1;
}

sub write_tag
{
    my ($self) = @_;
    die "simulated write failure\n" if $Local::MockMP3::FAIL_WRITE;
    $self->{written} = 1;
    return 1;
}

package main;

done_testing();
