package My::Module::Test;

use 5.006002;

use strict;
use warnings;

use Carp;
use Test::More 0.88;

use Exporter qw{ import };

our $VERSION = '0.011';

our @EXPORT =		## no critic (ProhibitAutomaticExportation)
qw{
    check_testable
    do_utf
    pb_name
    pb_opt
    pb_putter
    test_vs_pbpaste
};

sub check_testable (;$) {	## no critic (ProhibitSubroutinePrototypes)
    my ( $prog ) = @_;

    if ( defined $prog ) {
	`$prog -help 2>&1`;
	$?
	    and plan skip_all => "@{[ ucfirst $prog ]} program not found";
    }

    eval {
	require Mac::Pasteboard;
	1;
    } or plan skip_all => 'Can not load Mac::Pasteboard';

    Mac::Pasteboard->set( fatal => 0 );
    Mac::Pasteboard->new();
    Mac::Pasteboard->get( 'status' ) ==
    Mac::Pasteboard::coreFoundationUnknownErr()
	and plan skip_all => 'No access to desktop (maybe running as ssh session or cron job?)';
    Mac::Pasteboard->set( fatal => 1 );

    return;
}

{
    my $do_utf = eval {
	require POSIX;
	my ( $rls ) = split qr{ [.] }smx, ( POSIX::uname() )[2];
	$rls >= 12;	# Mountain Lion.
		    # Seen to work under Mountain Lion (Darwin 12).
		    # Seen not to work under Tiger (Darwin 8).
		    # In between unknown.
    };

    sub do_utf {
	return $do_utf;
    }
}

sub pb_name ($) {	## no critic (ProhibitSubroutinePrototypes, RequireArgUnpacking)
    $_[1] = 'name';
    goto &_pb_info;
}

sub pb_opt ($) {	## no critic (ProhibitSubroutinePrototypes, RequireArgUnpacking)
    $_[1] = 'pbopt';
    goto &_pb_info;
}

sub pb_putter ($) {	## no critic (ProhibitSubroutinePrototypes, RequireArgUnpacking)
    $_[1] = 'putter';
    goto &_pb_info;
}

{

    my %pasteboard_info = (
	default	=> {
	    putter	=> 'pbcopy',
	},
	general	=> {
	    name	=> Mac::Pasteboard::kPasteboardClipboard,
	    pbopt	=> '-pboard general',
	    putter	=> 'pbcopy',
	},
	find	=> {
	    name	=> Mac::Pasteboard::kPasteboardFind,
	    pbopt	=> '-pboard find',
	    putter	=> 'pbcopy_find',
	},
    );

    sub _pb_info {
	my ( $selector, $key ) = @_;
	my $info = $pasteboard_info{$selector}
	    or croak "No data for selector '$selector'";
	return $info->{$key};
    }
}

sub test_vs_pbpaste ($$$) {	## no critic (ProhibitSubroutinePrototypes, RequireArgUnpacking)
    my ( $pbopt, $expect, $name ) = @_;
    my @cmd = qw{ pbpaste };
    defined $pbopt
	and push @cmd, $pbopt;
    my $got = `@cmd`;
    chomp $got;
    chomp $expect;
    @_ = ( $got, $expect, $name );
    goto &is;
}

1;

__END__

=head1 NAME

My::Module::Test - Mac::Pasteboard testing utilities.

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Test;
 
 check_testable 'pbpaste';

=head1 DESCRIPTION

This Perl module contains utility subroutines of various sorts used in
testing C<Mac::Pasteboard>.

=head1 SUBROUTINES

This module exports the following subroutines:

=head2 check_testable

 check_testable;
 check_testable 'pbpaste';

This subroutine checks to see if C<Mac::Pasteboard> can actually be
tested in the current environment. If C<Mac::Pasteboard> can be tested
C<check_testable()> simply returns. If not, it calls C<plan 'skip_all>
with an appropriate message, and never returns.

The optional argument is the name of a program to try. If this argument
is supplied, the program must be runnable.

We also test to be sure C<Mac::Pasteboard> can be instantiated. This may
fail if run from an C<ssh> session or a C<cron> job, depending on the
version of Mac OS X.

The prototype is C<($)>, so parens are not needed.

=head2 do_utf

 do_utf
     and say "Can use UTF flavors";

This subroutine returns true if C<public.utf16-plain-text> is available
for testing. What this really is is a test of the version of Darwin,
using C<POSIX::uname()>. The return is true for Darwin 12 (Mountain
Lion) or higher, and false for lower versions. The actual situation is
that this flavor is known not to be useful for testing under Darwin 8
(Panther) and 9 (Tiger). The situation for Darwin 10 (Leopard) and 11
(Snow Leopard) is unknown, so we err on the conservative side.

=head2 pb_name

 say 'Name of general pasteboard is ', pb_name 'general';

This subroutine returns the Mac OS name of the pasteboard specified by
the argument, which may be C<'default'>, C<'general'> or C<'find'>. The
return may be C<undef>.

The prototype is C<($)>, so parens are not needed.

=head2 pb_opt

This subroutine returns the F<pbcopy> or F<pbpaste> option which selects
the pasteboard specified by the argument, which may be C<'default'>,
C<'general'> or C<'find'>. The return may be C<undef>.

The prototype is C<($)>, so parens are not needed.

=head2 pb_putter

This subroutine returns the name of the C<pbcopy*()> subroutine used to
copy data to the pasteboard specified by the argument, which may be
C<'default'>, C<'general'> or C<'find'>. The return will not be
C<undef>.

The prototype is C<($)>, so parens are not needed.

=head2 test_vs_pbpaste

 test_vs_pbpaste '-pboard general', 'Fubar',
     'General pasteboard contains "Fubar"';

This subroutine runs a test to see if F<pbpaste> returns the given
string. The first argument is the argument string for F<pbpaste> and may
be C<undef>. The second argument is the string to compare to, and the
third argument is the test name. The F<pbpaste> program is run with the
given arguments (if any) to retrieve the test string. The actual test is
done by C<goto &Test::More::is>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
