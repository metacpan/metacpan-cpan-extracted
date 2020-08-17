use strict;
use warnings;
package Lox::True;
use overload
  '""' => sub { 'true' },
  '!'  => sub { $Lox::False::False },
  'bool' => sub { 1 },
  fallback => 0;

our $True = bless {}, 'Lox::True';

package Lox::False;
use overload
  '""' => sub { 'false' },
  '!'  => sub { $Lox::True::True },
  'bool' => sub { undef },
  fallback => 0;

our $False = bless {}, 'Lox::False';

package Lox::Bool;
use Exporter 'import';
our $True = $Lox::True::True;
our $False = $Lox::False::False;
our @EXPORT = qw($True $False);
our $VERSION = 0.02;

1;
