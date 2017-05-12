#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename qw< dirname >;
use lib dirname(__FILE__);

my $module;
BEGIN {
   $|++;
   $module = shift || 'Log::Log4perl';
   (my $path = "$module.pm") =~ s{::}{/}gmxs;
   require $path;
   $module->import(':easy');
   no strict 'refs';
} ## end BEGIN

use LayoutCompareModule;

my $expander = shift || 'C';

Log::Log4perl->easy_init(
   {
      level  => $INFO,
      layout => "%m ${expander}[%$expander]%n",
   }
);

INFO "here we go";
Some::Package::what();
Some::Package::ever();
LayoutCompareModule::talk();
LayoutCompareModule::complain(sub { INFO 'complain' });

sub inside {
   INFO "inside";
   Some::Package::ever();
   Some::Other::ever();
}

inside();
LayoutCompareModule::complain(sub { INFO 'complain + inside'; inside() });
LayoutCompareModule::complain(\&Some::Other::ever);

package Some::Package;
use strict;
use warnings;

BEGIN {
   *INFO = *main::INFO;
}

sub what { INFO "what" }
sub ever { INFO "ever"; what() }

package Some::Other;
use strict;
use warnings;

BEGIN {
   *INFO = *main::INFO;
}

sub what { INFO "what" }
sub ever { INFO "ever"; Some::Package::ever() }
