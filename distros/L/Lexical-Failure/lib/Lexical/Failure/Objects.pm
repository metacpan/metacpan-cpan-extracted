package Lexical::Failure::Objects;

use 5.014;
use warnings;
use Hash::Util::FieldHash 'fieldhash';

our $VERSION = '0.000001';

# Be invisible to Carp...
our @CARP_NOT = __PACKAGE__;

# Attribute storage...
fieldhash my %msg_for;
fieldhash my %context_for;
fieldhash my %checked_for;

# Constructor...
sub new { 
    my ($class, %option) = @_;
    my $newobj = bless do{ \my $impl }, $class;

    $msg_for{$newobj}     = $option{msg};
    $context_for{$newobj} = $option{context};

    return $newobj;
}

# Utilities for error generation...
sub _croak {
    require Carp;
    Carp::croak(@_);
}

sub _cant_use {
    my ($obj, $as) = @_;
    $as //= q{};

    my (undef, $file, $line, $subname) = @{$context_for{$obj}};
    $checked_for{$obj} = 1;
    _croak("$msg_for{$obj} at $file line $line\nAttempt to use failure returned by $subname" . $as);
}

# How failure objects behave...
use overload (
    # Fail when used as a boolean...
    bool     => sub { my ($self) = @_;  $checked_for{$self} = 1; return;   },
    q[!]     => sub { my ($self) = @_;  $checked_for{$self} = 1; return 1; },

    # Croak when used any other way...
    q[neg]   => sub { my ($self) = @_;  _cant_use($self, " as negative value");       },
    q[~]     => sub { my ($self) = @_;  _cant_use($self, " in bitwise complement");   },
    q[""]    => sub { my ($self) = @_;  _cant_use($self, " as string");               },
    q[0+]    => sub { my ($self) = @_;  _cant_use($self, " as number");               },
    q[qr]    => sub { my ($self) = @_;  _cant_use($self, " as regex");                },
    q[++]    => sub { my ($self) = @_;  _cant_use($self, " in increment");            },
    q[--]    => sub { my ($self) = @_;  _cant_use($self, " in decrement");            },
    q[atan2] => sub { my ($self) = @_;  _cant_use($self, " as argument to atan2");    },
    q[cos]   => sub { my ($self) = @_;  _cant_use($self, " as argument to cos");      },
    q[sin]   => sub { my ($self) = @_;  _cant_use($self, " as argument to sin");      },
    q[exp]   => sub { my ($self) = @_;  _cant_use($self, " as argument to exp");      },
    q[abs]   => sub { my ($self) = @_;  _cant_use($self, " as argument to abs");      },
    q[log]   => sub { my ($self) = @_;  _cant_use($self, " as argument to log");      },
    q[sqrt]  => sub { my ($self) = @_;  _cant_use($self, " as argument to sqrt");     },
    q[int]   => sub { my ($self) = @_;  _cant_use($self, " as argument to int");      },
    q[+]     => sub { my ($self) = @_;  _cant_use($self, " in addition");             },
    q[-]     => sub { my ($self) = @_;  _cant_use($self, " in subtraction");          },
    q[*]     => sub { my ($self) = @_;  _cant_use($self, " in multiplication");       },
    q[/]     => sub { my ($self) = @_;  _cant_use($self, " in division");             },
    q[%]     => sub { my ($self) = @_;  _cant_use($self, " in modulo");               },
    q[**]    => sub { my ($self) = @_;  _cant_use($self, " in exponentiation");       },
    q[<<]    => sub { my ($self) = @_;  _cant_use($self, " in left shift");           },
    q[>>]    => sub { my ($self) = @_;  _cant_use($self, " in right shift");          },
    q[x]     => sub { my ($self) = @_;  _cant_use($self, " in repetition");           },
    q[.]     => sub { my ($self) = @_;  _cant_use($self, " in string concatenation"); },
    q[<>]    => sub { my ($self) = @_;  _cant_use($self, " in <> iterator");          },
    q[-X]    => sub { my ($self) = @_;  _cant_use($self, " in filetest");             },
    q[${}]   => sub { my ($self) = @_;  _cant_use($self, " as scalar reference");     },
    q[@{}]   => sub { my ($self) = @_;  _cant_use($self, " as array reference");      },
    q[%{}]   => sub { my ($self) = @_;  _cant_use($self, " as hash reference");       },
    q[&{}]   => sub { my ($self) = @_;  _cant_use($self, " as subroutine reference"); },
    q[*{}]   => sub { my ($self) = @_;  _cant_use($self, " as typeglob reference");   },
    q[+=]    => sub { my ($self) = @_;  _cant_use($self, " in assignment");           },
    q[-=]    => sub { my ($self) = @_;  _cant_use($self, " in assignment");           },
    q[*=]    => sub { my ($self) = @_;  _cant_use($self, " in assignment");           },
    q[/=]    => sub { my ($self) = @_;  _cant_use($self, " in assignment");           },
    q[%=]    => sub { my ($self) = @_;  _cant_use($self, " in assignment");           },
    q[**=]   => sub { my ($self) = @_;  _cant_use($self, " in assignment");           },
    q[<<=]   => sub { my ($self) = @_;  _cant_use($self, " in assignment");           },
    q[>>=]   => sub { my ($self) = @_;  _cant_use($self, " in assignment");           },
    q[x=]    => sub { my ($self) = @_;  _cant_use($self, " in assignment");           },
    q[.=]    => sub { my ($self) = @_;  _cant_use($self, " in assignment");           },
    q[&=]    => sub { my ($self) = @_;  _cant_use($self, " in assignment");           },
    q[|=]    => sub { my ($self) = @_;  _cant_use($self, " in assignment");           },
    q[^=]    => sub { my ($self) = @_;  _cant_use($self, " in assignment");           }, 
    q[<]     => sub { my ($self) = @_;  _cant_use($self, " in numeric comparison");   },
    q[<=]    => sub { my ($self) = @_;  _cant_use($self, " in numeric comparison");   },
    q[>]     => sub { my ($self) = @_;  _cant_use($self, " in numeric comparison");   },
    q[>=]    => sub { my ($self) = @_;  _cant_use($self, " in numeric comparison");   },
    q[==]    => sub { my ($self) = @_;  _cant_use($self, " in numeric comparison");   },
    q[!=]    => sub { my ($self) = @_;  _cant_use($self, " in numeric comparison");   },
    q[<=>]   => sub { my ($self) = @_;  _cant_use($self, " in numeric comparison");   },
    q[cmp]   => sub { my ($self) = @_;  _cant_use($self, " in string comparison");    },
    q[lt]    => sub { my ($self) = @_;  _cant_use($self, " in string comparison");    },
    q[le]    => sub { my ($self) = @_;  _cant_use($self, " in string comparison");    },
    q[gt]    => sub { my ($self) = @_;  _cant_use($self, " in string comparison");    },
    q[ge]    => sub { my ($self) = @_;  _cant_use($self, " in string comparison");    },
    q[eq]    => sub { my ($self) = @_;  _cant_use($self, " in string comparison");    },
    q[ne]    => sub { my ($self) = @_;  _cant_use($self, " in string comparison");    },
    q[&]     => sub { my ($self) = @_;  _cant_use($self, " in bitwise and");          },
    q[|]     => sub { my ($self) = @_;  _cant_use($self, " in bitwise or");           },
    q[^]     => sub { my ($self) = @_;  _cant_use($self, " in bitwise xor");          },
    q[~~]    => sub { my ($self) = @_;  _cant_use($self, " in smartmatch");           },
);

# Throw an exception if still unchecked upon destruction...
sub DESTROY {
    my ($self) = @_;

    if (!$checked_for{$self}) {
        $checked_for{$self} = 1;
        say {*STDERR} "$msg_for{$self} at $context_for{$self}[1] line $context_for{$self}[2]\n";
        exit();
    }
}

# Context-enquiry interface...
sub subname { my ($self) = @_; return $context_for{$self}[3]; }
sub line    { my ($self) = @_; return $context_for{$self}[2]; }
sub file    { my ($self) = @_; return $context_for{$self}[1]; }

sub context {
    my ($self) = @_;
    my ($subname, $file, $line) = @{$context_for{$self}}[3,1,2];
    return "call to $subname at $file line $line";
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Lexical::Failure::Objects - Special failure objects for Lexical::Failure


=head1 VERSION

This document describes Lexical::Failure::Objects version 0.000001


=head1 DESCRIPTION

This module implements the "failure objects" returned by the optional
C<'failobj'> mechanism of the C<Lexical::Failure> module.

When C<ON_FAILURE 'failobj'> is in effect, any call to C<fail> will
return one of these objects, which simulates a special out-of-band value
that you can either explicitly test for failure or else simply ignore
and automatically get an exception.

For example, given the subroutine:

    package Math;
    use Lexical::Failure;

    sub inverse_square {
        my ($n) = @_;

        if ($n == 0) {
            fail "Can't invert zero";
        }

        return 1/$n**2;
    }

when C<'failobj'> is the selected failure signalling strategy:

    use Math (fail => 'failobj')

then failure can either be tested for explicitly:

    # This block skipped if $n == 0...
    if (my $inv_sq = Math::inverse_square($n) {
        print $inv_sq;
    }

or else simply ignored, in which case an exception will automatically
be thrown:

    print inverse_square($n);    # ...throw exception if $n == 0


=head1 INTERFACE

If it is used as a boolean, a failure object evaluates false
(i.e. it acts as if C<ON_FAILURE 'undef'> had been in effect).

If it is used as a value in I<any> other way (as a string, as a
reference, as a regex, as a filehandle, etc., etc.), or if it's ignored
and allowed to go out of scope without being evaluated at all, then a
failure object throws an exception (i.e. it acts as if C<ON_FAILURE
'croak'> had been in effect).

=head2 Constructor (C<new()>)

The class's constructor expects two named arguments:

    $failure_obj = Lexical::Failure::Objects->new(
                       msg     => $MESSAGE_STR_OR_OBJ,
                       context => [$PACKAGE, $FILE, $LINE, $SUBNAME],
                   );

You should never normally need to construct failure objects directly;
it's better to let C<Lexical::Failure> craete them automatically
via its C<'failobj'> mechanism.


=head2 Methods

C<Lexical::Failure::Objects> also provides four methods with which you
can query the location of the failure that they represent. None of these
methods takes any arguments.

=over

=item C<< $failobj->subname() >>

Returns the name of the subroutine in which the failure was
signaled.
That is, the equivalent of S<C<(caller 0)[3]>>.

=item C<< $failobj->file() >>

Returns the name of the file containing the subroutine call from which
failure was signaled.
That is, the equivalent of S<C<(caller 0)[1]>>.

=item C<< $failobj->line() >>

Returns the line number of the subroutine call from which failure was
signaled.
That is, the equivalent of S<C<(caller 0)[2]>>.

=item C<< $failobj->context() >>

Returns a string summarizing the information provided by the
previous three methods, in the form: 

    "call to <subname> at <file> line <line>"

=back


=head1 DIAGNOSTICS

None of their own.

If they throw an exception (when misused or ignored), it will be the
exception that C<fail> would otherwise have thrown.


=head1 CONFIGURATION AND ENVIRONMENT

Lexical::Failure::Objects requires no configuration files or environment variables.


=head1 DEPENDENCIES

Requires the Hash::Util::FieldHash module.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-lexical-failure@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
