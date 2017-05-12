use ExtUtils::MakeMaker;
use Config;

#============================================================================
# We'll do our own prerequisite checking, since MakeMaker does it
# in a way that always fails: 'use Inline::C 0.33' will never work.
#============================================================================
eval { require Inline::C };
warn "Warning: prerequisite Inline::C  version 0.42 not found"
  if $@ or $Inline::C::VERSION < 0.42;

#=============================================================================
# Guess suitable defaults for assembler, compiler, linker, etc.
#=============================================================================
my $asm_guess;
my $cc_guess;
if ($Config{osname} =~ /^MSWin/) {
    $asm_guess = 'nasm';
    $cc_guess = 'cl';
}
elsif ($Config{osname} eq 'linux') {
    $asm_guess = 'as';
    $cc_guess = 'gcc';
}
else {
    $asm_guess = 'as';
    $cc_guess = 'gcc';
}

my %asflags_guess = 
  (
   nasm => ($Config{osname} =~ /^MSWin/) ? '-f win32' : '-f elf',
  );

#=============================================================================
# Prompt for assembler to use
#=============================================================================
my $asm = prompt("What assembler would you like to use?",
                 $asm_guess);
my $asflags = prompt("What flags do you want to pass to $asm by default?",
                     $asflags_guess{$asm} || '');

#=============================================================================
# Default C compiler
#=============================================================================
print 
  "Inline::ASM needs a C compiler to generate the Assembler-Perl bindings.\n";
my $cc = prompt("What C compiler would you like to use?",
                $cc_guess);
#=============================================================================
# Apply these defaults
#=============================================================================
open ASM, "ASM.pm";
my @lines = <ASM>;
close ASM;

for (@lines) {
    s|\@ASSEMBLER|$asm| if m|\# default assembler|;
    s|\@ASFLAGS|$asflags| if m|\# default asm flags|;
    s|\@COMPILER|$cc| if m|\# default compiler|;
}

open ASM, ">ASM.pm"
  or die "Can't write to ASM.pm!";
print ASM @lines;
close ASM;

#=============================================================================
# Write the Makefile
#=============================================================================
WriteMakefile(
	      NAME => 'Inline::ASM',
	      VERSION_FROM => 'ASM.pm',
	      PREREQ_PM => {
			    Inline => 0.42,
			   },
	      clean => {FILES => '_Inline_test/'},
	     );
