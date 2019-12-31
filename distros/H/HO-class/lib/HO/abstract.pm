package HO::abstract;
# *******************
use strict; use warnings;
our $VERSION='0.02';
# ******************

; use Package::Subroutine ()
; use Carp ()

; our $METHOD_DIE = sub
    { my ($method) = @_
    ; return sub
        { my $pkg = $_[0];
        ; if(ref($_[0]))
            { $pkg = ref($_[0])
            }
        ; Carp::croak("Class '$pkg' does not override ${method}()")
        }
    }

; our $CLASS_DIE = sub
    { my ($class) = @_
    ; return sub
        { my $instanceof = ref($_[0])
        ; if($instanceof eq $class)
            { Carp::croak("Abstract class '$class' should not be instantiated.")
            }
          else
            { Carp::croak("Class '$instanceof' should overwrite method init from abstract class '$class'.")
            }
        }
    }

; { our $target

  ; sub abstract_method
      { my @methods = @_
      ; unless(defined($target))
      { Carp::croak("No target class defined!")
      }
      ; foreach my $method (@methods)
          { install Package::Subroutine::
              $target => $method => $METHOD_DIE->($method)
          }
      }

  ; sub abstract_class
      { my (@classes) = @_ ? @_ : ($target)
      ; foreach my $class (@classes)
          { install Package::Subroutine::
                     $class => 'init' => $CLASS_DIE->($class)
          }
      }

  ; sub import
      { my ($self,$action,@params) = @_
      ; return unless defined $action
      ; local $target = caller

      ; my $perform =
              { 'method' => \&abstract_method
              , 'class' => \&abstract_class
              }->{$action}
      ; die "Unknown action '$action' in use of HO::abstract." unless $perform

      ; $perform->(@params)
      }
  }

; 1

__END__

=head1 NAME

HO::abstract - helper for abstract classes and methods

=head1 SYNOPSIS

   package Class::Is::Abstract;

   use HO::abstract 'class';

=head1 DESCRIPTION

=over 4

=item abstract_class

=item abstract_method

=back

Note the abstract class places an C<init> method not a C<new> method
in the package namespace. Thatswhy the order of use statements is important.

   package Wrong;
   use HO::class;
   use HO::abstract;

Here no init method is known when HO::class is called. Importing one from
HO::abstract does not matter.

   use Right;
   use HO::abstract;
   use HO::class;

Now C<Right-\>new> will die correctly.

=head1 AUTHOR

Sebastian Knapp, E<lt>rock@ccls-online.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2011 by Sebastian Knapp

You may distribute this code under the same terms as Perl itself.

=cut

