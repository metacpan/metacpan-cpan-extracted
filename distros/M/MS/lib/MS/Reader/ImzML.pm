package MS::Reader::ImzML;

use strict;
use warnings;

use parent qw/MS::Reader::MzML/;

use Carp;
use File::stat;
use URI::file;

use MS::Reader::ImzML::Spectrum;
use MS::CV qw/:IMS/;

sub _pre_load {

    my ($self, @args) = @_;
    $self->SUPER::_pre_load(@args);
    $self->{__record_classes}->{spectrum} = 'MS::Reader::ImzML::Spectrum';
    return;

}

sub _post_load {

    my ($self, @args) = @_;

    $self->SUPER::_post_load(@args);

    # check IBD file integrity
    if ($self->{__paranoid}) {
        # check IBD hash
        my $ref = $self->{fileDescription}->{fileContent};
        my $sha1 = $self->param(IMS_IBD_SHA_1, ref => $ref);
        my $md5  = $self->param(IMS_IBD_MD5,   ref => $ref);
        if (defined $sha1) {
            require Digest::SHA;
            my $h = Digest::SHA->new(1);
            $h->addfile($self->{__fn_ibd});
            croak "IBD SHA-1 mismatch" if (lc($sha1) ne lc($h->hexdigest));
        }
        elsif (defined $md5) {
            require Digest::MD5;
            my $h = Digest::MD5->new();
            $h->addfile($self->{__fn_ibd});
            croak "IBD SHA-1 mismatch" if (lc($md5) ne lc($h->hexdigest));
        }
        else { croak "Missing IBD checksum cvParam" }
    }
    else {
        # Check statsum
        my $st = stat( $self->{__fn_ibd} );
        my $statsum = $st->size . $st->mtime;
        croak "IBD statsum mismatch" if ($self->{__ibd_statsum} ne $statsum);
    }

    # open IBD filehandle
    open my $fh, '<', $self->{__fn_ibd}
        or croak "Error opening IBD file: $@";
    $self->{__fh_ibd} = $fh;

    # check UUID
    my $r = read($fh, my $given, 16);
    croak "Read count mismatch" if ($r != 16);
    croak "IBD UUID mismatch"
        if ( lc(unpack('H*', $given)) ne lc($self->{__ibd_uuid}) );

    return;

}

sub _write_index {

    my ($self) = @_;

    my $fh = $self->{__fh_ibd};
    $self->{__fh_ibd} = undef;
    $self->SUPER::_write_index();
    $self->{__fh_ibd} = $fh;

    return;

}

sub next_spectrum {

    my ($self, @args) = @_;

    my $s = $self->SUPER::next_spectrum(@args);
    return undef if (! defined $s);
    # the spectrum will need access to the binary filehandle
    $s->{__fh_ibd} = $self->{__fh_ibd};

    return $s;

}

sub fetch_spectrum {

    my ($self, @args) = @_;

    my $s = $self->SUPER::fetch_spectrum(@args);
    return undef if (! defined $s);
    # the spectrum will need access to the binary filehandle
    $s->{__fh_ibd} = $self->{__fh_ibd};

    return $s;

}

sub _load_new {

    my ($self, @args) = @_;

    $self->SUPER::_load_new(@args);

    # NOTE: <mzML> element hasn't been stripped yet
    my $ref = $self->{mzML}->{fileDescription}->{fileContent};

    # determine binary file type 
    $self->{__imzml_type}
        = defined $self->param(IMS_PROCESSED,  ref => $ref) ? 'processed'
        : defined $self->param(IMS_CONTINUOUS, ref => $ref) ? 'continuous'
        : croak "unknown imzML type";

    # check for existence of IBD
    my $fn_ibd;
    my $uri_ibd = $self->param(IMS_EXTERNAL_BINARY_URI, ref => $ref);
    if (defined $uri_ibd) {
        $fn_ibd = URI::file->new($uri_ibd)->file;
    }
    else {
        $fn_ibd = $self->{__fn};
        $fn_ibd =~ s/\.gz$//i;
        $fn_ibd =~ s/\.[^\.]+$/\.ibd/;
        croak "Unexpected input filename" if ($fn_ibd eq $self->{__fn});
    }
    croak "Failed to located IBD file" if (! -e $fn_ibd);
    $self->{__fn_ibd} = $fn_ibd;

    # check IBD hash
    my $sha1 = $self->param(IMS_IBD_SHA_1, ref => $ref);
    my $md5  = $self->param(IMS_IBD_MD5,   ref => $ref);
    if (defined $sha1) {
        require Digest::SHA;
        my $h = Digest::SHA->new(1);
        $h->addfile($fn_ibd);
        croak "IBD SHA-1 mismatch" if (lc($sha1) ne lc($h->hexdigest));
    }
    elsif (defined $md5) {
        require Digest::MD5;
        my $h = Digest::MD5->new();
        $h->addfile($fn_ibd);
        croak "IBD SHA-1 mismatch" if (lc($md5) ne lc($h->hexdigest));
    }
    else { croak "Missing IBD checksum cvParam" }

    # Use a simple/fast file check (file size + mod time)
    my $st = stat($fn_ibd);
    my $statsum = $st->size . $st->mtime;
    $self->{__ibd_statsum} = $statsum;

    # store IBD UUID
    my $uuid = $self->param(IMS_UNIVERSALLY_UNIQUE_IDENTIFIER, ref => $ref);
    croak "Missing IBD UUID cvParam" if (! defined $uuid);
    $uuid =~ s/[\{\}\-]//g;
    $self->{__ibd_uuid} = $uuid;

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::ImzML - A simple but complete imzML parser

=head1 SYNOPSIS

    use MS::Reader::ImzML;

    my $run = MS::Reader::ImzML->new('run.imzML');

    while (my $spectrum = $run->next_spectrum) {

        # see MS::Reader::ImzML::Spectrum, MS::Reader::MzML::Spectrum and
        # MS::Spectrum for all available methods

    }

    $spectrum = $run->fetch_spectrum(0);  # first spectrum
    $spectrum = $run->find_by_time(1500); # in seconds


=head1 DESCRIPTION

C<MS::Reader::ImzML> is a parser for the standard imzML format for raw imaging
mass spectrometry data. It aims to provide complete access to the data
contents while not being overburdened by detailed class infrastructure.

C<MS::Reader::ImzML> provides a fairly thin layer on top of
L<MS::Reader::MzML>, from which it inherits, in order to handle reading of
binary data from separate files (and associated file checks, etc) as well as
returning L<MS::Reader::ImzML::Spectrum> objects which add several imaging
MS-specific methods.

=head1 METHODS

C<MS::Reader::ImzML> is a subclass of L<MS::Reader::MzML> and does not add any
additional methods. Please see the documentation for that class for
documentation of available methods.

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 SEE ALSO

=over 4

=item * L<http://www.imzml.org>

=back

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2016 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
