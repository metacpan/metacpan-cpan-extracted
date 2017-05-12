package HTML::Template::JIT;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.05';

use Carp qw(croak);
use File::Spec;
use File::Path qw(rmtree mkpath);
use Digest::MD5 qw(md5_hex);

sub new {
  my $pkg = shift;
  
  croak(__PACKAGE__ . "::new() called with odd number of arguments")
    if @_ % 2;
  my %args = @_;

  croak(__PACKAGE__ . "::new() : called without required filename parameter")
    unless exists $args{filename};

  croak(__PACKAGE__ . "::new() : called without required jit_path parameter")
    unless exists $args{jit_path};
 
  croak(__PACKAGE__ . "::new() : jit_path \"$args{jit_path}\" does not exist!")
    unless -e $args{jit_path};

  croak(__PACKAGE__ . "::new() : jit_path \"$args{jit_path}\" is not a writable directory!")
    unless -d _ and -w _;

  # try to find the template file
  my $path = _find_file($args{filename}, $args{path} || []);
  croak(__PACKAGE__ . "::new() : unable to find template file \"$args{filename}\"")
    unless $path;

  # setup options we care about
  $args{global_vars}       ||= 0;
  $args{print_to_stdout}   ||= 0;
  $args{case_sensitive}    ||= 0;
  $args{loop_context_vars} ||= 0;

  # get a hash of the path and mtime.  hashing them together means
  # that everytime the template file is changed we'll get a new md5
  # and that'll force a recompile.
  my $path_md5     = md5_hex($path . (stat($path))[9] . $VERSION .
                             join(' ', $args{global_vars},
                                       $args{print_to_stdout},
                                       $args{loop_context_vars},
                                       $args{case_sensitive}));
  
  # compute package and filesystem details
  my $package      = "tmpl_$path_md5";      # package name
  my $package_dir  = File::Spec->catdir($args{jit_path}, $path_md5);
  my $package_path = File::Spec->catfile($package_dir, "$package.pm");

  print STDERR __PACKAGE__ . "::new() : found file : $path : $path_md5\n"
    if $args{jit_debug};

  print STDERR __PACKAGE__ . "::new() : attempting to load...\n"
    if $args{jit_debug};

  # try to load the module and return package handle if successful
  my $result;
  eval { $result = require $package_path; };
  if ($result) {
    $package->clear_params(); # need to clear out params from prior run
    return $package;
  }

  # die now if we can't compile
  croak(__PACKAGE__ . "::new() : no_compile is on but no compile form for $path is available!")
    if $args{no_compile};

  print STDERR __PACKAGE__ . "::new() : compiling...\n"
    if $args{jit_debug};

  # load the compiler
  require 'HTML/Template/JIT/Compiler.pm';

  # compile the template
  $result = HTML::Template::JIT::Compiler::compile(%args, 
						   package => $package, 
						   package_dir => $package_dir,
						   package_path => $package_path);
  croak(__PACKAGE__ . "::new() : Unable to compile $path.")
    unless $result;

  return $package;
}

# _find_file stolen from HTML::Template - needs to stay in sync but it
# would be a shame to have to load HTML::Template just to get it.
sub _find_file {
  my ($filename, $path) = @_;
  my $filepath;

  # first check for a full path
  return File::Spec->canonpath($filename)
    if (File::Spec->file_name_is_absolute($filename) and (-e $filename));

  # try pre-prending HTML_Template_Root
  if (exists($ENV{HTML_TEMPLATE_ROOT})) {
    $filepath =  File::Spec->catfile($ENV{HTML_TEMPLATE_ROOT}, $filename);
    return File::Spec->canonpath($filepath) if -e $filepath;
  }

  # try "path" option list..
  foreach my $path (@$path) {
    $filepath = File::Spec->canonpath(File::Spec->catfile($path, $filename));
    return File::Spec->canonpath($filepath) if -e $filepath;
  }

  # try even a relative path from the current directory...
  return File::Spec->canonpath($filename) if -e $filename;
  
  return undef;
}



1;
__END__

=pod

=head1 NAME

HTML::Template::JIT - a just-in-time compiler for HTML::Template

=head1 SYNOPSIS

  use HTML::Template::JIT;

  my $template = HTML::Template::JIT->new(filename => 'foo.tmpl',
                                          jit_path => '/tmp/jit',
                                         );
  $template->param(banana_count => 10);
  print $template->output();

=head1 DESCRIPTION

This module provides a just-in-time compiler for HTML::Template.  The
module works in two phases:

=over 4

=item Load

When new() is called the module checks to see if it already has an
up-to-date version of your template compiled.  If it does it loads the
compiled version and returns you a handle to call param() and
output().

=item Compile

If your template needs to be compiled - either because it has changed
or because it has never been compiled - then HTML::Template::JIT loads
HTML::Template::JIT::Compiler which uses HTML::Template and Inline::C
to compile your template to native machine instructions.  

The compiled form is saved to disk in the jit_path directory and
control returns to the Load phase.

=back

This may sound a lot like the way HTML::Template's cache mode works
but there are some significant differences:

=over 4

=item *

The compilation phase takes a long time.  Depending on your system it
might take several seconds to compile a large template.

=item *

The resulting compiled template is much faster than a normal cached
template.  My benchmarks show HTML::Template::JIT, with a precompiled
template, performing 4 to 8 times faster than HTML::Template in
cache mode.

=item *

The resulting compiled template should use less memory than a normal
cached template.  Also, if all your templates are already compiled
then you don't even have to load HTML::Template to use the templates!

=back

=head1 USAGE

Usage is the same as normal HTML::Template usage with a few addition
new() options.  The new options are:

=over 4

=item jit_path

This is the path that the module will use to store compiled modules.
It needs to be both readable and writeable.  This directory will
slowly grow over time as templates are changed and recompiled so you
might want to periodically clean it out.  HTML::Template::JIT might
get better at cleaning-up after itself in a future version.

=item no_compile

This option tells the module to never compile templates.  If it can't
find a compiled version of a template then it croak()s rather than
load HTML::Template::JIT::Compiler.  You might want to use this option
if you've precompiled your templates and want to make sure your users
are never subjected to the lag of a compiler run.

=item jit_debug

Spits out a bunch of obscure debugging on STDERR.  Note that you'll
need to have a working version of the C<indent> utility in your path
to use this option.  HTML::Template::JIT uses C<indent> to make
generated C code readable.

=item print_to_stdout

A special version of the HTML::Template print_to option is available
to print output to stdout rather than accumulating in a variable.  Set
this option to 1 and output() will print the template contents
directly to STDOUT.  Defaults to 0.

NOTE: Using print_to_stdout will result in significant memory savings
for large templates.  However my testing shows a slight slowdown in
overall performance compared to normal HTML::Template::JIT usage.

=back

=head1 CAVEATS

This version is rather limited.  It doesn't support the following options:

   cache (all modes)
   associate
   print_to
   scalarref (and friends)
   arrayref  (and friends)
   die_on_bad_params

Included files are not checked for changes when checking a compiled
template for freshness.

CODE-ref params are not supported.  

The query() method is not supported.

It's not as fast as it could be - I'd like to see it reach somewhere
around 10x faster than normal HTML::Template.

I wouldn't expect this module to work with UTF-8 unless your C
compiler will accept UTF-8 inside C strings.  I think that would be a
violation of the C standard, so I think I need to do some work here
instead.

As development progresses I hope to eventually address all of these
limitations.

=head1 BUGS

When you find a bug join the mailing list and tell us about it.  You
can join the HTML::Template mailing-list by visiting:

  http://lists.sourceforge.net/lists/listinfo/html-template-users

Of course, you can still email me directly (sam@tregar.com) with bugs,
but I reserve the right to forward bug reports to the mailing list.

When submitting bug reports, be sure to include full details,
including the VERSION of the module, a test script and a test template
demonstrating the problem!

=head1 AUTHOR

Sam Tregar <sam@tregar.com>

=head1 LICENSE

HTML::Template::JIT : Just-in-time compiler for HTML::Template

Copyright (C) 2001 Sam Tregar (sam@tregar.com)

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version,
or

b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
module, in the file ARTISTIC.  If not, I'll be glad to provide one.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

