#!/usr/bin/env perl
use strict; use warnings; 
no warnings 'redefine'; no warnings 'once';
use Test::More; use File::Spec; use File::Basename;

use rlib '../lib';

note( "Testing Devel::CmdProcessor::Command::Complete" );

BEGIN {
    use_ok( 'Devel::Trepan::CmdProcessor::Command::Complete' );
}

require_ok( 'Devel::Trepan::CmdProcessor' );

# Monkey::Patch doesn't work with methods with prototypes;
my $counter = 1;
sub monkey_patch_instance
{
    my($instance, $method, $code) = @_;
    my $package = ref($instance) . '::MonkeyPatch' . $counter++;
    no strict 'refs';
    @{$package . '::ISA'} = (ref($instance));
    *{$package . '::' . $method} = $code;
    bless $_[0], $package; # sneaky re-bless of aliased argument
}

my @msgs = ();
my $dir = File::Spec->catfile(dirname(__FILE__), '..', 'lib', 'Devel', 
			      'Trepan', 'CmdProcessor', 'Command');
my $cmdproc_opts = {cmddir => [$dir]};

my $cmdproc = Devel::Trepan::CmdProcessor->new(undef, undef, $cmdproc_opts);
monkey_patch_instance($cmdproc, 
		      msg => sub { my($self, $message, $opts) = @_;
				   push @msgs, $message;
				   });
my $cmd = Devel::Trepan::CmdProcessor::Command::Complete->new($cmdproc);

my $prefix = 'disas';
$cmd->{proc}{cmd_argstr} = $prefix;
@msgs = ();
$cmd->run([$cmd->name, $prefix]);
is($msgs[0], 'disassemble');
done_testing();
