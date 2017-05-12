use 5.008;
use strict;
use warnings;

package JSON::Path;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.205';
our $Safe      = 1;

use Carp;
use JSON qw[from_json];
use Scalar::Util qw[blessed];
use LV ();

use Exporter::Tiny ();
our @ISA       = qw/ Exporter::Tiny /;
our @EXPORT_OK = qw/ jpath jpath1 jpath_map /;

use overload '""' => \&to_string;

sub jpath
{
	my ($object, $expression) = @_;
	my @return = __PACKAGE__->new($expression)->values($object);
}

sub jpath1 :lvalue
{
	my ($object, $expression) = @_;
	__PACKAGE__->new($expression)->value($object);
}

sub jpath_map (&$$)
{
	my ($coderef, $object, $expression) = @_;
	return __PACKAGE__->new($expression)->map($object, $coderef);
}

sub new
{
	my ($class, $expression) = @_;
	return $expression
		if blessed($expression) && $expression->isa(__PACKAGE__);
	return bless \$expression, $class;
}

sub to_string
{
	my ($self) = @_;
	return $$self;
}

sub _get
{
	my ($self, $object, $type) = @_;
	$object = from_json($object) unless ref $object;
	
	my $helper = JSON::Path::Helper->new;
	$helper->{'resultType'} = $type;
	my $norm = $helper->normalize($$self);
	$helper->{'obj'} = $object;
	if ($$self && $object)
	{
		$norm =~ s/^\$;//;
		$helper->trace($norm, $object, '$');
		if (@{ $helper->{'result'} })
		{
			return @{ $helper->{'result'} };
		}
	}
	
	return;
}

sub _dive :lvalue
{
	my ($obj, $path) = @_;
	
	$path = [
		$path =~ /\[(.+?)\]/g
	] unless ref $path;
	$path = [ map { /^'(.+)'$/ ? $1 : $_ } @$path ];
	
	while (@$path > 1)
	{
		my $chunk = shift @$path;
		if (JSON::Path::Helper::isObject($obj))
			{ $obj = $obj->{$chunk} }
		elsif (JSON::Path::Helper::isArray($obj))
			{ $obj = $obj->[$chunk] }
		else
			{ print "Huh?" }
	}
	
	my $chunk = shift @$path;
	
	LV::lvalue(
		get => sub
		{
			if (JSON::Path::Helper::isObject($obj))
				{ $obj = $obj->{$chunk} }
			elsif (JSON::Path::Helper::isArray($obj))
				{ $obj = $obj->[$chunk] }
			else
				{ print "hUh?" }
		},
		set => sub
		{
			if (JSON::Path::Helper::isObject($obj))
				{ $obj->{$chunk} = shift }
			elsif (JSON::Path::Helper::isArray($obj))
				{ $obj->[$chunk] = shift }
			else
				{ print "huH?" }
		},
	);
}

sub paths
{
	my ($self, $object) = @_;
	return $self->_get($object, 'PATH');
}

sub get
{
	my ($self, $object) = @_;
	return $self->_get($object, 'VALUE');
}

sub set
{
	my ($self, $object, $value, $limit) = @_;
	my $count = 0;
	foreach my $path ( $self->_get($object, 'PATH') )
	{
		_dive($object, $path) = $value;
		++$count;
		last if $limit && ($count >= $limit);
	}
	return $count;
}

sub value :lvalue
{
	my ($self, $object) = @_;
	LV::lvalue(
		get => sub
		{
			my ($value) = $self->get($object);
			return $value;
		},
		set => sub
		{
			my $value = shift;
			$self->set($object, $value, 1);
		},
	);
}

sub values
{
	my ($self, $object) = @_;
	my @values = $self->get($object);
	wantarray ? @values : scalar @values;
}

sub map
{
	my ($self, $object, $coderef) = @_;
	my $count;
	foreach my $path ( $self->_get($object, 'PATH') )
	{
		++$count;
		my $value = do {
			no warnings 'numeric';
			local $_ = _dive($object, $path);
			local $. = $path;
			scalar $coderef->();
		};
		_dive($object, $path) = $value;
	}
	return $count;
}

BEGIN {
	package JSON::Path::Helper;
	
	use 5.008;
	use strict qw(vars refs);
	no warnings;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.205';
	
	use Carp;
	use Scalar::Util qw[blessed];
	
	sub new
	{
		bless {
			obj        => undef,
			resultType => 'VALUE',
			result     => [],
			subx       => [],
		}, $_[0];
	}
	
	sub normalize
	{
		my ($self, $x) = @_;
		$x =~ s/[\['](\??\(.*?\))[\]']/_callback_01($self,$1)/eg;
		$x =~ s/'?\.'?|\['?/;/g;
		$x =~ s/;;;|;;/;..;/g;
		$x =~ s/;\$|'?\]|'$//g;
		$x =~ s/#([0-9]+)/_callback_02($self,$1)/eg;
		$self->{'result'} = [];   # result array was temporarily used as a buffer
		return $x;
	}
	
	sub _callback_01
	{
		my ($self, $m1) = @_;
		push @{ $self->{'result'} }, $m1;
		my $last_index = scalar @{ $self->{'result'} } - 1;
		return "[#${last_index}]";
	}
	
	sub _callback_02
	{
		my ($self, $m1) = @_;
		return $self->{'result'}->[$m1];
	}
	
	sub asPath
	{
		my ($self, $path) = @_;
		my @x = split /\;/, $path;
		my $p = '$';
		my $n = scalar(@x);
		for (my $i=1; $i<$n; $i++)
		{
			$p .= /^[0-9]+$/ ? ("[".$x[$i]."]") : ("['".$x[$i]."']");
		}
		return $p;
	}
	
	sub store
	{
		my ($self, $p, $v) = @_;
		push @{ $self->{'result'} }, ( $self->{'resultType'} eq "PATH" ? $self->asPath($p) : $v )
			if $p;
		return !!$p;
	}
	
	sub trace
	{
		my ($self, $expr, $val, $path) = @_;
		
		return $self->store($path, $val) if "$expr" eq '';
		#return $self->store($path, $val) unless $expr;
		
		my ($loc, $x);
		{
			my @x = split /\;/, $expr;
			$loc  = shift @x;
			$x    = join ';', @x;
		}
		
		# in Perl need to distinguish between arrays and hashes.
		if (isArray($val)
		and $loc =~ /^\-?[0-9]+$/
		and exists $val->[$loc])
		{
			$self->trace($x, $val->[$loc], sprintf('%s;%s', $path, $loc));
		}
		elsif (isObject($val)
		and exists $val->{$loc})
		{
			$self->trace($x, $val->{$loc}, sprintf('%s;%s', $path, $loc));
		}
		elsif ($loc eq '*')
		{
			$self->walk($loc, $x, $val, $path, \&_callback_03);
		}
		elsif ($loc eq '..')
		{
			$self->trace($x, $val, $path);
			$self->walk($loc, $x, $val, $path, \&_callback_04);
		}
		elsif ($loc =~ /\,/)  # [name1,name2,...]
		{
			$self->trace($_.';'.$x, $val, $path)
				foreach split /\,/, $loc;
		}
		elsif ($loc =~ /^\(.*?\)$/) # [(expr)]
		{
			my $evalx = $self->evalx($loc, $val, substr($path, rindex($path,";")+1));
			$self->trace($evalx.';'.$x, $val, $path);
		}
		elsif ($loc =~ /^\?\(.*?\)$/) # [?(expr)]
		{
			# my $evalx = $self->evalx($loc, $val, substr($path, rindex($path,";")+1));
			$self->walk($loc, $x, $val, $path, \&_callback_05);
		}
		elsif ($loc =~ /^(-?[0-9]*):(-?[0-9]*):?(-?[0-9]*)$/) # [start:end:step]  python slice syntax
		{
			$self->slice($loc, $x, $val, $path);
		}
	}
	
	sub _callback_03
	{
		my ($self, $m, $l, $x, $v, $p) = @_;
		$self->trace($m.";".$x,$v,$p);
	}
	
	sub _callback_04
	{
		my ($self, $m, $l, $x, $v, $p) = @_;
		
		if (isArray($v)
		and isArray($v->[$m]) || isObject($v->[$m]))
		{
			$self->trace("..;".$x, $v->[$m], $p.";".$m);
		}
		elsif (isObject($v)
		and isArray($v->{$m}) || isObject($v->{$m}))
		{
			$self->trace("..;".$x, $v->{$m}, $p.";".$m);
		}
	}
	
	sub _callback_05
	{
		my ($self, $m, $l, $x, $v, $p) = @_;
		
		$l =~ s/^\?\((.*?)\)$/$1/g;
		
		my $evalx;
		if (isArray($v))
		{
			$evalx = $self->evalx($l, $v->[$m]);
		}
		elsif (isObject($v))
		{
			$evalx = $self->evalx($l, $v->{$m});
		}
		
		$self->trace($m.";".$x, $v, $p)
			if $evalx;
	}
	
	sub walk
	{
		my ($self, $loc, $expr, $val, $path, $f) = @_;
		
		if (isArray($val))
		{
			map {
				$f->($self, $_, $loc, $expr, $val, $path);
			} 0..scalar @$val;
		}
		
		elsif (isObject($val))
		{
			map {
				$f->($self, $_, $loc, $expr, $val, $path);
			} keys %$val;
		}
		
		else
		{
			croak('walk called on non hashref/arrayref value, died');
		}
	}
	
	sub slice
	{
		my ($self, $loc, $expr, $v, $path) = @_;
		
		$loc =~ s/^(-?[0-9]*):(-?[0-9]*):?(-?[0-9]*)$/$1:$2:$3/;
		my @s   = split /\:/, $loc;
		my $len = scalar @$v;
		
		my $start = $s[0]+0 ? $s[0]+0 : 0;
		my $end   = $s[1]+0 ? $s[1]+0 : $len;
		my $step  = $s[2]+0 ? $s[2]+0 : 1;
		
		$start = ($start < 0) ? max(0,$start+$len) : min($len,$start);
		$end   = ($end < 0)   ? max(0,$end+$len)   : min($len,$end);
		
		for (my $i=$start; $i<$end; $i+=$step)
		{
			$self->trace($i.";".$expr, $v, $path);
		}
	}
	
	sub max
	{
		return $_[0] > $_[1] ? $_[0] : $_[1];
	}
	
	sub min
	{
		return $_[0] < $_[1] ? $_[0] : $_[1];
	}
	
	sub evalx
	{
		my ($self, $x, $v, $vname) = @_;
		
		croak('non-safe evaluation, died') if $JSON::Path::Safe;
			
		my $expr = $x;
		$expr =~ s/\$root/\$self->{'obj'}/g;
		$expr =~ s/\$_/\$v/g;
		
		local $@ = undef;
		my $res = eval $expr;
		
		if ($@)
		{
			croak("eval failed: `$expr`, died");
		}
		
		return $res;
	}
	
	sub isObject
	{
		my $obj = shift;
		return 1 if ref($obj) eq 'HASH';
		return 1 if blessed($obj) && $obj->can('typeof') && $obj->typeof eq 'HASH';
		return;
	}
	
	sub isArray
	{
		my $obj = shift;
		return 1 if ref($obj) eq 'ARRAY';
		return 1 if blessed($obj) && $obj->can('typeof') && $obj->typeof eq 'ARRAY';
		return;
	}
};

1;

__END__

=head1 NAME

JSON::Path - search nested hashref/arrayref structures using JSONPath

=head1 SYNOPSIS

 my $data = {
  "store" => {
    "book" => [ 
      { "category" =>  "reference",
        "author"   =>  "Nigel Rees",
        "title"    =>  "Sayings of the Century",
        "price"    =>  8.95,
      },
      { "category" =>  "fiction",
        "author"   =>  "Evelyn Waugh",
        "title"    =>  "Sword of Honour",
        "price"    =>  12.99,
      },
      { "category" =>  "fiction",
        "author"   =>  "Herman Melville",
        "title"    =>  "Moby Dick",
        "isbn"     =>  "0-553-21311-3",
        "price"    =>  8.99,
      },
      { "category" =>  "fiction",
        "author"   =>  "J. R. R. Tolkien",
        "title"    =>  "The Lord of the Rings",
        "isbn"     =>  "0-395-19395-8",
        "price"    =>  22.99,
      },
    ],
    "bicycle" => [
      { "color": "red",
        "price": 19.95,
      },
    ],
  },
 };
 
 # All books in the store
 my $jpath   = JSON::Path->new('$.store.book[*]');
 my @books   = $jpath->values($data);
 
 # The author of the last (by order) book
 my $jpath   = JSON::Path->new('$..book[-1:].author');
 my $tolkien = $jpath->value($data);
 
 # Convert all authors to uppercase
 use JSON::Path 'jpath_map';
 jpath_map { uc $_ } $object, '$.store.book[*].author';

=head1 DESCRIPTION

This module implements JSONPath, an XPath-like language for searching
JSON-like structures.

JSONPath is described at L<http://goessner.net/articles/JsonPath/>.

=head2 Constructor

=over 4

=item C<<  JSON::Path->new($string)  >>

Given a JSONPath expression $string, returns a JSON::Path object.

=back

=head2 Methods

=over 4

=item C<<  values($object)  >>

Evaluates the JSONPath expression against an object. The object $object
can be either a nested Perl hashref/arrayref structure, or a JSON string
capable of being decoded by JSON::from_json.

Returns a list of structures from within $object which match against the
JSONPath expression. In scalar context, returns the number of matches.

=item C<<  value($object)  >>

Like C<values>, but returns just the first value. This method is an lvalue
sub, which means you can assign to it:

  my $person = { name => "Robert" };
  my $path = JSON::Path->new('$.name');
  $path->value($person) = "Bob";

=item C<<  paths($object)  >>

As per C<values> but instead of returning structures which match the
expression, returns canonical JSONPaths that point towards those structures.

=item C<<  get($object)  >>

In list context, identical to C<< values >>, but in scalar context returns
the first result.

=item C<<  set($object, $value, $limit)  >>

Alters C<< $object >>, setting the paths to C<< $value >>. If set, then
C<< $limit >> limits the number of changes made.

Returns the number of changes made.

=item C<<  map($object, $coderef)  >>

Conceptually similar to Perl's C<map> keyword. Executes the coderef
(in scalar context!) for each match of the path within the object,
and sets a new value from the coderef's return value. Within the
coderef, C<< $_ >> may be used to access the old value, and C<< $. >>
may be used to access the curent canonical JSONPath.

=item C<<  to_string  >>

Returns the original JSONPath expression as a string.

This method is usually not needed, as the JSON::Path should automatically
stringify itself as appropriate. i.e. the following works:

 my $jpath = JSON::Path->new('$.store.book[*].author');
 print "I'm looking for: " . $jpath . "\n";

=back

=head2 Functions

The following functions are available for export, but are not exported
by default:

=over

=item C<< jpath($object, $path_string) >>

Shortcut for C<< JSON::Path->new($path_string)->values($object) >>.

=item C<< jpath1($object, $path_string) >>

Shortcut for C<< JSON::Path->new($path_string)->value($object) >>.
Like C<value>, it can be used as an lvalue.

=item C<< jpath_map { CODE } $object, $path_string >>

Shortcut for C<< JSON::Path->new($path_string)->map($object, $code) >>. 

=back

=head1 PERL SPECIFICS

JSONPath is intended as a cross-programming-language method of
searching nested object structures. There are however, some things
you need to think about when using JSONPath in Perl...

=head2 JSONPath Embedded Perl Expressions

JSONPath expressions may contain subexpressions that are evaluated
using the native host language. e.g.

 $..book[?($_->{author} =~ /tolkien/i)]

The stuff between "?(" and ")" is a Perl expression that must return
a boolean, used to filter results. As arbitrary Perl may be used, this
is clearly quite dangerous unless used in a controlled environment.
Thus, it's disabled by default. To enable, set:

 $JSON::Path::Safe = 0;

There are some differences between the JSONPath spec and this
implementation.

=over 4

=item * JSONPath uses a variable '$' to refer to the root node.
This is not a legal variable name in Perl, so '$root' is used
instead.

=item * JSONPath uses a variable '@' to refer to the current node.
This is not a legal variable name in Perl, so '$_' is used
instead.

=back

=head2 Blessed Objects

Blessed objects are generally treated as atomic values; JSON::Path
will not follow paths inside them. The exception to this rule are blessed
objects where:

  Scalar::Util::blessed($object)
  && $object->can('typeof')
  && $object->typeof =~ /^(ARRAY|HASH)$/

which are treated as an unblessed arrayref or hashref appropriately.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

Specification: L<http://goessner.net/articles/JsonPath/>.

Implementations in PHP, Javascript and C#:
L<http://code.google.com/p/jsonpath/>.

Related modules: L<JSON>, L<JSON::JOM>, L<JSON::T>, L<JSON::GRDDL>,
L<JSON::Hyper>, L<JSON::Schema>.

Similar functionality: L<Data::Path>, L<Data::DPath>, L<Data::SPath>,
L<Hash::Path>, L<Path::Resolver::Resolver::Hash>, L<Data::Nested>,
L<Data::Hierarchy>... yes, the idea's not especially new. What's different
is that JSON::Path uses a vaguely standardised syntax with implementations
in at least three other programming languages.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

This module is pretty much a straight line-by-line port of the PHP
JSONPath implementation (version 0.8.x) by Stefan Goessner.
See L<http://code.google.com/p/jsonpath/>.

=head1 COPYRIGHT AND LICENCE

Copyright 2007 Stefan Goessner.

Copyright 2010-2013 Toby Inkster.

This module is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=head2 a.k.a. "The MIT Licence"

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
