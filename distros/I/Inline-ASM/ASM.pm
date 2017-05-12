package Inline::ASM;

use strict;
require Inline::C;
use Config;
use Data::Dumper;
use FindBin;
use Carp;
use Cwd qw(cwd abs_path);

$Inline::ASM::VERSION = '0.03';
@Inline::ASM::ISA = qw(Inline::C);

#==============================================================================
# Register this module as an Inline language support module
#==============================================================================
sub register {
    my $suffix = ($^O eq 'aix') ? 'so' : $Config{so};
    return {
	    language => 'ASM',
	    aliases => ['nasm', 'NASM', 'gasp', 'GASP', 'as', 'AS', 'asm'],
	    type => 'compiled',
	    suffix => $suffix,
	   };
}

#==============================================================================
# Validate the Assembler config options
#==============================================================================
sub validate {
    my $o = shift;

    $o->{ILSM} = {};
    $o->{ILSM}{XS} = {};
    $o->{ILSM}{MAKEFILE} = {};

    # These are written at configuration time
    $o->{ILSM}{AS} ||= '@ASSEMBLER';          # default assembler
    $o->{ILSM}{ASFLAGS} ||= '@ASFLAGS';       # default asm flags
    $o->{ILSM}{MAKEFILE}{CC} ||= '@COMPILER'; # default compiler

    $o->{ILSM}{AUTO_INCLUDE} ||= <<END;
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
END

    my @propagate;
    while (@_) {
	my ($key, $value) = (shift, shift);
        if ($key eq 'AUTOWRAP') {
            croak "'$key' is not a valid config option for Inline::ASM\n";
        }
	if ($key eq 'AS' or
	    $key eq 'ASFLAGS') {
	    $o->{ILSM}{$key} = $value;
	    next;
	}
	if ($key eq 'PROTOTYPES' or
	    $key eq 'PROTO') {
	    croak "Invalid value for '$key' option"
	      unless ref $value eq 'HASH';
	    $o->{ILSM}{PROTOTYPES} = $value;
	    next;
	}
	push @propagate, $key, $value;
    }

    $o->SUPER::validate(@propagate) if @propagate;
}

#==============================================================================
# Parse and compile code
#==============================================================================
sub build {
    my $o = shift;
    $o->parse;
    $o->write_XS;
    $o->write_ASM;
    $o->write_Makefile_PL;
    $o->compile;
}

#==============================================================================
# Return a small report about the ASM code.
#==============================================================================
sub info {
    my $o = shift;
    my $text = '';

    $o->parse unless $o->{parser};

    my $sym;
    if (defined $o->{parser}) {
	my $num_bound = scalar keys %{$o->{parser}{bound}};
	my $num_unbound = scalar keys %{$o->{parser}{unbound}};
	my $num_missing = scalar keys %{$o->{parser}{missing}};
	if ($num_bound) {
	    $text .= "The following ASM symbols have been bound to Perl:\n";
	    for $sym (keys %{$o->{parser}{bound}}) {
		my ($rtype, $args) = $o->{ILSM}{PROTOTYPES}{$sym}
		  =~ m!([^\(]+)(\([^\)]*\))!g;
		$text .= "\t$rtype $sym $args\n";
	    }
	}
	if ($num_unbound) {
	    $text .= "The following unprototyped symbols were ignored:\n";
	    for $sym (keys %{$o->{parser}{unbound}}) { $text .= "\t$sym\n"; }
	}
	if ($num_missing) {
	    $text .= "The following prototyped symbols were missing:\n";
	    for $sym (keys %{$o->{parser}{missing}}) { $text .= "\t$sym\n"; }
	}
    }
    else {
	$text .= "No ASM functions have been successfully bound to Perl.\n\n";
    }
    return $text;
}

#==============================================================================
# Parse the function definition information out of the ASM code
#==============================================================================
sub parse {
    my $o = shift;
    return if $o->{parser};
    $o->get_maps;
    $o->get_types;

    my $globals = $o->global_keys;

    # Extract the GLOBAL and COMMON symbols:
    $o->{ILSM}{code} = $o->filter(@{$o->{ILSM}{FILTERS}});
    my @symbols = ($o->{ILSM}{code} =~ m!^\s*(?:$globals)\s+(\w+)!mig);

    my %bound;
    my %unbound;
    my %missing;
    my $sym;

    for $sym (@symbols) {
	$bound{$sym}++ if $o->{ILSM}{PROTOTYPES}{$sym};
	$unbound{$sym}++ unless $o->{ILSM}{PROTOTYPES}{$sym};
    }
    for $sym (keys %{$o->{ILSM}{PROTOTYPES}}) {
	$missing{$sym}++ unless $bound{$sym};
    }

    $o->{parser} = {bound => \%bound,
		    unbound => \%unbound,
		    missing => \%missing,
		   };
}

#==============================================================================
# Write the ASM code
#==============================================================================
sub write_ASM {
    my $o = shift;
    open ASM, "> $o->{API}{build_dir}/$o->{API}{modfname}_asm.asm"
      or croak "Inline::ASM::write_ASM: $!";
    print ASM $o->{ILSM}{code};
    close ASM;
}

#==============================================================================
# Generate the XS glue code
#==============================================================================
sub write_XS {
    my $o = shift;
    my ($pkg, $module, $modfname) = @{$o->{API}}{qw(pkg module modfname)};
    my $prefix = (($o->{ILSM}{XS}{PREFIX}) ?
		  "PREFIX = $o->{ILSM}{XS}{PREFIX}" :
		  '');
		  
    $o->mkpath($o->{API}{build_dir});
    open XS, "> $o->{API}{build_dir}/$modfname.xs"
      or croak "Inline::ASM::write_XS: $!";

    print XS <<END;
$o->{ILSM}{AUTO_INCLUDE}
END

    for my $sym (keys %{$o->{parser}{bound}}) {
	my ($rtype, $args) = $o->{ILSM}{PROTOTYPES}{$sym}
	  =~ m!([^\(]+)(\([^\)]*\))!g;
	print XS "extern $rtype $sym $args;\n";
    }

    print XS <<END;

MODULE = $module	PACKAGE = $pkg	$prefix

PROTOTYPES: DISABLE
END

    warn("Warning. No Inline ASM functions bound to Perl\n" .
         "Check your PROTO option(s) for Inline compatibility\n\n")
      if ((not scalar keys %{$o->{parser}{bound}}) and ($^W));

    my $parm = "neil";
    for my $function (keys %{$o->{parser}{bound}}) {
	my ($rtype, $args) = $o->{ILSM}{PROTOTYPES}{$function}
	  =~ m!([^\(]+)(\([^\)]*\))!g;

	$args =~ s/\(([^\)]*)\)/$1/;
	my @arg_types = split/\s*,\s*/, $args;
	my @arg_names = map { $parm++ } @arg_types;

	print XS ("\n$rtype\n$function (", 
		  join(', ', @arg_names), ")\n");

	for my $arg_name (@arg_names) {
	    my $arg_type = shift @arg_types;
	    last if $arg_type eq '...';
	    print XS "\t$arg_type\t$arg_name\n";
	}

	my $listargs = '';
	my $arg_name_list = join(', ', @arg_names);

	if ($rtype eq 'void') {
	    print XS <<END;
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	$function($arg_name_list);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */
END
	}
    }
    print XS "\n";

    if (defined $o->{ILSM}{XS}{BOOT} and
	$o->{ILSM}{XS}{BOOT}) {
	print XS <<END;
BOOT:
$o->{ILSM}{XS}{BOOT}
END
    }

    close XS;
}

#==============================================================================
# Generate the Makefile.PL
#==============================================================================
sub write_Makefile_PL {
    my $o = shift;

    $o->{ILSM}{xsubppargs} = '';
    for (@{$o->{ILSM}{MAKEFILE}{TYPEMAPS}}) {
	$o->{ILSM}{xsubppargs} .= "-typemap $_ ";
    }

    my %options = (
		   VERSION => '0.00',
		   %{$o->{ILSM}{MAKEFILE}},
		   NAME => $o->{API}{module},
		   OBJECT => qq{\$(BASEEXT)\$(OBJ_EXT) $o->{API}{modfname}_asm\$(OBJ_EXT)},
		  );

    open MF, "> $o->{API}{build_dir}/Makefile.PL"
      or croak "Inline::ASM::write_Makefile_PL: $!\n";

    print MF <<END;
use ExtUtils::MakeMaker;
my %options = %\{
END

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    print MF Data::Dumper::Dumper(\ %options);

    my $asmcmd;
    # This neato little hack notices that GASP is being used, and substitutes
    # 'gasp' for 'gasp <filename.asm> | as -o <filename.o>'
    if ($o->{ILSM}{AS} =~ /^\s*gasp/) {
        $asmcmd = $o->{ILSM}{AS};
        $asmcmd =~ s|gasp|gasp $o->{API}{modfname}_asm.asm|;
        $asmcmd .= "| as $o->{ILSM}{ASFLAGS} -o $o->{API}{modfname}_asm\$(OBJ_EXT)";
    }
    else {
        $asmcmd = "$o->{ILSM}{AS} $o->{ILSM}{ASFLAGS} $o->{API}{modfname}_asm.asm ";
        $asmcmd .= "-o $o->{API}{modfname}_asm\$(OBJ_EXT)";
    }

    print MF <<END;
\};
WriteMakefile(\%options);

sub MY::postamble {
  <<'FOO';
$o->{API}{modfname}_asm\$(OBJ_EXT) : $o->{API}{modfname}_asm.asm
	$asmcmd
FOO
}

END
    close MF;
}

#==============================================================================
# Returns a string which, when used in a regex, can extract global symbols.
# Depends on assembler being used.
#==============================================================================
sub global_keys {
    my $o = shift;
    my $asm = $o->{ILSM}{AS};
    if ($asm =~ /nasm/i) {
	return 'GLOBAL|COMMON';
    }
    elsif ($asm =~ /gasp/i) {
        return '\.GLOBAL';
    }
    elsif ($asm =~ /as/i) {
	return '\.(?:globl|common)';
    }
}

1;

__END__
