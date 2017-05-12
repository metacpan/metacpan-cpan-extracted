# ============================================================================
package Mac::iPhoto::Exif;
# ============================================================================

use 5.010;
use utf8;
no if $] >= 5.017004, warnings => qw(experimental::smartmatch);

use Moose;

use Moose::Util::TypeConstraints;
use Path::Class;
use Encode;
use XML::LibXML;
use File::Copy;
use DateTime;
use Unicode::Normalize;

use Image::ExifTool;
use Image::ExifTool::Location;

our $VERSION = "1.01";
our $AUTHORITY = 'cpan:MAROS';

our @LEVELS = qw(debug info warn error);
our $DATE_SEPARATOR = '[.:\/]';
our $TIMERINTERVAL_EPOCH = 978307200; # Epoch of TimeInterval zero point: 2001.01.01
our $IPHOTO_ALBUM = $ENV{HOME}.'/Pictures/iPhoto Library/AlbumData.xml';

subtype 'Mac::iPhoto::Exif::Type::Dirs' 
    => as 'ArrayRef[Path::Class::Dir]';

subtype 'Mac::iPhoto::Exif::Type::File'
    => as 'Path::Class::File';

coerce 'Mac::iPhoto::Exif::Type::File'
    => from 'Str'
    => via { Path::Class::File->new($_) }
    => from 'ArrayRef[Str]'
    => via { Path::Class::Dir->new($_->[0]) };

coerce 'Mac::iPhoto::Exif::Type::Dirs'
    => from 'Str'
    => via { [ Path::Class::Dir->new($_) ] }
    => from 'ArrayRef[Str]'
    => via { [ map { Path::Class::Dir->new($_) } @$_ ] };

has 'dryrun' => (
    is                  => 'ro',
    isa                 => 'Bool',
    default             => 0,
    documentation       => 'Dry-run [Default: false]',
);

has 'directory'  => (
    is                  => 'ro',
    isa                 => 'Mac::iPhoto::Exif::Type::Dirs',
    coerce              => 1,
    predicate           => 'has_directory',
    documentation       => "Limit operation to given directories [Multiple; Default: All]",
);

has 'exclude'  => (
    is                  => 'ro',
    isa                 => 'Mac::iPhoto::Exif::Type::Dirs',
    coerce              => 1,
    predicate           => 'has_exclude',
    documentation       => "Exclude given directories  [Multiple; Default: None]",
);

has 'iphoto_album'  => (
    is                  => 'ro',
    isa                 => 'Mac::iPhoto::Exif::Type::File',
    coerce              => 1,
    #default             => $IPHOTO_ALBUM,
    documentation       => "Path to iPhoto library [Default: $IPHOTO_ALBUM]",
);

has 'changetime'  => (
    is                  => 'ro',
    isa                 => 'Bool',
    documentation       => 'Change file time according to exif timestamps [Default: true]',
    default             => 1,
);

has 'backup'  => (
    is                  => 'ro',
    isa                 => 'Bool',
    documentation       => 'Backup files [Default: false]',
    default             => 0,
);

has 'nomerge'  => (
    is                  => 'ro',
    isa                 => 'Bool',
    documentation       => 'Do not merge existing exif tags and faces but overwrite [Default: true]',
    default             => 0,
);

sub log {
    my ($self,$loglevel,$format,@params) = @_;
    # DO not log anything
    return;
}

sub parse_album {
    my ($self) = @_;
    
    my $parser = XML::LibXML->new(
        encoding    => 'utf-8',
        no_blanks   => 1,
    );
    
    my $doc = eval {
        $self->log('info','Reading iPhoto album %s',$self->iphoto_album);
        return $parser->parse_file($self->iphoto_album);
    };
    if (! $doc) {
        $self->log('error','Could not parse iPhoto album: %s',$@ // 'unknown error');
        die('Cannot continue');
    }
    return $doc;
}


sub run {
    my ($self) = @_;
    
    my $doc = $self->parse_album;
    
    my $persons = {};
    my $keywords = {};
    my $count = 0;
    foreach my $top_node ($doc->findnodes('/plist/dict/key')) {
        given ($top_node->textContent) {
            when ('List of Faces') {
                my $personlist_node = $top_node->nextNonBlankSibling();
                my $persons_hash = _plist_node_to_hash($personlist_node);
                foreach my $person (values %$persons_hash) {
                    $persons->{$person->{key}} = $person->{name};
                }
                $self->log('info','Fetching faces (%i)',scalar(keys %$persons));
            }
            when ('List of Keywords') {
                my $keywordlist_node = $top_node->nextNonBlankSibling();
                $keywords = _plist_node_to_hash($keywordlist_node);
                $self->log('info','Fetching keywords (%i)',scalar(keys %$keywords));
            }
            when ('Master Image List') {
                my $imagelist_node = $top_node->nextNonBlankSibling();
                my $key;
                IMAGE_NODES:
                foreach my $image_node ($imagelist_node->childNodes) {
                    given ($image_node->nodeName) {
                        when ('key') {
                            $key = $image_node->textContent;
                        }
                        when ('dict') {
                            
                            my $image = _plist_node_to_value($image_node);
                            
                            my $image_path = Path::Class::File->new($image->{OriginalPath} || $image->{ImagePath});
                            
                            # Check if original image file is present
                            unless (-e $image_path->stringify) {
                                $self->log('error','Could not find image at %s',$image_path->stringify);
                                next IMAGE_NODES;
                            }
                            
                            my $image_directory = $image_path->dir;
                            
                            # Process directories
                            if ($self->has_directory) {
                                my $contains = 0;
                                foreach my $directory (@{$self->directory}) {
                                    if ($directory->contains($image_directory)) {
                                        $contains = 1;
                                        last;
                                    }
                                }
                                next IMAGE_NODES
                                    unless $contains;
                            }
                            
                            # Process excludes
                            if ($self->has_exclude) {
                                my $contains = 0;
                                foreach my $directory (@{$self->exclude}) {
                                    if ($directory->contains($image_directory)) {
                                        $contains = 1;
                                        last;
                                    }
                                }
                                next IMAGE_NODES
                                    if $contains;
                            }
                            
                            my $latitude = $image->{latitude};
                            my $longitude = $image->{longitude};
                            my $rating = $image->{Rating};
                            my $comment = $image->{Comment};
                            my $faces = $image->{Faces};
                            
                            $self->log('info','Processing %s',$image_path->stringify);
                            my $exif = Image::ExifTool->new(
                                Charset => 'UTF8',
                                #DateFormat=>undef
                            );
                            $exif->Options(Charset => 'UTF8');
                            #$exif->Options(DateFormat => undef);
                            
                            $exif->ExtractInfo($image_path->stringify);
                            
                            my $date;
                            
                            # Take crazy date form iphoto album?
                            #my $date = $image->{DateAsTimerInterval} + $TIMERINTERVAL_EPOCH;
                            
                            my $date_original = $exif->GetValue('DateTimeOriginal');
                            if (defined $date_original
                                && $date_original =~ m/^
                                (?<year>(19|20)\d{2})
                                $DATE_SEPARATOR
                                (?<month>\d{1,2})
                                $DATE_SEPARATOR
                                (?<day>\d{1,2})
                                \s
                                (?<hour>\d{1,2})
                                $DATE_SEPARATOR
                                (?<minute>\d{1,2})
                                $DATE_SEPARATOR
                                (?<second>\d{1,2})
                                /x) {
                                $date = DateTime->new(
                                    (map { $_ => $+{$_} } qw(year month day hour minute second)),
                                    time_zone   => 'local',
                                );
                            } else {
                                $self->log('error','Could not parse date format %s',$date_original // 'UNDEF');
                                next IMAGE_NODES;
                            }
                            
                            my %keywords = map { $keywords->{$_} => 1 } @{$image->{Keywords}};
                            
                            my $changed_exif = 0;
                            
                            # Faces
                            if (defined $faces && scalar @{$faces}) {
                                my @persons_list_original = grep { Encode::_utf8_on($_); 1; } $exif->GetValue('PersonInImage'); 
                                my @persons_list_final;
                                
                                unless ($self->nomerge) {
                                    foreach my $person (@persons_list_original) {
                                        # i probably should not do that, but Image::ExifTools seems to
                                        # return utf8 encoded strings without the utf8 flag set
                                        Encode::_utf8_on($person);
                                        
                                        unless ($person ~~ \@persons_list_final) {
                                            push(@persons_list_final,$person)
                                        }
                                    }
                                }
                                
                                FACES:
                                foreach my $face (@$faces) {
                                    my $person = $persons->{$face->{'face key'}};
                                    next FACES
                                        unless defined $person;
                                    next FACES
                                        if $person ~~ \@persons_list_final;
                                    $self->log('debug','- Add person %s',$person)
                                        unless $self->nomerge;
                                    push(@persons_list_final,$person);
                                }
                                
                                @persons_list_original = sort @persons_list_original;
                                @persons_list_final = sort @persons_list_final;
                                
                                if (_list_is_changed(\@persons_list_final,\@persons_list_original)) {
                                    $changed_exif = 1;
                                    $self->log('debug','- Set persons %s',join(',',@persons_list_final))
                                        if $self->nomerge;
                                    $exif->SetNewValue('PersonInImage',[ @persons_list_final ]);
                                }
                            } 
                            
                            # Keywords
                            if (scalar keys %keywords) {
                                my @keywords_list_original = grep { Encode::_utf8_on($_); 1; } $exif->GetValue('Keywords');
                                my @keywords_list_final;
                                
                                unless ($self->nomerge) {
                                    foreach my $keyword (@keywords_list_original) {
                                        # i probably should not do that, but Image::ExifTools seems to
                                        # return utf8 encoded strings without the utf8 flag set
                                        Encode::_utf8_on($keyword);
                                        
                                        unless ($keyword ~~ \@keywords_list_final) {
                                            push(@keywords_list_final,$keyword)
                                        }
                                    }
                                }
                                
                                KEYWORDS:
                                foreach my $keyword (keys %keywords) {
                                    next KEYWORDS
                                        if $keyword ~~ \@keywords_list_final;
                                    $self->log('debug','- Add keyword %s',$keyword)
                                        unless $self->nomerge;
                                    push(@keywords_list_final,$keyword);
                                }
                                
                                @keywords_list_original = sort @keywords_list_original;
                                @keywords_list_final = sort @keywords_list_final;
                                
                               if (_list_is_changed(\@keywords_list_final,\@keywords_list_original)) {
                                    $changed_exif = 1;
                                    $self->log('debug','- Set keywords %s',join(',',@keywords_list_final))
                                        if $self->nomerge;
                                    $exif->SetNewValue('Keywords',[ @keywords_list_final ]);
                                }
                            }
                            
                            # User comments
                            if ($comment) {
                                my $old_comment = $exif->GetValue('UserComment');
                                Encode::_utf8_on($old_comment);
                                if (! defined $old_comment 
                                    || $old_comment ne $comment) {
                                    $self->log('debug','- Set user comment');
                                    $exif->SetNewValue('UserComment',$comment);
                                    $changed_exif = 1;
                                }
                            }
                            
                            # User ratings
                            if ($rating && $rating > 0) {
                                my $old_rating = $exif->GetValue('Rating') // 0;
                                if (! defined $old_rating 
                                    || $old_rating != $rating) {
                                    $self->log('debug','- Set rating %i',$rating);
                                    $exif->SetNewValue('Rating',$rating);
                                    $changed_exif = 1;
                                }
                            }
                            
                            # Geo Tags
                            if ($latitude && $longitude) {
                                my ($old_latitude,$old_longitude) = $exif->GetLocation($latitude,$longitude);
                                $old_latitude //= 0;
                                $old_longitude //= 0;
                                if (sprintf('%.4f',$latitude) != sprintf('%.4f',$old_latitude) 
                                    && sprintf('%.4f',$longitude) != sprintf('%.4f',$old_longitude)) {
                                    $self->log('debug','- Set geo location %fN,%fS',$latitude,$longitude);
                                    $exif->SetLocation($latitude,$longitude);
                                    $changed_exif = 1;
                                }
                            }
                            
                            unless ($self->dryrun) {
                                if ($changed_exif) {
                                    if ($self->backup) {
                                        my $backup_path = Path::Class::File->new($image_path->dir,'_'.$image_path->basename);
                                        $self->log('debug','- Writing backup file to %s',$backup_path->stringify);
                                        File::Copy::syscopy($image_path->stringify,$backup_path->stringify)
                                            or $self->log('error','Could not copy %s to %s: %s',$image_path->stringify,$backup_path->stringify,$!);
                                    }
                                    my $success = $exif->WriteInfo($image_path->stringify);
                                    if ($success) {
                                        $self->log('debug','- Exif data has been written to %s',$image_path->stringify);
                                    } else {
                                        $self->log('error','Could not write to %s: %s',$image_path->stringify,$exif->GetValue('Error'));
                                    }
                                }
                                
                                if ($self->changetime) {
                                    $self->log('debug','- Change file time to %s',$date->datetime);
                                    utime($date->epoch, $date->epoch, $image_path->stringify)
                                        or $self->log('error','Could not utime %s: %s',$image_path->stringify,$!);
                                }
                            }
                            
                            $count ++;
                        }
                    }
                }
            }
        }
    }
    
    return 1;
}



sub _fix_string {
    my ($string) = @_;
    
    if ($string =~ /[[:alpha:]]/) {
        $string = NFC($string);
        $string =~ s/\p{NonspacingMark}//g;
    }
    return $string;
}

sub _plist_node_to_hash {
    my ($node) = @_;
    
    my $return = {};
    my $key;
    foreach my $child_node ($node->childNodes) {
        if ($child_node->nodeType == 1) {
            given ($child_node->nodeName) {
                when ('key') {
                    $key = $child_node->textContent;
                }
                default {
                    $return->{$key} = _plist_node_to_value($child_node);
                }
            }
        }
    }
    
    return $return;
}

sub _plist_node_to_value {
    my ($node) = @_;
    given ($node->nodeName) {
        when ('string') {
            return _fix_string($node->textContent);
        }
        when ([qw(real integer)]) {
            return $node->textContent + 0;
        }
        when ('array') {
            return _plist_node_to_array($node);
        }
        when ('dict') {
            return _plist_node_to_hash($node);
        }
    }
    
    return;
}

sub _plist_node_to_array {
    my ($node) = @_;
    
    my $return = [];
    foreach my $child_node ($node->childNodes) {
        if ($child_node->nodeType == 1) {
            push (@$return,_plist_node_to_value($child_node));
        }
    }
    
    return $return;
}

sub _list_is_changed {
    my ($list_final,$list_original) = @_;
    
    return 1
        if scalar @$list_final != scalar @$list_original;
    
    for (my $index = 0; $index <= scalar @$list_final; $index ++) {
        return 1
            unless $list_final->[$index] ~~ $list_original->[$index];
    }
    return 0;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=encoding utf8

=head1 NAME 

Mac::iPhoto::Exif - Write iPhoto meta data to Exif

=head1 SYNOPSIS

 console$ iphoto2exif --directory /data/photo/2010/summer_vacation

or

 use Mac::iPhoto::Exif;
 my $iphotoexif = Mac::iPhoto::Exif->new(
    directory   => '/data/photo/2010/summer_vacation'
 );
 $iphotoexif->run;

=head1 DESCRIPTION

This module write meta data from the iPhoto database like keywords, 
geo locations, comments, ratings and faces to the pictures Exif data.

The following exif tags are being used:

=over

=item * PersonInImage

=item * Keywords

=item * UserComment

=item * Rating

=item * GPSLatitude, GPSLongitude, GPSLatitudeRef, GPSLongitudeRef

=item * Rating

=back

=head1 ACCESSORS

=head2 directory

Limit operation to one or more directories. 

ArrayRef of Path::Class::Dir

=head2 exclude

Exclude one or more directories.

ArrayRef of Path::Class::Dir

=head2 iphoto_album

Path to the iPhoto AlbumData.xml database.

Path::Class::File

=head2 loglevel

Be more/less verbose. 

Accepted loglevels are : debug, info, warn and error

Default: info

=head2 changetime

Change file create time according to exif timestamps

Default: true

=head2 backup

Backup changed files

Default: false

=head2 dryrun

Do not alter files, just log actions 

Default: false

=head1 METHODS

=head2 parse_album

Return the iPhoto album as a XML::LibXml::Doc object

=head2 run

Run the iPhoto to Exif conversion

=head2 log

Log message

=head1 DISCLAIMER

This module has been extensively tested on my machine (OSX 10.6.6,
iPhoto 9.1.1) and deemed to work correctly. However I do not guarantee that
it will work correctly on any other machine/setup. So make sure that you have
backups of your valualble pictures before running this program!

THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. PERFORMANCE OF THE
SOFTWARE IS WITH YOU.

IN NO EVENT WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY
AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE.

=head1 SUPPORT

Please report any bugs or feature requests to 
C<mac-iphoto-exif@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Mac::iPhoto::Exif>.
I will be notified and then you'll automatically be notified of the progress 
on your report as I make changes.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.k-1.com>

=head1 COPYRIGHT & LICENSE

Mac::iPhoto::Exif is Copyright (c) 2009, Maroš Kollár 
- L<http://www.k-1.com>

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut