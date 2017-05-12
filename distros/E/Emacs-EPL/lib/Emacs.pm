# Emacs.pm - redefine Perl's system primitives to work inside of Emacs.

package Emacs;

use 5.004;  # tied handles

use Emacs::Lisp ();
use Carp ();
use Tie::Handle ();
use Exporter ();

use strict;
use vars qw ( $VERSION @ISA $stuff_tied $old_warner @EXPORT );
use vars qw ( *REAL_STDIN *REAL_STDOUT *REAL_STDERR $real_pid );

$VERSION = '1.02';

@EXPORT = ('main', 'exit');
# XXX also need to redefine `open' to use Emacs locking.
# To think about: fork, exec, umask, Cwd.pm stuff, sysopen, kill
# (detect our pid or emacs's), chroot, alarm, ....

sub import {
    if (scalar (@_) == 1) {
	tie_stuff ();
    }
    for (my $i = 1; $i < scalar (@_); $i++) {
	if ($_[$i] eq ':tie') {
	    tie_stuff ();
	}
	else {
	    next;
	}
	splice (@_, $i, 1);
    }
    local @ISA = ('Exporter');
    Emacs->export_to_level (1, @_);
}

sub tie_stuff {
    return if $stuff_tied;

    if (defined (fileno (STDIN)) && ! defined (fileno (REAL_STDIN))) {
	open (REAL_STDIN, "<&=" . fileno (STDIN));
    }
    tie (*STDIN, 'Emacs::Minibuffer');

    if (defined (fileno (STDOUT)) && ! defined (fileno (REAL_STDOUT))) {
	open (REAL_STDOUT, ">&=" . fileno (STDOUT));
    }
    *::standard_output = *::standard_output;  # Avoid warnings.
    tie (*STDOUT, 'Emacs::Stream', \*::standard_output);

    if (defined (fileno (STDERR)) && ! defined (fileno (REAL_STDERR))) {
	open (REAL_STDERR, ">&=" . fileno (STDERR));
    }
    tie (*STDERR, 'Emacs::Minibuffer');

    $old_warner = $SIG{'__WARN__'};
    $SIG{'__WARN__'} = 'Emacs::SIG__WARN__';

    tie (%ENV, 'Emacs::ENV');
    tie (%SIG, 'Emacs::SIG');

    if (! defined ($real_pid)) {
	$real_pid = $$;
    }
    tie ($$, 'Emacs::PID');

    $stuff_tied = 1;
}

sub cleanup {
    return if ! $stuff_tied;

    untie ($$);
    untie (%SIG) if ref (tied (%SIG)) eq 'Emacs::SIG';
    untie (%ENV) if ref (tied (%ENV)) eq 'Emacs::ENV';

    $SIG{'__WARN__'} = $old_warner if $SIG{'__WARN__'} eq 'Emacs::SIG__WARN__';

    untie (*STDERR) if ref (tied (*STDERR)) eq 'Emacs::Minibuffer';
    untie (*STDOUT) if ref (tied (*STDOUT)) eq 'Emacs::Stream';
    untie (*STDIN) if ref (tied (*STDIN)) eq 'Emacs::Minibuffer';

    $stuff_tied = 0;
}

sub main {
    if (! defined (&_main)) {
	Carp::croak ("main() won't work, use \@Emacs::args instead");
    }
    package main;
    if (@_) {
	return Emacs::_main (@_);
    } else {
	return Emacs::_main ($0, @ARGV);
    }
}

sub SIG__WARN__ {
    my $msg = shift;
    chomp $msg;
    print STDERR $msg;
}

sub exit {
    my ($status) = @_;

    local $SIG{'__WARN__'} = 'DEFAULT';
    if ($Emacs::current) {
	&Emacs::Lisp::kill_emacs ($status);
    }
    CORE::exit ($status);
}


package Emacs::ENV;

sub TIEHASH {
    return (bless (\ do { my $x }, $_[0]));
}

sub FETCH	{ return &Emacs::Lisp::getenv ($_[1]); }
sub STORE	{ &Emacs::Lisp::setenv ($_[1], $_[2]); return ($_[2]); }

# XXX Need to write tests for these.

sub DELETE	{ &Emacs::Lisp::setenv ($_[1], undef); }
sub EXISTS	{ return defined (FETCH (@_)); }

sub FIRSTKEY {
    my ($pe, $str);

    $pe = Emacs::Lisp::Object::symbol_value (\*::process_environment);
    return undef if $pe->is_nil;
    $str = $pe->car->to_perl;
    $str =~ s/=.*//s;
    return $str;
}

sub NEXTKEY {
    my ($self, $lastkey) = @_;
    my ($tail, $str);

    for ($tail = Emacs::Lisp::Object::symbol_value (\*::process_environment);
	 not $tail->is_nil;
	 $tail = $tail->cdr)
    {
	if ($tail->car->to_perl =~ /^\Q$lastkey\E=/s) {
	    $tail = $tail->cdr;
	    return undef if $tail->is_nil;
	    $str = $tail->car->to_perl;
	    $str =~ s/=.*//s;
	    return $str;
	}
    }
    return undef;
}

sub CLEAR { &Emacs::Lisp::set (\*::process_environment, undef); }


package Emacs::Stream;

use vars ('@ISA');
@ISA = ('Tie::Handle');

sub TIEHANDLE {
    return (bless (\ do { my $x = $_[1] }, $_[0]));
}

sub WRITE {
    my ($stream, $output, $length, $offset) = @_;
    Emacs::Lisp::princ (substr ($output, $offset, $length),
			Emacs::Lisp::symbol_value ($$stream));
    return ($length);
}

sub PRINT {
    my ($stream, @items) = @_;
    Emacs::Lisp::princ (join ('', @items),
			Emacs::Lisp::symbol_value ($$stream));
    return (1);
}


package Emacs::Minibuffer;

use vars ('@ISA');
@ISA = ('Tie::Handle');

sub TIEHANDLE {
    return (bless (\ do { my $x }, $_[0]));
}

sub WRITE {
    my ($stream, $output, $length, $offset) = @_;
    Emacs::Lisp::message (substr ($output, $offset, $length));
    return ($length);
}

sub READ {
    die ("read() from STDIN is not implemented in Emacs.pm");
}

sub READLINE {
    return (Emacs::Lisp::read_string ("Enter input: "));
}


package Emacs::SIG;

sub TIEHASH {
    return (bless (\ do { my $x }, $_[0]));
}

sub signal_unsettable {
    return ($_[0] !~ m/^__/ && $_[0] !~ m/^USR[12]$/);
}

sub FETCH {
    my ($self, $sig) = @_;

    return 'EMACS' if signal_unsettable ($sig);
    { local $^W = 0; untie (%SIG); }
    my $handler = $SIG{$sig};
    tie (%SIG, 'Emacs::SIG');
    return $handler;
}

sub STORE {
    my ($self, $sig, $handler) = @_;

    if ($sig =~ m/^USR([12])$/) {
	no strict 'refs';
	my $key = \ [\*{"::usr${1}_signal"}];
	if (! defined ($handler)
	    || $handler eq 'DEFAULT'
	    || $handler eq 'IGNORE'
	    || $handler eq 'EMACS')
	{
	    Emacs::Lisp::global_unset_key ($key);
	}
	else {
	    # In Emacs, SIGUSR1 and SIGUSR2 are treated as keystrokes.
	    # Keys can be bound to commands, but not just ordinary
	    # functions.  Hence, "interactive".
	    $handler = Emacs::Lisp::Opaque->new ($handler)
		if ref ($handler);
	    $handler = [\*::lambda, undef, [\*::interactive],
			[\*::perl_call, $handler]];
	    Emacs::Lisp::global_set_key ($key, $handler);
	}
	return ($handler);
    }

    if (signal_unsettable ($sig)) {
	return if $handler eq 'EMACS';
	die ("Can't set signals under Emacs");
    }
    { local $^W = 0; untie (%SIG); }
    $SIG{$sig} = $handler;
    tie (%SIG, 'Emacs::SIG');
    return ($handler);
}

sub DELETE {
    my ($self, $sig) = @_;

    die ("Can't set signals under Emacs") if signal_unsettable ($sig);
    { local $^W = 0; untie (%SIG); }
    my $handler = delete $SIG{$sig};
    tie (%SIG, 'Emacs::SIG');
    return $handler;
}

sub EXISTS {
    my ($self, $sig) = @_;

    { local $^W = 0; untie (%SIG); }
    my $ret = exists $SIG{$sig};
    tie (%SIG, 'Emacs::SIG');
    return $ret;
}

sub CLEAR {}

sub FIRSTKEY {
    die "Can't iterate over signals under Emacs";
}

sub NEXTKEY {
    die "Can't iterate over signals under Emacs";
}

package Emacs::PID;

sub TIESCALAR { my ($x); return (bless (\$x, $_[0])); }
sub FETCH { return (Emacs::Lisp::emacs_pid ()); }
sub STORE { Carp::croak ("Can't change the process ID under Emacs"); }

1;
__END__


=head1 NAME

Emacs - Redefine Perl's system primitives to work inside of Emacs

=head1 SYNOPSIS

    perlmacs -w -MEmacs -e main -- --display :0.0 file.txt

    #! /usr/bin/perlmacs
    use Emacs;
    use Emacs::Lisp;
    setq { $mail_self_blind = t; };
    exit main ($0, "-q", @ARGV);


=head1 DESCRIPTION

This module replaces C<STDIN>, C<STDOUT>, C<STDERR>, C<%ENV>, C<%SIG>,
C<exit>, and C<warn> (via C<$SIG{__WARN__}>) with versions that work
safely within an Emacs session.  In Perlmacs, it also defines a
function named I<main>, which launches an Emacs editing session from
within a script.

=head2 STDIN

Reading a line from Perl's C<STDIN> filehandle causes a string to be
read from the minibuffer with the prompt C<"Enter input: ">.  To show
a different prompt, use:

    $string = &read_string ("Prompt: ");

=head2 STDOUT

Printing to Perl's C<STDOUT> filehandle inserts text into the current
buffer as though typed, unless you have changed the Lisp variable
C<standard-output> to do something different.

=head2 STDERR and `warn'

Perl's C<warn> operator and C<STDERR> filehandle are redirected to the
minibuffer.

=head2 %ENV

Access to C<%ENV> is redirected to the Lisp variable
C<process-environment>.

=head2 %SIG

Setting signal handlers is not currently permitted under Emacs.

=head2 exit

C<exit> calls C<kill-emacs>.

=head2 main (CMDLINE)

When you C<use Emacs> in a B<perlmacs> script, a Perl sub named
C<main> may be used to invoke the Emacs editor.  This makes it
possible to put customization code, which would normally appear as
Lisp in F<~/.emacs>, into a Perl script.

NOTE: This function does not work under EPL.  You have to have
Perlmacs to use it.  See L<Emacs::Lisp/"EPL AND PERLMACS">.

For example, this startup code

    (setq
     user-mail-address "gnaeus@perl.moc"
     mail-self-blind t
     mail-yank-prefix "> "
     )

    (put 'eval-expression 'disabled nil)

    (global-font-lock-mode 1 t)
    (set-face-background 'highlight "maroon")
    (set-face-background 'region "Sienna")

could be placed in a file with the following contents:

    #! /usr/local/bin/perlmacs

    use Emacs;
    use Emacs::Lisp;

    setq {
	$user_mail_address = 'gnaeus@perl.moc';
	$mail_self_blind = t;
	$mail_yank_prefix = '> ';
	$eval_expression{\*disabled} = undef;
    };

    &global_font_lock_mode(1, t);
    &set_face_background(\*highlight, "maroon");
    &set_face_background(\*region, "Sienna");

    exit main($0, "-q", @ARGV);

When you wanted to run Emacs, you would invoke this program.

The arguments to C<main> correspond to the C<argv> of the C<main>
function in a C program.  The first argument should be the program's
invocation name, as in this example.  B<-q> inhibits running
F<~/.emacs> (which is the point, after all).


=head1 BUGS

=over 4

=item * Problems with `main'.

C<main()> doesn't work under EPL.  It may open an X display and not
close it.  Those are the most obvious of many problems with C<main>.

The thing is, Emacs was not written with the expectation of being
embedded in another program, least of all a language interpreter such
as Perl.  Therefore, when Emacs is told to exit, it believes the
process is really about to exit, and it neglects to tidy up after
itself.

For best results, the value returned by C<main> should be passed to
Perl's C<exit> soon, as in this code:

    exit (main($0, @args));

=back


=head1 COPYRIGHT

Copyright (C) 1998-2001 by John Tobey,
jtobey@john-edwin-tobey.org.  All rights reserved.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; see the file COPYING.  If not, write to the
  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
  MA 02111-1307  USA


=head1 SEE ALSO

L<perl>, L<Emacs::Lisp>, B<emacs>.

=cut
