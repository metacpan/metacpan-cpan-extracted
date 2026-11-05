use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use File::Temp ();
use Devel::XSCover::XS ();

my $dir = File::Temp->newdir;

sub put {
    my ($name, $text) = @_;
    my $path = File::Spec->catfile($dir, $name);
    open my $fh, '>', $path or die "$path: $!";
    print $fh $text;
    close $fh;
    return $path;
}

put('Hand.xs', <<'XS');
MODULE = Hand  PACKAGE = Hand

int
named(x)
    int x
  CODE:
    RETVAL = x;
  OUTPUT:
    RETVAL

int
unnamed(x)
    int x
  CODE:
    RETVAL = 1;
  OUTPUT:
    RETVAL
XS

put('Hand.c', <<'C');
#line 1 "Hand.xs"
#line 3 "Hand.c"
XS_EUPXS(XS_Hand_named); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_Hand_named)
{
    dVAR; dXSARGS;
#line 8 "Hand.c"
    {
#line 7 "Hand.xs"
    RETVAL = x;
#line 12 "Hand.c"
    }
}
XS_EUPXS(XS_Hand_unnamed)
{
#line 15 "Hand.xs"
    RETVAL = 1;
#line 19 "Hand.c"
}
XS_EUPXS(XS_Hand_lost)
{
    dVAR; dXSARGS;
}
XS_EXTERNAL(boot_Hand)
{
        newXS_deffile("Hand::named", XS_Hand_named);
}
C

my $xs = Devel::XSCover::XS->new(dir => "$dir");
my %by = map { $_->{c_name} => $_ } $xs->xsubs('Hand.c');
is_deeply($by{XS_Hand_named}, { c_name => 'XS_Hand_named', c_line => 4, file => 'Hand.xs', body_line => 7 }, 'a #line back into the c before the body is passed over for the one into the xs');
is_deeply($by{XS_Hand_lost}, { c_name => 'XS_Hand_lost', c_line => 20 }, 'a wrapper with no #line at all has no file');

my $map = $xs->map('Hand.c');
is_deeply($map->{lines}[8], ['Hand.c', 8], 'the line after the #line into the c is the c');
is_deeply($map->{xsubs}{XS_Hand_unnamed}, { c_name => 'XS_Hand_unnamed', c_line => 14, file => 'Hand.xs', body_line => 15, names => [], line => 12 },
    'a wrapper the boot never registers has its declaration line and no Perl name');
is_deeply($map->{xsubs}{XS_Hand_lost}, { c_name => 'XS_Hand_lost', c_line => 20, names => [], line => undef }, 'one with neither a #line nor a name has nothing to go on');
is_deeply([ $xs->subroutines($map) ], [ { c_name => 'XS_Hand_named', file => 'Hand.xs', line => 4, names => ['Hand::named'] } ],
    'only the wrapper with both a line and a name is a subroutine');

my $abs = put('Abs.xs', <<'XS');
MODULE = Abs  PACKAGE = Abs

int
far()
  CODE:
    RETVAL = 1;
XS
put('Abs.c', <<"C");
XS_EUPXS(XS_Abs_far)
{
#line 6 "$abs"
    RETVAL = 1;
#line 6 "Abs.c"
}
XS_EXTERNAL(boot_Abs)
{
        newXS_deffile("Abs::far", XS_Abs_far);
}
C
my $far = $xs->map('Abs.c');
my $abs_name = $abs;
$abs_name =~ s{\\}{/}g if $^O eq 'MSWin32';
is_deeply($far->{files}, [$abs_name], 'a #line naming the xs by an absolute path, as an out-of-tree build writes, keeps that path, spelt with slashes on Windows');
is_deeply([ $xs->subroutines($far) ], [ { c_name => 'XS_Abs_far', file => $abs_name, line => 4, names => ['Abs::far'] } ], 'and the declaration is read from there');

put('Win.c', <<'C');
#line 1 "deep\Win.xs"
int x;
C
{
    local $^O = 'MSWin32';
    is_deeply($xs->map('Win.c')->{files}, ['deep/Win.xs'], 'a #line written with backslashes names the file with slashes on Windows');
}

my $nope = File::Spec->catfile($dir, 'nope.c');
eval { $xs->line_map('nope.c') };
like($@, qr/^xs_cover: cannot read \Q$nope\E: /, 'a generated file that is not there is a plain message');

my $blib = File::Spec->catdir($dir, 'blib');
mkdir $blib or die "$blib: $!";
for my $name (qw(B.xs B.c)) {
    open my $fh, '>', File::Spec->catfile($blib, $name) or die;
    close $fh;
}
is_deeply([ Devel::XSCover::XS->new(dir => $blib)->generated_files ], [['B.xs', 'B.c']], 'the top directory is scanned whatever its name, blib included');

done_testing;
