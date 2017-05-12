package Dunce::time;

use strict;
use vars qw($VERSION);
$VERSION = '0.02';

use overload    '""'    =>  \&timize,
                '0+'    =>  \&timize,
                'fallback'  =>  'TRUE',
                'cmp'   =>  \&str_compare,
                '<=>'	=>  \&num_compare,
    ;

sub import {
    my($class, $reaction) = @_;
    my $caller = caller;
    {
	no strict 'refs';
	*{$caller.'::time'} = sub {
	    return Dunce::time->new($reaction);
	};
    }
}

sub new {
    my($proto, $reaction) = @_;
    $reaction ||= ':DIE';
    my $class = ref $proto || $proto;
    bless {
	_time => time,
	_callback => $class->_get_callback($reaction),
    }, $class;
}

sub _get_callback {
    my($class, $reaction) = @_;
    my $dying_msg = "Possible misuse of time().";
    for ($reaction) {
	/^:WARN/i && return sub {
	    require Carp;
	    Carp::carp $dying_msg;
	};
	/^:FIX/i && return sub {
	    my($this, $that) = @_;
	    require Carp;
	    Carp::carp $dying_msg, " I'll fix it.";
	    return $this <=> $that; # goes to num_compare()
	};
	/^:DIE/i && return sub {
	    require Carp;
	    Carp::croak $dying_msg;
	};
    }
}
	
sub timize {
    shift->{_time};
}
    
sub str_compare {
    my($this, $that) = @_;
    my $mine = (grep { ref($this) } ($this, $that))[0];
    $mine->{_callback}->($this, $that);
}

sub num_compare {
    my($this, $that) = map { $_ + 0 } @_; # numize
    return $this <=> $that;
}


1;
    
__END__


=head1 NAME

Dunce::time - Protects against sloppy use of time.

=head1 SYNOPSIS

  use Dunce::time;

  my $this = time;
  my $that = time;

  my @sorted = sort $this, $that; # die with an error
  my @numerically_sorted = sort { $a <=> $b } $this, $that; # OK

=head1 DESCRIPTION

On Sun Sep 9 01:46:40 2001 GMT, time_t (UNIX epoch) reaches 10 digits. 
Sorting time()'s as strings will cause unexpected result after
that.

When Dunce::time is used, it provides special version of time() which
will die with a message when compared as strings.

=head1 USAGE

Just use the module. If it detects a problem, it will cause your
program to abort with an error. If you don't like this behaviour, you
can use the module with tags like ":WARN" or ":FIX".

  use Dunce::time qw(:WARN);

With ":WARN" tag, it will just warn instead of dying.

  use Dunce::time qw(:FIX);
  @sorted = sort @time; # acts like sort { $a <=> $b } @time;

With ":FIX" tag, it will warn and change the comparison behaviour so
that it acts like compared numerically.

=head1 CAVEATS

You store the variables into storage (like DBMs, databases), retrieve
them from storage, and compare them as strings ... this can't detect
in such a case.

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Dunce::time::Zerofill>, L<D::oh::Year>, L<overload>, L<perl>

=cut
