package HTML::Tag;

use strict;
use warnings;

use Tie::IxHash;
use Class::AutoAccess;
use base qw(Class::AutoAccess);


our $VERSION = '1.08';

BEGIN {
	our $class_def	= {
							element			=> 'SPAN',
							name				=> '',
							id					=> '',
							has_end_tag	=> 1,
							tabindex		=> '',
							onafterupdate	=> '', onblur	=> '', onchange	=> '', onclick	=> '',
							ondblclick	=> '', onerrorupdate	=> '', onfilterchange	=> '',
							onfocus	=> '', onhelp	=> '', onkeydown	=> '', onkeypress	=> '',
							onkeyup	=> '', onmousedown	=> '', onmousemove	=> '', 
							onmouseout	=> '', onmouseover	=> '', onmouseup	=> '', 
							onresize	=> '',
							style => '', class => '',
							attributes	=> ['name','id','tabindex','onafterupdate', 'onblur',
								'onchange', 'onclick', 'ondblclick', 'onerrorupdate',
								'onfilterchange', 'onfocus', 'onhelp', 'onkeydown', 
								'onkeypress', 'onkeyup', 'onmousedown', 'onmousemove',
								'onmouseout', 'onmouseover', 'onmouseup', 'onresize',
								'style','class'],
	};
}

sub new {
	my $class 		= shift;
	my %values		= @_;
	my $self;
	if ($class eq __PACKAGE__) {
		# call the true class
		my $element   = $values{element} || 'SPAN';
		require 'HTML/Tag/' . $element . '.pm';
		$self  = "HTML::Tag::$element"->new(%values);
		die "Unable to create HTML::Tag::$element object" unless ($self);
	} else {
		no strict "refs";
		$self				= {};
		my $opt_child		= ${$class . "::class_def"};
		my $opt_parent	= ${__PACKAGE__ . "::class_def"};
		__PACKAGE__->merge_attributes($opt_child,$opt_parent);
		__PACKAGE__->push_hashref($self,$opt_parent);
		__PACKAGE__->push_hashref($self,$opt_child);
		__PACKAGE__->push_hashref($self,\%values);
		bless $self,$class;
	}
	return $self;
}

sub html {
	my $self	= shift;
	return $self->_build_start_tag . ($self->can('inner') ? $self->inner : '') . $self->_build_end_tag;
}

sub _build_start_tag {
	my $self		= shift;
	my $ret			= '';
	$ret				.= "<" . lc($self->tag);
	foreach (@{$self->attributes}) {
		my @attr_value = $self->$_; 
		my $attr_value = $attr_value[0];
		if ("$attr_value" ne '') {
			$ret .= " " . $self->_build_attribute($_,$attr_value);
		}
	}
	$ret .= $self->has_end_tag ? '>' : ' />';
	return $ret;
}

sub _build_end_tag {
	my $self		= shift;
	return '' unless $self->has_end_tag;
	return "</" . lc($self->tag) . ">";
}

sub _build_attribute {
	my $self	= shift;
	my $name	= shift;
	my $value	= shift;
	return qq|$name="$value"|;
}

sub inner {
	return '';
}

sub push_hashref {
	my $self	= shift;
  my $dst = shift;
  my $src = shift;
  @$dst{keys %$src} = values %$src;
}

sub merge_attributes {
	# union of two arrayref
	my $self		= shift;
	my $dst			= shift;
	my $src			= shift;
	$src->{attributes} ||= [] ;
	$dst->{attributes} ||= [] ;
	tie my %union, 'Tie::IxHash';
	$union{$_} = 1 for (@{$src->{attributes}},@{$dst->{attributes}});
	@{$dst->{attributes}}		= keys %union;
}


1;

# vim: set ts=2:
