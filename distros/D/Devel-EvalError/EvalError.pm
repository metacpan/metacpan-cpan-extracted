package Devel::EvalError;
use strict;


use vars qw( $VERSION );

BEGIN {
    $VERSION= 0.001_002;
    my $idx= 0;
    for my $name (
        '_prevReason',  # Value from $@ when c'ted, restored to $@ in d'tor
        '_reasons',     # List of possible failure reasons from $SIG{__DIE__}
        '_prevHandler', # Value of $SIG{__DIE__} before c'ted
        '_newHandler',  # Address of $SIG{__DIE__} after c'ted
        '_succeeded',   # Whether the eval() was successful
        '_knowReason',  # True if $@ survived
    ) {
        my $code= "sub $name() { $idx; }";
        eval "$code; 1"
            or  die "Couldn't compile constant ($code): $@\n";
        $idx++;
    }
}


sub _croak {    # Die but report the caller's line number
    require Carp;
    Carp::croak( @_ );
}

sub _confess {  # Die with stack trace
    require Carp;
    local $Carp::CarpLevel= $Carp::CarpLevel + 1;
    Carp::confess( @_ );
}

sub _cluck {    # Warn with stack trace
    require Carp;
    local $Carp::CarpLevel= $Carp::CarpLevel + 1;
    Carp::cluck( @_ );
}


sub new {
    my( $we )= @_;
    _croak( "Devel::EvalError: new() via an object is not allowed" )
        if  ref $we;
    my $me= bless [], $we;
    $me->_init();
    return $me;
}


sub _init {
    my( $me )= @_;
    _confess( "Devel::EvalError: Erase() required before _init()" )
        if  $me->[_reasons];
    $me->[_prevReason]=     $@;
    $me->[_reasons]=        my $reasons= [];
    $me->[_prevHandler]=    my $prevHandler= $SIG{__DIE__};
    my $newHandler= sub { _handleDie( $reasons, $prevHandler, @_ ); };
    $me->[_newHandler]=     0 + $newHandler;
    $SIG{__DIE__}= $newHandler;
    return;
}


sub _handleDie {
    my $list= shift @_;
    my $handler= shift @_;
    push @{ $list },
        ( 1 == @_ )  ?  $_[0]  :  join '', @_;
    $handler->( @_ )
        if  $handler;
    return;
}


sub Erase {
    my( $me )= @_;
    $me->_revertHandler();
    my $prevReason= $me->[_prevReason];
    $@= $prevReason
        if  $prevReason;
    return;
}


sub Reuse {
    my( $me )= @_;
    $me->Erase();
    $me->_init();
    return $me;
}


sub ExpectOne {
    my $me= shift @_;
    my $okay;
    if(  @_ <= 1  &&  ! defined $_[0]  ) {
        $okay= 0;
    } elsif(  1 == @_  &&  1 eq $_[0]  ) {
        $okay= 1;
    }
    $me->_expected( $okay, @_ );
    return $me;
}


sub ExpectNonEmpty {
    my $me= shift @_;
    my $okay=  0 == @_ ? 0 : 1;
    $me->_expected( $okay, @_ );
    return wantarray ? @_ : $_[0];
}


sub _expected {
    my $me=     shift @_;
    my $okay=   shift @_;
    my $reason= $@;   # Copy early as $@ can easily change
    my $caller= (caller 1)[3];
    $me->_revertHandler();
    _croak( 'Devel::EvalError: $caller() called on Erase()d object' )
        if  ! $me->[_reasons];
    _croak( 'Devel::EvalError: $caller() called on object more than once' )
        if  defined $me->[_succeeded];
    $me->[_succeeded]= $okay;
    if( ! defined $okay ) {
        _croak(
            "Devel::EvalError: $caller() misused, passed( ",
            join( ", ", map { defined $_ ? $_ : "(undef)" } @_ ),
            " )",
        );
    }
    if(  ! $okay  &&  $reason  ) {
        $me->[_knowReason]= 1;
        push @{ $me->[_reasons] }, $reason
            if  $reason ne $me->[_reasons][-1];
    }
}


sub _revertHandler {
    my( $me )= @_;
    return
        if  ! $me->[_reasons];
    my $handler= $me->[_prevHandler];
    if(  '0' ne $handler  ) {
        my $current= $SIG{__DIE__};
        $SIG{__DIE__}= $handler;
        if(  $current != $me->[_newHandler]  ) {
            _cluck(
                '$SIG{__DIE__} changed out from under Devel::EvalError',
            );
        }
        $me->[_prevHandler]= 0;
    }
    return;
}


sub AllReasons {
    my( $me )= @_;
    return @{ $me->[_reasons] || [] };
}


sub Reason {
    my( $me )= @_;
    my @reasons= @{ $me->[_reasons] || [] };
    return ''
        if  ! defined $me->[_succeeded] # if eval() not called (yet?)
        ||  $me->[_succeeded];          # or eval() succeeded.
    if(  ! @reasons  ) {
        # We "know" eval() failed but we never intercepted a die() message.
        # There are several possibilities (likeliest first):
        #   1)  $ee->ExpectNonEmpty( eval { getList(); } );
        #       but getList() returned an empty list.
        #   2)  $ee->ExpectOne( eval { return; } ); # or similar
        #   3)  Some unexpected way for eval() to fail without our
        #       $SIG{__DIE__} handler ever getting called.  This might be
        #       a Perl bug or something strange that XS code can do or such.
        #   4)  Somebody meddling with our object's internals.  C'est le Vie.
        #   5)  etc.
        return 'Unknown failure reason or returned empty list!';
    }
    return $reasons[-1]
        if  1 == @reasons  ||  $me->[_knowReason];
    return join "\nTHEN ", @reasons;
}


sub Succeeded {
    my( $me )= @_;
    my $okay= $me->[_succeeded];
    _croak(
        'Devel::EvalError: Expect*() not called before checking for success',
    )   if  ! defined $okay;
    return $okay;
}


sub Failed {
    my( $me )= @_;
    return  ! $me->Succeeded();
}



sub DESTROY {
    my( $me )= @_;
    $me->Erase();
}


'Devel::EvalError';
__END__

=head1 NAME

Devel::EvalError -- Reliably detect if and why eval() failed

=head1 SYNOPSIS

    use Devel::EvalError();

    my $ee = Deval::EvalError->new();
    $ee->ExpectOne(
        eval { ...; 1 }
    );
    if ( $ee->Failed() ) { # if ( ! $ee->Succeeded() )
        ... $ee->Reason() ...;
    }

=head1 DESCRIPTION

Although it is common to check C<$@> to determine if a call to C<eval>
failed, it is easy to make C<eval> fail while leaving C<$@> empty.

Using C<Devel::EvalError> encourages you to use more reliable ways to check
whether C<eval> failed while also giving you access to the failure reason(s)
even if C<$@> ended up empty.  (It also makes C<$@> ending up empty less
likely for other uses of C<eval>.)

If you have code that looks like the following:

    eval { ... };
    if ( $@ ) {
        log_failure( "...: $@" );
    }

Then you should replace it with code more like this:

    use Devel::EvalError();
    # ...

    my $ee = Devel::EvalError->new();
    $ee->ExpectOne( eval { ...; 1 } );
    if ( $ee->Failed() ) {
        log_failure( "...: " . $ee->Reason() );
    }

=head2 Caveats

It is important to call C<Devel::EvalError->new()> before doing the C<eval>.
Although I believe that in all existing implementations of Perl v5, the
following code still works, there is no iron-clad guarantee that it will do
things in the required order (such as in some future version of Perl).  So
you might not want to risk using it:

    my $ee = Devel::EvalError->new()->ExpectOne(
        eval $code . "; 1"
    );

It is important that the Perl code that you evaluate ends with an expression
that returns just the number one.  When evaluating a string, append C<"; 1">
to the end of the string.  When evaluating a block, add C<; 1> to the end
inside the block, like so:

    $ee->ExpectOne()->( eval { ...; 1 } );

If the C<eval>'d code returns early, it is important that it does so either
via C<return 1;> or by C<die>ing.

Since you can't rely on C<$@> to tell if C<eval> failed or succeeded, you
need to rely on what C<eval> returns.  C<eval> indicates failure by returning
an empty list so it is very important to not do C<return;> inside the C<eval>
(of course, C<return;> in some subroutine called from your C<eval>'d code
is not a problem).  You also should avoid C<return @list;> unless you can
be certain that C<@list> is not empty.

C<ExpectOne()> requires that C<eval> either returns an empty list or returns
just the number one (otherwise it C<croak>s).

=head2 Why C<$@> is unreliable

It is a bug in Perl that the value of C<$@> is not guaranteed to survive until
C<eval> finishes returning.  This bug has existed since Perl 5 was created
so there are a lot of versions of Perl around where you can run into this
problem.  Here is a quick example demonstrating it:

    my $ok = eval {
        my $trigger = RunAtBlockEnd->new(
            sub { warn "Exiting block!\n" },
        );
        die "Something important!\n";
        1;
    };
    if( $@ ) {
        warn "eval failed ($@)\n";
    } elsif( $ok ) {
        warn "eval succeeded\n";
    } else {
        warn "eval failed but \$@ was empty!\n";
    }

    {
        package RunAtBlockEnd;
        sub new { bless \$_[-1], $_[0] }
        sub DESTROY {
            my $self = shift @_;
            eval { ${$self}->(); 1 }
                or  warn "RunAtBlockEnd failed: $@\n";
        }
    }

This code produces the following output:

    Exiting block!
    eval failed but $@ was empty!

The crux of the problem is the use of C<eval> inside of a C<DESTROY>
method while not also doing C<local $@> in that method.  Note that it is
also a problem if any code called, however indirectly, from a C<DESTROY>
method uses C<eval> without C<local $@>, so preventing the problem can be
quite difficult (and once you have identified that this problem is
happening to you, the inability to overload C<eval> prevents easily
finding the source of the problem).

Note that the use of C<Devel::EvalError> also has the side-effect of
localizing the changing of C<$@> so it not only works around this problem
if used on the outer C<eval>, it would also prevent the problem if only
used on the inner C<eval>.  If we change our C<DESTROY> method to:

    sub DESTROY {
        use Devel::EvalError();
        my $self = shift @_;
        my $ee = Devel::EvalError->new();
        $ee->ExpectOne( eval { ${$self}->(); 1 } );
        warn "RunAtBlockEnd failed: ", $ee->Reason(), "\n"
            if  $ee->Failed();
    }

Then our snippet produces the following results:

    Exiting block!
    eval failed (Something important!
    )

=head2 Why C<use> not C<require> ?

Note that we wrote C<use Devel::EvalError();> and not
C<require Devel::EvalError;> in the above contrived example.  That is because,
the first time a module is C<require>'d, the code for the module has to
be C<eval>'d, which also clobbers C<$@> just like a straight C<eval> would.
So doing a C<require> inside of a C<DESTROY> method causes the same problem.

So all of our examples use C<use Devel::EvalError();> just in case somebody
pastes some example code into their C<DESTROY> method.  In most real-world
code, the C<require> would be placed outside of the C<DESTROY> method and
so is unlikely to cause a problem.  So if you prefer C<require> over C<use>
in some cases, you can I<usually> write C<require Devel::EvalError;> with no
problem.

=head2 Methods

=head3 C<new>

C<new()> is a I<class> method that takes no arguments and returns a new
C<Devel::EvalError> object.  You usually call C<new()> like so:

    my $ee = Devel::EvalError->new();

C<new()> saves away the current value of C<$@> so that it can restore it
when you are done using the returned C<Devel::EvalError> object.  C<new()>
also sets up a C<$SIG{__DIE__}> handler to make a note of any exceptions that
get thrown (such as by calling C<die>).  This "die handler" will also call
the previous handler (if there was one) and the previous handler will be
automatically restored later.

=head3 C<ExpectOne>

    $ee->ExpectOne( eval { ...; 1 } );

    $ee->ExpectOne( eval $code . '; 1' );

C<ExpectOne()> should be passed the results of a call to C<eval>.  The code
being C<eval>'d should exit only by returning just the number one or by
throwning an exception (such as by calling C<die>).

C<ExpectOne()> returns the object that invoked it so that you can use
the following shortened form:

    my $ee = Devel::EvalError->new()->ExpectOne( eval ... );

But be aware that this shortened form relies on a particular I<order of
evaluation> that is not guaranteed.  So you may wish to avoid this risk
or just prefer to not rely on undefined evaluation order as a matter of
principle.

If C<ExpectOne()> gets passed just the number one, then the C<eval> succeeded,
setting what several other methods will return.

If C<ExpectOne()> gets passed the empty list, then the C<eval> failed, setting
the return values for other methods differently.

The current release also interprets a single undefined value as C<eval> having
failed.  This is to account for a use-case similar to:

    my $ee = Devel::EvalError->new();
    my $ok = eval { ...; 1 };
    $ee->ExpectOne( $ok );

But this interpretation may be subject to change in a future release of
C<Devel::EvalError> (to be treated the same as the following case).

Being passed any other value will cause C<ExpectOne()> to "croak" (see
the C<Carp> module), reporting that the module has been used incorrectly.

If C<ExpectOne()> gets passed the empty list, then the value of C<$@> is
immediately checked.  If C<$@> is not empty, then its value is saved as
I<the> failure reason (other failure reasons may have been collected by
the "die handler", but those will mostly be ignored in this case).

C<ExpectOne()> also restores the previous "die handler" (if any).

=head3 C<Reason>

C<Reason()> returns either the empty string or a string (or object)
containing (at least) the reason that the earlier C<eval> failed.  If it is
unclear which of several different reasons actually caused the C<eval> to
fail, then a string will be returned containing all of the possible reasons
in chronological order.

To simplify some coding cases, C<Reason()> will safely return an empty
string if called on an C<Erase()d> object or one where C<ExpectOne()>
has not yet been called [nor C<ExpectNonEmpty()>].

=head3 C<AllReasons>

C<AllReasons()> returns the list of strings and/or objects that repesent
exceptions thrown between when our object was created and when C<ExpectOne()>
was called [or C<ExpectNonEmpty()>], in chronological order.

Usually the last reason returned is the reason that the C<eval> failed.

Note that if a C<DESTROY> method tries to throw an exception (a rather
pointless thing to do unless the exception is caught within the DESTROY
method), then the real reason for the C<eval> failing can have other
reasons after it in the returned list of reasons.  If that DESTROY method
also did C<local $@;> (or equivalent) such that C<$@> was still properly
set after C<eval> finished failing, then the last reason returned will
be the real reason why the C<eval> failed; that reason will just appear
in the list of reasons twice.

=head3 C<Succeeded>

C<Succeeded()> returns a true value if the earlier C<eval> succeeded.  It
returns a false value if the earlier C<eval> failed.  Otherwise it "croaks"
(if C<ExpectOne()> has not yet been called or the invoking object has been
C<Erase()>d, etc.).

=head3 C<Failed>

C<Failed()> returns a true value if the earlier C<eval> failed.  It returns
a false value if the earlier C<eval> succeeded.  Otherwise it "croaks".

=head3 C<Reuse>

C<Reuse()> cleans up an existing C<Devel::EvalError> object and then prepares
it to be used again.  The following two snippets are equivalent:

    undef $ee;
    $ee = Devel::EvalError->new();

    # Same as

    $ee->Reuse();

Note that you should I<not> re-use a variable by simply puting a new
C<Devel::EvalError> object over the top of a previous one.  Don't ever
write code like the line marked "WRONG!" below:

    my $ee = Devel::EvalError->new();
    # ...
    $ee = Devel::EvalError->new();      # WRONG!

    my $e2 = Devel::EvalError->new();
    # ...
    $e2->Reuse();                      # RIGHT!

Here is a quick example of how badly that can go wrong:

    my $ee = Devel::EvalError->new();
    if ( $DoStuff ) {
        $ee->ExpectOne( eval { do_stuff(); 1 } );
        # ...
    }
    $ee = Devel::EvalError->new();

The above code produces output like:

    $SIG{__DIE__} changed out from under Devel::EvalError at ...
        Devel::EvalError::_revertHandler...
        Devel::EvalError::Erase...
        Devel::EvalError::DESTROY...
        ...
    $SIG{__DIE__} changed out from under Devel::EvalError at ...
        Devel::EvalError::_revertHandler...
        Devel::EvalError::Erase...
        Devel::EvalError::DESTROY...
        ...

This is because the second C<Devel::EvalError> object is created before
the first one gets destroyed.  The lifetimes of C<Devel::EvalError> objects
must be strictly nested or else they can't properly deal with sharing the
single global C<$SIG{__DIE__}> slot.

Calling C<$ee->Reuse();> ensures that the previous object gets cleaned up
I<before> the next one is initialized, preventing such noisy problems.

Note that C<Reuse()> returns the invoking object so that you can choose
to use the following shortened form, despite the fact that it relies on
a particular (undefined) order of evaluation:

    $ee->Reuse()->ExpectOne( eval ... );

=head3 C<Erase>

C<Erase()> cleans up and clears out a C<Devel::EvalError> object.  The below
two snippets are equivalent:

    my $ee = Devel::EvalError->new();
    # ...                           # eval() 1
    undef $ee;
    # ...                           # non-eval() code
    $ee = Devel::EvalError->new();
    # ...                           # eval() 2

    my $ee = Devel::EvalError->new();
    # ...                           # eval() 1
    $ee->Erase();
    # ...                           # non-eval() code
    $ee->Reuse();
    # ...                           # eval() 2

Notice how using C<Erase()> leaves the C<$ee> variable holding an object so
you can just use C<< $ee->Reuse() >> rather than having to repeat the whole
module name in order to call C<new()>.

Note also that C<< $ee->new() >> is not allowed.  If you don't want to
re-type the module name and you want to use one object to create another
I<separate> object, then you I<can> use C<< ref($ee)->new() >>.  But remember
that you need to ensure that the lifespans of C<Devel::EvalError> objects
are I<strictly> nested.

The following contrived example shows how not being explicit with the
nesting of the lifespans of C<Devel::EvalError> objects can be a problem:

    {
        my $e1 = Devel::EvalError->new();

        my $e2 = ref($e1)->new();

        # Both $e1 and $e2 get destroyed here ...
        # in what order?
    }

The above code produces two

    $SIG{__DIE__} changed out from under Devel::EvalError ...

complaints.  You can fix it as follows:

    {
        my $e1 = Devel::EvalError->new();
        {
            my $e2 = ref($e1)->new();

            # Only $e2 is destroyed here
        }

        # Only $e1 is destroyed here
    }

Sadly, the above contrived example may still give the annoying warnings
due to a rare appearance of Perl 5 optimizations.  Adding just one line
of useless code prevents the optimization and the warnings.  In real
code, this optimization problem is much less likely to appear.

    {
        my $e1 = Devel::EvalError->new();
        {
            my $e2 = ref($e1)->new();

            # Only $e2 is destroyed here
        }
        my $x= "You may need code here to thwart optimizations";

        # Only $e1 is destroyed here
    }

=head3 C<ExpectNonEmpty>

You should probably not use the C<ExpectNonEmpty()> method.

No, really.  Just go read some other section of the manual now.

Are you still here?  Okay, since I wrote it, I guess I'll let you read
the documentation about it as well.

C<ExpectNonEmpty()> can be used to use C<eval> to return an interesting
value.  For example:

    my $ee = Devel::EvalError->new();
    my @list = $ee->ExpectNonEmpty(
        eval { getListDangerously() }
    );

But you really shouldn't do it that way.  You should do it this way instead:

    my $ee = Devel::EvalError->new();
    my @list;
    $ee->ExpectOne(
        eval { @list = getListDangerously(); 1 }
    );

For one thing, if C<getListDangerously()> returned an empty list, then
much confusion would likely ensue.

For another, scalar context isn't preserved when changing code from:

    my $return = eval ...;

to:

    my $return = $ee->ExpectNonEmpty( eval ... );

In the second line above, the C<eval> is called in a list context.  That
code would be better written like:

    my $return;
    $ee->ExpectOne( eval { $return = ...; 1 } );

Or, in the case of C<eval>'ing a string of Perl code:

    my $return;
    $ee->ExpectOne( eval "\$return = $code; 1" );

=head1 CONTRIBUTORS

Original author: Tye McQueen, http://perlmonks.org/?node=tye

=head1 LICENSE

Copyright (c) 2008 Tye McQueen. All rights reserved.
This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

The Troll Under the Bridge, Fremont, WA

=cut
