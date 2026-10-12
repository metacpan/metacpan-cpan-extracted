package Term::ReadKey;

# A Term::ReadKey that is NOT there. Put t/lib/absent first on @INC and every
# `eval { require Term::ReadKey; 1 }` fails, which is what a machine without
# it looks like to the program.

die "Term::ReadKey is absent on purpose (t/lib/absent)\n";
