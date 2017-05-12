#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/BufCa/RCS/BufCaElt.pm,v 7.7 2006/10/20 18:52:16 claude Exp claude $
#
# copyright (c) 2003,2004,2005,2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::BufCa::BufCaElt;

use Genezzo::Util;
use Carp;
use warnings::register;

use Genezzo::BufCa::DirtyScalar;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
#    $VERSION     = 1.00;
    # if using RCS/CVS, this may be preferred
    $VERSION = do { my @r = (q$Revision: 7.7 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    @ISA         = qw(Exporter);
#    @EXPORT      = qw(&func1 &func2 &func4 &func5);
    @EXPORT      = ( );
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
#    @EXPORT_OK   = qw($Var1 %Hashit &func3 &func5);
    @EXPORT_OK   = ( );

}

our @EXPORT_OK;

# non-exported package globals go here


# initialize package globals, first exported ones
#my $Var1   = '';
#my %Hashit = ();

# then the others (which are still accessible as $Some::Module::stuff)
#$stuff  = '';
#@more   = ();

# all file-scoped lexicals must be created before
# the functions below that use them.

# file-private lexicals go here
#my $priv_var    = '';
#my %secret_hash = ();
# here's a file-private function as a closure,
# callable as &$priv_func;  it cannot be prototyped.
#my $priv_func = sub {
    # stuff goes here.
#};

# make all your functions, whether exported or not;
# remember to put something interesting in the {} stubs
#sub func1      {print "hi";}    # no prototype
#sub func2()    {}    # proto'd void
#sub func3($$)  {}    # proto'd to 2 scalars
#sub func5      {print "ho";}    # no prototype

sub _init
{
    #whoami;
    #greet @_;
    my $self = shift;

    my %required = (
                    blocksize => "no blocksize !"
                    );

    my %args = (
                @_);

    return 0
        unless (Validate(\%args, \%required));

    # XXX: a bit redundant to keep blocksize for each bce - should be
    # constant for entire cache...
    $self->{blocksize} = $args{blocksize};

    my $buf;
    $self->{tbuf}  = tie $buf, "Genezzo::BufCa::DirtyScalar";

    $buf = "\0" x $self->{blocksize};
    $self->{bigbuf} = \$buf;

    $self->{info}    = {}; # DEPRECATE: switch to Contrib

    # Contrib is the counterpart to the CPAN Genezzo::Contrib
    # namespace.  Add hash keys according to your package name, e.g.
    #   $self->{Contrib}->{Clustered} = 'foo' 
    # for Genezzo::Contrib::Clustered
    $self->{Contrib} = {}; # UNUSED until "info" is removed

    $self->{pin}    = 0;
    $self->{dirty}  = 0;

    $self->{file_read} = 0;

    return 1;
}

sub new 
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };

    my %args = (@_);

    return undef
        unless (_init($self,%args));

    my $foo = bless $self, $class;
    $self->_postinit();
    return $foo;

} # end new

sub _postinit
{
    my $self = shift;

    # supply a closure so the bce is marked dirty
    # if the underlying tied buffer gets overwritten
    my $foo = sub { $self->_dirty(1); };
    $self->{tbuf}->_StoreCB($foo);
    $self->{tbuf}->SetBCE($self); # DEPRECATE

}

sub _pin
{
# XXX: need atomic increment/decrement

    my $self = shift;

    if (scalar(@_))
    {
        my $pin_inc = shift;
#        whisper "pinning $pin_inc -> ";
        $self->{pin} += $pin_inc;
    }

    # XXX XXX XXX XXX: pin > 1 possible -- block zero (file header)
    # gets pinned multiple times

#    whisper "current pin val: ", $self->{pin};
    return $self->{pin};

} 

sub _dirty
{
    my $self = shift;
    $self->{dirty} = shift if @_ ;

    # HOOK: 
    # use sys_hook to define 
    if (defined(&_BCE_dirtyhook))
    {
        _BCE_dirtyhook($self, @_);
    }

    return $self->{dirty};

} 

sub _fileread
{
    my $self = shift;
    $self->{file_read} = shift if @_ ;

    return $self->{file_read};

} 

# DEPRECATE
sub GetInfo
{
    my $self = shift;
    return $self->{info};
}

sub GetContrib
{
    my $self = shift;
    return $self->{info};
}

sub RSVP
{
    my $self   = shift;

#    print "foo\n";

    my %args = @_;

    unless (exists($args{name}) &&
            exists($args{value}))
    {
        return undef;
    }

#    greet $args{name};
#    print $args{name},"\n";

    unless (exists($self->{info}->{mailbox}))
    {
        $self->{info}->{mailbox} = {};
    }

    $self->{info}->{mailbox}->{$args{name}} = $args{value};

#    whoami;

    return $self->{info};
}


END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE


1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::BufCa::BufCaElt - Buffer Cache Element

=head1 SYNOPSIS

=head1 DESCRIPTION

A Buffer Cache Element contains an actual datablock plus some minimal
state information: the blocksize, whether the block is in use, and
whether the contents have been modified.  BufCaElt clients can use
GetInfo() to store and retrieve a hash of arbitrary information for
each block.

=head1 ARGUMENTS

=head1 FUNCTIONS

=over 4

=item  GetInfo - return a reference to the info hash.  BCFile uses
       this hash to store the filenum/blocknum info associated with
       the current BufCaElt.

=item  GetContrib - return a reference to the info hash.  BCFile uses
       this hash to store the filenum/blocknum info associated with
       the current BufCaElt.

=item  _dirty - set/clear the "dirty" bit.  Used to indicate if buffer
       has been modified.

=item  _postinit - Pass a callback to the DirtyScalar tie so the "dirty" bit
       gets set automatically whenever the buffer is modified.  Also,
       pass a reference to $self so DirtyScalar can use GetInfo to find
       the current filenum/blocknum and any other interesting information.

=item  _pin - used to pin/unpin a block in the cache via the PinScalar tie.
       Blocks that are actively referenced must remain "pinned" in the
       buffer cache, but unreferenced blocks can be freed.  If they are
       "dirty", the modified buffer must be written to disk, else the
       BufCaElt can simply be re-used.

=back

=head2 EXPORT

=head1 LIMITATIONS

various

=head1 TODO

=over 4

=item Deprecate GetInfo, convert to GetContrib.

=item Switch syshook methods to use _BCE_dirtyhook

=item get fileno, blockno info

=item deal with multiple pins on same block sanely.  We shouldn't be
      maintaining a reference count scheme here.  Shouldn't pin be <= 1,
      and the destroy cb should set it to zero when last reference is
      garbage collected?

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2003, 2004, 2005, 2006 Jeffrey I Cohen.  All rights reserved.

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
