package Games::Mahjongg::Solver::deBondt::FFI;

$VERSION = '0.0.3';
my $pm_file = __FILE__;
use File::Basename qw(dirname);
my $pm_dir = dirname $pm_file;

use FFI::Platypus 1.00;
use FFI::Platypus::Memory qw( malloc free );
use FFI::CheckLib;

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lang('CPP');
my @libs = find_lib_or_die( lib => "Games-Mahjongg-Solver-deBondt-FFI",  libpath => [
    "$pm_dir/../../../../blib/lib/auto/share/dist/Games-Mahjongg-Solver-deBondt-FFI/lib",
    "$pm_dir/../../../../auto/share/dist/Games-Mahjongg-Solver-deBondt-FFI/lib",
]);
# warn "FYI: we found libs @libs";
my $lib = @libs ? $libs[0] : undef;
$lib or die "Found no lib, should never happen, giving up, cannot continue";
$ffi->lib($lib);

$ffi->custom_type( Foo => {
  native_type => 'opaque',
  perl_to_native => sub { ${ $_[0] } },
  native_to_perl => sub { bless \$_[0], 'Games::Mahjongg::Solver::deBondt::FFI' },
});

$ffi->attach( [ 'Foo::Foo()'     => '_new'     ]     => ['Foo']    => 'void' );
$ffi->attach( [ 'Foo::~Foo()'    => '_DESTROY' ]     => ['Foo']    => 'void' );
$ffi->attach( [ 'Foo::get_r1()'  => 'get_r1'  ]      => ['Foo']    => 'double'  );
$ffi->attach( [ 'Foo::get_r2()'  => 'get_r2'  ]      => ['Foo']    => 'double' );
$ffi->attach( [ 'Foo::get_g()'   => 'opaque_get_g' ] => ['Foo']    => 'opaque'  );
$ffi->attach( [ 'Foo::set_g(char*)'
                                 => 'set_g'  ]       => ['Foo','string']
                                                                   => 'void' );
$ffi->attach( [ 'Foo::set_r1(double)'
                                 => 'set_r1'  ]      => ['Foo','double']
                                                                   => 'void' );
$ffi->attach( [ 'Foo::set_r2(double)'
                                 => 'set_r2'  ]      => ['Foo','double']
                                                                   => 'void' );
$ffi->attach( [ 'Foo::foo_mjsolve()'
                                 => 'mjsolve' ]      => ['Foo']    => 'double' );
# $ffi->attach( [ 'Foo::free_string(char*)'
#                                  => 'free_string' ]  => ['opaque'] => 'void' );

my $size = $ffi->function('Foo::_size()' => [] => 'int')->call;

sub new
{
  my($class) = @_;
  my $ptr = malloc $size;
  my $self = bless \$ptr, $class;
  _new($self);
  $self;
}

sub DESTROY
{
  my($self) = @_;
  _DESTROY($self);
  free($$self);
}

sub get_g {
    my($self) = @_;
    my $ptr = $self->opaque_get_g;
    my $g = $ffi->cast( 'opaque' => 'string', $ptr );  # copies the string
    # $self->free_string($ptr);
    return $g;
}

1;

=head1 NAME

Games::Mahjongg::Solver::deBondt::FFI - Perl/FFI bindings to Mahjongg Solitaire Solver (after peeking) by Michiel de Bondt

=head1 SYNOPSIS

  my $ffi = Games::Mahjongg::Solver::deBondt::FFI->new();

  $ffi->set_g('  10 14 02 00 ... 08 10 00 35');
  $ffi->set_r1(0);
  $ffi->set_r2(0);
  my ($remain) = $ffi->mjsolve();

=head1 DESCRIPTION

The following is from the README of the DLL:

 The exported routine of the dll is:

 extern "C" __declspec (dllexport)
 double mjsolve (char* g, double r1, double r2)

 g is the string containing the positions of the (remaining) tiles, as decimal 
 numbers separated by whitespace, as follows:

 <row_1> <column_1> <level_1> <value_1>
 <row_2> <column_2> <level_2> <value_2>
 :
 :
 <row_n> <column_n> <level_n> <value_n>

 row_i and column_i must be in the interval [00..39]. level_i must be in the
 interval [00..09] and value_i must be in the interval [00..99], although you
 would need only [01..36] for value_i. Each value must appear an even number of
 times and may appear at most four times. 

 The program searches partial solutions that reduce the number of tiles to
 max(r1,r2) at least, and stops searching when a solution is found that reduce
 the number of tiles to min(r1,r2). If a solution is found, the best solution
 found solution is written to g in the very same format as the input in g, but 
 the tiles are in the take-away order. The length of g must be 12n at least. 

 The return value is max(r1,r2) + 2 if no solutions are found, and the number of
 tiles remaining for the returned solution otherwise.


=head1 BUGS

Exception handling is underdeveloped. Be careful what you can do with
$g, it is an opaque string that must match what the library expects
to get.

=head1 AUTHOR

Binding written by Andreas Koenig C<< <andk@cpan.org> >>

=head1 LICENSE

See the file COPYRIGHT that comes with this package

=head1 SEE ALSO

- home page of the library: https://www.math.ru.nl/~debondt/mjsolver.html

- link to the zip file with the library: https://www.math.ru.nl/~debondt/mjsolver_dll.zip

- thanks to Pedro Gimeno Fortea for his article about the solver at
  http://www.formauri.es/personal/pgimeno/mj-preview/MjSolver.php

- Kmahjongg Homepage: https://apps.kde.org/kmahjongg/

=cut
