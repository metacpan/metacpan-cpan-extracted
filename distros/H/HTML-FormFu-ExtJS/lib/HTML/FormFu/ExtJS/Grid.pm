#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package HTML::FormFu::ExtJS::Grid;
BEGIN {
  $HTML::FormFu::ExtJS::Grid::VERSION = '0.090';
}

use base "HTML::FormFu::ExtJS";

use JavaScript::Dumper;
use Hash::Merge::Simple qw(merge);
use Scalar::Util 'blessed';

use utf8;

use strict;
use warnings;

use HTML::FormFu::Util qw/require_class/;

use Class::C3;

use Carp;

sub new {
	carp "HTML::FormFu::ExtJS::Grid is deprecated, please use HTML::FormFu::ExtJS instead";
	return next::method(@_);
}


1;

__END__
=pod

=head1 NAME

HTML::FormFu::ExtJS::Grid

=head1 VERSION

version 0.090

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

