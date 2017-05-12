package Devel::Assert;
use 5.014;
use strict;

our $VERSION = '1.06';

our $__ASSERT_GLOBAL = 0;

require XSLoader;
XSLoader::load('Devel::Assert', $VERSION);

sub import {
	my ($class, $arg) = @_;
	my $caller = caller;

    $__ASSERT_GLOBAL = 1 if $arg eq 'global';

    my $ref = $arg eq 'off' || !$__ASSERT_GLOBAL && $arg ne 'on' ? \&assert_off : \&assert_on;
    {
        no strict 'refs';
        *{"${caller}::assert"} = $ref if !defined *{"${caller}::assert"}{CODE};
    }
}

sub assert_off {}

sub assert_fail {
    my ($op, $cop, $upcv) = @_;

    # idea taken from Zefram's Debug::Show
    # this code knows too much about B::Deparser internals

    unless (state $init_done++) {
        require B;
        require B::Deparse;

        require Carp;
        $Carp::Internal{'Devel::Assert'}++;
    }

    my $deparser = B::Deparse->new;
    $deparser->{curcop} = $cop;
    $deparser->{curcv}  = $upcv;

    my $deparsed;
    {
        local $@;
        local $SIG{__DIE__};

        $deparsed = eval {
            $deparser->indent($deparser->deparse($op->sibling, 50));
        } || "0";
        warn $@ if $@;

        $deparsed =~ s/\n[\t ]*/ /g;
        $deparsed =~ s/^[(]//;
        $deparsed =~ s/[)]$//;
    }

    Carp::confess("Assertion '$deparsed' failed");
}

1;

