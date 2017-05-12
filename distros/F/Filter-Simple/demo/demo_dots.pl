use DotsForArrows;

package MyClass;

sub new { bless [$_[1], 1..10], $_[0] }
sub next { my ($self) = @_; return "next is: " . shift(@$self) . "\n" }

package main;

my ($str1, $str2) = ("a", "z");
my $obj = MyClass.new($str1 . $str2);

print $obj.next() for 1..10;

print $obj.[0] . "\n";

my $next = 'next';
print $obj.$next;

#etc.


