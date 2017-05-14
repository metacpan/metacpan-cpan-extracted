use Java::Wrapper;
use Java::TieJavaArray;

package Java::Import::ClassProxy;

use overload q("") => sub {
	$_[0]{prisoner}->toString();
};

sub _wrap_java_object {
	#print "***_WRAP_JAVA_OBJECT***\n";
	my $prisoner = shift;
	my $self = {};
	$$self{prisoner} = $prisoner;
	bless $self, __PACKAGE__;
}

sub _get_argument_list {
	my $arg_list = new Java::Wrapper::ArgumentArray(scalar(@_));
        foreach my $arg ( @_ ) {
                my $prisoner = $$arg{prisoner};
                $arg_list->addElement($prisoner);
	}
        $arg_list->DISOWN();
	$arg_list;
}

sub _wrap_return_value {
	#print "***_WRAP_RETURN_VALUE***\n";
	my $input = shift;
	#XXX void return types from class compiled Java cause an error
	if ( $input->isArray() ) {
		#print "***IS ARRAY***\n";
		my @tiedarray;
		tie @tiedarray, "Java::Import::TieJavaArray", Java::Wrapper::ArrayWrapper::getObjectAsArray($input);
		$ret_val = \@tiedarray;
	} else {
		#print "***IS NOT ARRAY***\n";
		$ret_val = _wrap_java_object($input);
	}
	$ret_val;
}

sub _wrap_exception {
	my $exception = shift;
	#_wrap_java_object($exception);
	_wrap_java_object($exception->invokeMethod("getTargetException", undef));
}

sub _exec_method {
	my $method_name = shift;
	my $self = shift;
	my $ret_val = $$self{prisoner}->invokeMethod($method_name, _get_argument_list(@_));
	my $exception_thrown = $$self{prisoner}->getLastThrownException();
	
        die _wrap_exception($exception_thrown) if $exception_thrown;
        _wrap_return_value($ret_val);

}

sub _exec_static_method {
	my $method_name = shift;
	(my $called = shift) =~ s/::/\./g;
	print "$called ... $method_name\n";
	my $ret_val = Java::Wrapper::ObjectWrapper::invokeStaticMethod(
		$called, $method_name, _get_argument_list(@_)
	);
	my $exception_thrown = Java::Wrapper::ObjectWrapper::getLastStaticThrownException();
	
        die _wrap_exception($exception_thrown) if $exception_thrown;
        _wrap_return_value($ret_val);
}

sub new {

	#print "***NEW***\n";

	my $real_class = shift;
	(my $java_class = $real_class) =~ s/::/\./g;

	my $arg_list = _get_argument_list(@_);
	my $ret_val = Java::Wrapper::ObjectWrapper::newClassInstance($java_class, $arg_list);

        my $exception_thrown = Java::Wrapper::ObjectWrapper::getLastStaticThrownException();
	
	die _wrap_exception( $exception ) if $exception_thrown;
	return _wrap_return_value($ret_val);
}

sub isa {
	my $self = shift;
	(my $isa_class = shift) =~ s/::/\./g;
	$$self{prisoner}->perl_isa($isa_class);
}

sub can {
	my $self = shift;
	$$self{prisoner}->can(shift);
}

sub AUTOLOAD {

	#print "***AUTOLOAD***\n";

	my $either = shift;
	#print "\$either: $either\n";
	#print "\$AUTOLOAD: $AUTOLOAD\n";
	my $arg_list = _get_argument_list(@_);
        my $ret_val = undef;
	my $exception_thrown = undef;
	
	unless ( ref $either ) {
		#print "***STATIC METHOD\n***\n";
		#Static Method being called

#		my ($package_name) = ($AUTOLOAD =~/(.*)::\w+$/);
#		my ($method_name) = ($AUTOLOAD =~/.*::(\w+)$/);
#		print "\$package_name: $package_name\n";
#		eval qq{
#			package $package_name;
#			sub $method_name { Java::Import::ClassProxy::_exec_static_method("$method_name", \@_); }
#		};
#
#		unshift @_, $either;
#		goto &{$AUTOLOAD};

		(my $called = $AUTOLOAD) =~ s/::/\./g;
		$ret_val = Java::Wrapper::ObjectWrapper::invokeStaticMethod(
			($called =~ /(.*)\.\w+$/), 
			($called =~ /.*\.(\w+)$/), 
			$arg_list
		);
	
		$exception_thrown = Java::Wrapper::ObjectWrapper::getLastStaticThrownException();

	} else {
		#print "***OBJECT METHOD***\n";
		#Object Method being called

#		my ($package_name) = ($AUTOLOAD =~/(.*)::\w+$/);
#		my ($method_name) = ($AUTOLOAD =~/.*::(\w+)$/);
#		eval qq{
#			package $package_name;
#			sub $method_name { _exec_method("$method_name", \@_); }
#		};
#
#		unshift @_, $either;
#		goto &{$AUTOLOAD};
		
		$ret_val = $$either{prisoner}->invokeMethod(($AUTOLOAD =~/.*::(\w+)$/), $arg_list);
		$exception_thrown = $$either{prisoner}->getLastThrownException();
	}
	
	#HOW DO I HANDLE FIELDS?????
	die _wrap_exception($exception_thrown) if $exception_thrown;
	_wrap_return_value($ret_val);
}

sub DESTROY {}

1;
