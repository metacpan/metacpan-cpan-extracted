# Copyrights 2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.

package Math::Formula::Context;
use vars '$VERSION';
$VERSION = '0.15';


use warnings;
use strict;

use Log::Report 'math-formula';
use Scalar::Util qw/blessed/;


sub new(%) { my $class = shift; (bless {}, $class)->init({@_}) }

sub _default($$$$)
{	my ($self, $name, $type, $value, $default) = @_;
	my $form
	  = ! $value         ? $type->new(undef, $default)
	  : ! blessed $value ? ($value ? Math::Formula->new($name, $value) : undef)
	  : $value->isa('Math::Formula')       ? $value
	  : $value->isa('Math::Formula::Type') ? $value
	  : error __x"unexpected value for '{name}' in #{context}", name => $name, context => $self->name;
}

sub init($)
{	my ($self, $args) = @_;
	my $name   = $args->{name} or error __x"context requires a name";
	my $node   = blessed $name ? $name : MF::STRING->new(undef, $name);
	$self->{MFC_name}   = $node->value;

	my $now;
	$self->{MFC_attrs} = {
		ctx_name       => $node,
		ctx_version    => $self->_default(version => 'MF::STRING',   $args->{version}, "1.00"),
		ctx_created    => $self->_default(created => 'MF::DATETIME', $args->{created}, $now = DateTime->now),
		ctx_updated    => $self->_default(updated => 'MF::DATETIME', $args->{updated}, $now //= DateTime->now),
		ctx_mf_version => $self->_default(mf_version => 'MF::STRING', $args->{mf_version}, $Math::Formula::VERSION),
	};

	$self->{MFC_lead}   = $args->{lead_expressions} // '';
	$self->{MFC_forms}  = { };
	$self->{MFC_frags}  = { };
	if(my $forms = $args->{formulas})
	{	$self->add(ref $forms eq 'ARRAY' ? @$forms : $forms);
	}

	$self->{MFC_claims} = { };
	$self->{MFC_capts}  = [ ];
	$self;
}

# For save()
sub _index()
{	my $self = shift;
	 +{	attributes => $self->{MFC_attrs},
		formulas   => $self->{MFC_forms},
		fragments  => $self->{MFC_frags},
	  };
}

#--------------

sub name             { $_[0]->{MFC_name} }
sub lead_expressions { $_[0]->{MFC_lead} }

#--------------

sub attribute($)
{	my ($self, $name) = @_;
	my $def = $self->{MFC_attrs}{$name} or return;
	Math::Formula->new($name => $def);
}

#--------------
#XXX example with fragment

sub add(@)
{	my $self = shift;
	unless(ref $_[0])
	{	my $name = shift;
		return $name =~ s/^#// ? $self->addFragment($name, @_) : $self->addFormula($name, @_);
	}

	foreach my $obj (@_)
	{	if(ref $obj eq 'HASH')
		{	$self->add($_, $obj->{$_}) for keys %$obj;
		}
		elsif(blessed $obj && $obj->isa('Math::Formula'))
		{	$self->{MFC_forms}{$obj->name} = $obj;
		}
		elsif(blessed $obj && $obj->isa('Math::Formula::Context'))
		{	$self->{MFC_frags}{$obj->name} = $obj;
		}
		else
		{	panic __x"formula add '{what}' not understood", what => $obj;
		}
	}

	undef;
}


sub addFormula(@)
{	my ($self, $name) = (shift, shift);
	my $next  = $_[0];
	my $forms = $self->{MFC_forms};

	if(ref $name)
	{	return $forms->{$name->name} = $name
			if !@_ && blessed $name && $name->isa('Math::Formula');
	}
	elsif(! ref $name && @_)
	{	return $forms->{$name} = $next
			if @_==1 && blessed $next && $next->isa('Math::Formula');

		return $forms->{$name} = Math::Formula->new($name, @_)
			if ref $next eq 'CODE';

		return $forms->{$name} = Math::Formula->new($name, @_)
			if blessed $next && $next->isa('Math::Formula::Type');

		my ($data, %attrs) = @_==1 && ref $next eq 'ARRAY' ? @$next : $next;
		if(my $r = $attrs{returns})
		{	my $typed = $r->isa('MF::STRING') ? $r->new(undef, $data) : $data;
			return $forms->{$name} = Math::Formula->new($name, $typed, %attrs);
		}

		if(length(my $leader = $self->lead_expressions))
		{	my $typed  = $data =~ s/^\Q$leader// ? $data : \$data;
			return $forms->{$name} = Math::Formula->new($name, $typed, %attrs);
		}

		return $forms->{$name} = Math::Formula->new($name, $data, %attrs);
	}

	error __x"formula declaration '{name}' not understood", name => $name;
}


sub formula($) { $_[0]->{MFC_forms}{$_[1]} }


sub addFragment($;$)
{	my $self = shift;
	my ($name, $fragment) = @_==2 ? @_ : ($_[0]->name, $_[0]);
	$self->{MFC_frags}{$name} = MF::FRAGMENT->new($name, $fragment);
}


sub fragment($) { $_[0]->{MFC_frags}{$_[1]} }

#-------------------

sub evaluate($$%)
{	my ($self, $name) = (shift, shift);

	# Wow, I am impressed!  Caused by prefix(#,.) -> infix
	length $name or return $self;

	my $form = $name =~ /^ctx_/ ? $self->attribute($name) : $self->formula($name);
	unless($form)
	{	warning __x"no formula '{name}' in {context}", name => $name, context => $self->name;
		return undef;
	}

	my $claims = $self->{MFC_claims};
	! $claims->{$name}++
		or error __x"recursion in expression '{name}' at {context}",
			name => $name, context => $self->name;

	my $result = $form->evaluate($self, @_);

	delete $claims->{$name};
	$result;
}


sub run($%)
{	my ($self, $expr, %args) = @_;
	my $name  = delete $args{name} || join '#', (caller)[1,2];
	my $result = Math::Formula->new($name, $expr)->evaluate($self, %args);

	while($result && $result->isa('MF::NAME'))
	{	$result = $self->evaluate($result->token, %args);
	}

	$result;
}


sub value($@)
{	my $self = shift;
	my $result = $self->run(@_);
	$result ? $result->value : undef;
}


sub setCaptures($) { $_[0]{MFC_capts} = $_[1] }
sub _captures() { $_[0]{MFC_capts} }


sub capture($) { $_[0]->_captures->[$_[1]] }

#--------------

1;
