# Make with Perl.

![Test](https://github.com/philiprbrenan/MakeWithPerl/workflows/Test/badge.svg)

Integrated development environment for
[Geany](https://www.geany.org/download/releases/) or similar editor for
compiling running and documenting programs written in a number of languages.

# Installation

Install from [CPAN](https://metacpan.org/release/MakeWithPerl)

    sudo cpan install MakeWithPerl

# Configuration

Configure **Geany->Build->Set Build Commands** as shown in the following image: ![image](https://github.com/philiprbrenan/MakeWithPerl/blob/main/Geany.png).

The text to enter is:

    perl -M"MakeWithPerl" -e"MakeWithPerl::makeWithPerl" -- --compile "%d/%f"

    perl -M"MakeWithPerl" -e"MakeWithPerl::makeWithPerl" -- --run "%d/%f"

    .+ at (.+) line ([0-9]+).*

    perl -M"MakeWithPerl" -e"MakeWithPerl::makeWithPerl" --  --doc "%d/%f"

    perl -M"MakeWithPerl" -e"MakeWithPerl::makeWithPerl" -- --upload "%d/%f"

    perl -M"MakeWithPerl" -e"MakeWithPerl::makeWithPerl" --  --doc "%d/%f"


# Operation on Geany

### Press **F8** to compile a program

### Press **F9** to run a program

### Press **F5** to document a program


For documentation see: [CPAN](https://metacpan.org/pod/Make::With::Perl)