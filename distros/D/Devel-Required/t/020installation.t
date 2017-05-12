BEGIN {				# Magic Perl CORE pragma
    chdir 't' if -d 't';
    unshift @INC,'../lib';
}

use Test::More tests => ( 3 * 3 ) + 11;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use Devel::Required maint_blead => 5.014;

my @modules= qw( Foo Bar Baz );
foreach (@modules) {
    ok( open( OUT, ">$_.pm" ), "Failed to open $_.pm: $!" );
    print OUT <<EOD;
package $_;
\$VERSION = '1.01';

=head1 SYNOPSIS

This is just an example module.

=head1 VERSION

=head1 REQUIRED MODULES

=head1 INSTALLATION

=head1 COPYRIGHT


More text.
EOD
    ok( close OUT, "Failed to close $_.pm: $!" );
    ok( -e "$_.pm", "Check if $_.pm exists" );
}

ok( open( OUT, ">README" ), "Failed to open README for writing: $!" );
print OUT <<EOD;
Sample README file

Version:


Required Modules:


Installation:



More text.
EOD
ok( close OUT, "Failed to close README for writing: $!" );
ok( -e 'README', "Check if README exists" );

WriteMakefile (
 NAME           => "Foo",
 VERSION_FROM   => 'Foo.pm',
 PREREQ_PM      => { 'Bar' => '1.0', 'Baz' => 0},
);
ok( -e 'Makefile', "Check if Makefile exists" );

ok( open( IN, "README" ), "Failed to open README for reading: $!" );
is( do { local $/; <IN> }, <<EOD, "Check if README conversion successful" );
Sample README file

Version:
 1.01

Required Modules:
 Bar (1.0)
 Baz (any)

Installation:
This distribution contains two versions of the code: one maintenance version
for versions of perl < 5.014 (known as 'maint'), and the version currently in
development (known as 'blead').  The standard build for your perl version is:

 perl Makefile.PL
 make
 make test
 make install

This will try to test and install the "blead" version of the code.  If the
Perl version does not support the "blead" version, then the running of the
Makefile.PL will *fail*.  In such a case, one can force the installing of
the "maint" version of the code by doing:

 perl Makefile.PL maint

Alternately, if you want automatic selection behavior, you can set the
AUTO_SELECT_MAINT_OR_BLEAD environment variable to a true value.  On Unix-like
systems like so:

 AUTO_SELECT_MAINT_OR_BLEAD=1 perl Makefile.PL

If your perl does not support the "blead" version of the code, then it will
automatically install the "maint" version of the code.

Please note that any additional parameters will simply be passed on to the
underlying Makefile.PL processing.


More text.
EOD
ok( close IN, "Failed to close README: $!" );

ok( open( IN,"Foo.pm" ), "Failed to open Foo.pm for reading: $!" );
is( do { local $/; <IN> }, <<EOD, "Check if Foo.pm conversion successful" );
package Foo;
\$VERSION = '1.01';

=head1 SYNOPSIS

This is just an example module.

=head1 VERSION

This documentation describes version 1.01.

=head1 REQUIRED MODULES

 Bar (1.0)
 Baz (any)

=head1 INSTALLATION

This distribution contains two versions of the code: one maintenance version
for versions of perl < 5.014 (known as 'maint'), and the version currently in
development (known as 'blead').  The standard build for your perl version is:

 perl Makefile.PL
 make
 make test
 make install

This will try to test and install the "blead" version of the code.  If the
Perl version does not support the "blead" version, then the running of the
Makefile.PL will *fail*.  In such a case, one can force the installing of
the "maint" version of the code by doing:

 perl Makefile.PL maint

Alternately, if you want automatic selection behavior, you can set the
AUTO_SELECT_MAINT_OR_BLEAD environment variable to a true value.  On Unix-like
systems like so:

 AUTO_SELECT_MAINT_OR_BLEAD=1 perl Makefile.PL

If your perl does not support the "blead" version of the code, then it will
automatically install the "maint" version of the code.

Please note that any additional parameters will simply be passed on to the
underlying Makefile.PL processing.

=head1 COPYRIGHT


More text.
EOD
ok( close IN, "Failed to close Foo.pm: $!" );

my @file= grep { -e } ( qw(
 README
 Makefile
 MYMETA.json
 MYMETA.yml
), map { "$_.pm" } @modules );
is( unlink(@file), scalar @file, "Check if all files removed" );
1 while unlink @file; # multiversioned filesystems
