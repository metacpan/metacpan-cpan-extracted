

use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;
use Test::AbstractMethod;

package HOA::five;
use HO::abstract 'class';
use HO::class;

package HOA::four;
use subs 'init';
use HO::class;
HO::abstract->import('class',__PACKAGE__);

package main;

#############################
# Checks HO::abstract
#############################

throws_ok { HOA::five->new } 
	  qr/Abstract class 'HOA::five' should not be instantiated./;

throws_ok { HO::abstract->import('unknown') } 
	  qr/Unknown action '.*' in use of HO::abstract\./;

throws_ok { HOA::four->new } 
	  qr/Abstract class 'HOA::four' should not be instantiated./;

package HOB::six; use subs qw/init/; use HO::class;
use HO::abstract method => 'ups';

package HOB::seven; use subs qw/init/; use HO::class;
package HOB::eight; use subs qw/init/; use HO::class;

package main;

use HO::abstract class => qw/HOB::six HOB::seven HOB::eight/;

foreach my $class (qw/HOB::six HOB::seven HOB::eight/)
{
    throws_ok { $class->new } 
	  qr/Abstract class '$class' should not be instantiated./;
}

call_abstract_method_ok("HOB::six", "ups", "abstract method");
call_abstract_class_method_ok("HOB::six", "ups", "abstract class method");

#############################
# Checks HO::class
#############################

package HOB::zro;

use HO::class
  _ro => one => '$' => 'abstract',
  _rw => two => '$' => 'abstract',
  _method => three => sub { 42 };
  
package HOB::on;

BEGIN { our @ISA = 'HOB::zro'; };

use HO::class;

sub one { my ($s,$a) = @_; $s->[&_one] = $a if defined $a; return }

package main;

my $zero = HOB::zro->new;
my $one = HOB::on->new;

throws_ok { $zero->one } 
    qr/Can't locate object method "one" via package "HOB::zro" at.*/;
    
ok($zero->can('_one'),'index created');
ok($zero->_one =~ /^\d+$/, 'index is numeric');
    
throws_ok { $one->two }
    qr/Can't locate object method "two" via package "HOB::on" at.*/;

throws_ok { $one->__two }
    qr/Can't locate object method "__two" via package "HOB::on" at.*/;

is($one->three,42,'following definition');

ok($one->can('one'),'for sure');

my @methods_zro = sort( findsubs Package::Subroutine:: 'HOB::zro' );
my @expect_zro = qw(__three _one _three _two new three);
is_deeply(\@methods_zro,\@expect_zro,"expected methods");

my @methods_on = sort( findsubs Package::Subroutine:: 'HOB::on' );
my @expect_on = qw(__three _one _three _two new one);
is_deeply(\@methods_on,\@expect_on,"expected methods");

