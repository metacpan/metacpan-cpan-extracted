package Gfsm::XL;

use 5.008004;
use strict;
use warnings;
use Carp;
use AutoLoader;
use Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.11';

# we need Gfsm loaded
require Gfsm;

require XSLoader;
XSLoader::load('Gfsm::XL', $VERSION);

# Preloaded methods go here.
require Gfsm::XL::Cascade;
require Gfsm::XL::Cascade::Lookup;

# Autoload methods go after =cut, and are processed by the autosplit program.


##======================================================================
## Exports
##======================================================================
our @EXPORT      = qw();
our %EXPORT_TAGS = qw();

##======================================================================
## Constants
##======================================================================

##------------------------------------------------------------
## Constants: whatever

##======================================================================
## Exports: finish
##======================================================================
our @EXPORT_OK = map { @$_ } values(%EXPORT_TAGS);
#$EXPORT_TAGS{constants} = \@EXPORT_OK;


1;

__END__

# Below is stub documentation for your module. You'd better edit it!
=pod

=head1 NAME

Gfsm::XL - Perl interface to the libgfsmxl finite-state cascade library

=head1 SYNOPSIS

  use Gfsm;
  use Gfsm::XL;

  ##... stuff happens

=head1 DESCRIPTION

The Gfsm::XL module provides an object-oriented interface to the libgfsmxl
library for finite-state cascade lookup operations.

=head1 SEE ALSO

Gfsm(3perl),
perl(1),
gfsmutils(1),
fsm(1).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
