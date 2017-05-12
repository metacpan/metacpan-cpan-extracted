#
#  $Id: DB.pm,v 1.9 2008/07/09 20:40:20 mprewitt Exp $
#  $Source: /usr/local/src/perllib/Tail/0.1/lib/File/SmartTail/RCS/DB.pm,v $
#
# DMJA, Inc <smarttail@dmja.com>
# 
# Copyright (C) 2003-2008 DMJA, Inc, File::SmartTail comes with 
# ABSOLUTELY NO WARRANTY. This is free software, and you are welcome to 
# redistribute it and/or modify it under the same terms as Perl itself.
# See the "The Artistic License" L<LICENSE> for more details.
package File::SmartTail::DB;

use strict;
use warnings;

use Fcntl qw(:DEFAULT :flock);

use constant MAX_RETRIES => 6;

if ( ! -d "/var/tmp/filestatus" ) {
    mkdir( "/var/tmp/filestatus", 01777 ) ||
	die "Unable to make status directory /var/tmp/filestatus [$!].\n";

    chmod( 01777, "/var/tmp/filestatus" );
}

{
    my %cache;
    sub new {
        my $type = shift;
        my %h = @_;

        my $statuskey = $h{statuskey} or
            LOG()->logdie( "required param: statuskey" );
        my $tietype = $h{tietype} || 'DB_File';
        my $cachekey = join "\0", $statuskey, $tietype;
        $cache{$cachekey} and return $cache{$cachekey};

        my $filename = "/var/tmp/filestatus/$statuskey";
        my $saverr = "";
        my $fullname = $filename . (($tietype eq 'NDBM_File') ? ".pag" : "");
        if (-f $fullname && open(FH, ">> $fullname ")) {
            my $count = 0;
            while (++$count < MAX_RETRIES) {
                last if flock(FH, LOCK_EX | LOCK_NB);
                $saverr = $!;
                sleep (2 ** $count);
            }
            LOG()->logdie( "Could not lock $filename in @{[MAX_RETRIES()]} attemps [$saverr].\n" ) 
                if ($count >= MAX_RETRIES);
            flock(FH, LOCK_UN | LOCK_NB);
            close FH;
        }

        my %STATUS;
        eval "use $tietype";
        die "Unable to use $tietype [$@]" if $@;
        my $STATFILE = tie( %STATUS, $tietype, $filename,
                         O_RDWR | O_CREAT, 0600 ) ||
                             LOG()->logdie( "Tie of status for $statuskey failed [$!].\n" );

        my $self = bless {
            STATUS => \%STATUS,
            STATFILE => $STATFILE,
            STATUSKEY => $statuskey,
            TIETYPE => $tietype,
        }, ref $type || $type;

        #
        # keep our own reference, so the logging object is
        # destroyed AFTER $self.
        #
        $self->{LOG} = LOG();

        $self->sync;

        return $cache{$cachekey} = $self;
    }
}

sub sync {
    my $self = shift;

    if ($self->{STATFILE} && $self->can('sync')) {
        eval {
            $self->{STATFILE}->sync
        };
    }
}

sub DESTROY {
    my $self = shift or return;

    $self->sync;
    # LOG()->debug( sub {
    #     my $tt = $self->{TIETYPE} || '';
    #     my $sf = $self->{STATFILE} || '';
    #     my $ds = $self->DumpStatus || '';
    #     "sub DESTROY: TIETYPE: $tt; STATFILE: $sf; $ds";
    # } );
    # delete $self->{STATFILE};     # undef necessary?
    # untie %{ $self->{STATUS} };   # will this do the right thing?
}

sub DumpStatus {
    my $self = shift or return;
    my %h = @_;

    my $indent = $h{indent};
    defined $indent or $indent = 1;

    my $tab = "\t" x $indent;

    my $sk = $self->{STATUSKEY} || '';
    my @k = $self->{STATUS} ? sort keys %{ $self->{STATUS} } : ();
    my @m = @k ? map "$_ =>\t$self->{STATUS}->{$_}", @k : ();
    return join "\n$tab", "STATUSKEY file: $sk:", @m;
}

{
    my $v;
    sub LOG {
        $v ||= require File::SmartTail::Logger && File::SmartTail::Logger::LOG();
    }
}

1;
