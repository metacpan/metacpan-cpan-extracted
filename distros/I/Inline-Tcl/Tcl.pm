package Inline::Tcl;

use strict;
$Inline::Tcl::VERSION = '0.09';

require Inline;
require DynaLoader;
require Exporter;

use Carp;
use Data::Dumper;

use vars qw(@ISA $VERSION @EXPORT_OK);
@Inline::Tcl::ISA = qw(Inline DynaLoader Exporter);

@EXPORT_OK = qw(eval_tcl);

#==============================================================================
# Load (and initialize) the Tcl Interpreter
#==============================================================================
sub dl_load_flags { 0x01 }
Inline::Tcl->bootstrap($Inline::Tcl::VERSION);

#==============================================================================
# Allow 'use Inline::Tcl qw(eval_tcl)'
#==============================================================================
sub import {
    Inline::Tcl->export_to_level(1,@_);
}

#==============================================================================
# Provide an overridden function for evaluating Tcl code
#==============================================================================
sub eval_tcl {
  if (scalar @_ == 1) {
    return _eval_tcl(@_);
  }
  elsif ((scalar @_ < 3) or not (ref $_[2] =~ /::/)) {
    return _eval_tcl_function(@_);
  }
  else {
    croak "Invalid use of eval_tcl()." .
      " See 'perldoc Inline::Tcl' for details";
  }
}

#==============================================================================
# Register Tcl.pm as a valid Inline language
#==============================================================================
sub register {
    return {
	    language => 'Tcl',
	    aliases => ['tcl', 'tk'],
	    type => 'interpreted',
	    suffix => 'tcldat',
	   };
}

#==============================================================================
# Validate the Tcl config options
#==============================================================================
sub validate {
    my $o = shift;

    $o->{Tcl} = {};
    $o->{Tcl}{AUTO_INCLUDE} = {};
    $o->{Tcl}{PRIVATE_PREFIXES} = [];
    $o->{Tcl}{built} = 0;
    $o->{Tcl}{loaded} = 0;

    while (@_) {
	my ($key, $value) = (shift, shift);

	if ($key eq 'AUTO_INCLUDE') {
	    add_string($o->{Tcl}{AUTO_INCLUDE}, $key, $value, '');
	    warn "AUTO_INCLUDE has not been implemented yet!\n";
	}
	elsif ($key eq 'PRIVATE_PREFIXES') {
	    add_list($o->{Tcl}, $key, $value, []);
	}
	else {
	    croak "$key is not a valid config option for Tcl\n";
	}
	next;
    }
}

sub add_list {
    my ($ref, $key, $value, $default) = @_;
    $value = [$value] unless ref $value;
    croak usage_validate($key) unless ref($value) eq 'ARRAY';
    for (@$value) {
	if (defined $_) {
	    push @{$ref->{$key}}, $_;
	}
	else {
	    $ref->{$key} = $default;
	}
    }
}

sub add_string {
    my ($ref, $key, $value, $default) = @_;
    $value = [$value] unless ref $value;
    croak usage_validate($key) unless ref($value) eq 'ARRAY';
    for (@$value) {
	if (defined $_) {
	    $ref->{$key} .= ' ' . $_;
	}
	else {
	    $ref->{$key} = $default;
	}
    }
}

sub add_text {
    my ($ref, $key, $value, $default) = @_;
    $value = [$value] unless ref $value;
    croak usage_validate($key) unless ref($value) eq 'ARRAY';
    for (@$value) {
	if (defined $_) {
	    chomp;
	    $ref->{$key} .= $_ . "\n";
	}
	else {
	    $ref->{$key} = $default;
	}
    }
}

###########################################################################
# Print a short information section if PRINT_INFO is enabled.
###########################################################################
sub info {
    my $o = shift;
    my $info =  "";

    $o->build unless $o->{Tcl}{built};
    $o->load unless $o->{Tcl}{loaded};

    my @functions = @{$o->{Tcl}{namespace}{functions}||{}};
    $info .= "The following Tcl functions have been bound to Perl:\n"
      if @functions;
    for my $function (sort @functions) {
	$info .= "\tdef $function()\n";
    }

    return $info;
}

###########################################################################
# Use Tcl to Parse the code, then extract all newly created functions
# and save them for future loading
###########################################################################
sub build {
    my $o = shift;
    return if $o->{Tcl}{built};
    my $result = _eval_tcl($o->{API}{code});
    croak "Couldn't parse your Tcl code.\n" 
      unless $result;

    my %namespace = _Inline_parse_tcl_namespace();

    my @filtered;
    for my $func (@{$namespace{functions}}) {
	my $private = 0;
	for my $prefix (@{$o->{Tcl}{PRIVATE_PREFIXES}}) {
	    ++$private and last
	      if substr($func, 0, length($prefix)) eq $prefix;
	}
	push @filtered, $func
	  unless $private;
    }
    $namespace{functions} = \@filtered;

    warn "No functions found!"
      unless ((length @{$namespace{functions}}) > 0 );

    require Data::Dumper;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    my $namespace = Data::Dumper::Dumper(\%namespace);

    # if all was successful
    $o->mkpath("$o->{API}{install_lib}/auto/$o->{API}{modpname}");

    #$o->{Tcl}{location} = "$o->{API}{install_lib}/auto/$o->{API}{modpname}/$o->{API}{modfname}.$o->{API}{suffix}";
    #print Dumper $o;
    $o->mkpath( "$o->{API}{install_lib}/auto/$o->{API}{modpname}" );
    
    open TCLDAT, "> $o->{API}{location}" or
      croak "Inline::Tcl couldn't write parse information!";
    print TCLDAT <<END;
%namespace = %{$namespace};
END
    close TCLDAT;

    $o->{Tcl}{built}++;
}

#==============================================================================
# Load and Run the Tcl Code, then export all functions from the tcldat 
# file into the caller's namespace
#==============================================================================
sub load {
    #print "LOAD\n";
    my $o = shift;
    return if $o->{Tcl}{loaded};
    open TCLDAT, $o->{API}{location} or 
      croak "Couldn't open parse info!";
    my $tcldat = join '', <TCLDAT>;
    close TCLDAT;

    eval <<END;
;package Inline::Tcl::namespace;
no strict;
$tcldat
END

    croak "Unable to parse $o->{API}{location}\n$@\n" if $@;

    $o->{Tcl}{namespace} = \%Inline::Tcl::namespace::namespace;
    delete $main::{Inline::Tcl::namespace::};
    $o->{Tcl}{loaded}++;

    my $result = _eval_tcl($o->{API}{code});

    # bind some perl functions to the caller's namespace
    for my $function (@{$o->{Tcl}{namespace}{functions}}) {
      my $s = "*::" . "$o->{API}{pkg}";
      $s .= "::$function = sub { ";
      $s .= "Inline::Tcl::_eval_tcl_function";
      $s .= "(__PACKAGE__,\"$function\", \@_) }";
      #print "$s\n";
      eval $s;
      croak $@ if $@;
    }
}

1;

__END__
