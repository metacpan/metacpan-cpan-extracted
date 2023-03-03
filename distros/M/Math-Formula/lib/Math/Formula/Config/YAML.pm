# Copyrights 2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
package Math::Formula::Config::YAML;
use vars '$VERSION';
$VERSION = '0.14';

use base 'Math::Formula::Config';

use warnings;
use strict;

use Log::Report 'math-formula';

use YAML::XS 0.81;
use boolean ();
use File::Slurper 'read_binary';

# It is not possible to use YAML.pm, because it cannot produce output where
# boolean true and a string with content 'true' can be distinguished.

use Scalar::Util 'blessed';


#----------------------

sub save($%)
{	my ($self, $context, %args) = @_;
	my $name  = $context->name;

 	local $YAML::XS::Boolean = "boolean";
	my $index = $context->_index;

	my $fn = $self->path_for($args{filename} || "$name.yml");
	open my $fh, '>:encoding(utf8)', $fn
		or fault __x"Trying to save context '{name}' to {fn}", name => $name, fn => $fn;

	$fh->print(Dump $self->_set($index->{attributes}));
	$fh->print(Dump $self->_set($index->{formulas}));
	$fh->print(Dump $self->_set($index->{fragments}));

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
	if(blessed $what && $what->isa('MF::STRING'))
	{	$v = $what->value;
	}
	elsif(blessed $what && $what->isa('Math::Formula::Type'))
	{	$v	= $what->isa('MF::INTEGER') || $what->isa('MF::FLOAT') ? $what->value
			: $what->isa('MF::BOOLEAN') ? ($what->value ? boolean::true : boolean::false)
			: '=' . $what->token;
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
	my $fn   = $self->path_for($args{filename} || "$name.yml");

	local $YAML::XS::Boolean = "boolean";
	my ($attributes, $forms, $frags) = Load(read_binary $fn);

	my $attrs = $self->_set_decode($attributes);
	Math::Formula::Context->new(name => $name,
		%$attrs,
		formulas => $self->_set_decode($forms),
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

	if(ref $encoded eq 'boolean')
	{	return MF::BOOLEAN->new(undef, $encoded);
	}

	if($encoded =~ m/^\=(.*?)(?:;\s*(.*))?$/)
	{	my ($expr, $attrs) = ($1, $2 // '');
		my %attrs = $attrs =~ m/(\w+)\='([^']+)'/g;
		return Math::Formula->new($name, $expr =~ s/\\"/"/gr, %attrs);
	}

	  $encoded =~ qr/^[0-9]+$/           ? MF::INTEGER->new($encoded)
	: $encoded =~ qr/^[0-9][0-9.e+\-]+$/ ? MF::FLOAT->new($encoded)
	: MF::STRING->new(undef, $encoded);
}

#----------------------

1;
