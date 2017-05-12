package Devel::Profiler::Plugins::Template;

use 5.006_001;

use Devel::Profiler::Plugins::Template::Context;

use strict;
use warnings FATAL => qw(all);

#---------------------------------------------------------------------
# constants and global variables
#---------------------------------------------------------------------
our $VERSION = 0.01;

use constant DEBUG => $ENV{DEVEL_PROFILER_PLUGIN_DEBUG} || 0;


#---------------------------------------------------------------------
# make sure that a named subroutine consists of only characters
# perl likes in subroutines.
# stolen directly from ModPerl::RegistryCooker
#---------------------------------------------------------------------
sub _tidy_sub {

  my $name = shift;

  # translate the name into a suitable name for a perl subroutine
  # stolen directly from ModPerl::RegistryCooker
  $name =~ s/([^A-Za-z0-9_])/sprintf("_%2x", unpack("C", $1))/eg;
  $name =~ s/^(\d)/_$1/;

  print STDERR __PACKAGE__ . join ' ', "::_tidy_sub() returned",
                                       "$name\n"
    if DEBUG;

  return $name;
}


#---------------------------------------------------------------------
# call Devel::Profiler::instrument()
#---------------------------------------------------------------------
sub _instrument {

  my $package = shift;
  my $sub     = shift;
  my $name    = shift;

  our $cv     = shift;

  # don't re-instrument the block - it throws off our counts
  {
    no strict;
    return if defined *{$sub}{CODE};
  }

  # stick the BLOCK in its own package so Devel::Profiler has
  # something to wrap

  my $eval = <<"EOF";
    package $package;
    sub $name { shift; \$cv->(\@_) };
    1;
EOF

  print STDERR __PACKAGE__ . join ' ', "::_instrument() eval'ing",
                                       "$eval\n"
    if DEBUG;

  eval $eval;

  die $@ if $@;

  # finally, call instrument()
  {
    no strict;
    Devel::Profiler::instrument("${package}::", $name, *{$sub}{CODE});
  }

  print STDERR __PACKAGE__ . join ' ', "::_instrument() instrumented",
                                       "${package}::${name}\n"
    if DEBUG;
}

1;


__END__
=head1 NAME

Devel::Profiler::Plugins::Template - gather tmon.out data for Template Toolkit templates

=head1 SYNOPSIS

  use Devel::Profiler::Plugins::Template;  # enable TT hooks
  use Devel::Profiler;                     # required

  my $tt = Template->new();
  ...

=head1 DESCRIPTION

C<Devel::Profiler::Plugins::Template> wraps various Template Toolkit
calls in such a way that they are captured by Devel::Profiler
and added to C<tmon.out>, thus making them visible through
C<dprofpp>.  much hackery is involved, so it's not guaranteed
to work on all platforms, versions of perl, or versions of TT.
but if it does work, your C<dprofpp> results will look like this

  %Time ExclSec CumulS #Calls sec/call Csec/c  Name
   3.20   0.048  0.048   1794   0.0000 0.0000  Encode::_utf8_on
   1.27   0.019  0.028      2   0.0095 0.0140  TT::PROCESS::get_standard_nav
   0.00   0.000  0.000      2   0.0000 0.0000  TT::INCLUDE::layout_2fframe_2fhead_2ett

which corresponds to something like

  [% BLOCK get_standard_nav %]
    ...
  [% END %]

  [% PROCESS get_standard_nav %]
  [% INCLUDE layout/frame/head.tt %]

note that the TT results are right alongside of your normal perl calls,
which I find very convenient.  

currently, only C<PROCESS> and C<INCLUDE> blocks are instrumented.
hopefully this list will grow over time.

=head1 CAVEATS

this module contains a number of hacks just to get things working
at all, so it may not work for you.  but it is working well at work,
and if you ever saw our code you'd say that's probably a good enough
test.

oh, and this probably won't work so well unless you have the current
Devel::Profiler code from svn:

  http://sourceforge.net/projects/devel-profiler/

but it might.

=head1 SEE ALSO

C<Devel::Profiler>, C<Devel::Profiler::Plugins::Template::Context>

=head1 AUTHOR

Geoffrey Young <geoff@modperlcookbook.org>

=head1 COPYRIGHT

Copyright (c) 2007, Geoffrey Young
All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
