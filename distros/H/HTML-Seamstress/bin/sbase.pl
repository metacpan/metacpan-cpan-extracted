#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Cwd;
use HTML::Seamstress;
use File::Basename;
use File::Path;
use File::Slurp;
use File::Spec;
use Data::Dumper;
use Pod::Usage;

our $VERSION = 1.0;

my $_P = 'HTML::Seamstress::Base' ;

print "
I want to generate $_P and save it somewhere on 
\@INC so that it can be found by Perl. 
Here are your choices:\n\n";



my $INC;
printf("%2d - $_\n", $INC++) for (grep { $_ !~ /^[.][.]?$/ } @INC) ;

print "Enter the number of your choice: ";
my $dir = <STDIN>;
my $incdir = $INC[$dir];

my $outdir = "$incdir/HTML/Seamstress";

eval { mkpath [$outdir] };

if ($@) {
  die "I'm sorry. I could not make $outdir
Why dont you try mkdir -p $outdir
for me and then restart.
"
}

sub template {
  my $comp_root = shift;
sprintf
'package HTML::Seamstress::Base;

use base qw(HTML::Seamstress);

use vars qw($comp_root);

BEGIN {
  $comp_root = "%s"; # IMPORTANT: last character must be "/"
}

use lib $comp_root;

sub comp_root { $comp_root }

1;', $comp_root;

}


sub comp_root {
  print "
Ok, now I need to know the directory *above*
where your HTML files are. If your files are
in /usr/htdocs/, I recommend you give me the 
directory /usr so that you can obtain your
HTML files via use htdocs::filename.

So, what is the absolute path to 
your document root? ";

  my $comp_root=<STDIN>;
  chomp $comp_root;

#  $comp_root .= "/" 
#      unless ($comp_root =~ m!/$!);

  $comp_root;
}

my $outfile = "$outdir/Base.pm";

open  O, ">$outfile" or die "Could not write to $outfile: $!";
our  $C = comp_root;
print O template($C);

print "$_P has been written to $outdir as $outfile\n";









=head1 NAME

 sbase - Create class which will provide access to HTML files as modules

=head1 SYNOPSIS

 sbase $DOCUMENT_ROOT/..

=head1 DESCRIPTION

The first thing to never ever forget about L<HTML::Seamstress> is this:

 There is no magick *anywhere*

If you know object-oriented Perl and you are comfortable with
conceptualizing HTML as a tree, then you can never get
confused. Everything that Seamstress offers is based on improving the
synergy of these two powers.

So, let's look at one way to manipulate HTML, completely
Seamstress-free: 

 use HTML::TreeBuilder;
 my $tree = HTML::TreeBuilder->new_from_file('/usr/www/file.html');
 $tree->this;
 $tree->that;
 $tree->as_HTML;

Let's make it easier to find C<file.html>:

 package www::file;
 use base qw(HTML::Seamstress);

 sub new {
     HTML::TreeBuilder->new_from_file('/usr/www/file.html');
 }

So now our code is this:

 use www::file;
 my $tree = www::file->new;
 $tree->this;
 $tree->that;
 $tree->as_HTML;

Same amount of code. It's just we dont have to manage pathnames.

Now, Seamstress actually does something a little more flexible in the
package it creates for your class. Instead of a long absolute path,
it abstracts away the root of the absolute path, creating a class for
your HTML file like this:

 package www::file;
 use base qw(HTML::Seamstress::Base); # slight difference

 sub new {
     HTML::TreeBuilder->new_from_file(
       HTML::Seamstress::Base->comp_root() . 'file.html';
   )
 }

And the mainline code uses C<www::file> just as before.

So now we see some flexibility. The method
C<HTML::Seamstress::Base::comp_root()> can be
configured to return values based on configuration settings and can
vary based on deployment setup (e.g. production versus dev).

So, sbase creates the C<HTML::Seamstress::Base> package for you. It
will work fine for most setups. If your root is not hardcoded and must
be derived by a series of function calls, then simply modify
C<Base.pm> to fit your setup. Where I work, our Base class looks like
this: 


 package HTML::Seamstress::Base;
 use base qw(HTML::Seamstress);

 use Wigwam::Config;

 use vars     qw($comp_root);

 # put a "/" on end of path - VERY important
 BEGIN         { $comp_root = $Wigwam::Config{'PLAYPEN_ROOT'} . '/' }

 use lib         $comp_root;

 sub comp_root { $comp_root }

 1;


C<Wigwam> is a tool for specifying all software and file path
dependencies of your software: L<http://www.wigwam-framework.com>. So,
we get our 
