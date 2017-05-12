package Devel::Optrace;

use 5.008_001;
#use strict;
#use warnings;

BEGIN{
	our $VERSION = '0.05';

	require XSLoader;
	XSLoader::load(__PACKAGE__, $VERSION);

	$^H |= 0x600; # use strict qw(subs vars);
}

our $DB; # tracing flags

my %bits = (
	-trace   => DOf_TRACE,
	-stack   => DOf_STACK,
	-runops  => DOf_RUNOPS,

	-noopt   => DOf_NOOPT,
	-count   => DOf_COUNT,

	-all     => DOf_DEFAULT,
);


sub import{
	my $class = shift;

	if($^P != 0){
		push @_, -all;
	}

	while(scalar(@_) && $_[0] =~ /^-/){
		my $opt   = shift;
		my $value = (scalar(@_) && $_[0] =~ /^[01]$/ ? shift : 1);
		$class->set($opt => $value);
	}

	#no strict 'refs';
	*{caller() . '::p'} = \&p;
	return;
}

sub enable{
	$DB |=  DOf_DEFAULT;
}
sub disable{
	$DB &= ~DOf_DEFAULT;
}

sub set{
	my($class, $opt, $value) = @_;
	my $bit = $bits{$opt};

	unless(defined $bit){
		require Carp;
		Carp::croak(qq{Unknown option "$opt"});
	}

	if($value){
		$DB |= $bit;
	}
	else{
		$DB &= ~$bit;
	}

	return;
}


1;
__END__

=head1 NAME

Devel::Optrace - Traces opcodes which are running now

=head1 VERSION

This document describes Devel::Optrace version 0.05.

=head1 SYNOPSIS

	use Devel::Optrace;
	Devel::Optrace->enable();  # enables  -trace, -stack and -runops
	# ...
	Devel::Optrace->disable(); # disables -trace, -stack and -runops

	# or command line:
	# $ perl -MDevel::Optrace=-all -e '...'  # normal way
	# $ perl -d:Optrace -e '...'             # shortcut


=head1 DESCRIPTION

Devel::Optrace is an opcode debugger which traces opcodes and stacks.

There are several trace options:

=over 4

=item -trace

Traces opcodes like perl's C<-Dt>, reporting
C<"$opcode @op_private @op_flags"> or C<"$opcode(@op_data) @op_private @op_flags">.

The indent level indicates the depth of the context stacks.

=item -stack

Dumps the perl stack (C<PL_stack>) like perl's C<-Ds>.

=item -runops

Traces C<runops> levels with the current stack info type (MAIN, OVERLOAD, DESTROY, etc.).

=item -all

Sets C<-trace>, C<-stack> and C<-runops> on/off.

=item -count

Counts and reports opcodes executed.

=item -noopt

Disable the peephole optimizer.

=back

=head1 EXAMPLES

C<< perl -d:Optrace -e 'print qq{Hello, @ARGV world!\n}' Perl >>:

	Entering RUNOPS MAIN (-e:0)
	()
	enter
	 ()
	 nextstate(main -e:1) VOID
	 ()
	 pushmark SCALAR
	 ()
	 const("Hello, ") SCALAR
	 ("Hello, ")
	 pushmark SCALAR
	 ("Hello, ")
	 gvsv($") SCALAR
	 ("Hello, "," ")
	 gv(*ARGV) SCALAR
	 ("Hello, "," ",*ARGV)
	 rv2av LIST KIDS
	 ("Hello, "," ","Perl")
	 join SCALAR KIDS
	 ("Hello, ","Perl")
	 concat SCALAR KIDS
	 ("Hello, Perl")
	 const(" world!\n") SCALAR
	 ("Hello, Perl"," world!\n")
	 concat SCALAR KIDS STACKED
	 ("Hello, Perl world!\n")
	 print VOID KIDS
	 (YES)
	 leave VOID KIDS PARENS
	()
	Leaving RUNOPS MAIN (-e:0)

This reveals that the perl code C<< print qq{Hello, @ARGV world!\n} >> is
interpreted as C<< print qq{Hello, } . join($", @ARGV) . qq{ world!\n} >>.

=head1 DEPENDENCIES

Perl 5.8.1 or later, and a C compiler.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 SEE ALSO

L<perlrun>.

L<B::Concise>.

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
