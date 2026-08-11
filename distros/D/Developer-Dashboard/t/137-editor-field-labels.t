#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(abs_path);
use File::Find qw(find);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Auth;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;

# Resolve the checkout root before the hermetic chdir so the source scan can
# still find lib/ afterwards.
my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );

# Hermetic runtime rooted in a throwaway HOME; config resolves from the CWD's
# deepest .developer-dashboard layer, so we must chdir into the temp home.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
delete local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS};
delete local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED};
chdir $home or die "Unable to chdir to $home: $!";

# accessible_name_gaps($html)
# Replicates the browser accessibility audit rule for form-control names: a
# control is named by aria-label, aria-labelledby, title, or a label element
# whose for attribute points at its id.
# Input: an HTML document string.
# Output: list of offending control tag strings (empty when every control is named).
sub accessible_name_gaps {
    my ($html) = @_;
    my %labelled_id = map { $_ => 1 } $html =~ /<label\b[^>]*\bfor="([^"]*)"/g;
    my @gaps;
    for my $tag ( $html =~ /(<(?:textarea|input|select)\b[^>]*>)/g ) {
        my $type = $tag =~ /\btype="([^"]*)"/ ? $1 : '';
        next if $type eq 'hidden' || $type eq 'submit' || $type eq 'button';
        next if $tag =~ /\baria-label="[^"]+"/;
        next if $tag =~ /\baria-labelledby="[^"]+"/;
        next if $tag =~ /\btitle="[^"]+"/;
        my $id = $tag =~ /\bid="([^"]*)"/ ? $1 : '';
        next if $id ne '' && $labelled_id{$id};
        push @gaps, $tag;
    }
    return @gaps;
}

# drain($body)
# Collapses a streaming response body into a plain string.
# Input: response body (string or streaming hash).
# Output: body text.
sub drain {
    my ($body) = @_;
    return $body if ref($body) ne 'HASH' || ref( $body->{stream} ) ne 'CODE';
    my $out = '';
    $body->{stream}->( sub { $out .= $_[0] if defined $_[0] } );
    return $out;
}

my $paths    = Developer::Dashboard::PathRegistry->new( home => $home );
my $files    = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $store    = Developer::Dashboard::PageStore->new( paths => $paths );
my $config   = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $auth     = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );

my $app = Developer::Dashboard::Web::App->new(
    auth     => $auth,
    config   => $config,
    pages    => $store,
    sessions => $sessions,
);

my $page = Developer::Dashboard::PageDocument->new(
    id     => 'labelpage',
    title  => 'Label Page',
    layout => { body => '<p>label probe</p>' },
);
$store->save_page($page);

# ---------------------------------------------------------------------------
# 1. The page editor: every server-rendered control carries an accessible name.
# ---------------------------------------------------------------------------
my $edit = $app->handle(
    path        => '/app/labelpage/edit',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
);
is( $edit->[0], 200, 'page editor responds 200 for the loopback admin' );
my $edit_html = drain( $edit->[2] );

my @edit_gaps = accessible_name_gaps($edit_html);
is_deeply( \@edit_gaps, [], 'page editor serves no form control without an accessible name' )
  or diag( join "\n", @edit_gaps );

like(
    $edit_html,
    qr/<textarea class="instruction-source" id="instruction-source" name="instruction" aria-label="[^"]+"/,
    'mirrored bookmark source textarea is named for assistive technology',
);

# ---------------------------------------------------------------------------
# 2. The visible block editors are created by the served script, so the
#    accessible name has to be wired in the script itself. Each block is named
#    by the section label the sighted user reads, via a per-block unique id.
# ---------------------------------------------------------------------------
like( $edit_html, qr/let ddBlockSeq = 0;/,                                      'editor script seeds a monotonic block-label id counter' );
like( $edit_html, qr/const labelId = 'editor-block-label-' \+ \(\+\+ddBlockSeq\);/, 'editor script mints a unique element id for every generated block label' );
like( $edit_html, qr/label\.id = labelId;/,                                     'editor script stamps that unique id onto the visible block label element' );
like( $edit_html, qr/editor\.setAttribute\('aria-labelledby', labelId\);/,      'each generated block textarea is named by its own visible section label' );

# The naming fix must not restyle or restructure what the sighted user sees:
# the label stays the same element class the stylesheet targets.
like( $edit_html, qr/label\.className = 'editor-block-label';/, 'block label keeps the class the editor stylesheet targets' );

# ---------------------------------------------------------------------------
# 3. The blank editor for a missing page renders the same skeleton, so it must
#    satisfy the same contract. This is the route the audit reported separately.
# ---------------------------------------------------------------------------
my $blank = $app->handle(
    path        => '/app/no-such-page-409/edit',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
);
is( $blank->[0], 200, 'blank editor for a missing page responds 200' );
my @blank_gaps = accessible_name_gaps( drain( $blank->[2] ) );
is_deeply( \@blank_gaps, [], 'blank editor for a missing page names every form control' )
  or diag( join "\n", @blank_gaps );

# ---------------------------------------------------------------------------
# 4. The helper login page is the other generated form in the product; pin its
#    label wiring so the contract covers every shipped form.
# ---------------------------------------------------------------------------
my @login_gaps = accessible_name_gaps( $auth->login_page( redirect_to => '/' ) );
is_deeply( \@login_gaps, [], 'helper login page names every form control' )
  or diag( join "\n", @login_gaps );

# ---------------------------------------------------------------------------
# 5. Source guard: no module may introduce a new textarea without a
#    programmatic name. The block editors are built in JavaScript, so a static
#    scan cannot see them, but every literal markup textarea is in reach.
# ---------------------------------------------------------------------------
{
    my @offenders;
    find(
        {
            no_chdir => 1,
            wanted   => sub {
                return if $File::Find::name !~ /\.pm\z/;
                open my $fh, '<', $File::Find::name
                  or die "Unable to read $File::Find::name: $!";
                my $source = do { local $/; <$fh> };
                close $fh or die "Unable to close $File::Find::name: $!";
                my $rel = File::Spec->abs2rel( $File::Find::name, $ROOT );
                # An uppercase letter directly before the angle bracket means a
                # POD formatting code such as C<textarea>, not a markup tag.
                while ( $source =~ /(?<![A-Z])(<textarea\b[^>]*>)/g ) {
                    my $tag = $1;
                    next if $tag =~ /\baria-label="[^"]+"/;
                    next if $tag =~ /\baria-labelledby="[^"]+"/;
                    next if $tag =~ /\btitle="[^"]+"/;
                    push @offenders, "$rel: $tag";
                }
            },
        },
        File::Spec->catdir( $ROOT, 'lib' ),
    );
    is_deeply( \@offenders, [], 'no lib/ markup textarea ships without a programmatic name' )
      or diag( join "\n", @offenders );
}

done_testing();

__END__

=pod

=head1 NAME

t/137-editor-field-labels.t - every generated form control exposes an accessible name

=head1 PURPOSE

This test is the accessible-name contract for the dashboard's generated forms.
The page editor (both the saved-page route and the blank editor served for a
missing page) and the helper login page must expose a programmatic name for
every form control they serve, and the browser-built block editors must be
named by the section label the sighted user reads.

=head1 WHY IT EXISTS

DD-405 exploratory browser QA audited the running dashboard and reported four
unnamed edit fields on every editor route: the mirrored bookmark source
textarea plus one textarea per visible section block. A control with no
C<aria-label>, C<aria-labelledby>, C<title>, or associated label element is
announced by a screen reader as an anonymous edit field, which fails WCAG
4.1.2. The block editors are constructed in the served script rather than in
markup, so their name has to be wired in that script; a static source scan
alone would never have caught them.

=head1 WHEN TO USE

Use this file when changing the editor skeleton, the script that builds the
visible section blocks, the helper login form, or when adding any new form
control to the web layer.

=head1 HOW TO USE

Run C<prove -lv t/137-editor-field-labels.t> while iterating on web-layer form
markup, then keep it green under C<prove -lr t>.

=head1 WHAT USES IT

Developers during TDD and the repository test suite use this file to keep the
generated forms usable with assistive technology.

=head1 EXAMPLES

Example 1:

  prove -lv t/137-editor-field-labels.t

Run the accessible-name contract by itself.

Example 2:

  prove -lr t

Run it inside the full repository suite before release.

=cut
