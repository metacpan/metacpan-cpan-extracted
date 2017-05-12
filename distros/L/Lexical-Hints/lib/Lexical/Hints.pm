package Lexical::Hints;

use 5.010; use warnings;

our $VERSION = '0.000005';

# Track phase...
my $compiling;
BEGIN { $compiling = 1 }
CHECK { $compiling = 0 }


# Track lexical hints for each namespace...
my %LEXICAL_HINTS_FOR;


sub import {
    my ($package, $opt_ref) = @_;
    my $set_hint = $opt_ref->{set_hint} // 'set_hint';
    my $get_hint = $opt_ref->{get_hint} // 'get_hint';

    # Install API...
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::'.$set_hint} = _gen_set_hint($set_hint);
    *{$caller.'::'.$get_hint} = \&get_hint;
}

sub _gen_set_hint {
    my ($set_hint) = @_;

    return sub {
        my $key = shift;
        my $value = shift;
        my $opts_ref = _unpack_opts( shift );

        # Who is setting this hint???
        my $hint_owner = caller;

        # Lexical hints can only be autovivified at compile-time...
        if ($compiling) {
            # Allocate a unique number for the scope currently being compiled...
            my $scope_ID = scalar @{ $LEXICAL_HINTS_FOR{$hint_owner} //= [] };

            # Save that info in the lexical scope curently being compiled...
            $^H{$hint_owner.'->'.$key} = $scope_ID;

            # Save the corresponding value internally...
            push @{$LEXICAL_HINTS_FOR{$hint_owner}}, $value;
        }

        # Pre-existing hints can still be updated at run-time...
        elsif (defined(my $scope_ID = ((caller $opts_ref->{up}+1)[10]//{})->{$hint_owner.'->'.$key})) {
            # Update the corresponding value internally...
            $LEXICAL_HINTS_FOR{$hint_owner}[$scope_ID] = $value;
        }

        # But non-existing hints can't be created at run-time...
        else {
            $value = ref($value) || qq{"$value"};
            _croak(
                "Cannot autovivify hint '$key' at runtime for $hint_owner\n",
                "in call to $set_hint()",
            );
        }

        return;
    }
}

sub get_hint {
    my $key      = shift;
    my $opts_ref = _unpack_opts( shift );

    # Who is retrieving this hint???
    my $hint_owner = caller;

    # Query the caller's scope...
    my $hints_hash = $compiling ? \%^H : (caller $opts_ref->{up}+1)[10];

    # Recover the appropriate scope ID...
    my $scope_ID = $hints_hash->{$hint_owner.'->'.$key};

    # No such hint --> undef...
    return undef if !defined $scope_ID;

    # Otherwise, recover the appropriate value...
    return $LEXICAL_HINTS_FOR{$hint_owner}[$scope_ID];
}

sub dump { 
    my $opts_ref = _unpack_opts( shift );

    # Obtain dump of data...
    require Data::Dumper;
    my $dump = Data::Dumper::Dumper($compiling ? \%^H : (caller $opts_ref->{up})[10] // {});

    $dump = substr($dump,8,-2);
    $dump =~ s{[ ]{8}}{}gxms;

    # Return dump in non-void contexts...
    return $dump if defined wantarray;

    # Report to STDERR in void contexts...
    print {*STDERR} $dump, "\n";
}

sub _croak { require Carp; Carp::croak(@_); }
sub _carp  { require Carp; Carp::carp(@_);  }

sub _unpack_opts {
    my $opts_ref = shift // {};

    # Is it a valid hash ref???
    my $type = ref($opts_ref);
    _croak('Invalid option: expected hash ref, but was passed '
          . ( $type ? lc($type) . ' ref instead' : 'a scalar instead')
    ) if $type ne 'HASH';

    # Copy arg and insert default value, if necessary...
    $opts_ref = { up => 0, %{$opts_ref} };

    # Watch for misunderstandings...
    if ($compiling && $opts_ref->{'up'}) {
        _carp("Useless compile-time 'up' option ignored");
    }

    # Are there invalid options???
    my @unknown_opts = grep {$_ ne 'up'} keys %{$opts_ref};
    _croak('Unknown option'.(@unknown_opts==1?q{}:q{s}).": @unknown_opts")
        if @unknown_opts;

    # By this point, the options hash is cleansed...
    return $opts_ref;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Lexical::Hints - A featureful replacement for %^H


=head1 VERSION

This document describes Lexical::Hints version 0.000005


=head1 SYNOPSIS

    use Lexical::Hints;

    # Set a hint at compile-time...
    sub import {
        ...
        set_hint( $HINT_NAME => $HINT_VALUE );
        ...
    }

    # Retrieve a hint at runtime...
    sub runtime_sub {
        ...
        $hint_val = get_hint( $HINT_NAME );
        ...
    }

    # Dump all currently active hints...
    Lexical::Hints::dump();


=head1 DESCRIPTION

This module provides a cleaner interface to the built-in "lexical hints
hash" (%^H), and adds some useful new features to the existing mechanism.
See L<perlpragma> for details of the standard lexical hinting API.


=head1 INTERFACE

=head2 Setting up lexical hints at compile-time

C<set_hint( $HINT_NAME, $HINT_VALUE, \%OPTIONS )>

The C<set_hint()> subroutine expects two or three arguments:

=over

=item * The name of the hint whose value is being set

=item * The value of the hint whose value is being set

=item * An optional reference to a hash containing named options

=back

The subroutine does not return any useful value.

The name can be any string you choose. There is no need to follow
the normal convention of prefixing the hint name with the current
module name; C<set_hint()> will take care of that automatically.

The value can be any valid scalar: a number, a string, any kind of
reference, a C<qr>, I<etc.>.

The only option currently offered is: C<< { up => $UPSCOPE_COUNT } >>.
In the absence of this option, the hint is set for the scope currently being
compiled (at compile-time) or the lexical scope of the current subroutine's
immediate caller (at runtime).

However if the option is included in a runtime call to C<set_hint()>,
then the hint is (re)set in the scope indicated. For example:

    set_hint('debugger' => $debug_sub_ref , { up => 2 });

sets the C<'debugger'> hint in the scope of the current subroutine's
caller's caller's caller (i.e. in the scope that C<caller(2)> would
report on).

=head3 Setting lexical hints at runtime

Unlike C<%^H>, which can only be assigned to at compile-time,
C<set_hint()> can be called at runtime as well. However, when called at
runtime, only I<pre-existing> hints (i.e. those previously created by a
compile-time call to C<set_hint()>) can be modified.

Note that any runtime changes to a lexical hint will persist for the
rest of the program. Although the hints themselves are lexically scoped,
changes to the hint values are B<not>. That is, the hints of a
particular lexical scope are like invisible C<state> variables in that
scope, B<not> like invisible C<my> variables.

Generally, it's best not to reset lexical hints at run-time,
unless you're very confident you know what you are doing.


=head2 Retrieving lexical hints

C<$HINT_VALUE = get_hint( $HINT_NAME, \%OPTIONS )>

The C<get_hint()> subroutine may be called at compile-time or runtime
and expects either one or two arguments:

=over

=item * The name of the hint whose value is being retrieved

=item * An optional reference to a hash containing named options

=back

The function returns the value of the requested hint,
or C<undef> if the hint does not exist.

The only option currently offered is: C<< { up => $UPSCOPE_COUNT } >>,
which works exactly as for C<set_hint()>.

In the absence of this option, the hint is retrieved from the scope
currently being compiled (at compile-time) or from the lexical scope of
current subroutine's immediate caller (at runtime).

However, if the option is included in a runtime call to C<get_hint()>,
then the hint is retrieved from the scope indicated. For example:

    set_hint('logging_active' => $FALSE, { up => 1 });

retrieves the C<'logging_active'> hint from the scope of the current
subroutine's caller's caller.



=head2 Exporting C<set_hint()> and C<get_hint()> under different names

Normally a C<use Lexical::Hints> exports both C<set_hints()> and
C<get_hints()>. However, you can request that these two functions be
exported under different names, by specifying the name mappings in the
C<use> statement:

    use Lexical::Hints (
        set_hint => 'store_lex_data',
        get_hint => 'retrieve_lex_data',
    );


=head2 Debugging lexical hints

C<Lexical::Hints::dump( \%OPTIONS )>

You can always see the current hints of a given lexical scope
by placing one of the following statements in that scope:

    # See the hints at compile-time...
    BEGIN { use Data::Dumper 'Dumper'; warn Dumper \%^H; }

    # See the hints at runtime...
    sub { use Data::Dumper 'Dumper'; warn Dumper +(caller 0)[10]; }->();

But those are ugly and hard to remember. So Lexical::Hints provides a
utility to encapsulate and enhance them:

    # See the hints at compile-time...
    BEGIN { Lexical::Hints::dump(); }

    # See the hints at runtime...
    Lexical::Hints::dump();

This subroutine is not exported, so calls to it must be fully
qualified, as above.

In void context, the subroutine dumps the current contents of the
current scope's hints hash to C<STDERR>. In non-void contexts, it
returns a string with the serialization of the hints hash:

    # Dump to STDERR...
    Lexical::Hints::dump();

    # Dump to variable...
    my $hints_serialization = Lexical::Hints::dump();

C<dump()> optionally takes a single argument: a reference to a hash of options.
At present there is only one option available:

    { up => $UPSCOPE_COUNT }

which is identical in effect to the C<'up'> options of C<set_hint()> and
C<get_hint()>. That is: it selects a higher caller's scope to report on,
instead of the immediate caller's.


=head1 DIAGNOSTICS

=over

=item C<< Unknown option: %s >>

At present, C<set_hint()>, C<get_hint()>, and C<dump()> only accept a
single option in their option hashes:

    sethint( $HINT_NAME, $HINT_VALUE, { up => $UPSCOPE_COUNT } )
    gethint( $HINT_NAME,              { up => $UPSCOPE_COUNT } )
    Lexical::Hints::dump(             { up => $UPSCOPE_COUNT } )

You either specified some other option name in your options hash,
or else managed to misspell C<'up'>.


=item C<< Invalid option: expected hash ref, but was passed %s instead >>

The optional options argument for C<set_hint()>, C<get_hint()>, and C<dump()>
has to be a hash reference. You passed something else.


=item C<< Useless compile-time 'up' option ignored >>

The C<'up'> option only has an effect at run-time; at compile-time it
is not meaningful and so is ignored.

Are you sure you understand how the subroutine you called is supposed to
work at compile-time? And the runtime-only effect of the C<'up'> option?

Were you not expecting the call in question to happen at compile-time?
Was it unexpectedly called from your C<import()>, or in a C<BEGIN> block?

Or did you just make a cut-and-paste error?


=item C<< Cannot autovivify hint %s at runtime for %s in call to set_hint() >>

You attempted to call C<set_hint()> at runtime to set a value for a hint
that does not exist.

Because the %^H variable is readonly at runtime, it's only possible to
create new hint/value pairs at compile-time. The hint you were trying to
set at runtime didn't previously exist in the scope where you were trying
to set it, so it could not be created.

Make sure you "predeclare" (at compile-time) any hints that you want to
be able to modify at runtime. That is, put a call to C<set_hint()> for
those hints inside your C<import()> subroutine.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Lexical::Hints requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

This module is not currently thread-safe. Expert advice (or patches!)
for thread-safing the module will be most gratefully accepted.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-lexical-hints@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

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
