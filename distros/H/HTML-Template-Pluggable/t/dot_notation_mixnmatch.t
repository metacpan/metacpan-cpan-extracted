use Test::More;
use Test::MockObject;

use strict;

### Tests mixing method calls and hashkey access.
###
### The objective is to be able to say:
###   object.method.hashkey
### or
###   hashref.object.method
###
### Wilder patterns should work too.

# setup tags to test.
# the template var name is $key,
# the expected outcome is the $value.
my %pats =  map { split /\s+=>\s+/ } split $/, <<PATS;
hash.key.string									=> plain hash ref chain
hash.obj										=> Test::MockObject
hash.obj.property								=> direct object property
hash.obj.accessor								=> default accessor value
hash.obj.accessor('public')						=> public object property
hash.key.obj.accessor('hash').key.deep			=> deep hash ref via obj accessor via hash ref
obj.property									=> direct object property
obj.accessor									=> default accessor value
obj.accessor('public')							=> public object property
obj.accessor('hash').key.objaccess				=> hash ref via obj accessor
obj._private									=> private method
PATS

plan tests => 3						# use_ok
			  + scalar(keys %pats)	# method patterns
	;

use_ok('HTML::Template::Pluggable');
use_ok('HTML::Template::Plugin::Dot');
use_ok('Test::MockObject');

## setup data structures

my $obj  = Test::MockObject->new();
my $hash = {};

### fill them with something useful

$hash->{key}				= {};
$hash->{obj}				= $obj;
$hash->{key}->{string}		= 'plain hash ref chain';
$hash->{key}->{objaccess}	= 'hash ref via obj accessor';
$hash->{key}->{deep}		= 'deep hash ref via obj accessor via hash ref';
$hash->{key}->{obj}			= $obj;

$obj->{ 'property' } = 'direct object property';
$obj->{ 'public' }	 = 'public object property';
$obj->{ 'hash' }     = $hash;
$obj->mock('accessor', sub { 
					my ($self, $attr) = @_;
					return "default accessor value" unless $attr;
					return $self->{property}		if $attr eq 'property';
					return $self->{public}			if $attr eq 'public';
					return $self->{hash}			if $attr eq 'hash';
				}
		);
$obj->mock('_private', sub { "private method" });

# dump structures
# use Data::Dumper;
# diag("hash looks like ", Dumper($hash));
# diag("obj looks like ", Dumper($obj));

my ( $output, $template, $result );

foreach my $pat(sort keys %pats) {
	my $out = $pats{$pat};
	my $tag =  qq{ <tmpl_var name="$pat"> };
	
	# diag("template tag is $tag");
	my $t = HTML::Template::Pluggable->new(
			scalarref => \$tag,
			debug => 0
		);
	$t->param( obj  => $obj  ) if $pat =~ /^obj/;
	$t->param( hash => $hash ) if $pat =~ /^hash/;
	
	$output = $t->output;
	# diag("output is $output");
	like( $output, qr/\Q$out/, $pat);
}

# vi: filetype=perl
__END__
