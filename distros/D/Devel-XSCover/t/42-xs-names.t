use 5.020;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Devel::XSCover::XS ();

my $names = Devel::XSCover::XS->new(dir => 't/fixtures/spike')->perl_names('Spike.c');
is_deeply($names->{XS_Spike_add}, ['Spike::add', 'Spike::plus'], 'an ALIAS gives the wrapper two names');
is_deeply($names->{XS_Spike__More_triple}, ['Spike::More::triple'], 'a name in the included package');
is(scalar keys %$names, 11, 'eleven wrappers named');

$names = Devel::XSCover::XS->new(dir => 't/fixtures/ex-op')->perl_names('Op.c');
is_deeply($names->{XS_Ex__Op_import}, ['Ex::Op::import'], 'Ex::Op::import');
is(scalar keys %$names, 16, 'sixteen');

my $x = Devel::XSCover::XS->new;
my $text = <<'C';
        newXSproto_portable("Foo::bar", XS_Foo_bar, file, "$$");
        (void)newXS_flags("Foo::baz", XS_Foo_baz, file, "", 0);
        cv = newXS("Foo::old", XS_Foo_old, file);
C
my $dir = File::Temp->newdir;
open my $fh, '>', "$dir/x.c" or die;
print $fh $text;
close $fh;
is_deeply(Devel::XSCover::XS->new(dir => "$dir")->perl_names('x.c'),
    { XS_Foo_bar => ['Foo::bar'], XS_Foo_baz => ['Foo::baz'], XS_Foo_old => ['Foo::old'] },
    'the prototype, flags and plain newXS forms');

done_testing;
