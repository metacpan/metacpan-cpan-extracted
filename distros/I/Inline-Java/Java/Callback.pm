package Inline::Java::Callback ;

use strict ;
use Carp ;

$Inline::Java::Callback::VERSION = '0.53_90' ;

$Inline::Java::Callback::OBJECT_HOOK = undef ;


my %OBJECTS = () ;
my $next_id = 1 ;


sub InterceptCallback {
	my $inline = shift ;
	my $resp = shift ;

	# With JNI we need to store the object somewhere since we
	# can't drag it along all the way through Java land...
	if (! defined($inline)){
		$inline = $Inline::Java::JNI::INLINE_HOOK ;
	}

	if ($resp =~ s/^callback ([^ ]+) (\@?[\w:]+) ([^ ]+)//){
		my $via = $1 ;
		my $function = $2 ;
		my $cast_return = $3 ;
		my @args = split(' ', $resp) ;

		# "Relative" namespace...
		if ($via =~ /^::/){
			$via = $inline->get_api('pkg') . $via ;
		}
		if ($function =~ /^::/){
			$function = $inline->get_api('pkg') . $function ;
		}
		
		return Inline::Java::Callback::ProcessCallback($inline, $via, $function, $cast_return, @args) ;
	}

	croak "Malformed callback request from server: $resp" ;
}


sub ProcessCallback {
	my $inline = shift ;
	my $via = shift ;
	my $function = shift ;
	my $cast_return = shift ;
	my @sargs = @_ ;

	my $list_ctx = 0 ;
	if ($function =~ s/^\@//){
		$list_ctx = 1 ;
	}

	my $pc = new Inline::Java::Protocol(undef, $inline) ;
	my $thrown = 'false' ;

	my $ret = undef ;
	my @ret = () ;
	eval {
		my @args = map {
			my $a = $pc->DeserializeObject(0, $_) ;
			$a ;
		} @sargs ;

		no strict 'refs' ;
		if ($via =~ /^(\d+)$/){
			# Call via object
			my $id = $1 ;
			Inline::Java::debug(2, "processing callback $id" . "->" . "$function(" . 
				join(", ", @args) . ")") ;
			my $obj = Inline::Java::Callback::GetObject($id) ;
			if ($list_ctx){
				@ret = $obj->$function(@args) ;
			}
			else{
				$ret = $obj->$function(@args) ;
			}
		}
		elsif ($via ne 'null'){
			# Call via package
			Inline::Java::debug(2, "processing callback $via" . "->" . "$function(" . 
				join(", ", @args) . ")") ;
			if ($list_ctx){
				@ret = $via->$function(@args) ;
			}
			else{
				$ret = $via->$function(@args) ;
			}
		}
		else {
			# Straight call
			Inline::Java::debug(2, "processing callback $function(" . 
				join(", ", @args) . ")") ;
			if ($function !~ /::/){
				$function = 'main' . '::' . $function ;
			}
			if ($list_ctx){
				@ret = $function->(@args) ;
			}
			else{
				$ret = $function->(@args) ;
			}
		}

		if ($list_ctx){
			$ret = \@ret ;
		}
	} ;
	if ($@){
		$ret = $@ ;
		$thrown = 'true' ;

		if ((ref($ret))&&(! UNIVERSAL::isa($ret, "Inline::Java::Object"))){
			croak "Can't propagate non-Inline::Java reference exception ($ret) to Java" ;
		}
	}

	($ret) = Inline::Java::Class::CastArgument($ret, $cast_return, $inline) ;
	
	# Here we must keep a reference to $ret or else it gets deleted 
	# before the id is returned to Java...
	my $ref = $ret ;

	($ret) = $pc->ValidateArgs([$ret], 1) ;

	return ("callback $thrown $ret", $ref) ;
}


sub GetObject {
	my $id = shift ;

	my $obj = $OBJECTS{$id} ;
	if (! defined($obj)){
		croak("Can't find object $id") ;
	}

	return $obj ;
}


sub PutObject {
	my $obj = shift ;

	my $id = $next_id ;
	$next_id++ ;

	$OBJECTS{$id} = $obj ;

	return $id ;
}


sub DeleteObject {
	my $id = shift ;
	my $quiet = shift || 0 ;

	my $obj = delete $OBJECTS{$id} ;
	if ((! $quiet)&&(! defined($obj))){
		croak("Can't find object $id") ;
	}
}


sub ObjectCount {
	return scalar(keys %OBJECTS) ;
}


sub __GetObjects {
	return \%OBJECTS ;
}



########## Utility methods used by Java to access Perl objects #################


sub java_eval {
    my $code = shift ;

	Inline::Java::debug(3, "evaling Perl code: $code") ; 
    my $ret = eval $code ;
    if ($@){
        die($@) ;
    }

    return $ret ;
}


sub java_require {
    my $module = shift ;
	my $is_file = shift ;

	if (! defined($is_file)){
		if (-e $module){
			$module = "\"$module\"" ;
		}
	}

	if ($is_file){
		$module = "\"$module\"" ;
	}

	Inline::Java::debug(3, "requiring Perl module/file: $module") ; 
    return java_eval("require $module ;") ;
}


sub java_finalize {
	my $id = shift ;
	my $gc = shift ;

	Inline::Java::Callback::DeleteObject($id, $gc) ;
}


1 ;
