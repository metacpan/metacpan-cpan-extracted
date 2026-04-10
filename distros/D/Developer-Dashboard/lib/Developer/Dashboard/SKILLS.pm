package Developer::Dashboard::SKILLS;

use strict;
use warnings;

our $VERSION = '2.17';

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::SKILLS - shipped skill authoring reference for Developer Dashboard

=head1 SYNOPSIS

  # Read the long-form guide in the repository root
  perldoc Developer::Dashboard::SKILLS

Skill lifecycle:

  dashboard skills install git@github.com:user/example-skill.git
  dashboard skills update example-skill
  dashboard skills list
  dashboard skill example-skill hello arg1 arg2
  dashboard skills uninstall example-skill

=head1 DESCRIPTION

This module is documentation-first. It exists to ship a human-readable skill
authoring reference with the distribution.

For the long Markdown guide, see F<SKILL.md>.

Use a skill when you want a Git-backed package that can ship:

=over 4

=item *

isolated CLI commands

=item *

skill-local hook files

=item *

bookmarks rendered from C</skill/E<lt>repo-nameE<gt>/bookmarks/E<lt>idE<gt>>

=item *

an isolated config, state, logs, and local dependency root

=back

=head1 QUICK START

Create a Git repository with at least:

  example-skill/
  ├── cli/
  │   └── hello
  ├── config/
  │   └── config.json
  └── dashboards/
      └── welcome

Install it:

  dashboard skills install file:///absolute/path/to/example-skill

Run its command:

  dashboard skill example-skill hello

Open its bookmark:

  /skill/example-skill/bookmarks/welcome

=head1 LAYOUT

Installed skills live under
F<~/.developer-dashboard/skills/E<lt>repo-nameE<gt>/>.

The prepared layout is:

=over 4

=item B<cli/>

Executable skill commands. These are run through
C<dashboard skill E<lt>repo-nameE<gt> E<lt>commandE<gt>> and are not installed
into the system PATH.

=item B<cli/E<lt>commandE<gt>.d/>

Executable hook files for a command. They run in sorted order before the main
command. Their results are serialized into the C<RESULT> environment variable.

=item B<config/config.json>

Skill-owned JSON config. Developer Dashboard guarantees the file exists but
does not impose a rich schema.

=item B<config/docker/>

Reserved root for skill-local Docker or Compose files. The dispatcher exposes
this path through C<DEVELOPER_DASHBOARD_SKILL_DOCKER_ROOT>.

=item B<dashboards/>

Bookmark instruction files shipped by the skill.

=item B<state/>

Persistent skill-owned state.

=item B<logs/>

Persistent skill-owned logs.

=item B<local/>

Isolated local dependency root.

=item B<cpanfile>

Optional Perl dependency declaration. When present, Developer Dashboard runs
C<cpanm -L local --installdeps E<lt>skill-rootE<gt>>.

=back

=head1 SKILL COMMANDS AND HOOKS

Skill commands are file-based commands. Create runnable files such as:

=over 4

=item *

F<cli/report>

=item *

F<cli/report.pl>

=item *

F<cli/report.sh>

=item *

F<cli/report.ps1>

=back

Do not rely on a directory-backed C<run> pattern for skill commands. That
pattern belongs to dashboard-wide custom CLI commands under
F<~/.developer-dashboard/cli/E<lt>commandE<gt>/run> or
F<./.developer-dashboard/cli/E<lt>commandE<gt>/run>.

Hook files live under C<cli/E<lt>commandE<gt>.d/> and:

=over 4

=item *

must be executable to run

=item *

run in sorted filename order

=item *

have their C<stdout>, C<stderr>, and exit codes captured into C<RESULT>

=item *

do not automatically prevent the main command from running

=back

=head1 SKILL ENVIRONMENT

Skill hooks and commands currently receive these environment variables:

=over 4

=item *

C<DEVELOPER_DASHBOARD_SKILL_NAME>

=item *

C<DEVELOPER_DASHBOARD_SKILL_ROOT>

=item *

C<DEVELOPER_DASHBOARD_SKILL_COMMAND>

=item *

C<DEVELOPER_DASHBOARD_SKILL_CLI_ROOT>

=item *

C<DEVELOPER_DASHBOARD_SKILL_CONFIG_ROOT>

=item *

C<DEVELOPER_DASHBOARD_SKILL_DOCKER_ROOT>

=item *

C<DEVELOPER_DASHBOARD_SKILL_STATE_ROOT>

=item *

C<DEVELOPER_DASHBOARD_SKILL_LOGS_ROOT>

=item *

C<DEVELOPER_DASHBOARD_SKILL_LOCAL_ROOT>

=item *

C<RESULT>

=item *

C<PERL5LIB>

=back

If the skill has installed local Perl dependencies, C<PERL5LIB> is prefixed
with C<local/lib/perl5>.

=head1 BOOKMARKS

Skill bookmark files live under C<dashboards/>.

Current route surface:

=over 4

=item *

list bookmarks: C</skill/E<lt>repo-nameE<gt>/bookmarks>

=item *

render bookmark: C</skill/E<lt>repo-nameE<gt>/bookmarks/E<lt>idE<gt>>

=back

Examples:

  /skill/example-skill/bookmarks/welcome
  /skill/example-skill/bookmarks/nav/help.tt

Important current behavior:

=over 4

=item *

the list route only lists top-level files

=item *

nested bookmark files can still be rendered directly when the path is known

=item *

the skill route is a render surface, not a browser edit/source surface

=back

=head1 BOOKMARK LANGUAGE

Bookmark files use the original separator-line syntax with directives such as:

=over 4

=item *

C<TITLE:>

=item *

C<ICON:>

=item *

C<BOOKMARK:>

=item *

C<NOTE:>

=item *

C<STASH:>

=item *

C<HTML:>

=item *

C<CODE1:> and other C<CODE*> blocks

=back

Rules that matter:

=over 4

=item *

C<TITLE:> sets the browser title and is exposed to templates as C<title>

=item *

Earlier C<CODE*> blocks run before final template rendering

=item *

Returned hashes merge into stash

=item *

Printed C<STDOUT> becomes visible runtime output

=item *

C<STDERR> becomes visible error output

=item *

C<---> can also act as a section separator

=back

=head1 BOOKMARK HELPERS

The bookmark bootstrap exposes:

=over 4

=item *

C<fetch_value(url, target, options, formatter)>

=item *

C<stream_value(url, target, options, formatter)>

=item *

C<stream_data(url, target, options, formatter)>

=back

Bookmark pages can also use the built-in C</js/jquery.js> compatibility shim
for C<$>, C<$(document).ready(...)>, and C<$.ajax(...)>.

For normal saved runtime bookmarks, C<Ajax(file =E<gt> 'name', ...)> can create
stable saved Ajax endpoints. That capability is tied to the saved runtime
bookmark path. Skill bookmarks render through the skill route surface, so do
not assume stable saved C</ajax/E<lt>fileE<gt>> handlers there unless you have
tested that path explicitly.

=head1 NAV AND DASHBOARD-WIDE CLI

Normal runtime bookmarks support shared C<nav/*.tt> fragments above non-nav
saved pages. Skill bookmarks can still render files such as
C<dashboards/nav/help.tt> directly through
C</skill/E<lt>repo-nameE<gt>/bookmarks/nav/help.tt>, but the shared nav
auto-insert behavior belongs to the saved runtime bookmark path.

Dashboard-wide custom CLI hooks are separate from skill hooks. They live under
F<./.developer-dashboard/cli/E<lt>commandE<gt>.d> or
F<~/.developer-dashboard/cli/E<lt>commandE<gt>.d> and are used for normal
C<dashboard E<lt>commandE<gt>> commands. They can also use directory-backed
C<run> commands, which skill commands do not currently use.

=head1 FAQ

=head2 Do I need every folder?

No. Use the parts your skill actually needs.

=head2 Can a skill expose browser pages?

Yes, through C<dashboards/> and the C</skill/.../bookmarks/...> route.

=head2 Can I use isolated Perl dependencies?

Yes. Ship a C<cpanfile>. Dependencies install into C<local/>.

=head2 Where is the long-form guide?

See F<SKILL.md>.

=head1 SEE ALSO

F<SKILL.md>, L<Developer::Dashboard>, L<Developer::Dashboard::SkillManager>,
L<Developer::Dashboard::SkillDispatcher>

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is documentation-only and ships the long-form skill authoring reference inside the installed distribution. It explains the skill directory layout, command and hook model, bookmark routing, isolated dependency root, and environment variables visible to skill commands.

=head1 WHY IT EXISTS

It exists because a source-tree-only markdown guide is not enough for tarball and CPAN installs. The skill system needs a shipped manual that survives installation and can be read through C<perldoc> on a machine that does not have the Git checkout.

=head1 WHEN TO USE

Use this file when the skill feature gains new layout rules, command semantics, environment variables, or bookmark routing behavior, or when the shipped skill authoring manual needs to stay aligned with C<SKILL.md>.

=head1 HOW TO USE

Treat it as installed reference documentation. Keep its content synchronized with the markdown skill guide and focus on explaining how skill authors should structure repos and commands rather than on internal implementation details.

=head1 WHAT USES IT

It is used by C<perldoc Developer::Dashboard::SKILLS>, by release metadata checks that compare the shipped docs to the markdown guide, and by contributors authoring or reviewing dashboard skills.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::SKILLS -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/19-skill-system.t t/20-skill-web-routes.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
