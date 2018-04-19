package Linux::Perl::aio::bits64;

use strict;
use warnings;

use parent 'Linux::Perl::aio';

use Linux::Perl::EasyPack;

use constant {
    _context_template => 'Q',
};

sub unpack_context { unpack _context_template(), $_[1] }

my ($keys_ar, $pack);
sub io_event_pack { $pack }
sub io_event_keys { @$keys_ar }

BEGIN {
    my @_io_event_src = (
        data => 'Q',
        obj  => 'Q',
        res  => 'q',
        res2 => 'q',
    );

    ($keys_ar, $pack) = Linux::Perl::EasyPack::split_pack_list(@_io_event_src);
}

#----------------------------------------------------------------------

package Linux::Perl::aio::Control::bits64;

use parent -norequire => 'Linux::Perl::aio::Control';

use Linux::Perl::EasyPack;
use Linux::Perl::Endian;

my ($iocb_keys_ar, $iocb_pack);
sub iocb_pack { $iocb_pack }
sub iocb_keys { @$iocb_keys_ar }

BEGIN {
    my @_iocb_src = (
        data => 'Q',    #aio_data

        (
            Linux::Perl::Endian::SYSTEM_IS_BIG_ENDIAN()
            ? (
                rw_flags => 'L',
                key => 'L',
            )
            : (
                key => 'L',
                rw_flags => 'L',
            )
        ),

        lio_opcode => 'S',
        reqprio    => 's',
        fildes     => 'L',

        #Would be a P, but we grab the P and do some byte arithmetic on it
        #for the case of a buffer_offset.
        buf => 'Q',

        nbytes => 'Q',

        offset => 'q',

        reserved2 => 'x8',

        flags => 'L',
        resfd => 'L',
    );

    ($iocb_keys_ar, $iocb_pack) = Linux::Perl::EasyPack::split_pack_list(@_iocb_src);
}

sub unpack_pointer { unpack 'Q', $_[1] }

1;
