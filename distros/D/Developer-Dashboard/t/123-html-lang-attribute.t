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

my $LANG_OPEN = qr{<html lang="en">};

# ---------------------------------------------------------------------------
# 1. Every HTML document skeleton in lib/ must declare a language on <html>.
#    A bare <html> fails WCAG 3.1.1 (screen readers cannot pick pronunciation
#    rules), and DD-405 dogfooding observed lang="" on every rendered page.
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
                my $line_number = 0;
                while ( my $line = <$fh> ) {
                    $line_number++;
                    # A POD formatting code such as C<html> is not a markup
                    # tag, so an uppercase letter directly before the angle
                    # bracket disqualifies the match.
                    next if $line !~ /(?<![A-Z])<html(?![a-zA-Z0-9-])(?![^>]*\blang=)/;
                    my $rel = File::Spec->abs2rel( $File::Find::name, $ROOT );
                    push @offenders, "$rel:$line_number";
                }
                close $fh or die "Unable to close $File::Find::name: $!";
            },
        },
        File::Spec->catdir( $ROOT, 'lib' ),
    );
    is_deeply( \@offenders, [], 'no lib/ HTML skeleton opens <html> without a lang attribute' )
      or diag( join "\n", @offenders );
}

# ---------------------------------------------------------------------------
# 2. The three generators observed in the wild: saved-page render, the page
#    editor, and the helper login page.
# ---------------------------------------------------------------------------
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

sub drain {
    my ($body) = @_;
    return $body if ref($body) ne 'HASH' || ref( $body->{stream} ) ne 'CODE';
    my $out = '';
    $body->{stream}->( sub { $out .= $_[0] if defined $_[0] } );
    return $out;
}

my $page = Developer::Dashboard::PageDocument->new(
    id     => 'langpage',
    title  => 'Lang Page',
    layout => { body => '<p>lang probe</p>' },
);

like( $page->render_html, $LANG_OPEN, 'saved-page render skeleton declares lang="en"' );

$store->save_page($page);

my $render = $app->handle( path => '/app/langpage', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } );
is( $render->[0], 200, 'rendered page responds 200 for the loopback admin' );
like( drain( $render->[2] ), $LANG_OPEN, 'rendered page route emits the lang-tagged skeleton' );

my $edit = $app->handle( path => '/app/langpage/edit', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } );
is( $edit->[0], 200, 'editor responds 200 for the loopback admin' );
like( drain( $edit->[2] ), $LANG_OPEN, 'page editor skeleton declares lang="en"' );

like(
    $auth->login_page( redirect_to => '/' ),
    $LANG_OPEN,
    'helper login page skeleton declares lang="en"',
);

# The outsider tier serves the login page through the 401 path; it must carry
# the same language declaration.
$auth->add_user( username => 'lang-helper', password => 'lang-pass-405' );
my $outsider = $app->handle( path => '/app/langpage', remote_addr => '127.0.0.1', headers => { host => 'dogfood.test' } );
is( $outsider->[0], 401, 'non-loopback host from loopback lands on the helper tier' );
like( drain( $outsider->[2] ), $LANG_OPEN, 'outsider 401 login page declares lang="en"' );

done_testing();

__END__

=pod

=head1 NAME

t/123-html-lang-attribute.t - every generated HTML document declares its language

=head1 PURPOSE

This test is the accessibility contract for the dashboard's generated HTML
documents: the saved-page render skeleton, the page editor, and the helper
login page must all open with C<< <html lang="en"> >>, and no module under
F<lib/> may introduce a new skeleton whose C<< <html> >> tag lacks a C<lang>
attribute.

=head1 WHY IT EXISTS

DD-405 exploratory browser QA observed C<document.documentElement.lang> empty
on every route of a running dashboard. A missing language declaration fails
WCAG 3.1.1: screen readers fall back to their default voice profile and can
mispronounce the interface. The defect lived in three separate heredoc
skeletons, so a source-scan guard keeps any future skeleton honest too.

=head1 WHEN TO USE

Use this file when changing the page render skeleton, the editor skeleton, the
login page markup, or when adding any new full-document HTML generator to the
web layer.

=head1 HOW TO USE

Run C<prove -lv t/123-html-lang-attribute.t> while iterating on web-layer
markup, then keep it green under C<prove -lr t>.

=head1 WHAT USES IT

Developers during TDD and the repository test suite use this file to keep the
generated documents' language declaration in place.

=head1 EXAMPLES

Example 1:

  prove -lv t/123-html-lang-attribute.t

Run the accessibility contract by itself.

Example 2:

  prove -lr t

Run it inside the full repository suite before release.

=cut
