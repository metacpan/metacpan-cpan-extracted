	<bodytext>

###############################################################################
#
# new - construct a {{name}} object
#
###############################################################################

sub new {

	my ($class, $params) = @_;

	my $this = $class->SUPER::new();

	{{attributes}}

	return $this;

}</bodytext>
	<title>Constructor</title>
	<description>Template used by ModuleMaker to generate constructors</description>
