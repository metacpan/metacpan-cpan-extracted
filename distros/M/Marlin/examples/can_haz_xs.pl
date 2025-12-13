use v5.20.0;
use strict;
use warnings;
no warnings 'once';

use B;
use Scalar::Util;
use FindBin '$Bin';

use lib "$Bin/lib";
use lib "$Bin/../lib";
use lib '/home/tai/src/p5/p5-lexical-accessor/lib';

eval 'require Local::Example::Core;   1' or warn $@;
eval 'require Local::Example::Plain;  1' or warn $@;
eval 'require Local::Example::Marlin; 1' or warn $@;
eval 'require Local::Example::Moo;    1' or warn $@;
eval 'require Local::Example::Moose;  1' or warn $@;
eval 'require Local::Example::Tiny;   1' or warn $@;

sub is_xs {
	my $sub = $_[0];
	if ( Scalar::Util::blessed($sub) and $sub->isa( "Class::MOP::Method" ) ) {
		$sub = $sub->body;
	}
	elsif ( not ref $sub ) {
		no strict "refs";
		if ( not exists &{$sub} ) {
			my ( $pkg, $method ) = ( $sub =~ /\A(.+)::([^:]+)\z/ );
			if ( my $found = $pkg->can($method) ) {
				return lc(is_xs($found));
			}
			return "--";
		}
		$sub = \&{$sub};
	}
	require B;
	B::svref_2object( $sub )->XSUB ? 'XS' : 'PP';
}

my $current_class;

sub show_class {
	$current_class = shift;
	print "[ $current_class ]\n";
}

sub show_method {
	my $m = shift;
	printf(
		"%-15s %-7s %-7s %-7s %-7s %-7s %-7s\n",
		$m,
		map {
			is_xs("Local::Example::$_\::$current_class\::$m")
		} qw( Moo Moose Tiny Core Plain Marlin ),
	);
}

sub show_methods {
	show_method $_ for @_;
}

print "=" x 66, "\n";
printf "%-15s %-7s %-7s %-7s %-7s %-7s %-7s\n", qw( Method Moo Moose Tiny Core Plain Marlin );
print "=" x 66, "\n";
show_class('NamedThing');           show_methods qw/ new name /;
show_class('Person');               show_methods qw/ new name age has_age introduction /;
show_class('Employee');             show_methods qw/ new name age has_age employee_id introduction /;
show_class('Employee::Developer');  show_methods qw/ new name age has_age employee_id introduction get_languages all_languages add_language /;
print "=" x 66, "\n";
print "Key: XS = XSUB, PP = Pure Perl, lowercase = via inheritance.\n";
print "=" x 66, "\n";

__END__
==================================================================
Method          Moo     Moose   Tiny    Core    Plain   Marlin 
==================================================================
[ NamedThing ]
new             PP      PP      pp      XS      PP      XS     
name            XS      PP      PP      PP      PP      XS     
[ Person ]
new             PP      PP      pp      XS      PP      XS     
name            xs      pp      pp      pp      pp      XS     
age             XS      PP      PP      PP      PP      XS     
has_age         XS      PP      PP      PP      PP      XS     
introduction    PP      PP      PP      PP      PP      PP     
[ Employee ]
new             PP      PP      pp      XS      PP      XS     
name            xs      pp      pp      pp      pp      XS     
age             xs      pp      pp      pp      pp      XS     
has_age         xs      pp      pp      pp      pp      XS     
employee_id     XS      PP      PP      PP      PP      XS     
introduction    pp      pp      pp      pp      pp      PP     
[ Employee::Developer ]
new             PP      PP      pp      XS      PP      XS     
name            xs      pp      pp      pp      pp      XS     
age             xs      pp      pp      pp      pp      XS     
has_age         xs      pp      pp      pp      pp      XS     
employee_id     xs      pp      pp      pp      pp      XS     
introduction    PP      PP      PP      PP      PP      PP     
get_languages   PP      PP      PP      PP      PP      PP     
all_languages   PP      PP      PP      PP      PP      PP     
add_language    PP      PP      PP      PP      PP      PP     
==================================================================
Key: XS = XSUB, PP = Pure Perl, lowercase = via inheritance.
==================================================================