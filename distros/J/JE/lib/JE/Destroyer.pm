package JE::Destroyer;

our $VERSION = '0.066';

use strict;
use warnings;

# We cannot use JE::_FieldHash, because we end up triggering bugs in weak
# references in 5.8.  (JE::_FieldHash uses Tie::RefHash::Weak in 5.8.)
# (Those bugs were fixed between 5.10.1 and 5.12.4, but by which commit
# I wot not.)
#use JE::_FieldHash;
BEGIN {
    require constant;
    # unsafe_helem means that $h{$foo} will stringify $foo.
    # Hash::Util::FieldHash doesn’t stringify a ref key.
    import constant unsafe_helem =>
        not my $hufh = eval { require Hash::Util::FieldHash };
    if ($hufh) {
      import Hash::Util::FieldHash 'fieldhash';
    }
    else { *fieldhash = sub {$_[0]} }
}

use Scalar'Util qw 'refaddr weaken';

fieldhash my %js_envs;

$JE::Destroyer = 1;

sub register {
    my $global = $_[0]->global;
#    if (ref ($global) eq 'JE::Scope') { use Carp; Carp::cluck; warn "-"x70, "\n" }
    my $globaddr = refaddr $global;
    if ($globaddr == refaddr $_[0]) { return }
    ($js_envs{unsafe_helem ? $globaddr : $global} ||= &fieldhash({}))
      ->{unsafe_helem ? refaddr $_[0] : $_[0]} = \(my $entry = $_[0]);
    weaken $entry;
    return # nothing;
}

sub destroy {
 exists $js_envs{$_[0]} or return;
 # We can’t just iterate over the values, because $$_->destroy might
 # actually free some of the things we are iterating over. So put them in
 # an array first.
 my @objs = values %{ $js_envs{$_[0]} };
 # And still, since the values are themselves weak references to the
 # objects, we have to check for definition.
 defined $$_ and $$_->destroy for @objs;
 delete $js_envs{$_[0]};
 $_[0]->destroy;
 return # nothing;
}

__END__

=head1 NAME

JE::Destroyer - Experimental destructor for JE

=head1 SYNOPSIS

  use JE::Destroyer; # must come first
  use JE;

  $j = new JE;

  # ... do stuff ...

  JE::Destroyer::destroy($j); # break circular refs
  undef $j;

=head1 DESCRIPTION

This is an I<experimental> module that provides a way to destroy JE objects
without leaking memory.

Details of its interface are subject to change drastically between
releases.

See the L</SYNOPSIS> above for usage.

=head1 SEE ALSO

L<JE>
