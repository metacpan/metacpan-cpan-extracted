
use strict;
use warnings;
use Test::More tests => 6;
use Struct::Compare;

BEGIN {
	use_ok( 'HTML::Template::Dumper::Format' );
	use_ok( 'HTML::Template::Dumper::Data_Dumper' );
	use_ok( 'HTML::Template::Dumper' );

	SKIP: {
		eval { require YAML };
		skip 'YAML not installed', 1 if $@;

		use_ok( 'HTML::Template::Dumper::YAML' );
	}
}

my $dummy_tmpl = <<'END';
<TMPL_VAR dummy>
END

my $tmpl = HTML::Template::Dumper->new( scalarref => \$dummy_tmpl );
isa_ok( $tmpl, 'HTML::Template::Dumper' );


my @params_sent = (0 .. 3);
$tmpl->set_output_format( 'DummyFormatter', @params_sent );
ok( compare( \@DummyFormatter::PARAMS, \@params_sent ), 
	"Check param passing to formatter"
);


package DummyFormatter;
use base 'HTML::Template::Dumper::Format';

our @PARAMS;

sub new 
{
	my $class = shift;
	@PARAMS = @_;
	my $self = 0;
	bless \$self, $class;
}

