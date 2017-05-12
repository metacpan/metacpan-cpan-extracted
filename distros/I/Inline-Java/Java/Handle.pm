package Inline::Java::Handle ;
@Inline::Java::Handle::ISA = qw(Inline::Java::Handle::Tie) ;

use strict ;
use Symbol ;
use Carp ;

$Inline::Java::Handle::VERSION = '0.53' ;


# Here we store as keys the knots and as values our blessed objects
my $OBJECTS = {} ;


sub new {
	my $class = shift ;
	my $object = shift ;

	my $fh = gensym() ;
	my $knot = tie *{$fh}, $class ;
	my $this = bless ($fh, $class) ;

	$OBJECTS->{$knot} = $object ;

	Inline::Java::debug(5, "this = '$this'") ; 
	Inline::Java::debug(5, "knot = '$knot'") ;

	return $this ;
}


sub __get_object {
	my $this = shift ;

	my $knot = tied $this || $this ;

	my $ref = $OBJECTS->{$knot} ;
	if (! defined($ref)){
		croak "Unknown Java handle reference '$knot'" ;
	}
	
	return $ref ;
}


sub __isa {
	my $this = shift ;
	my $proto = shift ;

	return $this->__get_object()->__isa($proto) ;
}


sub __read {
 	my $this = shift ;
	my ($buf, $len, $offset) = @_ ;

	my $obj = $this->__get_object() ;

	my $ret = undef  ;
	eval {
		my $str = $obj->__get_private()->{proto}->ReadFromJavaHandle($len) ;
		$len = length($str) ;
        if ($len > 0){
            substr($buf, $offset, $len) = $str ;
            $_[0] = $buf ;
			$ret = $len ;
        }
	} ;
	croak $@ if $@ ;

	return $ret ;
}


sub __readline {
 	my $this = shift ;

	my $obj = $this->__get_object() ;

	my $ret = undef  ;
	eval {
		$ret = $obj->__get_private()->{proto}->ReadLineFromJavaHandle() ;
	} ;
	croak $@ if $@ ;

	return $ret ;
}


sub __write {
 	my $this = shift ;
	my $buf = shift ;
	my $len = shift ;
	my $offset = shift ;

	my $obj = $this->__get_object() ;

	my $ret = -1 ;
	eval {
		my $len = $obj->__get_private()->{proto}->WriteToJavaHandle(substr($buf, $offset, $len)) ;
		$ret = $len ;
	} ;
	croak $@ if $@ ;
}


sub __eof {
 	my $this = shift ;
}


sub __close {
 	my $this = shift ;

	my $obj = $this->__get_object() ;

	my $ret = undef ;
	{
		local $@ ;
		eval {
			$ret = $obj->__get_private()->{proto}->CloseJavaHandle() ;
			$obj->__get_private()->{closed} = 1 ;
		} ;
		croak $@ if $@ ;
	}

	return $ret ;
}



sub AUTOLOAD {
	my $this = shift ;
	my @args = @_ ;

	use vars qw($AUTOLOAD) ;
	my $func_name = $AUTOLOAD ;
	# Strip package from $func_name, Java will take of finding the correct
	# method.
	$func_name =~ s/^(.*)::// ;

	croak "Can't call method '$func_name' on Java handles" ;
}


sub DESTROY {
	my $this = shift ;


	my $knot = tied *{$this} ;
	if (! $knot){
		Inline::Java::debug(4, "destroying Inline::Java::Handle::Tie") ;

		my $obj = $this->__get_object() ;
		if (! $obj->__get_private()->{closed}){
		 	$this->__close() ;	
		}

		$OBJECTS->{$this} = undef ;
	}
	else {
		Inline::Java::debug(4, "destroying Inline::Java::Handle") ;
	}
}



######################## Handle methods ########################
package Inline::Java::Handle::Tie ;
@Inline::Java::Handle::Tie::ISA = qw(Tie::StdHandle) ;


use Tie::Handle ;
use Carp ;


sub TIEHANDLE {
	my $class = shift ;
	my $jclass = shift ;

	return $class->SUPER::TIEHANDLE(@_) ;
}


sub READ {
 	my $this = shift ;
	my ($buf, $len, $offset) = @_ ;

	my $ret = $this->__read($buf, $len, $offset) ;
	$_[0] = $buf ;

	return $ret ;
}


sub READLINE {
 	my $this = shift ;

	return $this->__readline() ;
}


sub WRITE {
 	my $this = shift ;
	my $buf = shift ;
	my $len = shift ;
	my $offset = shift ;

	return $this->__write($buf, $len, $offset) ;
}


sub BINMODE {
 	my $this = shift ;

	croak "Operation BINMODE not supported on Java handle" ;
}


sub OPEN {
 	my $this = shift ;

	croak "Operation OPEN not supported on Java handle" ;
}


sub TELL {
 	my $this = shift ;

	croak "Operation TELL not supported on Java handle" ;
}


sub FILENO {
 	my $this = shift ;

	croak "Operation FILENO not supported on Java handle" ;
}


sub SEEK {
 	my $this = shift ;

	croak "Operation SEEK not supported on Java handle" ;
}


sub EOF {
 	my $this = shift ;

	return $this->__eof() ;
}


sub CLOSE {
 	my $this = shift ;
		
	return $this->__close() ;
}


sub DESTROY {
 	my $this = shift ;
}


1 ;

