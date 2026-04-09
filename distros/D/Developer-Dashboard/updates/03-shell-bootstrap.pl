#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use File::Path qw(make_path);
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;

my $paths = Developer::Dashboard::PathRegistry->new(
    workspace_roots => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],
    project_roots   => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],
);
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );

my $shell_dir = File::Spec->catdir( $paths->config_root, 'shell' );
make_path($shell_dir) if !-d $shell_dir;

my $bootstrap = File::Spec->catfile( $shell_dir, 'bashrc.sh' );
open my $fh, '>', $bootstrap or die "Unable to write $bootstrap: $!";
print {$fh} <<'BASH';
# Developer Dashboard shell bootstrap
dd_cdr() {
  local target
  target="$(dashboard path resolve "$1" 2>/dev/null || true)"
  if [ -z "$target" ]; then
    target="$(dashboard path locate "$@" | perl -MJSON::XS -0777 -ne 'my $a=JSON::XS->new->decode($_); print $a->[0] // q{}')"
  fi
  if [ -n "$target" ]; then
    cd "$target"
  fi
}

export PS1='$(dashboard ps1 --jobs \j)'
BASH
close $fh;

my @rc_candidates = grep { -f $_ } map { File::Spec->catfile( $ENV{HOME}, $_ ) } qw(.bashrc .bash_profile .profile);
my $rc_file = $rc_candidates[0] || File::Spec->catfile( $ENV{HOME}, '.bashrc' );
my $marker = '# Developer Dashboard shell bootstrap';
my $source = qq{$marker\n. $bootstrap\n};

my $existing = '';
if ( -f $rc_file ) {
    open my $in, '<', $rc_file or die "Unable to read $rc_file: $!";
    local $/;
    $existing = <$in>;
    close $in;
}

if ( $existing !~ /\Q$marker\E/ ) {
    open my $out, '>>', $rc_file or die "Unable to append $rc_file: $!";
    print {$out} "\n$source";
    close $out;
    print "Updated $rc_file\n";
}
else {
    print "$rc_file already configured\n";
}

print "Wrote $bootstrap\n";

__END__

=head1 NAME

03-shell-bootstrap.pl - install shell bootstrap for Developer Dashboard

=head1 DESCRIPTION

This update script writes the generated bash bootstrap and appends its loader
line into the user's shell rc file when needed.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Update script in the Developer Dashboard codebase. This file writes the shell bootstrap snippets that let the user enter the dashboard-managed shell environment.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep update/bootstrap phases explicit, rerunnable, and separately testable.

=head1 WHEN TO USE

Use this file when you are working on the staged update/bootstrap pipeline or debugging update-time runtime preparation.

=head1 HOW TO USE

Run it through the dashboard update/bootstrap flow rather than inventing a parallel manual setup path. Keep the phase idempotent and explicit so reruns are safe.

=head1 WHAT USES IT

It is used by the runtime update/bootstrap pipeline, by the related update manager logic, and by tests that verify update behaviour.

=head1 EXAMPLES

  dashboard update

That higher-level command is the supported path that eventually reaches this staged update phase.

=for comment FULL-POD-DOC END

=cut
