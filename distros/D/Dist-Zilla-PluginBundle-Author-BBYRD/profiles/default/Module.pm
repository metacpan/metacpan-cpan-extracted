package {{$name}};

# AUTHORITY
# VERSION
# ABSTRACT: ---insert abstract here---

#############################################################################
# Modules

use sanity;
use Moo;
use Types::Tiny qw();

### INSERT MODULES HERE ###

use namespace::clean;
no warnings 'uninitialized';

#############################################################################
# Attributes

### INSERT ATTRS HERE ###

#############################################################################
# Pre/post-BUILD

around BUILDARGS => sub {
   my ($orig, $self) = (shift, shift);
   my $hash = shift;
   $hash = { $hash, @_ } unless ref $hash;

   ### INSERT CODE HERE ###

   $orig->($self, $hash);
};

#############################################################################
# Methods

### INSERT CODE HERE ###

42;

__END__

=begin wikidoc

= SYNOPSIS

   # code

= DESCRIPTION

### Ruler ########################################################################################################################12345

Insert description here...

= CAVEATS

### Ruler ########################################################################################################################12345

Bad stuff...

= SEE ALSO

### Ruler ########################################################################################################################12345

Other modules...

= ACKNOWLEDGEMENTS

### Ruler ########################################################################################################################12345

Thanks and stuff...

=end wikidoc
