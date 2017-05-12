package Grimlock::Schema::Candy;
{
  $Grimlock::Schema::Candy::VERSION = '0.11';
}
 
use base 'DBIx::Class::Candy';
 
sub base { $_[1] || 'Grimlock::Schema::Result' }
sub perl_version { 12 }
sub autotable { 1 }
1;

