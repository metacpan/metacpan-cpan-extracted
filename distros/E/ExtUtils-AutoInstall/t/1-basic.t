#!/usr/bin/perl

use strict;
use Test;

BEGIN { plan tests => 6; $^W = 0; };

# Intercepts calls to WriteMakefile and prompt.
my $mm_args;
my @prompts = qw/y n n y y/;

use ExtUtils::MakeMaker;
sub ExtUtils::MakeMaker::WriteMakefile { $mm_args = {@_} }
sub ExtUtils::MakeMaker::prompt ($;$) { return 'n' }

# tiehandle trick to intercept STDOUT.
sub PRINT  { my $self = shift; $$self .= join '', @_; }
sub PRINTF { my $self = shift; $$self .= sprintf(shift, @_); }
sub TIEHANDLE { my $self = ''; return bless \$self, shift; }
sub READ {} sub READLINE {} sub GETC {} sub FILENO {}

use Symbol ();
my $fh  = Symbol::gensym;
my $out = tie *$fh, __PACKAGE__;
select(*$fh);

# test from a clean state
$ENV{PERL_EXTUTILS_AUTOINSTALL} = '';
require ExtUtils::AutoInstall;
ExtUtils::AutoInstall::_accept_default(0);
*ExtUtils::AutoInstall::_prompt  = sub {
    ok($_[1], shift(@prompts));
    return 'n';
};

# calls the module.
ok(eval <<'.', $@);
use ExtUtils::AutoInstall (
    -version	=> '0.21',	# ExtUtils::AutoInstall version
    -config	=> {
	make_args	=> '--hello'	# option(s) for CPAN::Config 
    },
    -core	=> [		# core modules
	Package0	=> '',		# any version would do
    ],
    'Feature1'	=> [
	# do we want to install this feature by default?
	-default	=> 0,
	Package1	=> '0.01',
    ],
    'Feature2'	=> [
	# associate tests to be disabled along with this
	-tests		=> [ $0 ],
	Package2	=> '0.02',
    ],
    'Feature3'	=> {			# hash reference works, too
	Package3	=> '0.03',
    },
); '';
.

# simulates a makefile.
WriteMakefile(
    AUTHOR		=> 'Joe Hacker (joe@hacker.org)',
    ABSTRACT		=> 'Perl Interface to Joe Hacker',
    NAME		=> 'Joe::Hacker',
    VERSION_FROM	=> 'Hacker.pm',
    DISTNAME		=> 'Joe-Hacker',
    EXE_FILES		=> [ qw/foo bar baz/ ],
);

# XXX - test currently disabled in anticipation of a
#       rewrite using Test::MockObject.

exit;

$$out =~ s/.*\n//; # strip the version-dependent line.

ok($$out, qr/\Q*** Checking for dependencies...
[Core Features]
- Package0 ...failed! (needed)
[Feature1]
- Package1 ...failed! (needs 0.01)
[Feature2]
- Package2 ...failed! (needs 0.02)
[Feature3]
- Package3 ...failed! (needs 0.03)\E
.*\Q
*** ExtUtils::AutoInstall configuration finished.\E/s);

use vars qw/@Data_Stack $DNE/;
$mm_args->{test}{TESTS} = ''; # XXX: workaround false-positive globbing

ok(_deep_check($mm_args, 
{
    ABSTRACT		=> 'Perl Interface to Joe Hacker',
    test		=>  { 'TESTS' => '' },
    NAME		=> 'Joe::Hacker',
    DISTNAME		=> 'Joe-Hacker',
    AUTHOR		=> 'Joe Hacker (joe@hacker.org)',
    EXE_FILES		=> [],
    VERSION_FROM	=> 'Hacker.pm',
}));

#######################################################################
# The following section is adapated verbatim from Test::More v0.32.
#
# According to the Artistic License, the copyright information of 
# Test::More is acknowledged here:
# 
#   Test::More - yet another framework for writing test scripts
#
#   AUTHOR
#
#   Michael G Schwern <schwern@pobox.com> with much inspiration from
#   Joshua Pritikin's Test module and lots of discussion with Barrie
#   Slaymaker and the perl-qa gang.
#
# The source code of Test::More may be acquired at http://www.cpan.org/,
# or from a standard perl distribution of v5.7.2+.
#
#######################################################################

sub _deep_check {
    my($e1, $e2) = @_;
    my $ok = 0;

    my $eq;
    {
        # Quiet unintialized value warnings when comparing undefs.
        local $^W = 0; 

        if( $e1 eq $e2 ) {
            $ok = 1;
        }
        else {
            if( UNIVERSAL::isa($e1, 'ARRAY') and
                UNIVERSAL::isa($e2, 'ARRAY') )
            {
                $ok = eq_array($e1, $e2);
            }
            elsif( UNIVERSAL::isa($e1, 'HASH') and
                   UNIVERSAL::isa($e2, 'HASH') )
            {
                $ok = eq_hash($e1, $e2);
            }
            elsif( UNIVERSAL::isa($e1, 'REF') and
                   UNIVERSAL::isa($e2, 'REF') )
            {
                push @Data_Stack, { type => 'REF', vals => [$e1, $e2] };
                $ok = _deep_check($$e1, $$e2);
                pop @Data_Stack if $ok;
            }
            elsif( UNIVERSAL::isa($e1, 'SCALAR') and
                   UNIVERSAL::isa($e2, 'SCALAR') )
            {
                push @Data_Stack, { type => 'REF', vals => [$e1, $e2] };
                $ok = _deep_check($$e1, $$e2);
            }
            else {
                push @Data_Stack, { vals => [$e1, $e2] };
                $ok = 0;
            }
        }
    }

    return $ok;
}

sub eq_hash {
    my($a1, $a2) = @_;
    return 1 if $a1 eq $a2;

    my $ok = 1;
    my $bigger = keys %$a1 > keys %$a2 ? $a1 : $a2;
    foreach my $k (keys %$bigger) {
        my $e1 = exists $a1->{$k} ? $a1->{$k} : $DNE;
        my $e2 = exists $a2->{$k} ? $a2->{$k} : $DNE;

        push @Data_Stack, { type => 'HASH', idx => $k, vals => [$e1, $e2] };
        $ok = _deep_check($e1, $e2);
        pop @Data_Stack if $ok;

        last unless $ok;
    }

    return $ok;
}

sub eq_array  {
    my($a1, $a2) = @_;
    return 1 if $a1 eq $a2;

    my $ok = 1;
    my $max = $#$a1 > $#$a2 ? $#$a1 : $#$a2;
    for (0..$max) {
        my $e1 = $_ > $#$a1 ? $DNE : $a1->[$_];
        my $e2 = $_ > $#$a2 ? $DNE : $a2->[$_];

        push @Data_Stack, { type => 'ARRAY', idx => $_, vals => [$e1, $e2] };
        $ok = _deep_check($e1,$e2);
        pop @Data_Stack if $ok;

        last unless $ok;
    }
    return $ok;
}
