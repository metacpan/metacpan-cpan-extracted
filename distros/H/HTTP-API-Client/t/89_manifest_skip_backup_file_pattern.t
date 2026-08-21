=head1 NAME

89_manifest_skip_backup_file_pattern.t - HAC-123: MANIFEST.SKIP's backup-file
line was '\*\~', a Perl regex requiring a literal '*' immediately before the
'~' - it never matched an ordinary editor backup filename like 'Client.pm~'
or 'foo.pl~' (the actual Emacs/vim convention), only the essentially
impossible "contains a literal asterisk right before a tilde" case.
Live-verified before this fix: planting lib/HTTP/API/Client.pm~ and running
'dzil build' shipped it straight into the release tarball, unfiltered.

=cut

use strict;
use warnings;
use FindBin;
use Test::More;

my $manifest_skip = "$FindBin::Bin/../MANIFEST.SKIP";

open my $fh, '<', $manifest_skip or die "Can't read $manifest_skip: $!";
my @patterns = map { chomp; qr/$_/ } <$fh>;
close $fh;

sub skipped {
    my ($filename) = @_;
    return !!grep { $filename =~ $_ } @patterns;
}

for my $backup_file (qw( Client.pm~ foo.pl~ .Client.pm.swp )) {
    ok skipped($backup_file), "MANIFEST.SKIP excludes '$backup_file'";
}

ok !skipped("lib/HTTP/API/Client.pm"), "MANIFEST.SKIP does not exclude a real source file";

done_testing;
