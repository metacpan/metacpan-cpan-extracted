use Test::More;
use utf8;
use Data::Dumper;
use I22r::Translate;
use t::Constants;
use strict;
use warnings;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
if (defined $DB::OUT) {
    # if Perl debugger is running
    binmode $DB::OUT, ':encoding(UTF-8)';
}

ok(1, 'starting test');
t::Constants::skip_remaining_tests() unless $t::Constants::CONFIGURED;

my $src = 'en';
my $dest = $ARGV[0] || 'es';

t::Constants::basic_config();

my %INPUT = ( 'entities', 'Inside &lt;pre&gt;&lt;/pre&gt; tags.',
	      'no-ent',   'Outside <pre></pre> tags.',
	      'no-ent2',  'Outside <foo></bar> tags.',
	      'nbsp-no-content',     '( -- &nbsp; -- )' );

my %R = I22r::Translate->translate_hash(
    src => $src, dest => $dest, text => \%INPUT,
    filter => [ 'Literal', 'HTML' ], return_type => 'hash' );

# diag Dumper(\%INPUT,\%R);

ok( scalar keys %R == scalar keys %INPUT,
	'entity output count equals input count' );
ok( $R{entities}{TEXT} !~ /&amp;lt/,
	'&lt; did not become &amp;lt;' );
ok( $R{entities}{TEXT} =~ /&lt;/ && $R{entities}{TEXT} =~ /&gt;/ ,
	'&lt;&gt; tags preserved' )
	or diag( "translation was: ", $R{entities}{TEXT} );
ok( $R{"no-ent"}{TEXT} !~ /&/,
	'no entities in input => none in output' );
ok( $R{'no-ent'}{TEXT} =~ /<pre>/ && $R{'no-ent'}{TEXT} =~ m!</\s*pre>!,
	'no entities preserves <pre> and </pre>' )
	or diag Dumper($R{"no-ent"});
ok( $R{"no-ent2"}{TEXT} !~ /&/,
	'no entities in input2 => none in output' );
ok( $R{'no-ent2'}{TEXT} =~ /<foo>/ && $R{'no-ent2'}{TEXT} =~ m!</\s*bar>!,
	'no entities2 preserves <foo> and </bar>' )
	or diag Dumper($R{'no-ent2'});
ok( $R{'nbsp-no-content'}{TEXT} =~ /&nbsp;/,
	'&nbsp; entity preserved in translation' );

done_testing();
