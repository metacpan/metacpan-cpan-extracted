package main;

use strict;
use warnings;
use Test::More;
use Devel::IPerl;
use IPerl;
use lib 'xt/lib';

my $iperl = new_ok('IPerl');

is $iperl->load_plugin('EnvironmentModules'), 1, 'loaded';

can_ok $iperl, qw{module_avail module_load module_list module_show module_unload};

my @modules = qw{this that another git something else entirely};

for my $name(qw{load unload}){
  my $cb = $iperl->can("module_$name");
  is $iperl->$cb(), -1, 'empty args == -1';
  is $iperl->$cb( $modules[int rand $#modules - 1] ), 1, 'returns 1';
}

{
  local $ENV{PERL5LIB} = '';
  open (my $fh1, '>', "$Env::Modulecmd::PATH_TO_ADD/TestModuleLoad.pm");
  print $fh1 "package TestModuleLoad; sub new { return bless {}, shift; } 1;";
  close $fh1;

  open (my $fh2, '>', "$Env::Modulecmd::PATH_TO_ADD/TestModuleUnload.pm");
  print $fh2 "package TestModuleUnload; 1;";
  close $fh2;

  my @original =
    grep { $_ eq $Env::Modulecmd::PATH_TO_ADD } split /:/, $ENV{PERL5LIB};
  is @original, 0, 'does not currently exist there';
  @original = grep { $_ eq $Env::Modulecmd::PATH_TO_ADD } @INC;
  is @original, 0, 'does not currently exist in INC';
  is $ENV{FOO_BAR_BAZ}, undef, 'never set';

  is $iperl->module_load('test'), 1, 'success';
  my @added =
    grep { $_ eq $Env::Modulecmd::PATH_TO_ADD } split /:/, $ENV{PERL5LIB};
  is @added, 1, 'added by load';
  @added = grep { $_ eq $Env::Modulecmd::PATH_TO_ADD } @INC;
  is @added, 1, 'does not currently exist in INC';
  is $ENV{FOO_BAR_BAZ}, 1, 'now set';

  my $tmload = eval { require TestModuleLoad; 1; };
  is $tmload, 1, 'found the module';
  $tmload = new_ok('TestModuleLoad');

  is $iperl->module_unload('test'), 1, 'success';
  my @removed =
    grep { $_ eq $Env::Modulecmd::PATH_TO_ADD } split /:/, $ENV{PERL5LIB};
  is @removed, 0, 'removed by unload';
  @removed = grep { $_ eq $Env::Modulecmd::PATH_TO_ADD } @INC;
  is @removed, 0, 'does not currently exist in INC';
  is $ENV{FOO_BAR_BAZ}, undef, 'now unset';

  my $tmunload = eval { require TestModuleUnload; 1; };
  is $tmunload, undef, 'should not find this one';
}

done_testing;
