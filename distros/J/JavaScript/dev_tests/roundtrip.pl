use strict;
use warnings;
use JavaScript;

my $rt = JavaScript::Runtime->new;
my $cx = $rt->create_context;

$cx->bind_class(
 'package'   => 'Foo',
 'name'      => 'Foo',
 constructor => sub {
   return Foo->new;
 },
 properties        => {},
 static_methods    => {
   'list' => sub { my $self = shift; return $self->list; },
 }
);

{
 my $fn = $cx->eval("function t() { return Foo.list();  } t;" );
 my $v = $fn->();
 use Devel::Peek qw(Dump);

 Dump($v);
 
 my $v2 = Foo->list();
 Dump($v2);
 
}

print "destruction should be done\n";

sub END {
 print "should be really done now\n";
}

package Foo;

sub new {
 my $class = shift;
 my $self  = {};
 #$one ||=
 bless $self, $class;
}

sub list {
 my $class = shift;
 my @objs;
 for (1..2) {
   push @objs, $class->new;
 }
# return [{}];
 return \@objs;
}

sub DESTROY {
 print "object going boom!\n";
}

JavaScript::dump_sv_report_used();
1;