use strict;
use warnings FATAL => 'all';

package HTML::Tested::Value::Snippet;
use base 'HTML::Tested::Value';
use Carp;
use Template;

sub value_to_string {
	my ($self, $name, $val, $caller, $stash) = @_;
	my $res;
	my $t = Template->new;
	$t->process(\$val, $stash, \$res) or confess "process: " . $t->error;
	return $res;
}

1;
