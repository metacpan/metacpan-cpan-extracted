  package HO::mixin;
# ******************
  our $VERSION = '0.01';
# **********************
; use strict; use warnings

; use Carp ()
; use Package::Subroutine ()
; use Data::Dumper

; our $class

; sub import
    { my ($self, $mixin, @args) = @_
    ; my $class = $HO::mixin::class || CORE::caller
    ; unless (defined $mixin)
        { Carp::croak("Which class do you want to mix into ${self}?")
        }
    ; eval "require $mixin"

    ; $HO::accessor::classes{$class} = [] unless
        defined $HO::accessor::classes{$class}
    ; my $mix = $HO::accessor::classes{$mixin}
    ; push @{$HO::accessor::classes{$class}}, @$mix
    ; my @methods = Package::Subroutine->findsubs( $mixin )
    ; Package::Subroutine->export_to($class)->($mixin,@methods)
    }

; 1

