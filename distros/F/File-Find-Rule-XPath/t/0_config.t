# $Id: 0_config.t,v 1.1.1.1 2002/12/18 09:21:18 grantm Exp $
# vim: syntax=perl

use strict;
use File::Spec;

use Test::More tests => 1;

# Modules to inspect for version numbers

my @mod_list = qw(
  File::Find::Rule XML::LibXML XML::XPath
);


# Extract the version number from each module

my(%version);
foreach my $module (@mod_list) {
  eval " require $module; ";
  unless($@) {
    no strict 'refs';
    $version{$module} = ${$module . '::VERSION'} || "Unknown";
  }
}


# Add version number of the Perl binary

eval ' use Config; $version{Perl} = $Config{version} ';  # Should never fail
if($@) {
  $version{Perl} = $];
}
unshift @mod_list, 'Perl';


# Print details of installed modules on STDERR

diag(sprintf("\r#%-30s %s\n", 'Package', 'Version'));
foreach my $module (@mod_list) {
  $version{$module} = 'Not Installed' unless(defined($version{$module}));
  diag(sprintf(" %-30s %s\n", $module, $version{$module}));
}


# Now create some test data files

my $path = File::Spec->catfile('t', 'testdata');
mkdir($path, 0755);

while(<DATA>) {
  if(/^>/) {
    my @parts = /([\w\.]+)/g;
    my $path = File::Spec->catfile('t', 'testdata', @parts);
    open(OUT, ">", $path) || die "open($path): $!";
    next;
  }
  print OUT $_;
}
close(OUT);

ok(1);

__DATA__
> hello.xml
<doc>
  <greeting>Hello World!</greeting>
</doc>

> plain.txt
Hello World!

> quote.xml
<doc>
  <para>And then he said <quote>Hello World!</quote>.</para>
</doc>

> unbalanced.xml
<doc>
  <title>Hello World!</title>
  <para>This document should be ignored since it is not well formed.<para>
</doc>

