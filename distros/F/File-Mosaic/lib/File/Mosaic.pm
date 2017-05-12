# $Id: Mosaic.pm 2466 2006-06-14 22:30:52Z cboumeno $
######################################################################
#
# This program is Copyright 2006-2007 by Christopher Boumenot 
# <boumenot@gmail.com>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the same license as Perl.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# 
######################################################################

package File::Mosaic;

require 5.006;
use strict;
use warnings;

our $VERSION = '0.03';

use IO::File;
use File::Spec;
use File::Path;
use Digest::MD5;
use Storable;
use Data::Dumper;
use Log::Log4perl qw(:easy get_logger);
use Carp;

sub new {
    my ($class, %options) = @_;

    unless (defined $options{filename}) {
        confess "%Error: the parameter 'filename' is mandatory!\n";
    }

    unless (defined $options{mosaic_directory}) {
        confess "%Error: the paramter 'mosaic_directory' is mandatory\n";
    }

    my $self = {
        'mosaic_file'   => '.mosaics',
        '_mosaics'      => {},
        '_count'        =>  0,
        '_is_closed'    =>  0,
        %options,
    };

    unless (-d $self->{mosaic_directory}) {
        File::Path::mkpath($self->{mosaic_directory});
    }

    $self->{mosaic_path} = File::Spec->catfile($self->{mosaic_directory}, $self->{mosaic_file});

    bless $self, $class;

    if (-f $self->{mosaic_path}) {
        $self->_load_mosaic_directory();
    }

    return $self;
}

sub DESTROY {
    my ($self) = @_;
    unless ($self->{_is_closed}) {
        $self->close();
    }
}

sub append {
    my $self = shift;
    my %options = (
        tag    => undef,
        mosaic => undef,
        @_,
    );

    my $tag       = $options{tag};
    my $mosaic    = $options{mosaic};

    confess "%Error: 'tag' is a mandatory parameter!\n" unless defined $tag;
    confess "%Error: 'mosaic' is a mandatory parameter!\n" unless defined $mosaic;

    DEBUG( sub { "append: tag => $tag\n" });

    $self->{_mosaics}->{$tag}->{data}  = $mosaic;
    $self->{_mosaics}->{$tag}->{count} = $self->{_count}++;

    $self->_add_digest_tag($tag, $mosaic);
}

sub insert_before {
    my $self = shift;
    my %options = (
        tag        => undef,
        before_tag => undef,
        mosaic     => undef,
        @_,
    );

    my $tag        = $options{tag};
    my $mosaic     = $options{mosaic};
    my $before_tag = $options{before_tag};

    confess "%Error: 'tag' is a mandatory parameter!\n" unless defined $tag;
    confess "%Error: 'mosaic' is a mandatory parameter!\n" unless defined $mosaic;
    confess "%Error: 'before_tag' is a mandatory parameter!\n" unless defined $before_tag;

    confess "%Error: the tag '$tag' already exist!" if $self->_valid_tag($tag);
    confess "%Error: the tag '$before_tag' does not exists!" unless $self->_valid_tag($before_tag);

    DEBUG( sub { "insert_before: tag => $tag, before_tag => $before_tag\n" });

    my $count = $self->{_mosaics}->{$before_tag}->{count};
    $self->_insert($tag, $count, $mosaic);
}

sub insert_after {
    my $self = shift;
    my %options = (
        tag        => undef,
        after_tag  => undef,
        mosaic     => undef,
        @_,
    );

    my $tag       = $options{tag};
    my $mosaic    = $options{mosaic};
    my $after_tag = $options{after_tag};

    confess "%Error: 'tag' is a mandatory parameter!\n" unless defined $tag;
    confess "%Error: 'mosaic' is a mandatory parameter!\n" unless defined $mosaic;
    confess "%Error: 'after_tag' is a mandatory parameter!\n" unless defined $after_tag;

    confess "%Error: the tag '$tag' already exist!" if $self->_valid_tag($tag);
    confess "%Error: the tag '$after_tag' does not exist!" unless $self->_valid_tag($after_tag);

    DEBUG( sub { "insert_after: tag => $tag, after_tag => $after_tag\n" });

    my $count = $self->{_mosaics}->{$after_tag}->{count} + 1;
    $self->_insert($tag, $count, $mosaic);
}

sub replace {
    my $self = shift;
    my %options = (
        tag        => undef,
        mosaic     => undef,
        @_,
    );

    my $tag        = $options{tag};
    my $mosaic     = $options{mosaic};

    confess "%Error: 'tag' is a mandatory parameter!\n" unless defined $tag;
    confess "%Error: 'mosaic' is a mandatory parameter!\n" unless defined $mosaic;
    confess "%Error: the tag '$tag' does not exist!" unless $self->_valid_tag($tag);

    DEBUG( sub { "replace: tag => $tag\n" });

    $self->{_mosaics}->{$tag}->{data} = $mosaic;
    $self->{_mosaics}->{$tag}->{sum}  = $self->_digest_tag($tag, $mosaic);
}

sub remove {
    my $self = shift;
    my %options = (
        tag        => undef,
        @_,
    );

    my $tag        = $options{tag};

    confess "%Error: 'tag' is a mandatory parameter!\n" unless defined $tag;
    confess "%Error: the tag '$tag' does not exist!" unless $self->_valid_tag($tag);

    DEBUG( sub { "remove: tag => $tag\n" });

    $self->{_count}--;

    delete $self->{_mosaics}->{$tag};

    $self->_increment_counts($tag, -1);
}

sub fetch {
    my $self = shift;
    my %options = (
        tag        => undef,
        @_,
    );

    my $tag = $options{tag} or confess "%Error: 'tag' is a mandatory parameter!\n";
    confess "%Error: the tag '$tag' does not exist!" unless $self->_valid_tag($tag);

    DEBUG( sub { "fetch: tag => $tag\n" });

    my $count = $self->{_mosaics}->{$tag}->{count};
    return $self->{_mosaics}->{$tag}->{data};
}

sub fetch_tags {
    my $self = shift;

    my @tags;
    for (sort {$self->{_mosaics}->{$a}->{count} <=> 
               $self->{_mosaics}->{$b}->{count}} keys %{$self->{_mosaics}}) {
        push @tags, $_;
    }

    return (wantarray) ? @tags : \@tags;
}

sub reorder_tags {
    my $self = shift;
    my %options = (
        tags       => undef,
        @_,
    );

    my $tags = $options{tags} or confess "%Error: 'tags' is a mandatory parameter!\n";

    for my $tag (@$tags) {
        confess "%Error: the tag '$tag' does not exist!" unless $self->_valid_tag($tag);
    }

    for my $i (0..scalar(@$tags)-1) {
        my $tag = $tags->[$i];
        $self->{_mosaics}->{$tag}->{count} = $i;
    }
}


sub close {
    my ($self) = @_;

    $self->_write_file();
    $self->_write_mosaics();
    $self->_write_mosaic_file();
    
    $self->{_is_closed} = 1;
}

##################################################
## PRIVATE
##################################################

sub _write_file {
    my ($self) = @_;

    my $fouth = IO::File->new(">$self->{filename}") or
            confess "%Error: $! '$self->{filename}'!\n";

    DEBUG( sub { "_write_file:\n" . Dumper($self) });
        
    for my $tag (sort { $self->{_mosaics}->{$a}->{count} <=> 
                        $self->{_mosaics}->{$b}->{count} }
                 keys %{$self->{_mosaics}}) {
        
        DEBUG( sub { "_write_file: tag => $tag\n" });
        print $fouth $self->{_mosaics}->{$tag}->{data};
    }

    $fouth->close();
}

sub _write_mosaics {
    my ($self) = @_;

    for my $tag (keys %{$self->{_mosaics}}) {
        my $mosaic = $self->{_mosaics}->{$tag}->{data};
        my $sum = $self->_digest_tag($tag, $mosaic);
        my $fn  = File::Spec->catfile($self->{mosaic_directory}, $sum);

        my $fouth = IO::File->new(">$fn") or
            confess "%Error: $! '$fn'!\n";

        print $fouth $mosaic;
        
        $fouth->close();
    }
}

sub _write_mosaic_file {
    my ($self) = @_;
    store $self->{_mosaics}, $self->{mosaic_path};
}

sub _valid_tag {
    my ($self, $tag) = @_;
    my $rc = (defined $self->{_mosaics}->{$tag}) ? 1 : 0;
    DEBUG(sub { "_valid_tag: tag => $tag\n" . Dumper($self) }) unless $rc;
    return $rc;
}

sub _digest_tag {
    my ($self, $tag, $mosaic) = @_;

    my $ctx = Digest::MD5->new;
    $ctx->add($tag);
    $ctx->add($mosaic);
    my $sum = $ctx->hexdigest;

    return $sum;
}

sub _add_digest_tag {
    my ($self, $tag, $mosaic) = @_;

    my $sum = $self->_digest_tag($tag, $mosaic);
    $self->{_mosaics}->{$tag}->{sum} = $sum;
}

sub _insert {
    my ($self, $tag, $count, $mosaic) = @_;

    DEBUG( sub { "_insert: tag => $tag, count => $count\n" });

    $self->_increment_counts($count);
    $self->{_mosaics}->{$tag}->{count} = $count;
    $self->{_mosaics}->{$tag}->{data}  = $mosaic;

    $self->_add_digest_tag($tag, $mosaic);
}

sub _increment_counts {
    my ($self, $count, $offset) = @_;

    $offset = 1 unless defined $offset;
    
    for my $tag (keys %{$self->{_mosaics}}) {
        if ($self->{_mosaics}->{$tag}->{count} >= $count) {
#             DEBUG( sub { "_increment
            $self->{_mosaics}->{$tag}->{count} += $offset;
            }
    }
}

sub _load_mosaic_directory {
    my ($self) = @_;

    $self->_load_mosaic_file();
    
    my $count = 0;
    for my $tag (sort { $self->{_mosaics}->{$a}->{count} <=> 
                        $self->{_mosaics}->{$b}->{count} }
                 keys %{$self->{_mosaics}}) {

        my $count = $self->{_mosaics}->{$tag}->{count};
        my $sum   = $self->{_mosaics}->{$tag}->{sum};

        DEBUG( sub { "_load_mosaic_directory: tag => $tag, count => $count\n" });

        my $mfn = File::Spec->catfile($self->{mosaic_directory}, $sum);
        confess "%Error: a mosaic file, '$mfn', is missing!\n" unless -f $mfn;

        $self->{_mosaics}->{$tag}->{count} = $count;
        $self->{_mosaics}->{$tag}->{data}  = $self->_slurp_file($mfn);
    }
}

sub _load_mosaic_file {
    my ($self) = @_;

    $self->{_mosaics} = retrieve($self->{mosaic_path}) or
        confess "%Error: $! '$self->{mosaic_path}'!\n";
}

sub _slurp_file {
    my ($self, $fn) = @_;
    
    local $/;
    my $finh = IO::File->new($fn) or
        confess "%Error: $! '$fn'!\n";

    my $mosaic = <$finh>;

    $finh->close();

    return $mosaic;
}


#######################################################################
1;
__END__

=pod

=head1 NAME

File::Mosaic - assemble the constituent pieces of a file into a single file.

=head1 SYNOPSIS

 use File::Mosaic;

 my $m = File::Mosaic->new(filename         => "/etc/dhcpd.conf", 
                           mosaic_directory => "/etc/dhcpd.conf.mosaic");

 $m->append(tag => 'begin', mosaic => "# dhcpd.conf\n");

 my $subnet;
 $subnet .= "subnet 192.168.1.1 netmask 255.255.255.0 {\n";
 $subnet .= "    option routers 192.168.1.1;\n";
 $subnet .= "    range 192.168.1.100 192.168.1.254;\n";
 $subnet .= "}\n\n";

 $m->append(tag => 'subnet1', mosaic => $subnet);
 $m->append(tag => 'begin', mosaic => "# dhcpd.conf\n");

 my $host;
 $host .= "host test {\n";
 $host .= "    hardware ethernet ff:ff:ee:00:00:01;\n";
 $host .= "    fixed-address 192.168.1.25;\n";
 $host .= "}\n";

 $m->insert_after(tag => 'host1', after_tag => 'subnet1', mosaic => $host);
 $m->close();

=head1 DESCRIPTION

C<File::Mosaic> is a Perl module to assemble a target file from smaller files.
The creation, maintenance, and order of the small files, as well as the
assembling of the target file are handled by the library.  Data for the small
files are added by the user along with a tag.  The tags are used to determine
position within the target file.  Users have the ability to add data before, or
after a tag, as well as at the end of the file.  Tags can be removed, and the
data attached to a tag can be fetchied using the methods of the class.

The motivation for creating this library was due to all of the auto-generated
files I have to deal with.  The files almost always have a static header, and
footer, but with some piece of data constantly being added and or removed from
the middle.  Updating a single entry would require the entire regeneration of
the file, but unfortunatley I can't always guarantee the state of the entries
at the time of regeneration.  Ideally, I just want to update my entry, and my
entry only.

=head1 METHODS

=over 4

=item new

=item append(tag, mosaic)

Append the tag, and mosaic to the end of the file.

=item insert_before(tag, before_tag, mosaic)

Insert the tag, and mosaic before the tag before_tag.

=item insert_after(tag, after_tag, mosaic)

Insert the tag, and mosaic after the tag after_tag.

=item replace(tag, mosaic)

Replace the mosaic at tag, with the user supplied mosaic.

=item remove(tag)

Remove the tag from the file.

=item fetch(tag)

Return the mosaic located at the tag.

=item fetch_tags()

Return an array or array ref of all of the current tags.

=item reorder_tags(tags)

Use the tags array to reorder the position of the current tags.  The position
in the array determines the position of the tags.  The tag at index 0 of tags
it put at the beginning of the file.  Likewise the tag at index -1 of tags it
put at the end of the file.

=item close

Close the mosaic file, save all of the tag and mosaic information, and
reconstruct the file based on the current information.

=back

=head1 AUTHORS

Christopher Boumenot E<lt>boumenot@gmail.comE<gt>

=cut
