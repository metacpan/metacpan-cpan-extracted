  package HO::accessor
# ++++++++++++++++++++
; use strict; use warnings;
our $VERSION='0.04';

; use Class::ISA
; require Carp

; my %classes
; my %accessors

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
    ( '$' => sub { my ($n,$i) = @_
                 ; return sub (){ Carp::confess("Not a class method '$n'.")
                     unless ref($_[0]); shift()->[$i] }
                 }
    , '@' => sub { my ($n,$i) = @_
                 ; return sub { my ($obj,$idx) = @_
                     ; if(@_==1)
                        {return @{$obj->[$i]}}
                       else
                        {return $obj->[$i]->[$idx]}
                 }}
    , '%' => sub { my ($n,$i) = @_
                 ; return sub { my ($obj,$key) = @_
                 ; (@_==1) ? {%{$obj->[$i]}}
                           : $obj->[$i]->{$key}
                 }}
    )

; our %rw_accessor =
    ( '$' => sub { my ($n,$i) = @_
                 ; return sub { my ($obj,$val) = @_
                     ; return $obj->[$i] if @_==1
                     ; $obj->[$i] = $val
                     ; return $obj
                 }}
    , '@' => sub { my ($n,$i) = @_
                 ; return sub
                     { my ($obj,$idx,$val) = @_
                     ; Carp::confess("Not a class method '$n'.") unless ref $obj
                     ; if(@_==1) # get values
                         { # etwas mehr Zugriffsschutz da keine Ref
                           # einfache Anwendung in bool Kontext
                         ; return @{$obj->[$i]}
                         }
                       elsif(@_ == 2)
                         { unless(ref $idx eq 'ARRAY')
                             {  return $obj->[$i]->[$idx]     # get one index
                             }
                           else
                             { $obj->[$i] = $idx                 # set complete array
                             ; return $obj
                             }
                         }
                       elsif(@_==3)
                         { if(ref($idx))
                 { if($val eq '<')
                                 { $$idx = shift @{$obj->[$i]} }
                               elsif($val eq '>')
                                 { $$idx = pop @{$obj->[$i]} }
                               else
                                 { if(@$val == 0)
                        { @$idx = splice(@{$obj->[$i]}) }
                                   elsif(@$val == 1)
                                    { @$idx = splice(@{$obj->[$i]},$val->[0]); }
                                   elsif(@$val == 2)
                                    { @$idx = splice(@{$obj->[$i]},$val->[0],$val->[1]); }
                                 }
                             }
                            elsif($idx eq '<')
                             { push @{$obj->[$i]}, $val
                             }
                            elsif($idx eq '>')
                             { unshift @{$obj->[$i]}, $val
                             }
                            else
                             { $obj->[$i]->[$idx] = $val     # set one index
                             }
                          ; return $obj
                          }
                     }
                 }
    , '%' => sub { my ($n,$i) = @_
                 ; return sub { my ($obj,$key) = @_
                 ; if(@_==1)
                     { return $obj->[$i] # for a hash an reference is easier to handle
                     }
                   elsif(@_==2)
                     { if(ref($key) eq 'HASH')
                         { $obj->[$i] = $key
                         ; return $obj
                         }
                        else
                         { return $obj->[$i]->{$key}
                         }
                     }
                   else
                     { shift(@_)
                     ; my @kv = @_
                     ; while(@kv)
                         { my ($k,$v) = splice(@kv,0,2)
                         ; $obj->[$i]->{$k} = $v
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
    { my ($package,$ac,$init,$new) = @_
    ; $ac   ||= []

    ; my $caller = $HO::accessor::class || caller

    ; die "HO::accessor::import already called for class $caller."
        if $classes{$caller}

    ; $classes{$caller}=$ac

    ; my @build = reverse Class::ISA::self_and_super_path($caller)
    ; my @constructor

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
            ; if($accessors{$class}{$accessor})
                { $constructor[$accessors{$class}{$accessor}->()] = $proto
                }
              else
                { my $val=$count
                ; my $acc=sub {$val}
                ; $accessors{$class}{$accessor}=$acc
                ; $constructor[$acc->()] = $proto
                }
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

      ; my %acc=@{$classes{$caller}}
      ; foreach my $acc (keys %acc)
          { *{"${caller}::${acc}"}=$accessors{$caller}{$acc}
          }
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
    ; my @classes = Class::ISA::self_and_super_path($class)
    ; foreach my $c (@classes)
        { if(defined($accessors{$c}{$accessorname}))
            { #warn $accessorname.": ".$accessors{$c}{$accessorname}->()
            ; return $accessors{$c}{$accessorname}->()
            }
        }
    ; die "Accessor $accessorname is unknown for class $class."
    }

#########################
# this functions defines
# accessors
#########################
; sub ro
    { my ($name,$idx,$type,$class) = @_
    ; return $ro_accessor{$type}->($name,$idx,$class)
    }

; sub rw
    { my ($name,$idx,$type,$class) = @_; #warn "$name,$idx,$type,$class"
    ; return $rw_accessor{$type}->($name,$idx,$class)
    }

; sub method
    { my ($idx,$cdx) = @_
    ; if(defined $cdx)
        { return sub
            { my $self = shift
            ; return $self->[$idx] ? $self->[$idx]->($self,@_)
                                   : $self->[$cdx]->($self,@_)
            }
        }
      else
        { return sub
             { my $self = shift
             ; return $self->[$cdx]->($self,@_)
             }
        }
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

