
package HTML::Transmorgify::Symbols;

use strict;
use warnings;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(new_hash new_array);

my $counter = 0;
sub new_hash
{
	my $sym = sprintf("hash_%5d", $counter++);
	no strict 'refs';
	my $h = \%{__PACKAGE__."::$sym"};
	%$h = @_;
	return $h;
}

sub new_array
{
	my $sym = sprintf("array_%5d", $counter++);
	no strict 'refs';
	my $a = \@{__PACKAGE__."::$sym"};
	@$a = @_;
	return $a;
}

1;
