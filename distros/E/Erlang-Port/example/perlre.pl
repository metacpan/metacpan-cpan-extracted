#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  perlre.pl, Erlang::Port::Regexp.
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2007 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Erlang-Port/example/perlre.pl 388 2007-05-22T11:24:11.684354Z hio  $
# -----------------------------------------------------------------------------
package Erlang::Port::Regexp;
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
	if( !defined($key) || $key ne 'match' )
	{
		return $port->_newTuple([$port->_newAtom('badarg'), $obj]);
	}
	
	my $str = _to_s($obj->[1]);
	my $re  = _to_s($obj->[2]);
	if( !defined($str) || !defined($re) )
	{
		return $port->_newTuple([$port->_newAtom('badarg'), $obj]);
	}
	my $log = $port->{log};
	$log and print $log "str = [$str]\n";
	$log and print $log "re  = [$re]\n";
	
	[$str =~ $re];
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

example/perlre.pl - Erlang::Port example

=head1 SYNOPSIS

 example/$ erl
 1> perlre:start("perl -Mblib perlre.pl").
 #Port<0.94>
 2> perlre:match("abc", "(\\w+)(.+)").
 ["ab","c"]

=head1 DESCRIPTION

Example for L<Erlang::PerlPort>.

=head2 perlre:start().

=head2 perlre:start(Script).

Start script in an erlang external port.
Default is "perlre.pl".

=head2 perlre:stop().

Stop port.

=head2 perlre:match(String, Regexp).

execute $String =~ $Regexp in perl interpreter.

=head1 SEE ALSO

L<Erlang::Port>

=cut

