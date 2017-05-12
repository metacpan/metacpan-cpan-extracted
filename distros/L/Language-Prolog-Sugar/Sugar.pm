package Language::Prolog::Sugar;

our $VERSION = '0.06';

use strict;
use warnings;

use Carp qw(carp croak);
use Language::Prolog::Types ':ctors';


sub export {
    my ($sub, $pkg, $name)=@_;
    no strict 'refs';
    *{$pkg.'::'.$name}=$sub;
}

sub import {
    my $class=shift;
    my $to=caller
	or die "unable to infer importer package";
    while(@_) {
	my $key=shift;
	if ($key eq 'vars' or $key eq 'variables') {
	    my $vars=shift;
	    if (ref $vars eq 'ARRAY') {
		foreach (@{$vars}) {
		    my $var=prolog_var($_);
		    export sub () { $var }, $to, $_;
		}
	    }
	    elsif (ref $vars eq 'HASH') {
		foreach my $name (keys %{$vars}) {
		    my $var=prolog_var($name);
		    export sub () { $var }, $to, $name;
		}
	    }
	    else {
		croak "invalid argument '$vars' for $key option";
	    }
	}
	elsif ($key eq 'functors') {
	    my $functors=shift;
	    if (ref $functors eq 'ARRAY') {
		foreach (@{$functors}) {
		    my $functor=$_;
		    export sub {
			prolog_functor($functor, @_);
		    }, $to, $functor;
		}
	    }
	    elsif (ref $functors eq 'HASH') {
		foreach my $name (keys %{$functors}) {
		    my $functor=$functors->{$name};
		    export sub {
			prolog_functor($functor, @_);
		    }, $to, $name;
		}
	    }
	    else {
		croak "invalid argument '$functors' for $key option";
	    }
	}
	elsif ($key eq 'atoms') {
	    my $atoms=shift;
	    if (ref $atoms eq 'ARRAY') {
		foreach (@{$atoms}) {
		    my $atom=$_;
		    export sub () { $atom }, $to, $atom;
		}
	    }
	    elsif (ref $atoms eq 'HASH') {
		foreach my $name (keys %{$atoms}) {
		    my $atom=$atoms->{$name};
		    export sub () { $atom }, $to, $name;
		}
	    }
	    else {
		croak "invalid argument '$atoms' for $key option";
	    }
	}
	elsif ($key eq 'chains') {
	    my $chains=shift;
	    if (ref $chains eq 'ARRAY') {
		foreach (@{$chains}) {
		    my $chain=$_;
		    export sub {
			prolog_chain($chain, @_);
		    }, $to, $chain;
		}
	    }
	    elsif (ref $chains eq 'HASH') {
		foreach my $name (keys %{$chains}) {
		    my $chain=$chains->{$name};
		    export sub {
			prolog_chain($chain, @_);
		    }, $to, $name;
		}
	    }
	    else {
		croak "invalid argument '$chains' for $key option";
	    }
	}
        elsif ($key eq 'auto_functor') {
            carp "Language::Prolog::Sugar auto_functor has been obsoleted";
            export \&_auto_functor, $to, 'AUTOLOAD';
        }
        elsif ($key eq 'auto_term') {
            export \&_auto_term, $to, 'AUTOLOAD';
        }
	else {
	    croak "Unknow option '$key'";
	}
    }
}

our $AUTOLOAD;
sub _auto_functor {
    my ($pkg, $name) = $AUTOLOAD =~ /(?:(.*)::)?(.*)/;
    $pkg = 'main' unless length $pkg;
    $name =~ /^[A-Z]/
        and croak "invalid functor name '$name': starts with uppercase";

    export sub { prolog_functor($name, @_) }, $pkg, $name;

    no strict 'refs';
    goto &$AUTOLOAD
}

sub _auto_term {
    my ($pkg, $name) = $AUTOLOAD =~ /(?:(.*)::)?(.*)/;
    $pkg = 'main' unless length $pkg;
    if ($name =~ /^[A-Z]/) {
        my $var = prolog_var $name;
        my $sub = sub () { $var };
        export $sub, $pkg, $name;
    }
    else {
        export sub { prolog_functor($name, @_) }, $pkg, $name;
    }

    no strict 'refs';
    goto &$AUTOLOAD
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Language::Prolog::Sugar - Syntactic sugar for Prolog term constructors

=head1 SYNOPSIS

  use Language::Prolog::Sugar vars => [qw(X Y Z)];

  use Language::Prolog::Sugar functors =>{ equal => '=',
                                           minus => '-' };

  use Language::Prolog::Sugar functors =>[qw(is)];

  use Language::Prolog::Sugar atoms =>[qw(foo bar)];

  use Language::Prolog::Sugar atoms =>{ cut => '!' };

  use Language::Prolog::Sugar chains =>{ andn => ',',
                                         orn => ';' };


  $term=andn( equal(X, foo),
              orn( equal(Y, [4, bar]),
		   equal(Y, foo)),
	      cut,
	      is(Z, minus(34, Y)));

=head1 ABSTRACT

This module allows you to easily define constructor subs for Prolog
terms.

=head1 DESCRIPTION

Language::Prolog::Sugar is able to export to the calling package a set
of subrutines to create Prolog terms as defined in the
L<Language::Prolog::Types> module.

Perl programs using these constructors have the same look as real
Prolog programs.

Unfortunately Prolog operators syntax could not be simulated in any
way I know (well, something could be done using overloading, but just
something).

=head2 EXPORT

Whatever you wants!

Language::Prolog::Sugar can create constructors for four Prolog types:
atoms, functors, vars and chains.

The syntax to use it is as follows:

  use Language::Prolog::Sugar $type1s=>{ $name1 => $prolog_name1,
                                         $name2 => $prolog_name2,
                                        ... },
                              ...

or

  use Language::Prolog::Sugar $type2s=>[qw($name1 $name2 ...)],
                              ...

C<$type1s>, C<$type2s>, ... are C<atoms>, C<functors>, C<vars> or
C<chains>.

C<$name1>, C<$name2>, ... are the names of the subrutines exported to
the caller package.

C<$prolog_name>, C<$prolog_name2>, ... are the names that the
constructors use when making the Prolog terms.

i.e:

  use Language::Prolog::Sugar atoms=>{ cut => '!' }

exports a subrutine C<cut> that when called returns a Prolog atom C<!>.

  use Language::Prolog::Sugar functor=>{ equal => '=' }

exports a subrutine C<equal> that when called returns a Prolog functor
C<=>.

  equal(3,4)

returns

  '='(3,4)

It should be noted that functor arity is inferred from the number of
arguments:

  equal(3, 4, 5, 6, 7)

returns

  '='(3, 4, 5, 6, 7)

I call 'chain' the structure formed tipically by ','/2 or ';'/2
operators in Prolog programs. i.e., Prolog program

  p, o, r, s.

is actually

  ','(p, ','(o, ','(r, s))).


using chains allows for a more easily composition of those structures:

  use Language::Prolog::Sugar chains => { andn => ',' },
                              atoms => [qw(p o r s)];

and

  andn(p, o, r, s)

generates the Prolog structure for the example program above.


Also, the tag C<auto_term> can be used to install and AUTOLOAD sub on
the caller module that would make a functor, term or variable for
every undefined subroutine. For instance:

  use Language::Prolog::Sugar 'auto_term';
  swi_call(use_module(library(pce)));
  swi_call(foo(hello, Hello))

The old C<auto_functor> tag has been obsoleted.

=head1 SEE ALSO

L<Language::Prolog::Types>, L<Language::Prolog::Types::Factory>


=head1 COPYRIGHT AND LICENSE

Copyright 2002-2006 by Salvador FandiE<ntilde>o (sfandino@yahoo.com).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
