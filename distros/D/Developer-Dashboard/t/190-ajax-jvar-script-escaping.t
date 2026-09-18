#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

my $repo_root = abs_path( File::Spec->catdir( dirname(__FILE__), '..' ) );

my $tempdir = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $tempdir;
chdir $tempdir or die "Unable to chdir to $tempdir: $!";

require lib;
lib->import( File::Spec->catdir( $repo_root, 'lib' ) );
require Developer::Dashboard::Zipper;
Developer::Dashboard::Zipper->import('Ajax');

sub _captured_ajax {
    my (%args) = @_;
    no warnings 'once';
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = undef;
    my $out = '';
    {
        local *STDOUT;
        open my $fh, '>', \$out or die $!;
        select $fh;
        Ajax(%args);
        select STDOUT;
    }
    return $out;
}

# DD-895: a jvar containing a single quote and a </script> sequence must
# not be able to break out of the surrounding <script> tag.
my $evil = q{a.b} . q{'} . q{--></script><script>alert(document.cookie)</script><script>x='};
my $html = _captured_ajax( jvar => $evil, singleton => 'ok' );

unlike( $html, qr{</script><script>alert\(document\.cookie\)</script>},
    'AC-2: the injected payload does not appear as a literal script-tag boundary' );
like( $html, qr{\\'}, 'AC-1: the single quote from jvar is escaped (backslash-quote survives in the JS string)' );

# AC-3: normal case unchanged.
my $normal = _captured_ajax( jvar => 'window', singleton => 'normal' );
like( $normal, qr{set_chain_value\(window,'','/ajax\?token=&type=text&singleton=normal'\)},
    'AC-3: a plain jvar with no special characters is unaffected' );

done_testing;

__END__

=head1 NAME

t/190-ajax-jvar-script-escaping.t - Ajax()'s jvar cannot break out of its <script> tag

=head1 PURPOSE

Proves the fix for DD-895: C<Developer::Dashboard::Zipper::Ajax()>
interpolated its C<jvar> argument's split C<$path> component into a
C<< <script> >> tag's JS string literal without escaping, unlike the
adjacent C<singleton> value handled two lines away by C<_js_single_quote>.
A C<jvar> containing a single quote and a C<< </script> >> sequence broke
out of the surrounding script tag, confirmed live in a
C<developer-dashboard:latest> container before this fix.

=head1 WHY IT EXISTS

Found by the hourly bug-hunt automation, the same defect class as DD-892
(unescaped author-supplied template data breaking its output context) one
output-context over: a JS string literal inside C<< <script> >>, not HTML
markup - so the fix is C<_js_single_quote>, not C<_escape_html>.

=head1 WHEN TO USE

Run whenever C<Ajax()>'s jvar handling changes, or when a new caller adds
another interpolation into its C<< <script> >> output.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/190-ajax-jvar-script-escaping.t

=head1 WHAT USES IT

The suite, via C<prove -lr t>. Exercises
C<Developer::Dashboard::Zipper::Ajax()> directly.

=head1 EXAMPLES

Watching this fail on a reintroduced regression: remove the
C<_js_single_quote> call around C<$path> in C<Ajax()> and rerun - AC-1/2
fail.

=cut
