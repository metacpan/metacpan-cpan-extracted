# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-Tooltip-Javascript.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 15;
BEGIN { use_ok('HTML::Tooltip::Javascript') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $tt = HTML::Tooltip::Javascript->new(
    javascript_dir => '/javascript',
    # We're not testing all of them
    options => {
        bgcolor => '#EEEEEE',
        borderwidth => 3,
        bordercolor => '#EEEEFF',
        default_tip => 'Default',
        fontcolor => '#FFCCCC',
        fontface => 'verdana',
        fontsize => '10px',
        fontweight => 'normal',
        title => 'Tooltip',
    },
);
ok (defined $tt);
ok ($tt->isa('HTML::Tooltip::Javascript'));

my $output = $tt->tooltip();
like($output, qr/onmouseover="/, 'Testing output format: onmouseover');
like($output, qr/this.T_BORDERCOLOR='#EEEEFF';/, 'Testing output format: bordercolor');
like($output, qr/this.T_FONTFACE='verdana';/, 'Testing output format: fontface');
like($output, qr/this.T_FONTWEIGHT='normal';/, 'Testing output format: fontweight');
like($output, qr/this.T_FONTCOLOR='#FFCCCC';/, 'Testing output format: fontcolor');
like($output, qr/this.T_FONTSIZE='10px';/, 'Testing output format: fontsize');
like($output, qr/this.T_BGCOLOR='#EEEEEE';/, 'Testing output format: bgcolor');
like($output, qr/this.T_TITLE='Tooltip';/, 'Testing output format: title');
like($output, qr/this.T_BORDERWIDTH=3;/, 'Testing output format: borderwidth');
like($output, qr/return escape\('Default'\);"/, 'Testing output format: escape');

my $output2 = $tt->tooltip("Test", {
        bgcolor => undef,
        borderwidth => undef,
        bordercolor => undef,
        fontcolor => undef,
        fontface => undef,
        fontsize => undef,
        fontweight => undef,
        title => undef,
    });

is($output2, q( onmouseover="return escape('Test');" ), 'Testing output format: unset options');

my $at_end = $tt->at_end();

is($at_end, q(<SCRIPT LANGUAGE="Javascript" TYPE="text/javascript" src="/javascript/wz_tooltip.js"></SCRIPT>), 'Testing output format: script');
