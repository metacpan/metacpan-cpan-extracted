#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/SpaceMan/RCS/SMFreeBlock.pm,v 1.3 2007/02/05 05:48:33 claude Exp claude $
#
# copyright (c) 2006, 2007 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::SpaceMan::SMFreeBlock;

use strict;
use warnings;

use Carp;
use Genezzo::Util;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
#    $VERSION     = 1.00;
    # if using RCS/CVS, this may be preferred
    $VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    @ISA         = qw(Exporter);
    @EXPORT      = ( ); # qw(&NumVal);
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
#    @EXPORT_OK   = qw($Var1 %Hashit &func3 &func5);
    @EXPORT_OK   = (); 

}

our $GZERR = sub {
    my %args = (@_);

    return 
        unless (exists($args{msg}));

    if (exists($args{self}))
    {
        my $self = $args{self};
        if (defined($self) && exists($self->{GZERR}))
        {
            my $err_cb = $self->{GZERR};
            return &$err_cb(%args);
        }
    }

    my $warn = 0;
    if (exists($args{severity}))
    {
        my $sev = uc($args{severity});
        $sev = 'WARNING'
            if ($sev =~ m/warn/i);

        # don't print 'INFO' prefix
        if ($args{severity} !~ m/info/i)
        {
            printf ("%s: ", $sev);
            $warn = 1;
        }

    }
    # XXX XXX XXX
    print __PACKAGE__, ": ",  $args{msg};
#    print $args{msg};
#    carp $args{msg}
#      if (warnings::enabled() && $warn);
    
};


sub _init
{
    #whoami;
    #greet @_;
    my $self     = shift;
    my %required = (
                    blocknum        => "no blocknum !",
                    current_extent  => "no extent !",
                    extent_size     => "no extent size !",
                    extent_position => "no extent position!"
                    );

    my %optional = (
                    firstextent => 0,
                    newextent => 0
                    );
    
    my %args = (%optional,
                @_);

    return undef
        unless (Validate(\%args, \%required));

    $self->{blocknum}        = $args{blocknum};
    $self->{current_extent}  = $args{current_extent};
    $self->{extent_size}     = $args{extent_size};
    $self->{extent_position} = $args{extent_position};
    $self->{firstextent}     = $args{firstextent};
    $self->{newextent}       = $args{newextent};

    return 1;

}

sub new 
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };
    
#    whoami @_;
    my %args = (@_);
    return undef
        unless (_init($self,%args));

    if ((exists($args{GZERR}))
        && (defined($args{GZERR}))
        && (length($args{GZERR})))
    {
        # NOTE: don't supply our GZERR here - will get
        # recursive failure...
        $self->{GZERR} = $args{GZERR};
    }

    my $blessref = bless $self, $class;

    return $blessref;

} # end new

sub GetBlocknum
{
    my $self = shift;

    return $self->{blocknum};
}

sub GetCurrentExtent
{
    my $self = shift;

    return $self->{current_extent};
}
sub GetExtentSize
{
    my $self = shift;

    return $self->{extent_size};
}
sub GetExtentPosition
{
    my $self = shift;

    return $self->{extent_position};
}

sub IsNewExtent
{
    my $self = shift;

    return $self->{newextent};
}

sub IsFirstExtent
{
    my $self = shift;

    return $self->{firstextent};
}


1;  # don't forget to return a true value from the file

__END__

=head1 NAME

Genezzo::SpaceMan::SMFreeBlock.pm - FreeBlock Space Management

=head1 SYNOPSIS

 use Genezzo::SpaceMan::SMFreeBlock;

=head1 DESCRIPTION

SMFreeBlock is a data structure which describes the basic space
objects associated with each block.

=head1 FUNCTIONS

=over 4

=item GetBlocknum

=item GetCurrentExtent

=item GetExtentSize

=item IsNewExtent

=item IsFirstExtent

=back


=head2 EXPORT

=head1 TODO

=over 4

=item Under Construction

=back



=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

perl(1), L<Genezzo::SpaceMan::SMFile>, L<Genezzo::SpaceMan::SMExtent>.

Copyright (c) 2006, 2007 Jeffrey I Cohen.  All rights reserved.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

Address bug reports and comments to: jcohen@genezzo.com

For more information, please visit the Genezzo homepage 
at L<http://www.genezzo.com>

=cut
