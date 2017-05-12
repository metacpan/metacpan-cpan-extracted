package Grep::Query::Parser::QOPS;

use strict;
use warnings;

sub __union
{
	my $l = shift;
	my $r = shift;
	
	return __unionOrIntersection($l, $r, 0);
}

sub __intersection
{
	my $l = shift;
	my $r = shift;
	
	return __unionOrIntersection($l, $r, 1);
}

sub __difference
{
	my $l = shift;
	my $r = shift;

	my %diff;
	foreach my $item (keys(%$r))
	{
		$diff{$item} = $r->{$item} unless exists($l->{$item});
	}
	
	return \%diff;
}

sub __unionOrIntersection
{
	my $l = shift;
	my $r = shift;
	my $modeIntersection = shift;

	my %union;
	my %intersect;
	
	foreach my $e (keys(%$l), keys(%$r))
	{
		$union{$e}++ && $intersect{$e}++;
	}

	my $h = $modeIntersection ? \%intersect : \%union;

	my %answer;
	$answer{$_} = ($l->{$_} || $r->{$_}) foreach (keys(%$h));
	
	return \%answer;
}

### INDIVIDUAL OPERATIONS

## disj

package Grep::Query::Parser::QOPS::disj;

sub xeq
{
	my $self = shift;
	my $fieldAccessor = shift;
	my $data = shift;

	my $answer = $self->{conj}->xeq($fieldAccessor, $data);
	if (exists($self->{__ALT}))
	{
		foreach my $alt (@{$self->{__ALT}})
		{
			$answer = Grep::Query::Parser::QOPS::__union($answer, $alt->{conj}->xeq($fieldAccessor, $data));
		}
	}
	
	return $answer;
}

## conj

package Grep::Query::Parser::QOPS::conj;

sub xeq
{
	my $self = shift;
	my $fieldAccessor = shift;
	my $data = shift;
	
	my $answer = $self->{unary}->xeq($fieldAccessor, $data);
	if (exists($self->{__ALT}))
	{
		foreach my $alt (@{$self->{__ALT}})
		{
			next unless keys(%$answer);
			$answer = Grep::Query::Parser::QOPS::__intersection($answer, $alt->{unary}->xeq($fieldAccessor, $data));
		}
	}
	
	return $answer;
}

## unary

package Grep::Query::Parser::QOPS::unary;

sub xeq
{
	my $self = shift;
	my $fieldAccessor = shift;
	my $data = shift;
	
	my $o = exists($self->{disj}) ? $self->{disj} : $self->{field_op_value_test};
	my $answer = $o->xeq($fieldAccessor, $data);
	$answer = Grep::Query::Parser::QOPS::__difference($answer, $data) if $self->{not};
	
	return $answer;
}

## atom

package Grep::Query::Parser::QOPS::field_op_value_test;

sub xeq
{
	my $self = shift;
	my $fieldAccessor = shift;
	my $data = shift;
	
	my %answer;
	grep
		{
			my $rv = $data->{$_};
			my $v = defined($fieldAccessor) ? $fieldAccessor->access($self->{field}, $$rv) : $$rv;
			$answer{$_} = $rv if $self->{op}->($v, $self->{value});
			0;
		} keys(%$data);
	
	return \%answer;
}

1;
