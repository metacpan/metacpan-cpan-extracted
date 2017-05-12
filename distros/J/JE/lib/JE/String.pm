package JE::String;

our $VERSION = '0.066';


use strict;
use warnings; no warnings 'utf8';

use overload fallback => 1,
	'""' => 'value',
#	 cmp =>  sub { "$_[0]" cmp $_[1] }
;

use Carp;
use Scalar::Util qw 'blessed tainted';

use Exporter 5.57 'import';
our @EXPORT_OK = qw'surrogify desurrogify';

require JE::Object::String;
require JE::Boolean;
require JE::Number;


# Internals:
# bless [ $utf16_string, $unicode_string, $global_object], 'JE::String';
# Either of the first two slots may be empty. It will be filled in
# on demand.


sub new {
	my($class, $global, $val) = @_;
	defined blessed $global
	   or croak "First argument to JE::String->new is not an object";

	my $self;
	if(defined blessed $val and $val->can('to_string')) {
		$self = bless [$val->to_string->[0],undef,$global], $class;
	}
	else {
		$self = bless [undef,$val, $global], $class;
	}
	$self;
}

sub _new { # ~~~ Should we document this and make it public? The problem
            #     with it is that it has no error-checking whatsoever, and
            #     can consequently make JS do weird things. (Maybe it’s OK,
            #     since I doubt any code would choke on a charCodeAt result
            #     > 0xffff.)
	bless [defined $_[2] ? $_[2] : '',undef,$_[1]], $_[0];
}

sub prop {
	 # ~~~ Make prop simply return the value if the prototype has that
	 #      property.
	my $self = shift;

	if ($_[0] eq 'length') {
		return JE::Number->new($$self[2], length (
				defined $$self[0] ? $$self[0] :
					($$self[0]=surrogify($$self[1]))
		));
	}

	$$self[2]->prototype_for('String')->prop(@_);
}

sub keys {
	my $self = shift;
	$$self[2]->prototype_for('String')->keys;}

sub delete {
	return $_[1] ne 'length'
}

sub method {
	my $self = shift;
	$$self[2]->prototype_for('String')->prop(shift)->apply(
		$self,$$self[2]->upgrade(@_)
	);
}


sub value {
	defined $_[0][1] ? $_[0][1] : ($_[0][1] = desurrogify($_[0][0]));
}
*TO_JSON=*value;

sub value16 {
	defined $_[0][0] ? $_[0][0] : ($_[0][0] = surrogify($_[0][1]));
}


sub typeof    { 'string' }
sub id        { 'str:' . $_[0]->value16 }
sub class     { 'String' }
sub primitive { 1 }

sub to_primitive { $_[0] }
sub to_string    { $_[0] }
                                       # $_[0][2] is the global obj
sub to_boolean { JE::Boolean->new(       $_[0][2],
	length defined $_[0][0]
		? $_[0][0] : $_[0][1]
) }
sub to_object  { JE::Object::String->new($_[0][2], shift) }

our $s = qr.[\p{Zs}\s\ck\x{2028}\x{2029}]*.;

sub to_number  {
	my $value = (my $self = shift)->[0];
	defined $value or $value = $$self[1];
	JE::Number->new($self->[2],
		$value =~ /^$s
		  (
		    [+-]?
		    (?:
		      (?=[0-9]|\.[0-9]) [0-9]* (?:\.[0-9]*)?
		      (?:[Ee][+-]?[0-9]+)?
		        |
		      Infinity
		    )
		    $s
		  )?
		  \z
		/ox ? defined $1 ? $value : 0 :
		$value =~ /^$s   0[Xx] ([A-Fa-f0-9]+)   $s\z/ox ? hex $1 :
		'NaN'
	);
}

sub global { $_[0][2] }

sub taint {
	my $self = shift;
	tainted $self->[0] || tainted $self->[1] and return $self;
	my $alter_ego = [@$self];
	$alter_ego->[defined $alter_ego->[0] ? 0 : 1] .= shift();
	return bless $alter_ego, ref $self;
}


sub desurrogify($) {
	my $ret = shift;
	my($ord1, $ord2);
	for(my $n = 0; $n < length $ret; ++$n) {  # really slow
		($ord1 = ord substr $ret,$n,1) >= 0xd800 and
		 $ord1                          <= 0xdbff and
		($ord2 = ord substr $ret,$n+1,1) >= 0xdc00 and
		$ord2                            <= 0xdfff and
		substr($ret,$n,2) =
		chr 0x10000 + ($ord1 - 0xD800) * 0x400 + ($ord2 - 0xDC00);
	}

	# In perl 5.8.8, if there is a sub on the call stack that was
	# triggered by the overloading mechanism when the object with the 
	# overloaded operator was passed as the only argument to 'die',
	# then the following substitution magically calls that subroutine
	# again with the same arguments, thereby causing infinite
	# recursion:
	#
	# $ret =~ s/([\x{d800}-\x{dbff}])([\x{dc00}-\x{dfff}])/
	# 	chr 0x10000 + (ord($1) - 0xD800) * 0x400 +
	#		(ord($2) - 0xDC00)
	# /ge;
	#
	# 5.9.4 still has this bug.

	$ret;
}

sub surrogify($) {
	my $ret = shift;

	no warnings 'utf8';

	$ret =~ s<([^\0-\x{ffff}])><
		  chr((ord($1) - 0x10000) / 0x400 + 0xD800)
		. chr((ord($1) - 0x10000) % 0x400 + 0xDC00)
	>eg;
	$ret;
}


1;
__END__

=head1 NAME

JE::String - JavaScript string value

=head1 SYNOPSIS

  use JE;
  use JE::String;

  $j = JE->new;

  $js_str = new JE::String $j, "etetfyoyfoht";

  $perl_str = $js_str->value;

  $js_str->to_object; # retuns a new JE::String::Object;

=head1 DESCRIPTION

This class implements JavaScript string values for JE. The difference
in use between this and JE::Object::String is that that module implements
string
I<objects,> while this module implements the I<primitive> values.

The stringification operator is overloaded.

=head1 THE FUNCTION

There are two exportable functions, C<surrogify> and C<desurrogify>, which
convert characters outside the BMP into surrogate pairs, and convert
surrogate pairs in the string input argument into the characters they
represent, respectively, and return the modified string. E.g.:

  use JE::String qw 'desurrogify surrogify';
  
  {
          no warnings 'utf8';
          $str = "\x{d834}\x{dd2b}";
  }

  $str = desurrogify $str;  # $str now contains "\x{1d12b}" (double flat)
  $str = surrogify $str;    # back to "\x{d834}\x{dd2b}"

=head1 SEE ALSO

=over 4

=item L<JE>

=item L<JE::Types>

=item L<JE::Object::String>

=back
