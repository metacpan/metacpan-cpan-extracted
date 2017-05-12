package Inline::Select ;

use strict ;
use Carp ;
use Data::Dumper ;


$Inline::Select::VERSION = '0.01' ;

%Inline::Select::GROUPS = () ;


sub import {
	my $class = shift ;
	
	return $class->bind(@_) ;
}


sub register {
	my $class = shift ;
	my %args = @_ ;

	my $group = delete $args{PACKAGE} ;
	croak("PACKAGE configuration attribute not defined") unless $group ;

	my $inline = delete $args{Inline} ;
	croak("Inline configuration attribute not defined") unless $inline ;
	croak("Inline configuration attribute must be an ARRAY reference") 
		unless UNIVERSAL::isa($inline, 'ARRAY') ;

	# Registration mode
	my $language = $inline->[0] ;
	$Inline::Select::GROUPS{$group}->{$language} = $inline ;
	debug($inline) ;
}


sub bind {
	my $class = shift ;
	my %args = @_ ;

	my $group = delete $args{PACKAGE} ;
	croak("PACKAGE configuration attribute not defined") unless $group ;

	my $inline = delete $args{Inline} ;
	croak("Inline configuration attribute not defined") unless $inline ;
	croak("Inline configuration attribute must be a SCALAR") unless ! ref($inline) ;

	# Selection mode
	my $caller = caller() ;
	debug(\%Inline::Select::GROUPS) ;
	my $code = undef ;
	if ($inline !~ /^perl$/i){
		require Inline ;
		$code = <<CODE;
package $caller ;
use Inline (\@{\$Inline::Select::GROUPS{'$group'}->{'$inline'}}) ;
CODE
	}
	else {
		croak("Source must be a CODE reference in the case of the 'Perl' language") 
			unless UNIVERSAL::isa($Inline::Select::GROUPS{$group}->{$inline}->[1], 'CODE') ;
		$code = <<CODE;
package $caller ;
\$Inline::Select::GROUPS{'$group'}->{'$inline'}->[1]->() ;
CODE
	}
	debug($code) ;
	eval $code ;
	croak($@) if $@ ;
}


sub debug {
	my $msg = shift ;

	if ($ENV{PERL_INLINE_SELECT_DEBUG}){
		if (ref($msg)){
			print STDERR Dumper($msg) ;
		}
		else{
			print STDERR "$msg\n" ;
		}
	}
}



1 ;
