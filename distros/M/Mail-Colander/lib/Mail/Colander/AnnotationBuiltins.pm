package Mail::Colander::AnnotationBuiltins;
use v5.24;
use utf8;
use experimental qw< signatures >;
use Net::Subnet;
{ our $VERSION = '0.004' }

sub factory ($parse_ctx, $name) {
   state $intermediate_for = {
      is_element_of  => \&set_is_element_of,
      '∈'            => \&set_is_element_of,
      contains       => \&set_contains,
      '∋'            => \&set_contains,
      subnet_matcher => \&subnet_matcher,
   };
   return $intermediate_for->{$name} // undef;
}

sub set_contains ($set, $target) {
   warn "set contains set<$set> target<$target>";
   return defined($set->($target)) if ref($set) eq 'CODE';
   for my $item ($set->@*) { return 1 if $item eq $target }
   return 0;
}

sub set_is_element_of ($elem, $set) { return set_contains($set, $elem) }

1;
