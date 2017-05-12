use Test::More tests => 28;
use Devel::IntelliPerl;
use Scalar::Util qw(refaddr);

my $source = <<'SOURCE';
package Foo;

use Moose;

has foobar => ( isa => 'Str', is => 'rw' );

{ no strict qw(refs);
*{'sub_'.$_} = sub {} for(1..9);
}

=head2 bar

=for intelliperl
method bar (Catalyst $c) returns Foo;

=cut

sub bar {
    my ($self, $c) = @_;
    $self->o;
}

my $file = new Path::Class::File;


1;
SOURCE


my $ip = Devel::IntelliPerl->new(source => $source, line_number => 20, column => 12);
like($ip->source, qr/package Foo/, 'constructor works as expected');
is($ip->line_number, 20, 'constructor works as expected');
is($ip->column, 12, 'constructor works as expected');
is($ip->line, '    $self->o;', 'get current line');
ok($ip->line('     $brabl->;'), 'set current line');
is($ip->line, '     $brabl->;', 'current line set successfully');
like($ip->source, qr/brabl/, 'source() updated accordingly');
ok($ip->line('    $self->o;'), 'restore line()');
isa_ok($ip->ppi, 'PPI::Document');
my $ref = refaddr $ip->ppi;
is(refaddr $ip->ppi, $ref, 'refaddr of ppi() and ppi() match');
ok($ip->source($ip->source), 'reset source');
isnt(refaddr $ip->ppi, $ref, 'refaddr of ppi changed');

# test class
ok($ip->line_number(25));
ok($ip->line('Foo->'));
ok($ip->column(6));
ok(grep { $_ eq 'bar' } $ip->methods, 'found method "bar"');

# test $self
$ip = Devel::IntelliPerl->new(source => $source, line_number => 20, column => 12);
like($ip->inject_statement('fo'), qr/\$self->foo;/, 'inject code after the current position');

is($ip->keyword, '$self', $ip->line);
is($ip->prefix, '');
ok($ip->column(15), 'set column to 15');
is($ip->prefix, 'foo');
is_deeply([$ip->methods], ['foobar']);
is_deeply([$ip->trimmed_methods], ['bar']);

# test $var
ok($ip->line_number(24), 'set line number to 24');
ok($ip->line('$file->'), 'set line to $file->');
ok($ip->column(9), 'set column to 9');
ok(grep { $_ eq 'absolute' } $ip->methods, 'found method "absolute"');
ok($ip->methods > 1, 'found more than one method');

