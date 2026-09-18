package Developer::Dashboard::FileSlurp;

use strict;
use warnings;

our $VERSION = '4.45';

use Exporter 'import';

our @EXPORT_OK = qw(slurp_file);

# slurp_file($path, %opts)
# Reads an entire file into a string, in raw or text mode, with a
# caller-chosen missing-file behavior.
# Input: file path string; %opts - raw (bool, default false), on_missing
#   ('die'|'empty', default 'die'), missing_message (sprintf template with
#   two %s for path and $!, used only when on_missing is 'die'),
#   normalize_undef (bool, default false - when true, a read that yields
#   undef, e.g. an I/O error on an already-open handle, is returned as ''
#   instead of undef).
# Output: file content string; '' when the file is absent and
#   on_missing => 'empty'; dies otherwise on an unreadable/missing file.
sub slurp_file {
    my ( $path, %opts ) = @_;
    my $on_missing = $opts{on_missing} // 'die';

    if ( $on_missing eq 'empty' && !-f $path ) {
        return '';
    }

    my $layer = $opts{raw} ? '<:raw' : '<';
    open my $fh, $layer, $path or do {
        my $message = $opts{missing_message}
            ? sprintf( $opts{missing_message}, $path, $! )
            : "Unable to read $path: $!";
        die "$message\n";
    };
    local $/;
    my $body = <$fh>;
    close $fh;
    return $body if defined $body || !$opts{normalize_undef};
    return '';
}

1;

__END__

=head1 NAME

Developer::Dashboard::FileSlurp - shared whole-file-read helper

=head1 SYNOPSIS

  use Developer::Dashboard::FileSlurp qw(slurp_file);
  my $text = slurp_file($path);
  my $raw  = slurp_file($path, raw => 1, on_missing => 'empty');

=head1 DESCRIPTION

Provides C<slurp_file>, the single home for the open/read-whole-file idiom
that used to be written out independently, and had already drifted, at
three call sites across three modules.

=head1 PURPOSE

This module exists to give the codebase one place to read a whole file into
a string, with explicit options for raw-vs-text mode and missing-file
behavior, instead of three independent copies of the same open/read loop.

=head1 WHY IT EXISTS

C<Collector.pm>, C<CollectorRunner.pm> and C<CLI/Ask.pm> each carried their
own C<_slurp> sub, and by the time anyone looked (DD-888) the three had
already diverged: one opened C<:raw> and returned C<''> on a missing file,
one opened without C<:raw> and died unconditionally, and one opened
C<:raw>, died with a custom message, and explicitly normalized an undef
read to C<''>. Same class of duplication DD-762 fixed for directory
listings with C<DirEntries.pm>.

=head1 WHEN TO USE

Use C<slurp_file> whenever code needs to read an entire file into memory as
a string. Choose C<raw =E<gt> 1> for byte-exact reads (binary data,
attachments); leave it off for text files where Perl's default encoding
translation is wanted. Choose C<on_missing =E<gt> 'empty'> when a missing
file is an expected, non-fatal case; leave the default (C<'die'>) when a
missing file is a real error the caller should not swallow.

=head1 HOW TO USE

  my $text = slurp_file('/path/to/file.txt');
  my $raw  = slurp_file('/path/to/file.bin', raw => 1);
  my $safe = slurp_file('/maybe/missing', on_missing => 'empty');
  my $msg  = slurp_file(
      '/maybe/missing',
      missing_message => 'Unable to read attachment %s: %s',
  );

=head1 WHAT USES IT

C<Developer::Dashboard::Collector>, C<Developer::Dashboard::CollectorRunner>
and C<Developer::Dashboard::CLI::Ask>, each preserving its own pre-existing
raw-mode and missing-file contract via explicit options.

=head1 EXAMPLES

  use Developer::Dashboard::FileSlurp qw(slurp_file);

  # Collector.pm-shaped call: raw, empty string on a missing file
  my $body = slurp_file($state_file, raw => 1, on_missing => 'empty');

  # CollectorRunner.pm-shaped call: text mode, dies with the default message
  my $config = slurp_file($config_file);

  # CLI/Ask.pm-shaped call: raw, a custom die message, undef normalized to ''
  my $attachment = slurp_file(
      $attachment_path,
      raw             => 1,
      missing_message => 'Unable to read attachment %s: %s',
      normalize_undef => 1,
  );

=cut
