use strict;
use warnings;

use Cwd qw(abs_path);
use File::Find qw(find);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );

my $pm = _slurp( _repo_path('lib', 'Developer', 'Dashboard.pm') );
my $readme = _slurp_optional( _repo_path('README.md') );
my $plain_readme = _slurp_optional( _repo_path('README') );
my $skill_guide = _slurp_optional( _repo_path('SKILL.md') );
my $release_doc = _slurp_optional( _repo_path( 'doc', 'update-and-release.md' ) );
my $changes = _slurp( _repo_path('Changes') );
my $dist = _slurp_optional( _repo_path('dist.ini') );
my $meta = _slurp_optional( _repo_path('META.json') );
my $cpanfile = _slurp( _repo_path('cpanfile') );
my $makefile = _slurp( _repo_path('Makefile.PL') );
my $agents_override = _slurp_optional( _repo_path('AGENTS.override.md') );
my @doc_paths = grep { -e $_ } (
    _repo_path('README.md'),
    _repo_path('SQL_DASHBOARD_SUPPORTS_DB.md'),
    _repo_path('SKILL.md'),
    _repo_path('FIXED_BUGS.md'),
    _repo_path('MISTAKE.md'),
    _repo_path('CONTRIBUTING.md'),
    _repo_path('SOFTWARE_SPEC.md'),
    _repo_path('TEST_PLAN.md'),
    _repo_path( 'doc', 'architecture.md' ),
    _repo_path( 'doc', 'integration-test-plan.md' ),
    _repo_path( 'doc', 'security.md' ),
    _repo_path( 'doc', 'skills.md' ),
    _repo_path( 'doc', 'static-file-serving.md' ),
    _repo_path( 'doc', 'testing.md' ),
    _repo_path( 'doc', 'update-and-release.md' ),
);
my @pod_paths = (
    _repo_path( 'lib', 'Developer', 'Dashboard.pm' ),
    _repo_path( 'lib', 'Developer', 'Dashboard', 'SKILLS.pm' ),
    _repo_path( 'lib', 'Developer', 'Dashboard', 'CLI', 'Query.pm' ),
    _repo_path( 'lib', 'Developer', 'Dashboard', 'DataHelper.pm' ),
    _repo_path( 'lib', 'Developer', 'Dashboard', 'Doctor.pm' ),
    _repo_path( 'lib', 'Developer', 'Dashboard', 'File.pm' ),
    _repo_path( 'lib', 'Developer', 'Dashboard', 'Folder.pm' ),
    _repo_path( 'lib', 'Developer', 'Dashboard', 'PageRuntime.pm' ),
    _repo_path( 'lib', 'Developer', 'Dashboard', 'Zipper.pm' ),
);
my $skills_pm = _slurp( _repo_path( 'lib', 'Developer', 'Dashboard', 'SKILLS.pm' ) );
my $skills_pod = _extract_pod($skills_pm);

like( $pm, qr/our \$VERSION = '([^']+)'/, 'main module declares a version' );
my ($version) = $pm =~ /our \$VERSION = '([^']+)'/;
is( $version, '2.34', 'repo version bumped for the same-repo skill-layer fallback fix' );
like( $pm, qr/^2\.34$/m, 'main POD version matches the module version' );
if ( $dist ne '' ) {
    like( $dist, qr/^version = 2\.34$/m, 'dist.ini version matches the module version in the source tree' );
    like( $dist, qr/^exclude_filename = LICENSE$/m, 'dist.ini excludes the tracked LICENSE so dzil does not build duplicate LICENSE files' );
    like( $dist, qr/^exclude_match = \^cover_db\/$/m, 'dist.ini excludes cover_db so coverage artifacts do not leak into release tarballs' );
    like( $dist, qr/^exclude_match = \^integration\/$/m, 'dist.ini excludes integration assets so repo-only verification helpers do not leak into release tarballs' );
    like( $dist, qr/^exclude_match = \^node_modules\/$/m, 'dist.ini excludes node_modules so JavaScript dependency trees do not leak into release tarballs' );
    like( $dist, qr/^exclude_match = \^test_by_michael\/$/m, 'dist.ini excludes test_by_michael so private scratch fixtures do not leak into release tarballs' );
    like( $dist, qr/^exclude_match = \^updates\/$/m, 'dist.ini excludes checkout-only update scripts so user-defined update remains the installed runtime contract' );
    like( $dist, qr/^exclude_match = \\.md\$$/m, 'dist.ini excludes Markdown files so repo-internal docs do not leak into release tarballs' );
    like( $dist, qr/^\[ShareDir\]$/m, 'dist.ini installs the seeded share assets into the built distribution' );
}
else {
    like( $meta, qr/"version"\s*:\s*"2\.34"/, 'META.json version matches the module version in the built distribution' );
}
like( $changes, qr/^2\.34\s+2026-04-12$/m, 'Changes top entry matches the bumped version' );
ok( $plain_readme ne '', 'plain README is tracked for release kwalitee compatibility' );
like( $plain_readme, qr/Developer Dashboard/, 'plain README identifies the distribution clearly' );

for my $path (
    qw(
    bin/pjq
    bin/pyq
    bin/ptomq
    bin/pjp
    bin/jq
    bin/yq
    bin/tomq
    bin/propq
    bin/iniq
    bin/csvq
    bin/xmlq
    bin/of
    bin/open-file
    )
  )
{
    ok( !-e _repo_path($path), "$path is no longer shipped as a public executable" );
}

for my $module (
    qw(
    Developer::Dashboard::Folder
    Developer::Dashboard::DataHelper
    Developer::Dashboard::Zipper
    Developer::Dashboard::Runtime::Result
    )
  )
{
    like( $pm, qr/\Q$module\E/, "main POD documents $module" );
}

unlike( $makefile, qr/bin\/pjq|bin\/pyq|bin\/ptomq|bin\/pjp|bin\/jq|bin\/yq|bin\/tomq|bin\/propq|bin\/iniq|bin\/csvq|bin\/xmlq|bin\/of|bin\/open-file/, 'Makefile.PL does not install generic helper commands into the global PATH' );
unlike( $makefile, qr/["']HTTP::Daemon["']\s*=>\s*0/, 'Makefile.PL no longer declares unused HTTP::Daemon metadata' );
unlike( $makefile, qr/["']HTTP::Status["']\s*=>\s*0/, 'Makefile.PL no longer declares unused HTTP::Status metadata' );
for my $module (
    qw(
    JSON::XS
    YAML::XS
    TOML::Tiny
    Capture::Tiny
    Getopt::Long
    Digest::MD5
    Digest::SHA
    Archive::Zip
    MIME::Base64
    IO::Compress::Gzip
    IO::Uncompress::Gunzip
    Dancer2
    Plack
    Starman
    HTTP::Request
    LWP::Protocol::https
    LWP::UserAgent
    Template
    URI
    URI::Escape
    XML::Parser
    )
  )
{
    like( $makefile, qr/["']\Q$module\E["']\s*=>\s*0/, "Makefile.PL declares runtime prerequisite $module" );
    like( $cpanfile, qr/requires ['"]\Q$module\E['"];/, "cpanfile declares runtime prerequisite $module" );
    like( $dist, qr/^\Q$module\E = 0$/m, "dist.ini declares runtime prerequisite $module" ) if $dist ne '';
}
for my $helper (qw(_dashboard-core jq yq tomq propq iniq csvq xmlq of open-file ticket path paths ps1 encode decode indicator collector config auth init cpan page action docker serve stop restart shell doctor skills)) {
    ok( -f _repo_path( 'share', 'private-cli', $helper ), "share/private-cli/$helper is shipped as a private helper asset" );
}

for my $doc ( grep { defined && $_ ne '' } ( $readme, $pm ) ) {
    like( $doc, qr/~\/\.developer-dashboard\/cli/, 'docs describe private helper extraction under the runtime cli root' );
    like( $doc, qr/\bof\b.*~\/\.developer-dashboard\/cli|~\/\.developer-dashboard\/cli.*\bof\b/s, 'docs describe private of/open-file helper staging' );
    like( $doc, qr/\bticket\b.*~\/\.developer-dashboard\/cli|~\/\.developer-dashboard\/cli.*\bticket\b/s, 'docs describe private ticket helper staging' );
    like( $doc, qr/dashboard jq/, 'docs describe the renamed jq subcommand' );
    like( $doc, qr/dashboard yq/, 'docs describe the renamed yq subcommand' );
    like( $doc, qr/dashboard tomq/, 'docs describe the renamed tomq subcommand' );
    like( $doc, qr/dashboard propq/, 'docs describe the renamed propq subcommand' );
    like( $doc, qr/dashboard of \. jq|jq\.js.*jquery\.js|jquery\.js.*jq\.js/s, 'docs describe the scoped open-file ranking behaviour' );
    like( $doc, qr/Ok\\\.js\$|ok\.json|case-insensitive regex/i, 'docs describe regex-based scoped open-file matching explicitly' );
    like( $doc, qr/javax\.jws\.WebService|Maven source jar|~\/\.developer-dashboard\/cache\/open-file/i, 'docs describe Java source lookup through archives and cached Maven downloads' );
    like( $doc, qr/vim -p|C<vim -p>/, 'docs describe vim tab mode for blank-enter open-all' );
    like( $doc, qr/stream_data\(url, target, options, formatter\)|C<stream_data\(url, target, options, formatter\)>/, 'docs describe the bookmark stream_data helper' );
    like( $doc, qr/XMLHttpRequest/, 'docs describe incremental browser streaming through XMLHttpRequest' );
    like( $doc, qr/Postman-style|Postman collection/, 'docs describe the Postman-style api-dashboard workspace' );
    like( $doc, qr/import and export(?: of)? Postman collection v2\.1 JSON|import and export(?: of)? Postman collection v2\.1 JSON/i, 'docs describe Postman collection import/export support' );
    like( $doc, qr/config\/api-dashboard/, 'docs describe the runtime config/api-dashboard collection storage path' );
    like( $doc, qr/API_DASHBOARD_IMPORT_FIXTURE/, 'docs describe the generic api-dashboard import-fixture browser repro' );
    like( $doc, qr/t\/25-api-dashboard-large-import-playwright\.t/, 'docs describe the oversized api-dashboard browser import regression' );
    like( $doc, qr/Collections and Workspace.*top-level tabs|top-level tabs.*Collections and Workspace/s, 'docs describe the tabbed api-dashboard shell layout' );
    like( $doc, qr/config\/sql-dashboard.*0700|0700.*config\/sql-dashboard/s, 'docs describe the owner-only sql-dashboard profile directory' );
    like( $doc, qr/profile JSON file owner-only at `0600`|profile JSON file owner-only at C<0600>|saved profile files at `0600`|saved profile files at C<0600>/, 'docs describe owner-only sql-dashboard profile files' );
    like( $doc, qr/current SQL .*browser URL instead of a saved SQL file|current SQL .*browser URL.*saved SQL file/s, 'docs describe current SQL as URL state instead of a saved SQL file' );
    like( $doc, qr/stored collections as click-through tabs|collection tab strip|collection-to-collection tab strip/s, 'docs describe the tabbed api-dashboard collection browser' );
    like( $doc, qr/Request Details, Response Body, and Response Headers.*inner workspace tabs|inner workspace tabs.*Request Details, Response Body, and Response Headers/s, 'docs describe the tabbed api-dashboard response layout' );
    like( $doc, qr/request-specific\s+token\s+form|carry(?:ing)?\s+those\s+token\s+values\s+across\s+matching\s+placeholders|(?:`\{\{token\}\}`|C<\{\{token\}\}>|\{\{token\}\})\s+placeholders/s, 'docs describe the request-token carry-over workflow' );
    like( $doc, qr/below\s+the\s+response\s+`pre`|below\s+the\s+response\s+C<pre>/s, 'docs describe the response tabs below the response pre box' );
    like( $doc, qr/back\/forward navigation|browser URL/, 'docs describe browser navigation-aware api-dashboard state' );
    like( $doc, qr/PDF,\s+image,\s+and\s+TIFF\s+responses|PDF,\s+image,\s+and\s+TIFF/is, 'docs describe api-dashboard media preview support' );
    like( $doc, qr/empty `200` save\/delete responses|empty C<200> save\/delete responses|execve/s, 'docs describe the stricter api-dashboard save success handling and large-import transport guardrail' );
    like( $doc, qr/dashboard cpan(?: <Module\.\.\.>| E<lt>Module\.\.\.E<gt>)?|C<dashboard cpan E<lt>Module\.\.\.E<gt>>/, 'docs describe the runtime-local dashboard cpan command' );
    like( $doc, qr/ssl_subject_alt_names/, 'docs describe configured extra SSL SAN aliases and IPs' );
    like( $doc, qr/sql-dashboard/, 'docs describe the seeded sql-dashboard workspace' );
    like( $doc, qr/config\/sql-dashboard/, 'docs describe the runtime config/sql-dashboard profile storage path' );
    like( $doc, qr/config\/sql-dashboard\/collections/, 'docs describe the runtime config/sql-dashboard collection storage path' );
    like( $doc, qr/portable `connection` id|portable C<connection> id|dsn\|user/, 'docs describe the portable sql-dashboard connection id model' );
    like( $doc, qr/table_info|column_info/, 'docs describe generic DBI schema metadata browsing for sql-dashboard' );
    like( $doc, qr/Collection.*Run SQL|Run SQL.*Collection/s, 'docs describe the sql-dashboard inner workspace tabs' );
    like( $doc, qr/auto-resiz|auto resiz|large auto-resizing editor/, 'docs describe the sql-dashboard large auto-resizing editor' );
    like( $doc, qr/inline\s+(?:`\[X\]`|C<\[X\]>|\[X\])/, 'docs describe inline saved-SQL deletion' );
    like( $doc, qr/live filter|table list a live filter|schema table filter/i, 'docs describe schema table filtering' );
    like( $doc, qr/View Data|copy a table name|copy a table/i, 'docs describe schema copy and view-data actions' );
    like( $doc, qr/human type labels|positive length labels|raw numeric type codes/i, 'docs describe normalized schema type and length labels' );
    like( $doc, qr/SQLS_SEP.*INSTRUCTION_SEP|INSTRUCTION_SEP.*SQLS_SEP/s, 'docs describe programmable sql-dashboard statement separators' );
    like( $doc, qr/singleton workers|singleton saved-Ajax workers|singleton saved Ajax workers/, 'docs describe singleton sql-dashboard Ajax workers' );
    like( $doc, qr/dashboard cpan DBD::Driver|DBD::\*/, 'docs describe optional DBD driver installation instead of bundling one database driver' );
    like( $doc, qr/t\/27-sql-dashboard-playwright\.t/, 'docs describe the sql-dashboard Playwright browser verification' );
    like( $doc, qr/SQLite.*MySQL.*PostgreSQL.*MSSQL.*Oracle|MySQL.*PostgreSQL.*MSSQL.*Oracle.*SQLite/s, 'docs describe the five live-supported SQL dashboard database families' );
    like( $doc, qr/DBD::ODBC|ODBC/, 'docs describe the MSSQL ODBC driver path' );
    like( $doc, qr/DBD::Oracle|Oracle/, 'docs describe the Oracle driver path' );
    like( $doc, qr/t\/32-sql-dashboard-rdbms-playwright\.t/, 'docs describe the multi-RDBMS Playwright browser verification' );
    like( $doc, qr/bin\/dashboard|dashboard entrypoint|C<dashboard> entrypoint/, 'docs describe the dashboard cpan implementation as entrypoint-local' );
    like( $doc, qr/config\/config\.json.*intact|preserves an existing .*config\/config\.json/s, 'docs describe non-destructive dashboard init reruns' );
    like( $doc, qr/cli\/dd/, 'docs describe the dedicated dd helper namespace under the home runtime CLI root' );
    like( $doc, qr/config\.json.*\{\}|creates it as `\{\}`|creates it as C<\{\}>/s, 'docs describe empty-object config bootstrapping instead of example collector seeding' );
    like( $doc, qr/preserve(?:s|d)?\s+.*user-owned.*~\/\.developer-dashboard\/cli|~\/\.developer-dashboard\/cli.*user-owned.*preserve|non-destructive.*~\/\.developer-dashboard\/cli/s, 'docs describe non-destructive preservation of user-owned files under the home runtime CLI root' );
    like( $doc, qr/MD5.*skip(?:s|ping)?.*rewrit|skip(?:s|ping)?.*MD5.*rewrit/s, 'docs describe MD5-based skipping for unchanged managed init files' );
    like( $doc, qr/cdr.*regex|regex.*cdr|which_dir.*regex/i, 'docs describe regex-based cdr and which_dir narrowing' );
    like( $doc, qr/sort keys %\$d|Perl expression.*\$d|\$d.*Perl expression/is, 'docs describe Perl-expression query support through $d' );
    like( $doc, qr/_attributes|_text|decoded XML tree|xmlq.*root\.value/is, 'docs describe decoded XML query output instead of a raw xml wrapper' );
    like( $doc, qr/share\/seeded-pages/, 'docs describe shipped seeded bookmark assets outside the main command script' );
    like( $doc, qr/distribution share dir|distribution share directory|cpanm install.*source checkout/s, 'docs describe installed seeded bookmark asset lookup through the dist share directory' );
    like( $doc, qr/stays thin for all built-in commands|thin for all built-in commands.*_dashboard-core|_dashboard-core.*share\/private-cli/s, 'docs describe the thin lazy loader path for all built-in commands' );
    like( $doc, qr/DD-OOP-LAYERS/, 'docs describe the layered runtime inheritance contract explicitly' );
    like( $doc, qr/raw TT\/HTML fragment files under `nav\/` also work|raw TT\/HTML fragment files under C<nav\/> also work|raw `nav\/\*\.tt` TT\/HTML fragment rendering/i, 'docs describe raw nav tt fragment support explicitly' );
    like( $doc, qr/local\/lib\/perl5/, 'docs describe layered runtime local Perl library exposure' );
    like( $doc, qr/LAST_RESULT/, 'docs describe the immediate previous-hook LAST_RESULT payload' );
    like( $doc, qr/\[\[STOP\]\]/, 'docs describe the explicit stderr stop marker for hook chains' );
    unlike( $doc, qr/CPANManager/, 'docs do not describe a dedicated CPAN manager module for the sql-dashboard runtime driver flow' );
    like( $doc, qr/Developer::Dashboard::SKILLS/, 'docs point readers at the shipped skill POD module' );
    unlike( $doc, qr/standalone `of` and `open-file`|standalone of and open-file/, 'docs no longer advertise public standalone of/open-file executables' );
    unlike( $doc, qr/standalone `ticket` executable|standalone ticket executable/, 'docs no longer advertise a public standalone ticket executable' );
    like( $doc, qr/Developer::Dashboard::Runtime::Result/, 'docs use the namespaced Runtime::Result module name' );
    like( $doc, qr/Developer::Dashboard::Folder/, 'docs use the namespaced Folder module name' );
}

for my $doc ( grep { defined && $_ ne '' } ( $skill_guide, $skills_pod ) ) {
    like( $doc, qr/dashboard skills install/, 'skill authoring docs explain installation' );
    like( $doc, qr/dashboard example-skill\.hello/, 'skill authoring docs explain dotted command dispatch' );
    unlike( $doc, qr/dashboard skill example-skill/, 'skill authoring docs no longer describe the removed singular dispatcher' );
    like( $doc, qr{~/.developer-dashboard/skills/<repo-name>/|F<~/.developer-dashboard/skills/E<lt>repo-nameE<gt>/>}, 'skill authoring docs describe the isolated skill root' );
    like( $doc, qr/DD-OOP-LAYERS.*skill|skill.*DD-OOP-LAYERS/is, 'skill authoring docs describe layered skill lookup through DD-OOP-LAYERS' );
    like( $doc, qr/deepest.*shadow|shadow.*deepest|deepest matching repo name/is, 'skill authoring docs describe deepest-layer skill shadowing' );
    like( $doc, qr/cli\/<command>\.d|cli\/E<lt>commandE<gt>\.d/, 'skill authoring docs explain skill hook directories' );
    like( $doc, qr/dashboards\//, 'skill authoring docs explain skill bookmark storage' );
    like( $doc, qr{/app/<repo-name>|/app/E<lt>repo-nameE<gt>|/skill/<repo-name>/bookmarks/<id>|/skill/E<lt>repo-nameE<gt>/bookmarks/E<lt>idE<gt>}, 'skill authoring docs explain skill bookmark routes' );
    like( $doc, qr/TITLE:.*BOOKMARK:.*HTML:.*CODE1:/s, 'skill authoring docs explain bookmark section syntax' );
    like( $doc, qr/fetch_value\(|stream_value\(|stream_data\(/, 'skill authoring docs explain bookmark browser helpers' );
    like( $doc, qr/Ajax\(file\s*=>\s*'name'|C<Ajax\(file =E<gt> 'name'/, 'skill authoring docs explain saved Ajax endpoints' );
    like( $doc, qr/nav\/\*\.tt|nav\/foo\.tt/, 'skill authoring docs explain nav bookmark structure' );
    like( $doc, qr{~/.developer-dashboard/cli/<command>\.d|~/.developer-dashboard/cli/E<lt>commandE<gt>\.d}, 'skill authoring docs explain dashboard-wide custom CLI hooks' );
    like( $doc, qr/DEVELOPER_DASHBOARD_SKILL_ROOT/, 'skill authoring docs explain the skill command environment' );
    like( $doc, qr/LAST_RESULT/, 'skill authoring docs explain previous-hook payloads' );
    like( $doc, qr/\[\[STOP\]\]/, 'skill authoring docs explain explicit hook stop markers' );
    like( $doc, qr/_example-skill|_<repo-name>|_E<lt>repo-nameE<gt>|_something/, 'skill authoring docs explain underscored skill config merge keys' );
    like( $doc, qr/aptfile/, 'skill authoring docs explain isolated apt dependency installation' );
    like( $doc, qr/cpanfile/, 'skill authoring docs explain isolated dependency installation' );
    like( $doc, qr/config\/docker/, 'skill authoring docs explain skill docker roots' );
    like( $doc, qr/FAQ/i, 'skill authoring docs include an FAQ section' );
    unlike( $doc, qr/FORM\.TT:|FORM:/, 'skill authoring docs no longer document removed FORM bookmark directives' );
}

for my $path (@doc_paths) {
    my $doc = _slurp($path);
    unlike( $doc, qr/\blegacy\b/i, "$path no longer mentions the retired internal wording" );
    unlike( $doc, qr/`FORM\.TT:`|`FORM:`|\bFORM\.TT\b/, "$path no longer documents removed FORM bookmark directives" );
}

for my $path (@pod_paths) {
    my $pod = _extract_pod( _slurp($path) );
    unlike( $pod, qr/\blegacy\b/i, "$path POD no longer mentions the retired internal wording" );
    unlike( $pod, qr/C<FORM\.TT:>|C<FORM:>|\bFORM\.TT\b/, "$path POD no longer documents removed FORM bookmark directives" );
}

for my $doc ( grep { defined && $_ ne '' } ($readme) ) {
    like( $doc, qr/dashboard skills install/, 'README documents skill installation' );
    like( $doc, qr/dashboard skills uninstall/, 'README documents skill uninstallation' );
    like( $doc, qr/dashboard skills update/, 'README documents skill updates' );
    like( $doc, qr/dashboard skills enable/, 'README documents skill enablement' );
    like( $doc, qr/dashboard skills disable/, 'README documents skill disablement' );
    like( $doc, qr/dashboard skills usage/, 'README documents skill usage inspection' );
    like( $doc, qr/dashboard skills list -o table|dashboard skills usage example-skill -o table/, 'README documents table output for skill inspection' );
    like( $doc, qr/dashboard example-skill\.somecmd/, 'README documents dotted isolated skill command dispatch' );
    unlike( $doc, qr/dashboard skill example-skill/, 'README no longer documents the removed singular dispatcher' );
    like( $doc, qr/aptfile/, 'README documents skill apt dependency bootstrap' );
    like( $doc, qr/_example-skill|_<repo-name>/, 'README documents underscored skill config merge keys' );
    like( $doc, qr{/app/<repo-name>|/app/<repo-name>/<page>}, 'README documents app-style skill routes' );
    like( $doc, qr/disabled skills.*re-enabled|re-enabled.*disabled skills/is, 'README documents disabled-skill runtime exclusion and restoration' );
    like( $doc, qr/DD-OOP-LAYERS.*skills|skills.*DD-OOP-LAYERS/is, 'README documents layered skill lookup through DD-OOP-LAYERS' );
    like( $doc, qr/deepest.*shadow|shadow.*deepest|deepest matching repo name/is, 'README documents deepest-layer skill shadowing' );
    like( $doc, qr/fix -> test -> commit -> push -> rerun scorecard/, 'README documents the post-commit Scorecard enforcement loop explicitly' );
    like( $doc, qr/git-push-mf|~\/bin\/git-push-mf/, 'README documents the authenticated push helper in the Scorecard timing flow' );
    like( $doc, qr/Do not treat Scorecard as a pre-commit local gate/, 'README documents that live Scorecard runs happen after local gates and commit/push' );
}
like( $release_doc, qr/dzil build/, 'release doc still documents the dzil build step' ) if $release_doc ne '';
like( $release_doc, qr/cpanm .*Developer-Dashboard-1\.\d+\.tar\.gz/, 'release doc still documents tarball installation verification' ) if $release_doc ne '';
like( $agents_override, qr/DD-OOP-LAYERS/, 'AGENTS.override.md documents the layered runtime contract' ) if $agents_override ne '';
like( $agents_override, qr/FULL-POD-DOC/, 'AGENTS.override.md documents the FULL-POD-DOC rule' ) if $agents_override ne '';
unlike( $readme, qr/FULL-POD-DOC/, 'README no longer embeds the contributor-only FULL-POD-DOC contract in the product manual' ) if $readme ne '';
unlike( $pm, qr/FULL-POD-DOC/, 'main module POD no longer embeds the contributor-only FULL-POD-DOC contract' );
unlike( $readme, qr/\b[A-Za-z0-9_\/.-]+\.md\b/, 'README does not point readers at repo-internal markdown filenames' ) if $readme ne '';
unlike( $pm, qr/\b[A-Za-z0-9_\/.-]+\.md\b/, 'main module POD does not point readers at repo-internal markdown filenames' );
unlike( $readme, qr/real\s+inputs.*outputs|outputs.*real\s+inputs/is, 'README no longer carries file-level FULL-POD-DOC contributor guidance' ) if $readme ne '';
unlike( $pm, qr/real\s+inputs.*outputs|outputs.*real\s+inputs/is, 'main module POD no longer carries file-level FULL-POD-DOC contributor guidance' );
unlike( $readme, qr/common\s+path.*edge|edge.*common\s+path/is, 'README no longer carries the contributor example-bank wording' ) if $readme ne '';
unlike( $pm, qr/common\s+path.*edge|edge.*common\s+path/is, 'main module POD no longer carries the contributor example-bank wording' );
like( $readme, qr/How is the browser UI served\?|browser UI runs as the dashboard web service.*dashboard serve/is, 'README explains the browser service entrypoint instead of framing it as a framework requirement' ) if $readme ne '';
like( $pm, qr/How is the browser UI served\?|browser UI runs as the dashboard web service.*dashboard serve/is, 'main module explains the browser service entrypoint instead of framing it as a framework requirement' );
unlike( $pm, qr/=head2 Does it require a web framework\?/m, 'main module no longer carries the misleading web framework FAQ heading' );
unlike( $readme, qr/minimal HTTP layer implemented with core Perl-oriented modules/i, 'README no longer claims the web stack avoids a framework' ) if $readme ne '';
unlike( $pm, qr/minimal HTTP layer implemented with core Perl-oriented modules/i, 'main module no longer claims the web stack avoids a framework' );
like( $readme, qr/LWP::UserAgent.*api-dashboard|api-dashboard.*LWP::UserAgent|LWP::UserAgent.*open-file|open-file.*LWP::UserAgent/is, 'README describes active LWP::UserAgent usage' ) if $readme ne '';
like( $pm, qr/LWP::UserAgent.*api-dashboard|api-dashboard.*LWP::UserAgent|LWP::UserAgent.*open-file|open-file.*LWP::UserAgent/is, 'main module POD describes active LWP::UserAgent usage' );
unlike( $readme, qr/no outbound HTTP client in the core runtime/i, 'README no longer claims outbound HTTP is unused' ) if $readme ne '';
unlike( $pm, qr/no outbound HTTP client in the core runtime/i, 'main module POD no longer claims outbound HTTP is unused' );

my $main_see_also = _section_body( $pm, 'SEE ALSO' );
like( $main_see_also, qr/L<\/Main Concepts>/, 'main module SEE ALSO links to the local Main Concepts section' );
like( $main_see_also, qr/L<\/Working With Collectors>/, 'main module SEE ALSO links to the local collector guide section' );
like( $main_see_also, qr/L<\/Runtime Lifecycle>/, 'main module SEE ALSO links to the local runtime lifecycle section' );
like( $main_see_also, qr/L<\/Skills System>/, 'main module SEE ALSO links to the local skills guide section' );
unlike(
    $main_see_also,
    qr/L<Developer::Dashboard::PathRegistry>|L<Developer::Dashboard::PageStore>|L<Developer::Dashboard::CollectorRunner>|L<Developer::Dashboard::Prompt>/,
    'main module SEE ALSO avoids brittle private-module links that can degrade into broken rendered targets',
);
unlike(
    $pm,
    qr/L<Developer::Dashboard::[A-Za-z:]+>/,
    'main module product manual avoids brittle private-module POD links and stays self-contained',
);

for my $path ( _perl_doc_paths() ) {
    my $content = _slurp($path);
    like( $content, qr/^__END__$/m, "$path keeps Perl POD after __END__" );
    like( $content, qr/^=head1 NAME$/m, "$path documents NAME" );
    unlike( _extract_pod($content), qr/\b[A-Za-z0-9_\/.-]+\.md\b/, "$path POD does not point readers at repo-internal markdown filenames" );
    next if $path eq _repo_path( 'lib', 'Developer', 'Dashboard.pm' );
    like( $content, qr/^=head1 PURPOSE$/m, "$path documents PURPOSE" );
    like( $content, qr/^=head1 WHY IT EXISTS$/m, "$path documents WHY IT EXISTS" );
    like( $content, qr/^=head1 WHEN TO USE$/m, "$path documents WHEN TO USE" );
    like( $content, qr/^=head1 HOW TO USE$/m, "$path documents HOW TO USE" );
    like( $content, qr/^=head1 WHAT USES IT$/m, "$path documents WHAT USES IT" );
    like( $content, qr/^=head1 EXAMPLES$/m, "$path documents EXAMPLES" );
}

my @forbidden_full_pod_boilerplate = (
    qr/Perl module in the Developer Dashboard codebase\./,
    qr/Private helper script in the Developer Dashboard codebase\./,
    qr/Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it\./,
    qr/It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts\./,
    qr/Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug\./,
    qr/Load C<Developer::Dashboard::[A-Za-z:]+> from Perl code under C<lib\/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS\/METHODS sections\./,
    qr/This file is used by whichever runtime path owns this responsibility:/,
    qr/That example is only a quick load check\./,
);

for my $path ( _shipped_perl_doc_paths() ) {
    my $content = _slurp($path);
    for my $pattern (@forbidden_full_pod_boilerplate) {
        unlike( $content, $pattern, "$path no longer uses the generic FULL-POD-DOC boilerplate" );
    }

    next if $path eq _repo_path( 'lib', 'Developer', 'Dashboard.pm' );

    my $how_to_use = _section_body( $content, 'HOW TO USE' );
    my $normalized_how_to_use = $how_to_use;
    $normalized_how_to_use =~ s/\s+/ /g;
    $normalized_how_to_use =~ s/^\s+|\s+$//g;
    cmp_ok(
        length($normalized_how_to_use),
        '>=',
        140,
        "$path documents HOW TO USE with enough operational detail",
    );

    my $examples = _section_body( $content, 'EXAMPLES' );
    my @example_lines = grep { /\S/ } map { s/^\s+//r } split /\n/, $examples;
    cmp_ok(
        scalar(@example_lines),
        '>=',
        2,
        "$path documents at least two concrete examples",
    );
}

done_testing();

sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}

sub _slurp_optional {
    my ($path) = @_;
    return '' if !-f $path;
    return _slurp($path);
}

sub _repo_path {
    return File::Spec->catfile( $ROOT, @_ );
}

sub _extract_pod {
    my ($content) = @_;
    return '' if $content !~ /\n__END__\n/s;
    $content =~ /\n__END__\n(.*)\z/s;
    return $1 // '';
}

sub _perl_doc_paths {
    my @paths;
    my @roots = (
        _repo_path('lib'),
        _repo_path('t'),
        _repo_path('share', 'private-cli'),
        _repo_path('updates'),
        _repo_path('integration'),
    );
    push @paths, grep { -f $_ } (
        _repo_path('app.psgi'),
        _repo_path('bin', 'dashboard'),
    );

    for my $root (@roots) {
        next if !-d $root;
        find(
            {
                no_chdir => 1,
                wanted   => sub {
                    return if !-f $_;
                    return if $_ =~ m{/OLD_CODE/};
                    return if $_ !~ /\.(?:pm|pl|t)\z/ && $_ !~ m{/share/private-cli/[^/]+\z};
                    push @paths, $File::Find::name;
                },
            },
            $root,
        );
    }

    my %seen;
    return sort grep { !$seen{$_}++ } @paths;
}

sub _shipped_perl_doc_paths {
    my @paths;
    push @paths, grep { -f $_ } (
        _repo_path('app.psgi'),
        _repo_path('bin', 'dashboard'),
    );

    for my $root ( _repo_path('lib'), _repo_path( 'share', 'private-cli' ) ) {
        next if !-d $root;
        find(
            {
                no_chdir => 1,
                wanted   => sub {
                    return if !-f $_;
                    return if $_ =~ m{/OLD_CODE/};
                    return if $_ !~ /\.(?:pm|pl)\z/ && $_ !~ m{/share/private-cli/[^/]+\z};
                    push @paths, $File::Find::name;
                },
            },
            $root,
        );
    }

    my %seen;
    return sort grep { !$seen{$_}++ } @paths;
}

sub _section_body {
    my ( $content, $section ) = @_;
    return '' if !defined $content || !defined $section;

    if ( $content =~ /^=head1 \Q$section\E\s*\n(.*?)(?=^=head1 |\z)/ms ) {
        return $1;
    }

    return '';
}

__END__

=head1 NAME

15-release-metadata.t - verify release metadata and docs for private helpers and skills

=head1 DESCRIPTION

This test keeps the shipped version metadata, public executable list, and core
documentation aligned for the private-helper and isolated-skill packaging
model.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Test file in the Developer Dashboard codebase. This file verifies release metadata, shipped assets, docs, and contributor guardrails.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to enforce the TDD contract for this behaviour, stop regressions from shipping, and keep the mandatory coverage and release gates honest.

=head1 WHEN TO USE

Use this file when you are reproducing or fixing behaviour in its area, when you want a focused regression check before the full suite, or when you need to extend coverage without waiting for every unrelated test.

=head1 HOW TO USE

Run it directly with C<prove -lv t/15-release-metadata.t> while iterating, then keep it green under C<prove -lr t> before release. Add or update assertions here before changing the implementation that it covers.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by coverage runs, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/15-release-metadata.t

Run the release metadata and documentation contract checks by themselves while editing docs or version metadata.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/15-release-metadata.t

Confirm the metadata guardrails still behave under the covered test path.

Example 3:

  dzil build

Follow the metadata assertions with a real distribution build, because this test protects the release contract.

Example 4:

  prove -lr t

Run the whole suite after the focused metadata check to keep the documentation contract aligned with runtime behavior.


=for comment FULL-POD-DOC END

=cut
