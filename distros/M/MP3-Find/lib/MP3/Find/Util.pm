package MP3::Find::Util;

use strict;
use warnings;

use base qw(Exporter);
use vars qw(@EXPORT_OK);

@EXPORT_OK = qw(build_query get_mp3_metadata);

use Carp;
use MP3::Info;

eval { require MP3::Tag };
my $CAN_USE_ID3V2 = $@ ? 0 : 1;

sub build_query {
    my @args = @_;
    
    # first find all the directories
    my @dirs;
    while (local $_ = shift @args) {
        if (/^-/) {
            # whoops, there's the beginning of the query
            unshift @args, $_;
            last;
        } else {
            push @dirs, $_;
        }
    }
    
    # now build the query hash
    my %query;
    my $field;
    while (local $_ = shift @args) {
        if (/^--?(.*)/) {
            $field = uc $1;
        } else {
            $field ? push @{ $query{$field} }, $_ : die "Need a field name before value '$_'\n";
        }
    }
    
    return (\@dirs, \%query);
}

sub get_mp3_metadata {
    my $args = shift;

    my $filename = $args->{filename} or croak "get_mp3_metadata needs a 'filename' argument";
    
    my $mp3 = {
        FILENAME => $filename,
        %{ get_mp3tag($filename)  || {} },
        %{ get_mp3info($filename) || {} },
    };
    
    if ($CAN_USE_ID3V2 and $args->{use_id3v2}) {
	# add ID3v2 tag info, if present
	my $mp3_tags = MP3::Tag->new($filename);
	unless (defined $mp3_tags) {
	    warn "Can't get MP3::Tag object for $filename\n";
	} else {
	    $mp3_tags->get_tags;
	    if (my $id3v2 = $mp3_tags->{ID3v2}) {
		for my $frame_id (keys %{ $id3v2->get_frame_ids }) {
		    my ($info) = $id3v2->get_frame($frame_id);
		    if (ref $info eq 'HASH') {
			# use the "Text" value as the value for this frame, if present
			$mp3->{$frame_id} = $info->{Text} if exists $info->{Text};
		    } else {
			$mp3->{$frame_id} = $info;
		    }
		}
	    }
	}
    }

    return $mp3;
}

# module return
1;
