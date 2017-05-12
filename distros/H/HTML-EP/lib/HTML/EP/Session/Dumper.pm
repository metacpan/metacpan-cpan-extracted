# -*- perl -*-
#
#   HTML::EP	- A Perl based HTML extension.
#
#
#   Copyright (C) 1998    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#
############################################################################

require 5.004;
use strict;
use Data::Dumper ();
use Safe ();
use Fcntl ();
use Symbol ();


package HTML::EP::Session::Dumper;

sub new {
    my($proto, $ep, $id, $attr) = @_;
    my $session = { '_ep_data' => { 'fh' => $attr->{'fh'} } };
    bless($session, (ref($proto) || $proto));
}

sub Open {
    my($proto, $ep, $id, $attr) = @_;
    my $fh = Symbol::gensym();
    sysopen($fh, $id, Fcntl::O_RDWR()|Fcntl::O_CREAT())
	or die "Failed to open $id for writing: $!";
    flock($fh, Fcntl::LOCK_EX()) or die "Failed to lock $id: $!";
    return $proto->new($ep, $id, {'fh' => $fh}) if eof($fh);
    local $/ = undef;
    my $contents = <$fh>;
    die "Failed to read $id: $!" unless defined $contents;
    my $self = Safe->new()->reval($contents);
    die "Failed to eval $id: $@" if $@;
    die "Empty or trashed $id: Returned a false value" unless $self;
    $self->{'_ep_data'} = { 'fh' => $fh };
    bless($self, (ref($proto) || $proto));
}

sub Store {
    my($self, $ep, $id, $locked) = @_;
    my $data = delete $self->{'_ep_data'};
    my $fh = $data->{'fh'};
    (seek($fh, 0, 0)  and
     (print $fh (Data::Dumper->new([$self])->Indent(1)->Terse(1)->Dump()))  and
     truncate($fh, 0))
	or die "Failed to update $id: $!";
    if ($locked) {
	$self->{'_ep_data'} = $data;
    }
}


sub Delete {
    my($self, $ep, $id) = @_;
    if (-f $id) {
	unlink $id or die "Failed to delete $id: $!";
    };
}


1;

