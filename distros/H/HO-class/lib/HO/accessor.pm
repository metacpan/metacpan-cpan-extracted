package HO::accessor;
# +++++++++++++++++++
use strict; use warnings;
our $VERSION='0.053';
# +++++++++++++++++++

; use Class::ISA ()
; use Package::Subroutine ()
; use Carp ()

; our %classes
; my %accessors
; my %methods

; our %type = ('@'=>sub () {[]}, '%'=>sub () {{}}, '$'=>sub () {undef})

; our %init =
    ( 'hash' => sub
        { my ($self,%args) = @_
        ; while(my ($method,$value)=each(%args))
            { my $access = "_$method"
            ; $self->[$self->$access] = $value
            }
        ; return $self
        },
      'hashref' => sub
        { my ($self,$args) = @_
        ; while(my ($method,$value)=each(%$args))
            { my $access = "_$method"
            ; $self->[$self->$access] = $value
            }
        ; return $self
        }
    )

; our %ro_accessor =
    ( '$' => sub { my ($n,$class) = @_
                 ; my $idx = HO::accessor::_value_of($class, "_$n")
                 ; return sub ()
                     { Carp::confess("Not a class method '$n'.")
                         unless ref($_[0])
                     ; $_[0]->[$idx]
                     }
                 }
    , '@' => sub { my ($n,$class) = @_
                 ; my $ai = HO::accessor::_value_of($class, "_$n")
                 ; return sub
                     { my ($obj,$idx) = @_
                     ; if(@_==1)
                        { return @{$obj->[$ai]}
                        }
                       else
                        { return $obj->[$ai]->[$idx]
                        }
                 }}
    , '%' => sub { my ($n,$class) = @_
                 ; my $idx = HO::accessor::_value_of($class, "_$n")
                 ; return sub
                     { my ($obj,$key) = @_
                     ; (@_==1) ? {%{$obj->[$idx]}}
                               : $obj->[$idx]->{$key}
                     }
                 }
    )

; our %rw_accessor =
    ( '$' => sub { my ($n,$class) = @_
                 ; my $idx = HO::accessor::_value_of($class, "_$n")
                 ; return sub
                     { my ($obj,$val) = @_
                     ; Carp::confess("Not a class method '$n'.")
                         unless ref($obj)
                     ; return $obj->[$idx] if @_==1
                     ; $obj->[$idx] = $val
                     ; return $obj
                     }
                 }
    , '@' => sub { my ($n,$class) = @_
                 ; my $ai = HO::accessor::_value_of($class, "_$n")
                 ; return sub
                     { my ($obj,$idx,$val) = @_
                     ; Carp::confess("Not a class method '$n'.")
                         unless ref $obj
                     ; if(@_==1) # get values
                         { # etwas mehr Zugriffsschutz da keine Ref
                           # einfache Anwendung in bool Kontext
                         ; return @{$obj->[$ai]}
                         }
                       elsif(@_ == 2)
                         { unless(ref $idx eq 'ARRAY')
                             {  return $obj->[$ai]->[$idx]     # get one index
                             }
                           else
                             { $obj->[$ai] = $idx                 # set complete array
                             ; return $obj
                             }
                         }
                       elsif(@_==3)
                         { if(ref($idx))
                             { if($val eq '<')
                                 { $$idx = shift @{$obj->[$ai]}
                                 }
                               elsif($val eq '>')
                                 { $$idx = pop @{$obj->[$ai]}
                                 }
                               else
                                 { if(@$val == 0)
                                     { @$idx = splice(@{$obj->[$ai]})
                                     }
                                   elsif(@$val == 1)
                                     { @$idx = splice(@{$obj->[$ai]},$val->[0]);
                                     }
                                   elsif(@$val == 2)
                                     { @$idx = splice(@{$obj->[$ai]},$val->[0],$val->[1]);
                                     }
                                 }
                             }
                            elsif($idx eq '<')
                             { push @{$obj->[$ai]}, $val
                             }
                            elsif($idx eq '>')
                             { unshift @{$obj->[$ai]}, $val
                             }
                            else
                             { $obj->[$ai]->[$idx] = $val     # set one index
                             }
                          ; return $obj
                          }
                     }
                 }
    , '%' => sub { my ($n,$class) = @_
                 ; my $idx = HO::accessor::_value_of($class, "_$n")
                 ; return sub { my ($obj,$key) = @_
                 ; if(@_==1)
                     { return $obj->[$idx] # for a hash an reference is easier to handle
                     }
                   elsif(@_==2)
                     { if(ref($key) eq 'HASH')
                         { $obj->[$idx] = $key
                         ; return $obj
                         }
                        else
                         { return $obj->[$idx]->{$key}
                         }
                     }
                   else
                     { shift(@_)
                     ; my @kv = @_
                     ; while(@kv)
                         { my ($k,$v) = splice(@kv,0,2)
                         ; $obj->[$idx]->{$k} = $v
                         }
                     ; return $obj
                     }
                 }}
    )

; our $class

; my $object_builder = sub
    { my ($obj,$constructor,$args) = @_
    ; foreach my $typedefault (@$constructor)
        { push @{$obj}, ref($typedefault) ? $typedefault->($obj,$args)
                                          : $typedefault
        }
    }

; sub import
    { my ($package,$ac,$methods,$init,$new) = @_
    ; our %classes
    ; $ac   ||= []

    ; my $caller = $HO::accessor::class || CORE::caller

    ; Carp::croak "HO::accessor::import already called for class $caller."
        if Package::Subroutine->isdefined($caller,'new') && $new

    ; $classes{$caller} = [] unless defined $classes{$caller}
    ; push @{$classes{$caller}}, @$ac

    ; my @build = reverse Class::ISA::self_and_super_path($caller)
    ; my @constructor
    ; my @class_accessors

    ; my $count=0
    ; foreach my $class (@build)
        { $classes{$class} or next
        ; my @acc=@{$classes{$class}} or next
        ; while (@acc)
            { my ($accessor,$type)=splice(@acc,0,2)
            ; my $proto = ref($type) eq 'CODE' ? $type : $type{$type}
            ; unless(ref $proto eq 'CODE')
                { Carp::carp("Unknown property type '$type', in setup for class $caller.")
                ; $proto=sub{undef}
                }
            ; my $val=$count
            ; my $acc=sub {$val}
            ; push @class_accessors, $accessor
            ; $accessors{$caller}{$accessor}=$acc
            ; $constructor[$acc->()] = $proto
            ; $count++
            }
        }
    # FIXME: Die init Methode sollte Zugriff auf $self haben können.
    ; { no strict 'refs'
      ; if($new)
          { *{"${caller}::new"}=
              ($init || $caller->can('init')) ?
                sub
                  { my ($self,@args)=@_
                  ; my $obj = bless [], ref $self || $self
                  ; $object_builder->($obj,\@constructor,\@args)
                  ; return $obj->init(@args)
                  }
              : sub
                  { my ($self,@args)=@_
                  ; my $obj = bless [], ref $self || $self
                  ; $object_builder->($obj,\@constructor,\@args)
                  ; return $obj
                  }
          }

      ; foreach my $acc (@class_accessors)
          { *{"${caller}::${acc}"} = $accessors{$caller}{$acc}
          }

      ; my %class_methods = @$methods
      ; $methods{$caller} = \%class_methods
      }

    # setup init method
    ; if($init)
        { unless(ref($init) eq 'CODE' )
            { $init = $init{$init}
            ; unless(defined $init)
                { Carp::croak("There is no init defined for init argument $init.")
                }
            }
        ; no strict 'refs'
        ; *{"${caller}::init"}= $init
        }
    }

# Package Method
; sub accessors_for_class
    { my ($self,$class)=@_
    ; return $classes{$class}
    }

# Package Function
; sub _value_of
    { my ($class,$accessorname) = @_
    ; return $accessors{$class}{$accessorname}->()
    }

; sub _methods_code
    { my ($class,$methodname) = @_
    ; return $methods{$class}{$methodname}
    }

; 1

__END__

=head1 NAME

HO::accessor

=head1 SYNOPSIS

    package HO::World::Consumer;
    use base 'HO::World::Owner';

    use HO::accessor [ industry => '@', profit => '$' ];

=head1 DESCRIPTION

=over 4

=item import

=item accessors_for_class

=item method

=item ro

=item rw

=back

=head1 SEE ALSO

L<Class::ArrayObjects> by Robin Berjon (RBERJON)

L<Class::BuildMethods> by Ovid -- add inside out data stores to a class.

=head1 AUTHOR

Sebastian Knapp, E<lt>news@young-workers.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2017 by Sebastian Knapp

You may distribute this code under the same terms as Perl itself.

=cut

