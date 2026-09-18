package Developer::Dashboard::CLI::Source;

use strict;
use warnings;

our $VERSION = '4.45';

use File::Find ();
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray);

# run_source_command(%args)
# Dispatches the lightweight `dashboard source` helper command (DD-938).
# Input: command name under "command", remaining argv under "args", optional
# "out" sink (scalar ref/filehandle/undef for STDOUT) and "home" override
# (defaults to $ENV{HOME}) for tests.
# Output: prints a list of installed Developer Dashboard files to the sink
# and returns a process exit code; dies with a usage message when invalid.
sub run_source_command {
    my (%args) = @_;
    my $command = $args{command} || die "Missing command name\n";
    my $argv    = $args{args}    || die "Missing command arguments\n";
    die "Command arguments must be an array reference\n" if ref($argv) ne 'ARRAY';
    die _usage() if $command ne 'source';

    my @argv  = @{$argv};
    my $files = 0;
    GetOptionsFromArray(
        \@argv,
        'files' => \$files,
    ) or die _usage();
    die _usage() if !$files;

    my $home = $args{home} // $ENV{HOME} // die "HOME is not set\n";
    my @roots = grep { -d $_ } map { File::Spec->catdir( $home, 'perl5', $_ ) } qw(lib bin);

    my @found;
    for my $root (@roots) {
        File::Find::find(
            {
                wanted => sub {
                    push @found, $File::Find::name if -f $_;
                },
                no_chdir => 1,
            },
            $root
        );
    }
    @found = sort @found;

    _emit( $args{out}, join( "\n", @found ) ) if @found;
    return 0;
}

# _usage()
# Input: none.
# Output: usage message string for a dashboard source invocation error.
sub _usage {
    return "Usage: dashboard source --files\n";
}

# _emit($out, $text)
# Writes text (with a trailing newline) to the given sink.
# Input: sink (scalar ref, filehandle, or undef for STDOUT), text string.
# Output: none.
sub _emit {
    my ( $out, $text ) = @_;
    my $line = $text;
    $line .= "\n" if $line !~ /\n\z/;
    if ( ref($out) eq 'SCALAR' ) {
        ${$out} .= $line;
        return;
    }
    if ( ref($out) ) {
        print {$out} $line;
        return;
    }
    print $line;
    return;
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::CLI::Source - list installed Developer Dashboard files (DD-938)

=head1 PURPOSE

Implements C<dashboard source --files>, a fallback reference command for an
agent that needs to dig into Developer Dashboard's real, current
implementation beyond what C<dashboard ask --docs>'s curated summary covers.

=head1 WHY IT EXISTS

C<dashboard ask --docs> (DD-938) is deliberately a short, curated summary -
cheap enough to inject on every call. When an agent needs more than that
summary, C<dashboard source --files> answers "what files exist to read?" by
listing every file installed under C<~/perl5/{lib,bin}>, so the agent can
C<grep>/C<Read> the real source directly rather than guess.

=head1 WHEN TO USE

Called via the C<dashboard source> switchboard entry, staged the same way as
every other private CLI helper (C<share/private-cli/source>).

=head1 HOW TO USE

  dashboard source --files

Run this from anywhere on a machine with Developer Dashboard installed. It
takes no other flags, needs no arguments beyond C<--files>, and prints one
absolute file path per line, sorted, covering everything under
C<~/perl5/lib> and C<~/perl5/bin>. Pipe the output into C<grep> to search
across the whole installed implementation, or read an individual line's
path directly to see the real, current source of any command or module.

=head1 WHAT USES IT

C<share/private-cli/source> dispatches straight into C<run_source_command>.

=head1 EXAMPLES

  $ dashboard source --files
  /home/user/perl5/bin/d2
  /home/user/perl5/bin/dashboard
  /home/user/perl5/lib/perl5/Developer/Dashboard.pm
  ...

=cut
