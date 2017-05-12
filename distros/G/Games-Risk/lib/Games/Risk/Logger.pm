#
# This file is part of Games-Risk
#
# This software is Copyright (c) 2008 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.010;
use strict;
use warnings;

package Games::Risk::Logger;
# ABSTRACT: logging capacities for prisk
$Games::Risk::Logger::VERSION = '4.000';
use Exporter::Lite;
use FindBin         qw{ $Bin };
use Path::Class;
use Term::ANSIColor qw{ :constants };
use Text::Padding;
 
our @EXPORT_OK = qw{ debug };



my $debug = -d dir($Bin)->parent->subdir('.git');
my $pad   = Text::Padding->new;
sub debug {
    return unless $debug;
    my ($pkg, $filename, $line) = caller;
    $pkg =~ s/^Games::Risk:://g;
    # BLUE and YELLOW have a length of 5. RESET has a length of 4
    my $prefix = $pad->right( BLUE . $pkg . YELLOW . ":$line" . RESET, 40);
    warn "$prefix @_";
}


1;

__END__

=pod

=head1 NAME

Games::Risk::Logger - logging capacities for prisk

=head1 VERSION

version 4.000

=head1 SYNOPSIS

    use Games::Risk::Logger qw{ debug };
    debug( "useful stuff" );

=head1 DESCRIPTION

This module provides some logging capacities to be used within prisk.

=head1 METHODS

=head2 debug( @stuff );

Output C<@stuff> on stderr if we're in a local git checkout. Do nothing
in regular builds.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
