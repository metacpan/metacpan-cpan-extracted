package Devel::Profiler::Plugins::Template::Context;

use Template::Context;

use strict;
use warnings FATAL => qw(all);

#---------------------------------------------------------------------
# constants and global variables
#---------------------------------------------------------------------
our @ISA = qw(Template::Context);

use constant DEBUG => $ENV{DEVEL_PROFILER_PLUGIN_DEBUG} || 0;

# tell tt to use this package instead of Template::Context
# for directive parsing
$Template::Config::CONTEXT = __PACKAGE__;

# capture the real process() sub as a coderef
our $process;

BEGIN {
  our $process = *Template::Context::process{CODE};
};


#---------------------------------------------------------------------
# override Template::Context::process() with our own routine
# so we can inject Devel::Profiler magic
#---------------------------------------------------------------------
sub process {

  my $self = shift;

  my ($template, $params, $localize) = @_;

  # derive the name of the BLOCK as best we can
  my $name = $template;

  $name = $template->name()
    if ref $template && $template->isa('Template::Document');

  # make sure it's safe to use as a perl subroutine
  $name = Devel::Profiler::Plugins::Template::_tidy_sub($name);

  # now, create and instrument a new subroutine, based on the
  # name of the BLOCK.  the fully qualified subroutine looks like
  #   TT::INCLUDE::layout_2fframe_2fhead_2ett

  my $type    = $localize ? 'INCLUDE' : 'PROCESS';
  my $package = "TT::${type}";
  my $sub     = "${package}::${name}";

  # instrument this puppy...
  Devel::Profiler::Plugins::Template::_instrument($package, $sub,
                                                  $name, $process);

  # and remember to actually call it so it runs
  return $package->$name($self, @_);
};


1;

__END__
=head1 NAME

Devel::Profiler::Plugins::Template::Context - Devel::Profiler hooks for INCLUDE and PROCESS

=head1 SYNOPSIS

  use Devel::Profiler::Plugins::Template;  # enable TT hooks
  use Devel::Profiler;                     # required

  my $tt = Template->new();
  ...

=head1 DESCRIPTION

this is the class that implements C<PROCESS> and C<INCLUDE>
wrappers for Devel::Profiler and Template Toolkit.  you probably
want to see C<Devel::Profiler::Plugins::Template> instead.

=head1 SEE ALSO

C<Devel::Profiler>, C<Devel::Profiler::Plugins::Template>

=head1 AUTHOR

Geoffrey Young <geoff@modperlcookbook.org>

=head1 COPYRIGHT

Copyright (c) 2007, Geoffrey Young
All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
