  package HO::class;
# ******************
  our $VERSION='0.073';
# ********************
; use strict; use warnings

; require HO::accessor
; require Carp

; sub import
    { my ($package,@args)=@_
    ; my $makeconstr = 1
    ; # uncoverable branch false
      # uncoverable condition right
      # uncoverable condition false
      my $class = $HO::accessor::class ||
          CORE::caller    # uncoverable statement
    ; my @acc         # all internal accessors
    ; my @methods     # method changeable on a per object base
    ; my @lvalue      # lvalue accessor
    ; my @r_          # common accessors
    ; my $makeinit    # key for init method or subref used as init
    ; my @alias

    ; while(@args)
        { my $action = lc(shift @args)
        ; my ($name,$type,$code)
        ;({ '_method' => sub
            { ($name,$code) = splice(@args,0,2)
            ; push @acc, "__$name",sub { $code } if defined $code
            ; push @acc, "_$name",'$'
            ; push @methods, $name, $code
            }
          , '_index' => sub
            { ($name,$type) = splice(@args,0,2)
            ; push @acc, $name, $type
            }
          , '_lvalue' => sub
            { ($name,$type) = splice(@args,0,2)
            ; push @acc, "_$name", $type
            ; push @lvalue, $name
            }
          , '_rw' => sub
            { ($name,$type) = splice(@args,0,2)
            ; push @acc, "_$name", $type
            ; if(defined($args[0]) && lc($args[0]) eq 'abstract')
                { shift @args
                }
              else
                { $type = _type_of($type) if ref($type) eq 'CODE'
                ; push @r_, $name => sub
                    { my $idx = HO::accessor::_value_of($class,"_$name")
                    ; return HO::accessor::rw($name,$idx,$type,$class)
                    }
                }
            }
          , '_ro' => sub
            { ($name,$type) = splice(@args,0,2)
            ; push @acc, "_$name", $type
            # abstract is similar to _index, but there is TIMTOWTDI
            ; if(defined($args[0]) && lc($args[0]) eq 'abstract')
                { shift @args
                }
              else
                { $type = _type_of($type) if ref($type) eq 'CODE'
                ; push @r_, $name => sub
                    { my $idx = HO::accessor::_value_of($class,"_$name")
                    ; return HO::accessor::ro($name,$idx,$type,$class)
                    }
                }
            }
          , 'init' => sub
              { $makeinit = shift @args
              }
          # no actions => options
          # all are untested until now
          , 'noconstructor' => sub
            { $makeconstr = 0
            }
          , 'alias' => sub
            { push @alias, splice(@args,0,2)
            }
          }->{$action}||sub { die "Unknown action '$action' for $package."
                            })->()
    }
    ; { local $HO::accessor::class = $class
      ; import HO::accessor:: (\@acc,$makeinit,$makeconstr)
      }

    ; { no strict 'refs'
      ; while(@methods)
          { my ($name,$code) = splice(@methods,0,2)
          ; my $idx = HO::accessor::_value_of($class,"_$name")
          ; my $cdx = HO::accessor::_value_of($class,"__$name")
          ; *{join('::',$class,$name)} = HO::accessor::method($idx,$cdx)
          }

      ; while(@lvalue)
          { my $name = shift(@lvalue)
          ; my $idx = HO::accessor::_value_of($class,"_$name")
          ; *{join('::',$class,$name)} = sub : lvalue
               { shift()->[$idx]
               }
          }
      ; while(my ($name,$subref) = splice(@r_,0,2))
          { *{join('::',$class,$name)} = $subref->()
          }
      ; while(my ($new,$subname) = splice(@alias,0,2))
          { my $idx = HO::accessor::_value_of($class,"_$subname")
          ; *{join('::',$class,$new)} = \&{join('::',$class,$subname)}
          ; *{join('::',$class,"_$new")} = \&{join('::',$class,"_$subname")}
          }
      }
    }

; sub _type_of ($)
  { my $coderef = shift
  ; my $val = $coderef->()
  ; return ref($val) eq 'HASH' ? '%' :
           ref($val) eq 'ARRAY' ? '@' : '$'
  }

; 1

__END__

=head1 NAME

HO::class - class builder for hierarchical objects

=head1 SYNOPSIS

   package Foo::Bar;

   use subs 'init';
   use HO::class
      _lvalue => hey => '@',
      _method => huh => sub { print 'go' },
      _rw     => bla => '%',
      _ro     => foo => '$',
      alias   => foobar => 'foo';

    sub init {
       my ($self,@args) = @_;
       ...
       return $self;
    }

=head1 DESCRIPTION

This is a simple class builder for array based objects. Normally it does
its job during compile time. A constructor new is build. The generated
new will initialize each member with an appropriate default value.

The method C<init> is reserved for setting up objects during construction.
This method gets the fresh build object, and the arguments given calling C<new>.
A little questionable optimization is that the call to C<init> is not build
into the constructor when no such method exists or the option C<init> is not
part of C<HO::class-\>import> call.

For that reason the pragma C<subs> is often used, before C<HO::class>.

Five different keys could be used, to define different accessors.

=over 4

=item C<_rw>

The generated accessor can read and write the data.

=item C<_ro>

The accessor is for read access only.

=item C<_lvalue>

=item C<_method>

=item C<_index>

=back

The second field is name of the part from class
which will be created. Third field is used for datatype or
code references.

=head2 Simple Accessors

For this the keys _ro and _rw exists. How the accessor is
defined depends on the third argument. The datatypes are
defined in L<HO::accessor> class in the global C<%type> hash.

=over 4

=item @ - data behind the accessor is array reference

=item % - a hash reference

=item $ - means a scalar and defaults to undef

=back

=head2 Building a class at runtime

It is possible to build class at runtime. The easiest way to do this,
is calling C<HO::class-\>import>. At runtime the caller is commonly
not the wanted class name. For that reason the global variable
C<$HO::accessor::class> is used.

   {
      local $HO::accessor::class = 'My::Class';
      HO::class->import(_ro => acc => '$', init => 'hash');
   }
   my $obj = My::Class->new(acc => 'data');

=head2 Methods Changeable For A Object

You can change methods for an object if you overwrite the method
using the index.

   package H::first;
   use HO::class _method => hw => sub { 'Hallo Welt!' };

   my $o2 = H::first->new;
   is($o2->hw,'Hallo Welt!'); # ok

   $o2->[$o2->_hw] = sub { 'Hello world!' }
   is($o2->hw,'Hello world!'); # ok

How you can see, it is quite easy to do this in perl. Here during
class construction you have to provide the default method, which
is used when the object does not has an own method.

The method name can be appended with an additional parameter C<static>
separated by a colon. This means that the default method is stored
in an additional slot in the object. So it is changeable on per class
base. This is not the default, because the extra space required.

   use HO::XML
       _method => namespace:static => sub { undef }

Currently the word behind the colon could be free choosen. Only the
existence of a colon in the name is checked.

=head2 Motivation

Development started because there was no class builder for array based
objects with all the features I needed.

=head1 ACKNOWLEDGEMENT

=over 4

=item my employer in Leipzig

=item translate.google.com

=back

=head1 AUTHOR

Sebastian Knapp, E<lt>news@young-workers.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2017 by Sebastian Knapp

You may distribute this code under the same terms as Perl itself.


