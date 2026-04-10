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

This staged update script owns one explicit phase of runtime update, bootstrap, and staged maintenance behavior. Read it when you need the real runtime side effects, logging, and failure behavior for that phase rather than inferring it from the higher-level command wrapper.

=head1 WHY IT EXISTS

It exists so the update pipeline stays explicit, inspectable, and testable one phase at a time. That keeps failures visible and avoids hiding important runtime changes inside one oversized installer step.

=head1 WHEN TO USE

Use this file when changing runtime update, bootstrap, and staged maintenance behavior, when debugging the staged update pipeline, or when the higher-level dashboard update flow fails and you need to isolate this phase.

=head1 HOW TO USE

Run it through C<dashboard update> for the supported path, or invoke the file directly from the source tree when you need to debug only this phase. Keep the phase explicit, idempotent where intended, and noisy on failure.

=head1 WHAT USES IT

The staged runtime update pipeline, update-manager verification, and contributors debugging install or bootstrap regressions use this file.

=head1 EXAMPLES

Example 1:

  prove -lv t/30-dashboard-loader.t

Recheck the thin dashboard loader contract after changing shell bootstrap behavior.

Example 2:

  prove -lv t/05-cli-smoke.t

Rerun the shell-helper smoke tests after changing how this phase wires the shell bootstrap.

Example 3:

  dashboard update

Run the supported end-user path that can reach this update phase.

Example 4:

  perl updates/03-shell-bootstrap.pl

Invoke only this phase while debugging the update pipeline in a source checkout.

=for comment FULL-POD-DOC END

=cut
