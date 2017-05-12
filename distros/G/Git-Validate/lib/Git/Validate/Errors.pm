package Git::Validate::Errors;
$Git::Validate::Errors::VERSION = '0.001001';
use Moo;
use overload
   q("") => '_stringify',
   'bool' => '_boolify',
;

has errors => (
   is => 'ro',
   required => 1,
   isa => sub {
      die 'errors must be an arrayref'
         unless ref $_[0] && ref $_[0] eq 'ARRAY'
   },
);

sub _stringify {
   return "" . $_[0]->errors->[0] if @{$_[0]->errors} == 1;

   join "\n", map " * $_", @{$_[0]->errors}
}

sub _boolify { scalar @{$_[0]->errors} }

1;
