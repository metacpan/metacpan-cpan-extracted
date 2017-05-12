#!/local/new_freeware/perl5.004/perl -w
#!/local/disk3/local/bin/perl -w
#!/usr/local/bin/perl -w

use Hook::PrePostCall;
use strict;

sub try {
  print "in try: @_\n";
  @_;
}

print "= No added routines\n";
my $test1 = Hook::PrePostCall->new('try');
print try(10), "\n";

print "= add a pre routine\n";
$test1->pre(sub { print "a 'pre' routine @_\n"; @_;});
print try(10), "\n";

print "= add a post routine\n";
$test1->post(sub { print "a 'post' routine @_\n"; @_;});
print try(10), "\n";

print "= restore initial definition\n";
$test1->restore();
print try(10), "\n";
print "\n";

print "= Change the post routine\n";
my $test2 = Hook::PrePostCall->new(
			       'try',
			       undef,
			       sub {
				 print STDERR "A new post: @_\n";
				 @_;
			       }
			      );
print try(10), "\n";


print "= add another level\n";
my $test3 = Hook::PrePostCall->new(
				   'try',
				   sub {
				     print STDERR "in pre: @_\n";
				     @_;
				   },
				   sub {
				     print STDERR "Another post: @_\n";
				     @_;
				   }
				  );


print try(10), "\n";

