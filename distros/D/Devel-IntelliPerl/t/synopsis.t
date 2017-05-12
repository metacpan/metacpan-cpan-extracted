use Test::More tests => 1;
use Devel::IntelliPerl;

my $source = <<'SOURCE';
package Foo;

use Moose;

has foobar => ( isa => 'Str', is => 'rw' );

sub bar {
    my $self = shift;
    $self->
}

1;
SOURCE


my $ip = Devel::IntelliPerl->new(source => $source, line_number => 9, column => 12);
ok(grep { $_ eq 'bar' } $ip->methods);
