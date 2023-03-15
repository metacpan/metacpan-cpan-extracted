# Copyrights 2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
package Math::Formula::Config::JSON;
use vars '$VERSION';
$VERSION = '0.16';

use base 'Math::Formula::Config';

use warnings;
use strict;

use Log::Report 'math-formula';
use Scalar::Util  'blessed';
use File::Slurper 'read_binary';
use Cpanel::JSON::XS  ();

my $json = Cpanel::JSON::XS->new->pretty->utf8->canonical(1);


#----------------------

sub save($%)
{	my ($self, $context, %args) = @_;
	my $name  = $context->name;

	my $index = $context->_index;
	my $tree  = $self->_set($index->{attributes});
	$tree->{formulas} = $self->_set($index->{formulas});

	my $fn = $self->path_for($args{filename} || "$name.json");
	open my $fh, '>:raw', $fn
		or fault __x"Trying to save context '{name}' to {fn}", name => $name, fn => $fn;

	$fh->print($json->encode($tree));
	$fh->close
		or fault __x"Error on close while saving '{name}' to {fn}", name => $name, fn => $fn;
}

sub _set($)
{	my ($self, $set) = @_;
	my %data;
	$data{$_ =~ s/^ctx_//r} = $self->_serialize($_, $set->{$_}) for keys %$set;
	\%data;
}

sub _serialize($$)
{	my ($self, $name, $what) = @_;
	my %attrs;

	if(blessed $what && $what->isa('Math::Formula'))
	{	if(my $r = $what->returns) { $attrs{returns} = $r };
		$what = $what->expression;
	}

	my $v = '';
	if(blessed $what && $what->isa('Math::Formula::Type'))
	{	# strings without quote
		$v	= $what->isa('MF::STRING')  ? $what->value
			: $what->isa('MF::BOOLEAN') ? ($what->value ? Cpanel::JSON::XS::true : Cpanel::JSON::XS::false)
			: $what->isa('MF::FLOAT')   ? $what->value  # otherwise JSON writes a string
			: $what->token;
	}
	elsif(ref $what eq 'CODE')
	{	warning __x"cannot (yet) save CODE, skipped '{name}'", name => $name;
		return undef;
	}
	elsif(length $what)
	{	$v = '=' . $what;
	}

	if(keys %attrs)
	{	$v .= '; ' . (join ', ', map "$_='$attrs{$_}'", sort keys %attrs);
	}

	return $v;
}



sub load($%)
{	my ($self, $name, %args) = @_;
	my $fn   = $self->path_for($args{filename} || "$name.json");

	my $tree     = $json->decode(read_binary $fn);
	my $formulas = delete $tree->{formulas};

	my $attrs = $self->_set_decode($tree);
	Math::Formula::Context->new(name => $name,
		%$attrs,
		formulas => $self->_set_decode($formulas),
	);
}

sub _set_decode($)
{	my ($self, $set) = @_;
	$set or return {};

	my %forms;
	$forms{$_} = $self->_unpack($_, $set->{$_}) for keys %$set;
	\%forms;
}

sub _unpack($$)
{	my ($self, $name, $encoded) = @_;
	my $dummy = Math::Formula->new('dummy', '7');

	if(ref $encoded eq 'JSON::PP::Boolean')
	{	return MF::BOOLEAN->new(undef, $encoded);
	}

	if($encoded =~ m/^\=(.*?)(?:;\s*(.*))?$/)
	{	my ($expr, $attrs) = ($1, $2 // '');
		my %attrs = $attrs =~ m/(\w+)\='([^']+)'/g;
		return Math::Formula->new($name, $expr =~ s/\\"/"/gr, %attrs);
	}

	# No JSON implementation parses floats and ints cleanly into SV
	# So, we need to check it by hand.  Gladly, ints are converted
	# to strings again when that was the intention.

	  $encoded =~ qr/^[0-9]+$/           ? MF::INTEGER->new(undef, $encoded + 0)
	: $encoded =~ qr/^[0-9][0-9.e+\-]+$/ ? MF::FLOAT->new(undef, $encoded + 0.0)
	: MF::STRING->new(undef, $encoded);
}

#----------------------

1;
