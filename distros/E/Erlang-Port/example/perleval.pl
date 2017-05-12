#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  perleval.pl, Erlang::Port::Eval.
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2007 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Erlang-Port/example/perleval.pl 388 2007-05-22T11:24:11.684354Z hio  $
# -----------------------------------------------------------------------------
package Erlang::Port::Eval;
use strict;
use warnings;
use Erlang::Port;

caller or __PACKAGE__->main(@ARGV);

1;

# -----------------------------------------------------------------------------
# main.
#
sub main
{
	my $pkg = shift;
	
	Erlang::Port->new(sub{
		my $obj  = shift;
		my $port = shift;
		#$port->{log} ||= \*STDERR;
		
		my $log = $port->{log};
		$log and _dump($log, request => $obj);
		
		my $ret = eval{
			_my_proc($obj, $port);
		};
		$@ and $ret = $port->_newTuple([ $port->_newAtom('error') => $@, ]);
		$log and _dump($log, result => $ret);
		
		$ret;
	})->loop();
}

# -----------------------------------------------------------------------------
# _my_proc($obj, $port).
#
sub _my_proc
{
	my $obj  = shift;
	my $port = shift;
	
	if( !UNIVERSAL::isa($obj, 'ARRAY') )
	{
		return $port->_newTuple([$port->_newAtom('badarg'), $obj]);
	}
	
	my $key = _to_s($obj->[0]);
	if( !defined($key) )
	{
		return $port->_newTuple([$port->_newAtom('badarg'), $obj]);
	}
	
	my ($sub, @args);
	if( $key eq 'eval' )
	{
		@args = (_to_s($obj->[1]));
		$sub = sub{
			my $str = shift;
			
			my $log = $port->{log};
			$log and print $log "str = [$str]\n";
			
			my $ret = eval "no strict 'vars';".$str;
			if( $@ )
			{
				return $port->_newTuple([$port->_newAtom('error'), $@]);
			}
			$ret;
		};
	}elsif( $key eq 'set' )
	{
		$args[0] = _to_s($obj->[1]);
		$args[1] = $obj->[2];
		$sub = sub{
			my $key = shift;
			my $val = shift;
			
			my $log = $port->{log};
			$log and print $log "key = [$key]\n";
			$log and print $log "val = [".Dumper($val)."]\n";
			
			if( $key !~ /^(\w+)\z/ )
			{
				return $port->_newTuple([$port->_newAtom('badarg'), $obj]);
			}
			do
			{
				no strict 'refs';
				$$1 = $val;
			};
			$val;
		};
	}else
	{
		return $port->_newTuple([$port->_newAtom('badarg'), $obj]);
	}
	if( grep{!defined($_)} @args )
	{
		return $port->_newTuple([$port->_newAtom('badarg'), $obj]);
	}
	
	my $ret = $sub->(@args);
	$ret;
}

sub _to_s
{
	my $obj = shift;
	if( defined($obj) && !ref($obj) )
	{
		$obj;
	}elsif( $obj && ref($obj) eq 'ARRAY' && @$obj==0 )
	{
		"";
	}elsif( ref($obj) && UNIVERSAL::isa($obj, 'Erlang::Atom') )
	{
		$$obj;
	}elsif( ref($obj) && UNIVERSAL::isa($obj, 'Erlang::Binary') )
	{
		$$obj;
	}else
	{
		undef;
	}
}


sub _dump
{
	my $log = shift;
	
	my $msg = shift;
	my $obj = shift;
	
	my $x = Dumper($obj);use Data::Dumper;
	$x =~ s/([^ -~\n])/sprintf('[%02x]',unpack("C",$1))/ge;
	$x =~ s/\r?\n/\r\n/g;
	print $log "$msg = ".$x;
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
__END__

=encoding utf8

=for stopwords
	YAMASHINA
	Hio
	ACKNOWLEDGEMENTS
	AnnoCPAN
	CPAN
	RT

=head1 NAME

example/perleval.pl - Erlang::Port example

=head1 SYNOPSIS

 example/$ erl
 1> perleval:start("perl -Mblib perleval.pl").
 #Port<0.94>
 2> perleval:eval("1+2").
 3

=head1 DESCRIPTION

Example for L<Erlang::PerlPort>.

=head2 perleval:start().

=head2 perleval:start(Script).

Start script in an erlang external port.
Default is "perleval.pl".

=head2 perleval:stop().

Stop port.

=head2 perleval:eval(String).

eval $String in perl interpreter.

=head2 perleval:set(VarName, Object).

set Object into $VarName in perl.

=head1 EXAMPLE

 1> perleval:start("perl -Mblib perleval.pl").
 #Port<0.94>
 2> perleval:eval("1+2").
 3
 3> perleval:set(var, [{a,3}, {b,4}]).
 [{a,3},{b,4}]
 4> perleval:eval("$var->{a} * $var->{b}").
 12
 5> perleval:eval("$var").
 [{a,3},{b,4}]

=head1 SEE ALSO

L<Erlang::Port>

=cut

