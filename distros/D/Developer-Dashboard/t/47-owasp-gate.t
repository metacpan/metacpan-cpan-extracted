use strict;
use warnings FATAL => 'all';

use Cwd qw(abs_path);
use File::Find qw(find);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );

my $security_checks = _slurp_repo('SECURITY_CHECKS.md');
my $security_doc    = _slurp_repo( File::Spec->catfile( 'doc', 'security.md' ) );
my $release_doc     = _slurp_repo( File::Spec->catfile( 'doc', 'update-and-release.md' ) );
my $owasp_sow_doc   = _slurp_repo( File::Spec->catfile( 'doc', 'owasp-compliance-sow.md' ) );
my $readme          = _slurp_repo('README.md');
my $main_pod        = _slurp_repo( File::Spec->catfile( 'lib', 'Developer', 'Dashboard.pm' ) );
my $web_app         = _slurp_repo( File::Spec->catfile( 'lib', 'Developer', 'Dashboard', 'Web', 'App.pm' ) );
my $web_server      = _slurp_repo( File::Spec->catfile( 'lib', 'Developer', 'Dashboard', 'Web', 'Server.pm' ) );
my $auth_module     = _slurp_repo( File::Spec->catfile( 'lib', 'Developer', 'Dashboard', 'Auth.pm' ) );
my $web_security_t  = _slurp_repo( File::Spec->catfile( 't', '08-web-update-coverage.t' ) );
my $static_files_t  = _slurp_repo( File::Spec->catfile( 't', 'web_app_static_files.t' ) );
my $ssl_t           = _slurp_repo( File::Spec->catfile( 't', '17-web-server-ssl.t' ) );

for my $doc (
    [ SECURITY_CHECKS => $security_checks ],
    [ SECURITY_DOC    => $security_doc ],
    [ RELEASE_DOC     => $release_doc ],
    [ OWASP_SOW_DOC   => $owasp_sow_doc ],
  )
{
    my ( $label, $text ) = @{$doc};

    like( $text, qr/OWASP ASVS 5\.0|ASVS 5\.0/, "$label names the current ASVS generation" );
    like( $text, qr/Level 2/, "$label sets Level 2 as the default floor" );
    like( $text, qr/Level 3/, "$label escalates higher-trust work to Level 3 review" );
    like( $text, qr/OWASP Top 10/i, "$label cross-maps the gate to OWASP Top 10" );

    for my $chapter ( 1 .. 14 ) {
        like( $text, qr/\bV$chapter\b/, "$label covers ASVS chapter V$chapter" );
    }

    for my $risk ( 1 .. 10 ) {
        like( $text, qr/\bA0?$risk\b/, "$label covers Top 10 risk A0$risk" );
    }
}

like( $owasp_sow_doc, qr/OWASP-aligned|OWASP-gated/i, 'OWASP SOW doc keeps the safe public-claim wording' );
like( $owasp_sow_doc, qr/Do not claim .*OWASP compliant|blanket .*OWASP compliant/i, 'OWASP SOW doc blocks an unqualified compliance claim before closure' );
like( $owasp_sow_doc, qr/Current Status|Status As Of/i, 'OWASP SOW doc records a concrete current-status section' );
like( $owasp_sow_doc, qr/Completion Criteria|Closure Criteria/i, 'OWASP SOW doc records closure criteria for the stronger claim' );

for my $pattern (
    qr/LWP::Simple\|HTTP::Tiny\|JSON::PP\|capture_merged/,
    qr/Transient token URLs are disabled\|_transient_url_tokens_allowed\|verify_user\|login_response\|_session_cookie/,
    qr/DBI->connect\|\\\\\$dbh->prepare\\\\\(\\\\\$sql\\\\\)\|table_info\|column_info/,
    qr/_sanitize_redirect_target\|Location\|redirect/,
    qr/dashboards\/public/,
    qr/dashboards\/ajax/,
    qr/skills\/\.\+\/dashboards/,
    qr/system\\\\\(\|exec\\\\\(\|open STDOUT\|open STDERR\|timeout_ms\|alarm\\\\\(/,
    qr/prove -lv t\/08-web-update-coverage\.t t\/web_app_static_files\.t t\/17-web-server-ssl\.t/,
  )
{
    like( $security_checks, $pattern, "SECURITY_CHECKS.md carries required OWASP audit evidence: $pattern" );
}

like( $readme, qr/OWASP ASVS 5\.0|ASVS 5\.0/, 'README exposes the full OWASP verification gate' );
like( $readme, qr/OWASP Top 10/i, 'README exposes the Top 10 cross-check requirement' );
like( $main_pod, qr/OWASP ASVS 5\.0|ASVS 5\.0/, 'main POD exposes the full OWASP verification gate' );
like( $main_pod, qr/OWASP Top 10/i, 'main POD exposes the Top 10 cross-check requirement' );

like( $web_app, qr/sub _sanitize_redirect_target\b/, 'web app still owns redirect target sanitization' );
like( $web_app, qr/HttpOnly; SameSite=Strict/, 'web app keeps strict live session cookie attributes' );
like( $web_server, qr/'X-Frame-Options'\s*=>\s*'DENY'/, 'web server keeps frame denial header' );
like( $web_server, qr/'X-Content-Type-Options'\s*=>\s*'nosniff'/, 'web server keeps nosniff header' );
like( $web_server, qr/'Referrer-Policy'\s*=>\s*'no-referrer'/, 'web server keeps no-referrer policy' );
like( $web_server, qr/'Content-Security-Policy'\s*=>/, 'web server still sets a CSP header' );
like( $auth_module, qr/sub verify_user\b/, 'auth module still owns helper credential verification' );

like( $web_security_t, qr/redirect_to/, 'focused web regression test still covers post-login redirect behavior' );
like( $web_security_t, qr/Content-Security-Policy/, 'focused web regression test still covers security headers' );
like( $static_files_t, qr/\.\.\/\.\.\/\.\.\/etc\/passwd/, 'static-file regression test still covers traversal blocking' );
like( $ssl_t, qr/307/, 'SSL regression test still covers redirect status handling' );
like( $ssl_t, qr/https:\/\//, 'SSL regression test still covers HTTPS redirect targets' );

my $source_code = _code_only_repo_sources();

for my $forbidden (
    qr/\bLWP::Simple\b/,
    qr/\bHTTP::Tiny\b/,
    qr/\bJSON::PP\b/,
    qr/\bcapture_merged\b/,
    qr/\bDBI->connect\b/,
    qr/\$dbh->prepare\(\$sql\)/,
    qr/\btable_info\b/,
    qr/\bcolumn_info\b/,
  )
{
    unlike( $source_code, $forbidden, "repo code body avoids forbidden security pattern: $forbidden" );
}

done_testing();

sub _slurp_repo {
    my ($relative_path) = @_;
    my $path = File::Spec->catfile( $ROOT, split m{/}, $relative_path );
    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return $text;
}

sub _code_only_repo_sources {
    my @paths;

    find(
        {
            no_chdir => 1,
            wanted   => sub {
                return if !-f $_;
                return if $_ !~ /\.(?:pm|pl|t)\z/ && $_ !~ m{/dashboard\z};
                return if $_ =~ m{/OLD_CODE/};
                push @paths, $File::Find::name;
            },
        },
        File::Spec->catdir( $ROOT, 'lib' ),
        File::Spec->catdir( $ROOT, 'bin' ),
    );

    my @chunks;
    for my $path (@paths) {
        next if $path eq File::Spec->catfile( $ROOT, 'lib', 'Developer', 'Dashboard.pm' );
        my $text = _slurp_absolute($path);
        $text =~ s/\n__END__\n.*\z//s;
        push @chunks, $text;
    }

    return join "\n", @chunks;
}

sub _slurp_absolute {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return $text;
}

__END__

=pod

=head1 NAME

t/47-owasp-gate.t - enforce full-repository OWASP gate coverage and security invariants

=head1 PURPOSE

This test is the executable regression contract for the repository-wide OWASP
gate. It keeps the ASVS scope, Top 10 cross-check, audit-command evidence, and
core repo-side security invariants from silently drifting apart.

=head1 WHY IT EXISTS

The repository had real security controls and focused tests, but the formal
OWASP gate was too easy to narrow back down to a baseline-only statement. This
test exists so the wider enterprise-style gate fails loudly if the docs, main
manual, or core security-sensitive code paths regress.

=head1 WHEN TO USE

Use this file when changing security policy, release gating, auth/session
behavior, redirect handling, static-file safety, TLS headers, or any repo docs
that define what the security gate is supposed to enforce.

=head1 HOW TO USE

Run C<prove -lv t/47-owasp-gate.t> while iterating on security-policy or
security-sensitive runtime changes. Keep it green under C<prove -lr t> and the
coverage gate before calling the work complete. When it fails, either restore
the missing gate coverage or update the repo-wide security contract and the
implementation together.

=head1 WHAT USES IT

Developers during TDD, the repository test suite, the release metadata gate,
and future security-audit work all use this file to keep the OWASP gate
concrete instead of leaving it as prose-only guidance.

=head1 EXAMPLES

Example 1:

  prove -lv t/47-owasp-gate.t

Run the dedicated OWASP gate regression check by itself.

Example 2:

  prove -lr t

Run the dedicated gate inside the full repository suite before release.

=cut
