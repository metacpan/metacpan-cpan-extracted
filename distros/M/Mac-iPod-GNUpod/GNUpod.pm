#!/usr/bin/perl

package Mac::iPod::GNUpod;

=head1 NAME

Mac::iPod::GNUpod - Add and remove songs from your iPod; read and write
databases in iTunes and GNUpod format

=head1 ABSTRACT

This is the module to do anything with your iPod, with methods for initializing
your iPod, adding and removing songs, and reading and writing databases in the
iTunes and GNUpod formats. This module was originally based on the GNUpod
script package, written and distributed by Adrian Ulrich, (pab at
blinkenlights.ch), L<http://www.gnu.org/software/gnupod/>. However, a lot of
development has occurred since then, making the module more flexible and more
appropriate for CPAN. This module and the GNUpod scripts remain completely
interoperable--they write the same file format and work in much the same way.

=head1 SYNOPSIS

    use Mac::iPod::GNUpod;

    my $ipod = Mac::iPod::GNUpod->new(mountpoint => '/mnt/ipod');

    # Read existing databases
    $ipod->read_gnupod;
    $ipod->read_itunes;

    # Add songs
    my $id = $ipod->add_song('~/music/The Foo Brothers - All Barred Up.mp3');

    # Get paths to songs
    my $path = $ipod->get_path($id);

    # Find the id numbers of existing songs
    my @yuck = $ipod->search(artist => 'Yoko Ono');

    # Remove songs based on id
    $ipod->rm_song(@yuck);

    # Write databases
    $ipod->write_gnupod;
    $ipod->write_itunes;

=cut

# Remainder of POD after __END__

use warnings;
use warnings::register;
use strict;

use Mac::iPod::GNUpod::Utils;
use File::Copy;
use File::Spec;
use File::Spec::Mac;
use XML::Parser;
use Carp qw/carp croak/;
our @CARP_NOT = qw/XML::Parser XML::Parser::Expat Mac::iPod::GNUpod/;

our $VERSION = '1.24';

# Global variables

sub new {
    my ($class, %opt) = @_;

    my $self = {
        mnt => '',          # Mountpoint
        itunes_db => '',    # iTunes DB
        gnupod_db => '',    # GNUpod DB
        allow_dup => 0,     # Whether duplicates are allowed
        move_files => 1,    # Whether to actually move files on add or rm
        files => [],        # List of file hrefs
        idx => {},          # Indices of song properties (for searching)
        plorder => [],      # List of playlists in order
        pl_idx => {},       # Playlists by name
        spl_idx => {}       # Smartplaylists by name
    };

    bless $self, $class;

    if ($opt{mountpoint}) {
        $self->mountpoint($opt{mountpoint});
    }
    elsif ($opt{itunes_db} && $opt{gnupod_db}) {
        $self->itunes_db($opt{itunes_db});
        $self->gnupod_db($opt{gnupod_db});
    }
    else {
        croak "You must specify either the mountpoint or both the itunes_db and gnupod_db options";
    }

    return $self;
}

sub mountpoint {
    my $self = shift;
    if (@_) {
        $self->{mnt} = File::Spec->canonpath(shift);
        $self->{itunes_db} = File::Spec->catfile($self->{mnt}, "iPod_Control", "iTunes", "iTunesDB");
        $self->{gnupod_db} = File::Spec->catfile($self->{mnt}, "iPod_Control", ".gnupod", "GNUtunesDB");
    }
    return $self->{mnt};
}

# Here we define the template get-set funcs
my @flags = qw/itunes_db gnupod_db allow_dup move_files/;
for my $flag (@flags) {
    no strict 'refs';
    *$flag = sub {
        my $self = shift;
        if (@_) {
            $self->{$flag} = shift;
        }
        return $self->{$flag};
    };
}

# Format a new iPod, create directory structure, prepare for GNUpod
sub init {
    my ($self, %opts) = @_;

    if (not $self->{mnt}) {
        croak "Can't init iPod without the mountpoint set";
    }

    # Folder structure
    for my $path( ('Calendars', 'Contacts', 'Notes', 'iPod_Control', 'iPod_Control/Music',
             'iPod_Control/iTunes', 'iPod_Control/Device', 'iPod_Control/.gnupod') ) {
        my @path = split('/', $path);
        my $path = File::Spec->catdir($self->{mnt}, @path);
        next if -d $path;
        mkdir $path or croak "Could not create $path ($!)";
    }

    # Music folders
    for(0..19) {
        my $path = File::Spec->catdir($self->{mnt}, "iPod_Control", "Music", sprintf("f%02d", $_));
        next if -d $path;
        mkdir $path or croak "Could not create $path ($!)";
    }

    # Convert iTunes db if allowed
    if(-e $self->{itunes_db} && !$opts{'noconvert'}) {
        $self->read_itunes;
    }

    # Make empty db otherwise
    else {
        open(ITUNES, ">", $self->{itunes_db}) or croak "Could not create $self->{itunes_db}: $!";
        print ITUNES "";
        close(ITUNES);
    }

    $self->write_gnupod;

    return 1;
}

# Convert iTunesDB to GNUpodDB
#
# This function almost entirely copyright (C) 2002-2003 Adrian Ulrich. Adapted
# from tunes2pod.pl in the GNUpod toolset
sub read_itunes {
    my ($self) = @_;

    require Mac::iPod::GNUpod::iTunesDBread or die;

    $self->_clear;

    Mac::iPod::GNUpod::iTunesDBread::open_itunesdb($self->{itunes_db}) 
        or croak "Could not open $self->{itunes_db}";

    #Check where the FILES and PLAYLIST part starts..
    #..and how many files are in this iTunesDB
    my $itinfo = Mac::iPod::GNUpod::iTunesDBread::get_starts();
    
    # These 2 will change while running..
    my $pos = $itinfo->{position};
    my $pdi = $itinfo->{pdi};

    #Get all files
    for my $i (0 .. ($itinfo->{songs} - 1)) {
        ($pos, my $href) = Mac::iPod::GNUpod::iTunesDBread::get_mhits($pos); #get the mhit + all child mhods
        #Seek failed.. this shouldn't happen..  
        if($pos == -1) {
            croak "Expected to find $itinfo->{data} files, failed to get file $i";
        }
        $self->_addfile($href);  
    }

    #Now get each playlist
    for my $i (0 .. ($itinfo->{playlists} - 1)) {
        ($pdi, my $href) = Mac::iPod::GNUpod::iTunesDBread::get_pl($pdi); #Get an mhyp + all child mhods
        if($pdi == -1) {
            croak "Expected to find $itinfo->{playlists} playlists, I failed to get playlist $i";
        }
        next if $href->{type}; #Don't list the MPL
        $href->{name} = "NONAME" unless($href->{name}); #Don't create an empty pl

        #SPL Data present
        if(ref($href->{splpref}) eq "HASH" && ref($href->{spldata}) eq "ARRAY") { 
            $self->_render_spl($href->{name}, $href->{splpref}, $href->{spldata}, $href->{matchrule}, $href->{content});
        }

        #Normal playlist 
        else { 
            $self->_addpl($href->{name});
            # Render iPod pls in GNUpod format
            $self->_addtopl($self->{cur_pl}, { add => { id => $_ } }) foreach @{$href->{content}};
        }
    }

    # Close the db
    Mac::iPod::GNUpod::iTunesDBread::close_itunesdb();
}

# Parse the GNUpod db (in XML)
sub read_gnupod {
    my ($self, %opts) = shift;
    unless (-r $self->{gnupod_db}) {
        croak "Can't read GNUpod database at $self->{gnupod_db}";
    }

    $self->_clear;

    # Call _eventer as a method
    my $wrapper = sub { $self->_eventer(@_) };

    my $p = new XML::Parser( Handlers => { Start => $wrapper });
    # Save this value to be our overall return value
    my $rv = $p->parsefile($self->gnupod_db);

    # At end of file parsing unset cur_pl
    $self->{cur_pl} = undef;

    # Return value from parsefile
    return $rv;
}

# Write the iTunes Db
#
# This code adapted from the mktunes.pl script, copyright (C) 2002-2003 Adrian
# Ulrich.
sub write_itunes {
    my $self = shift;

    require Mac::iPod::GNUpod::iTunesDBwrite or die;
 
    # Undocumented, used only for debugging
    my %opt = @_;
    $opt{name} = 'GNUpod' unless $opt{name};

    my ($num, %data, %length, %ids);
    my @newfiles = (undef); # Will become $self->{files} at end

    # Create mhits and mhods for all files
    for (@{$self->{files}}) {
        next if not $_ or not keys %$_;
        # iTunes ID and GNUpod ID are NOT necessarily the same!  So we build a
        # hash of GNUpod => iTunes ids for translating playlists
        $ids{$_->{id}} = ++$num;
        $_->{id} = $num;
        push @newfiles, $_;

        $data{mhit} .= Mac::iPod::GNUpod::iTunesDBwrite::render_mhit($_, $num);
    }
    $length{mhit} = length($data{mhit});

    # Here, after remaking all files, we remake our indexes and playlists
    $self->_remake(\@newfiles, \%ids);

    # Create header for mhits
    $data{mhlt} = Mac::iPod::GNUpod::iTunesDBwrite::mk_mhlt({ songs => $num });
    $length{mhlt} = length($data{mhlt});

    # Create header for the mhlt
    $data{mhsd_1} = Mac::iPod::GNUpod::iTunesDBwrite::mk_mhsd({
        size => $length{mhit} + $length{mhlt},
        type => 1
    });
    $length{mhsd_1} = length($data{mhsd_1});

    # Create the master playlist
    ($data{playlist}, $num) = Mac::iPod::GNUpod::iTunesDBwrite::r_mpl(
        name => $opt{name},
        ids => [ 1 .. $num ],
        type => 1,
        curid => $num
    );

    # Create child playlists
    for my $plname (@{$self->{plorder}}) {
        my %common = ( name => $plname, type => 0, curid => $num );
        if (my $spl = $self->get_spl($plname)) {
            (my $dat, $num) = Mac::iPod::GNUpod::iTunesDBwrite::r_mpl(
                %common, 
                splprefs => $spl->{pref},
                spldata => $spl->{data}
            );
            $data{playlist} .= $dat;
        }
        else {
            (my $dat, $num) = Mac::iPod::GNUpod::iTunesDBwrite::r_mpl(
                %common, 
                ids => [ $self->render_pl($plname) ]
            );
            $data{playlist} .= $dat;
        }
    }
    $data{playlist} = Mac::iPod::GNUpod::iTunesDBwrite::mk_mhlp({ playlists => scalar @{$self->{plorder}} + 1  }) . $data{playlist};
    $length{playlist} = length($data{playlist});

    # Make pl headers
    $data{mhsd_2} = Mac::iPod::GNUpod::iTunesDBwrite::mk_mhsd({ size => $length{playlist}, type => 2 });
    $length{mhsd_2} = length($data{mhsd_2});

    # Calculate total file length
    my $totlength = 0;
    $totlength += $_ for values %length;

    # Make master header
    $data{mhbd} = Mac::iPod::GNUpod::iTunesDBwrite::mk_mhbd({ size => $totlength });

    # Debug me!
    if ($opt{dump}) {
        use Data::Dumper;
        open DUMP, '>', $opt{dump} or croak "Couldn't open dump file: $!";
        print DUMP Dumper(\%data);
        close DUMP;
    }

    # Write it all
    open IT, '>', $self->{itunes_db} or croak "Couldn't write iTunes DB: $!";
    binmode IT;
    for ('mhbd', 'mhsd_1', 'mhlt', 'mhit', 'mhsd_2', 'playlist') {
        no warnings 'uninitialized'; # In case one of these is empty
        print IT $data{$_};
    }
    close IT;
}

sub _remake {
    my ($self, $newfiles, $ids) = @_;

    # Set new files
    $self->{files} = $newfiles;

    # Update playlists
    for (@{$self->{plorder}}) {
        my $pl = $self->get_pl($_);
        if ($pl) {
            for (@$pl) {
                if ($_ eq int $_) {
                    $_ = $ids->{$_};
                }
            }
        }
    }

    # Update index
    for (values %{$self->{idx}}) { # Fields
        for (values %$_) { # Values
            for (@$_) { # Id numbers
                $_ = $ids->{$_};
            }
        }
    }
}

# Write the GNUpod DB XML File
sub write_gnupod {
    my($self) = @_;
    open(OUT, ">$self->{gnupod_db}") or croak "Could not write $self->{gnupod_db}: $!\n";
    binmode OUT ;

    # In this section all printing goes to OUT
    my $oldfh = select OUT;

    # Values throughout this code are Unicode::String objects, and we want to
    # make sure that these stringify as utf8
    Unicode::String::stringify_as('utf8');

    print "<?xml version='1.0' standalone='yes'?>\n";
    print "<gnuPod>\n";

    # Write the files section
    print "\t<files>\n";
    for (@{$self->{files}}) {
        next if not $_ or not keys %$_;
        my %filehash = %$_; # Work with a copy, not orig hashref

        # A few keys that don't need to be written to disk
        for my $del ('notorig', 'uniq') {
            delete $filehash{$del};
        }

        print "\t\t", mktag("file", \%filehash), "\n";
    }
    print "\t</files>\n";

    #Print all playlists
    foreach (@{$self->{plorder}}) {
        my $name;
        # Smartplaylists
        if (my $ref = $self->get_spl($_)) {
            print "\t" . mktag("smartplaylist", $ref->{pref}, noend => 1) . "\n";
            for my $item (@{$ref->{data}}) {
                for (keys %$item) {
                    next if not keys %{$item->{$_}};
                    print "\t\t", mktag($_, $item->{$_}), "\n";
                }
            }
            print "</smartplaylist>";
        }

        # Regular playlists
        elsif ($ref = $self->get_pl($_)) {
            print "\t" . mktag("playlist", { name => $_ }, noend => 1) . "\n";
            for (@$ref) {
                print "\t\t";
                if ($_ eq int $_) {
                    print mktag("add", { id => $_ });
                }
                elsif ($_->{exact}) {
                    my %write = %$_;
                    delete $write{exact};
                    print mktag("add", \%write);
                }
                elsif ($_->{nocase}) {
                    my %write =  %$_;
                    delete $write{nocase};
                    print mktag("iregex", \%write);
                }
                else {
                    print mktag("regex", $_);
                }
                print "\n";
            }
            print "\t</playlist>\n";
        }

        # Bad playlist entry--can't happen
        else {
            warnings::warnif("Unknown playlist $name");
            next;
        }

    }
    print "</gnuPod>\n";
    close OUT ;

    # Restore original value of filehandle and stringify
    select $oldfh;
}
                
# Restore an iPod w/ corrupted dbs
sub restore {
    my ($self, %opts) = @_;
    if (not defined $self->{mnt}) {
        croak "Can't restore iPod without mountpoint set";
    }

    local $self->{move_files} = 0;
    local $self->{allow_dup} = 1;
    local $self->{restore} = 1;
    $self->_clear;
    $self->add_song(glob(File::Spec->catpath($self->{mnt}, "iPod_Control", "Music", "*", "*")));
}

# Add a song to the ipod
sub add_song {
    my ($self, @songs) = @_;
    my @newids;

    foreach my $song (@songs) {
        my $filename;
        if (ref($song) eq 'HASH') {
            $filename = $song->{filename};
        }
        else {
            $filename = $song;
        }
        if (not defined $filename) {
            warnings::warnif "Undefined filename";
            next;
        }

        # Get the magic hashref
        my $fh = Mac::iPod::GNUpod::Utils::wtf_is($filename);
        if (not $fh) {
            warnings::warnif "$@, skipping '$song'";
            next;
        }

        # Update hashref w/ user-supplied info (if needed)
        if (ref($song) eq 'HASH') {
            $fh->{$_} = $song->{$_} for (keys %$song);
        }

        # Get the path, etc.
        ($fh->{path}, my $target) = $self->_getpath($filename);

        # Check for duplicates
        unless ($self->allow_dup) {
            if (my $dup = $self->_chkdup($fh)) {
                warnings::warnif "'$song' is a duplicate of song $dup, skipping";
                next;
            }
        }

        # Copy the file
        if (defined $self->{mnt} and $self->move_files) {
            File::Copy::copy($filename, $target) or do {
                warnings::warnif "Couldn't copy $song to $target: $!, skipping";
                next;
            }
        }

        # Add this to our list of files
        push @newids, $self->_newfile($fh);
    }

    return @newids if wantarray;
    return $newids[0];
}

# Remove a song from the ipod
sub rm_song {
    my ($self, @songs) = @_;
    my $rmcount = 0;

    foreach my $id (@songs) {
        if (not exists $self->{files}->[$id]) {
            warnings::warnif "No song with id $id";
            next;
        }

        if (defined $self->{mnt} and $self->move_files) {
            my $path = $self->_realpath($self->{files}->[$id]->{path});
            unless (unlink $path) {
                warnings::warnif "Remove failed for song $id ($path): $!";
                next;
            }
        }


        my $gone = delete $self->{files}->[$id];
        $rmcount++;

        # Get rid of index entries, dupdb
        no warnings 'uninitialized';
        delete $self->{dupdb}->{"$gone->{bitrate}/$gone->{time}/$gone->{filesize}"};
        for (keys %{$self->{idx}}) {
            my @list;
            if (exists $self->{idx}{$_}{$gone->{$_}}) {
                @list = @{$self->{idx}{$_}{$gone->{$_}}};
                for (my $i = 0; $i < @list; $i++) {
                    if ($list[$i] eq $id) {
                        splice @list, $i, 1;
                    }
                }
            }
            if (@list) {
                $self->{idx}{$_}{$gone->{$_}} = \@list;
            }
            else {
                delete $self->{idx}{$_}{$gone->{$_}};
            }
        }
    }

    return $rmcount;
}

# Get a song by id
sub get_song {
    my ($self, @ids) = @_;
    # Must make new hash to prevent tampering w/ internals
    my @rv;
    for (@ids) {
        my $song = $self->{files}[$_];
        if (ref $song eq 'HASH') {
            my %song = %$song;
            push @rv, \%song;
        }
        else {
            push @rv, undef;
        }
    }
    if (wantarray) {
        return @rv;
    }
    else {
        return $rv[0];
    }
}

# Get possible duplicates of a song by ID
sub get_dup {
    my $self = shift;
    my $fh = Mac::iPod::GNUpod::Utils::wtf_is(shift);
    return $self->_chkdup($fh);
}

sub _chkdup {
    my ($self, $fh) = @_;
    no warnings 'uninitialized';
    return $self->{dupdb}->{"$fh->{bitrate}/$fh->{time}/$fh->{filesize}"};
}

# Get the real path to a song by id
sub get_path {
    my ($self, @ids) = @_;
    return unless defined $self->{mnt};
    return map { $self->_realpath($self->{files}->[$_]->{path}) } @ids if wantarray;
    return $self->_realpath($self->{files}->[$ids[0]]->{path});
}

# Get all songs
sub all_songs {
    my $self = shift;
    return grep { defined $self->{files}->[$_] } 1 .. $#{$self->{files}};
}

# Add a pl to the ipod
sub add_pl {
    my ($self, $name, @songs) = @_;
    $name = Mac::iPod::GNUpod::Utils::getutf8($name);
    warnings::warnif $@ if not defined $name;

    # Sets $self->{cur_pl}
    $self->_addpl($name);

    $self->_addtopl($self->{cur_pl}, $_) for (@songs);
    
    # Prevent others from accidentally writing to this pl
    $self->{cur_pl} = undef;

    return 1;
}

# Get a pl by name
sub get_pl {
    my ($self, @names) = @_;
    my @rv;
    for (@names) {
        if (exists $self->{pl_idx}->{$_}) {
            push @rv, $self->{pl_idx}->{$_};
        }
        else {
            push @rv, undef;
        }
    }
    return @rv if wantarray;
    return $rv[0];
}

# Get all playlists
sub all_pls {
    my $self = shift;
    return grep { defined $_ } @{$self->{plorder}};
}

# Remove a pl by name
sub rm_pl {
    my ($self, @names) = @_;
    my $count;
    for (@names) {
        if (delete $self->{pl_idx}->{$_}) {
            $count++;
            for my $i (0 .. $#{$self->{plorder}}) {
                no warnings 'uninitialized';
                if ($self->{plorder}->[$i] eq $_) {
                    splice(@{$self->{plorder}}, $i, 1);
                }
            }
        }
    }
    return $count;
}

# Get an spl by name
sub get_spl {
    my ($self, @names) = @_;
    return @{$self->{spl_idx}}{@names} if wantarray;
    return $self->{spl_idx}->{$names[0]};
}

# Get a list of ids by search terms
sub search {
    my ($self, %terms) = @_;

    # Pick opts out from terms
    my %opts;
    for ('nocase', 'nometachar', 'exact') {
        $opts{$_} = delete $terms{$_};
    }

    # Main searches
    my %count;
    my $term = 0;
    while (my ($key, $val) = each %terms) {
        for my $idxval (keys %{$self->{idx}->{$key}}) {
            if (matches($idxval, $val, %opts)) {
                $count{$_}++ for @{$self->{idx}->{$key}->{$idxval}};
            }
        }
        $term++;
    }

    # Get the list of everyone that matched
    # Sort by Artist > Album > Cdnum > Songnum > Title
    return 
        sort {
            $self->{files}->[$a]->{uniq} cmp $self->{files}->[$b]->{uniq}
        } grep { 
            $count{$_} == $term 
        } keys %count;
}

# Clear the ipod db
sub _clear {
    my $self = shift;
    $self->{files} = [];
    $self->{idx} = {};
    $self->{plorder} = [];
    $self->{pl_idx} = {};
    $self->{spl_idx} = {};
}

# Add a new file to db, create indices
sub _newfile {
    my ($self, $file) = @_;

    # Find the first open index slot
    my $idx = 1;
    $idx++ while defined $self->{files}->[$idx];
    $file->{id} = $idx;

    $self->_addfile($file);
}

# Add info from a file in the db
sub _addfile {
    my ($self, $file) = @_;
    no warnings 'uninitialized';

    # Check for bad path
    {
        # Get the real path
        my $rpath;
        if ($self->{mnt} && $self->move_files) {
            $rpath = $self->_realpath($file->{path});
            
        }
        last if not $rpath;

        my $errst;
        if (not -e $rpath) {
            $errst = "File does not exist ($rpath)";
        }
        if (-d $rpath) {
            $errst = "Path is a directory ($rpath)";
        }
        if ($errst) {
            warnings::warnif $errst;
            return;
        }

    }
    
    
    # Check for bad ids
    {
        my $badid;
        my $errstr;
        if ($file->{id} < 1) {
            $file->{id} = 'MISSING' if not exists $file->{id};
            warnings::warnif "Bad id ($file->{id}) for file";
            $badid = 1;
        }
        elsif (defined $self->{files}->[$file->{id}]) {
            warnings::warnif "Duplicate song id ($file->{id})";
            $badid = 1;
        }

        if ($badid) {
            # Attempt to rescue w/ newfile (which re-assigns id)
            if (my $r = $self->_newfile($file)) {
                warnings::warnif " ...fixed";
                # Note that this song does not have its original id
                $self->{files}->[$r]->{notorig} = 1;
                return $r;
            }
            # Getting here is bad failure
            return;
        }
    }
        
    # Make duplicate index
    $self->{dupdb}->{"$file->{bitrate}/$file->{time}/$file->{filesize}"} = $file->{id};

    # Add a uniq for sorting
    $file->{uniq} = sprintf "%s|%s|%02d|%02d|%s|%s",
        $file->{artist}, $file->{album}, $file->{cdnum}, $file->{songnum}, $file->{title}, $file->{path};

    # Make indexes, convert to utf8
    for (keys %$file) {
        # Don't index the id or uniq (redundant!)
        next if $_ eq 'id' or $_ eq 'uniq';
        push @{$self->{idx}->{$_}->{$file->{$_}}}, $file->{id};
        $file->{$_} = Mac::iPod::GNUpod::Utils::getutf8($file->{$_});
        warnings::warnif $@ if not defined $file->{$_};
    }

    # Add to file index
    $self->{files}->[$file->{id}] = $file;

    return $file->{id};
}

# Add a playlist
sub _addpl {
    my($self, $name, $opt) = @_;

    if($self->get_pl($name)) {
        warnings::warnif "Playlist '$name' is a duplicate, not adding it";
        return;
    }
    $self->{cur_pl} = $self->{pl_idx}->{$name} = [];
    push(@{$self->{plorder}}, $name);
}

# Add a smart playlist
sub _addspl {
    my($self, $name, $opt) = @_;

 
    if($self->get_spl($name)) {
        warnings::warnif "Playlist '$name' is a duplicate, not adding it";
        return;
    }
    $self->{spl_idx}->{$name}->{pref} = $opt;
    $self->{cur_pl} = $self->{spl_idx}->{$name}->{data} = [];
    push(@{$self->{plorder}}, $name);
}

# Add a file to a playlist
sub _addtopl {
    my ($self, $pl, $href) = @_;

    # ids added from add_pl
    if (ref $href ne 'HASH') {
        push @$pl, $href;
    }
    # <add /> tags from db
    elsif (exists $href->{add}) {
        if (exists $href->{add}->{id}) {
            push @$pl, $href->{add}->{id};
        }
        else {
            push @$pl, { %{$href->{add}}, exact => 1 };
        }
    }
    # <regex /> tags from db
    elsif (exists $href->{regex}) {
        push @$pl, $href->{regex};
    }
    # <iregex /> tags from db
    elsif (exists $href->{iregex}) {
        push @$pl, { %{$href->{iregex}}, nocase => 1 };
    }
    # Hash references from add_pl
    else {
        push @$pl, $href;
    }
}

# create a spl
sub _render_spl {
    my($self, $name, $pref, $data, $mr, $content) = @_;
    my $of = {};
    $of->{liveupdate} = $pref->{live};
    $of->{moselected} = $pref->{mos};
    $of->{matchany}   = $mr;
    $of->{limitsort} = $pref->{isort};
    $of->{limitval}  = $pref->{value};
    $of->{limititem} = $pref->{iitem};
    $of->{checkrule} = $pref->{checkrule};

    #create this playlist
    $self->_addspl($name, $of);
}

# Create a filled-out pl (replacing 'add' and 'regex' entries w/ ids)
sub render_pl {
    my ($self, $name) = @_;
    my @list;

    for my $item (@{$self->{pl_idx}->{$name}}) {
        # Exact id numbers
        if (int $item eq $item) {
            push @list, $item;
        }
        else {
            push @list, $self->search(%$item);
        }
    }
    return @list;
}

#Get all playlists
sub _getpl_names {
    my $self = shift;
    return @{$self->{plorder}};
}

# Call events (event handler for XML::Parser)
sub _eventer {
    my $self = shift;
    my($href, $el, %it) = @_;
    no warnings 'uninitialized';

    return undef unless $href->{Context}[0] eq "gnuPod";

    # Warnings for elements that should have attributes
    if ( (     $href->{Context}[1] eq 'files'
            || $href->{Context}[1] eq 'playlist' 
            || $href->{Context}[1] eq 'smartplaylist') 
            && not keys %it) {
        warnings::warnif "No attributes found for <$el /> tag";
        return;
    }

    # Convert all to utf8
    for (keys %it) {
        $it{$_} = Unicode::String::utf8($it{$_})->utf8;
    }

    # <file ... /> tags
    if($href->{Context}[1] eq "files") {
        if ($el eq 'file') {
            $self->_addfile(\%it);
        }
        else {
            warnings::warnif "Found improper <$el> tag inside <files> tag";
        }
    } 

    # <playlist ..> tags
    elsif($href->{Context}[1] eq "" && $el eq "playlist") {
        $it{name} = "NONAME" unless $it{name};
        $self->_addpl($it{name});
    }

    # <add .. /> tags inside playlist
    elsif($href->{Context}[1] eq "playlist") {
        $self->_addtopl($self->{cur_pl}, { $el => \%it });
    }

    # <smartplaylist ... > tags
    elsif($href->{Context}[1] eq "" && $el eq "smartplaylist") {
        $it{name} = "NONAME" unless $it{name};
        $self->_addspl($it{name}, \%it);
    }

    # <add .. /> tags inside smartplaylist
    elsif($href->{Context}[1] eq "smartplaylist") {
        if (not keys %it) {
            warnings::warnif "No attributes found for <$el /> tag";
            return;
        }
        $self->_addtopl($self->{cur_pl}, { $el => \%it });
    }
}

# Get an iPod-safe path for filename
sub _getpath {
    my($self, $filename) = @_;
    my $path;

    if (not $self->move_files) { #Don't create a new filename..
        $path = $filename;
    }

    else { #Default action.. new filename to create 
        my $name = (File::Spec->splitpath($filename))[2];
        $name =~ tr/a-zA-Z0-9\./_/c; 
        #Search a place for the MP3 file
        for(my $i = 0;; $i++) {
            my $dir = sprintf("f%02d", int(rand(20)));
            my $fname = sprintf("%d_$name", $i);
            $path = File::Spec->catfile($self->{mnt}, "iPod_Control", "Music", $dir, $fname);
            last unless -e $path;
        }
    }

    # Now break the $ipath into pieces and remake it Mac style Make a path
    # Get the ipod-relative path
    my $relpath = File::Spec->abs2rel($path, $self->{mnt});
    my @pieces = File::Spec->splitpath($relpath);
    my @dirs = File::Spec->splitdir($pieces[1]);
    my $ipath = File::Spec::Mac->catfile(@dirs, $pieces[2]);

    return ($ipath, $path);
}

# Convert an ipod path to Unix
sub _realpath {
    my ($self, $ipath) = @_;
    no warnings 'uninitialized';
    my @list = split /:/, $ipath;
    return File::Spec->catfile($self->{mnt}, @list);
}

1;

__END__

=head1 DESCRIPTION

Mac::iPod::GNUpod is a module designed to let you read the database(s) on your
iPod and add and remove songs from it using Perl. It is based on the GNUpod
script package written by Adrian Ulrich, which is available at
L<http://www.gnu.org/software/gnupod/>. You do NOT need to install the GNUpod
scripts in order to use Mac::iPod::GNUpod module.  The GNUpod scripts use a
plaintext XML database alongside the binary iTunes database used internally by
the iPod. This package is capable of reading and writing both the GNUpod
database format and the iTunes database format, and can peacefully coexist with
both. 

Currently this module ONLY works with Unix and Unix-like systems. This probably
includes Linux, FreeBSD, MacOS 10.x, and Solaris. OS-independence will come,
someday.

Note that the GNUpod database format, the original GNUpod package, and much of
the code in this module is (c) Adrian Ulrich.

This module is object oriented. A brief description of the methods needed to
perform various tasks follows:

=head2 Preparing a blank or corrupted iPod

Your iPod must be formatted and mounted for this module to see it. It can be
formatted in FAT32 (Windows) or HFS+ (Mac) format, just so long as your kernel
supports it.

If your iPod is fresh out of the box, probably nothing needs to be
done, but if its file structure has been corrupted you should initialize it
with the L<"init"> method.

If your databases have been lost or corrupted, you may use the L<"restore">
method to find all of the songs on the iPod and rewrite fresh databases.

=head2 Reading and writing databases

You can read and write the iTunes DBs with the L<"read_itunes"> and
L<"write_itunes"> methods respectively. Conversely, the GNUpod DBs are accessed
with L<"read_gnupod"> and L<"write_gnupod">.

The advantage of the GNUpod DB is that it can be read and written many times
faster than the iTunes DB can, so your scripts will run much faster than if you
use only the iTunes format. The following scripts are functionally identical:

A:

    my $ipod = Mac::iPod::GNUpod->new(mountpoint => '/mnt/ipod');

    $ipod->read_itunes;

    # Etc ...

    $ipod->write_itunes;

B:

    my $ipod = Mac::iPod::GNUpod->new(mountpoint => '/mnt/ipod');

    $ipod->read_gnupod;

    # Etc ...

    $ipod->write_gnupod;
    $ipod->write_itunes;

However, in my tests version B runs about twice as fast as A, because the gain
of speed reading the GNUpod DB far outweighs the cost of the extra write step.
(Of course, the significance of this depends on what you do in the middle.)

=head2 Adding and removing songs

Add songs with L<"add_song">. Remove songs with L<"rm_song">.

=head2 Finding existing songs

You can search for existing songs on your iPod with the L<"search"> method. If
you want a list of all songs, use L<"all_songs">.

=head2 Working with playlists

This module can read existing playlists from your iPod and allows you to modify
them in any way you want, or you can create new ones. There is also a mechanism
for creating playlists that mimic the smartplaylists created by iTunes. See
L<"add_pl">, L<"get_pl"> and L<"render_pl"> for details.

The smartplaylists created by iTunes are theoretically not touched by this
module, although they cannot be modified. This feature is untested, so it is
possible that this module will munge your smartplaylists.

=head1 METHODS

=head2 new

    my $ipod = Mac::iPod::GNUpod->new(mountpoint => '/mnt/ipod');

You create a new iPod object with new(). You must supply key-value pairs as
arguments. Most of the time you will only provide the C<mountpoint> key, which
indicates where the iPod is mounted. However, if your iPod structure is
nonstandard or you wish to test without writing to the actual iPod, you may
provide both the C<gnupod_db> and C<itunes_db> keys with values indicating the
locations of those files.

=head2 mountpoint

    my $mnt = $ipod->mountpoint;
    $ipod->mountpoint('/mnt/ipod2');

You may use this method to get the current mountpoint for the iPod. If you
provide an argument, it sets the mountpoint. When you use this method to set
the mountpoint, it automatically sets the C<itunes_db> and C<gnupod_db>,
potentially overwriting values you may have previously had there.

=head2 itunes_db

    my $itunes = $ipod->itunes_db;
    $ipod->itunes_db('/home/ipod/testdb');

Use this method to get/set the location of the iTunes DB, if it is different
from the default location on the iPod. The default location is
C<{mountpoint}/iPod_Control/iTunes/iTunesDB>.

=head2 gnupod_db

    my $gnupod = $ipod->gnupod_db;
    $ipod->gnupod_db('/home/ipod/gnupod.xml');

Use this method to get/set the location of the GNUpod DB, if it is different
from the default location. The default location is
C<{mountpoint}/iPod_Control/.gnupod/GNUtunesDB>.

=head2 allow_dup

    $ipod->allow_dup(1);

Get/set the flag stating whether duplicate songs are allowed. If this is false,
when you call C<add_song>, this module will check for duplicates in the DB and
refuse to add the song if a duplicate is found. If true, no duplicate checking
is done. Default is FALSE, which means no duplicates.

Note that this module identifies duplicates pretty stupidly, simply by
comparing file size and bitrate. False positives are possible, and in your
application you might want to use some other, more sophisticated method for
determining if two files are duplicate. You can find out which song in the
database is suspected to be a duplicate by using L<"get_dup">.

=head2 move_files

    $ipod->move_files(0);

Get/set the flag stating whether or not to actually (re)move files. If true,
when you call C<add_song> or C<rm_song>, the files will actually be copied or
deleted. If false, the songs will simply be added or removed from the database,
but the file contents of your iPod will not be changed. Default is TRUE. 

=head2 init

    $ipod->init;

Initialize a blank or empty iPod. NOTE: this method only pays attention to
C<mountpoint>. 

=head2 restore

    $ipod->restore;

Restore an iPod with corrupted databases. This scans the files on the iPod and
rebuilds the databases with the files it finds. (This is equivalent to the
C<gnupod_addsong.pl> script with the C<--restore> option.

=head2 read_itunes

    $ipod->read_itunes;

Read an iTunes database (found at C<itunes_db>) into memory. Note that this
will forget any iTunes or GNUpod DB previously read.

=head2 write_itunes

    $ipod->write_itunes(name => 'my iPod');

Write the contents of memory to the iTunes DB. You should do this at the end of
any script if you want your newly added or deleted songs to be available when
you unmount your iPod! You may pass a name argument as shown above if you want
to change the name of your iPod.

Beware that when you call C<write_itunes()> the id numbers of songs in the
database may change. Data that are internal to this module are properly
updated, but beware that if you have id numbers stored from before calling
C<write_itunes()> they may not still point to the song you intend.

=head2 read_gnupod

    $ipod->read_gnupod;

Read the GNUpod database into memory. This also forgets any databases
previously read.

=head2 write_gnupod

    $ipod->write_gnupod;

Write the GNUpod database. If you want to use any GNUpod tools with the iPod,
you should write this db at the end of any script.

=head2 add_song

    $ipod->add_song('/home/music/The Cure - Fascination Street.mp3');
    $ipod->add_song(@songs);

Add a song to the iPod. Takes one or more arguments, which are the filenames of
songs to be added. Files are recognized by their extensions, so attempting to
add a file with an unknown extension (or no extension) will fail. Currently
C<.mp3>, C<.wav>, C<.mp4> and C<.m4a> files are supported.  On success, this
method returns the new id number of the song(s), on failure returns undef.
Failure can mean that the file could not be copied or that duplicate files were
found.

For MP3 files, metadata (artist, title, etc.) are gleaned from the ID3 tag,
with preference given to ID3v2. For WAV files, data are taken from metadata
encoded with Audio::Mix or from the path. If path information is used, the
filename (minus extension) is taken to be title, the enclosing directory the
album, and the directory above that the artist. If you wish to override the
default way that metadata are gathered you can give a hash reference as the
argument to this function. In this case, your hash reference must contain a
C<filename> key that gives the path to the file, and the remaining keys may
contain the file's metadata. Ex:

    $ipod->add_song({ filename => 'random.wav', artist => 'The Digits', album => 'Of Pi' });

You can also use this method to add custom fields to your database. Any keys
you put in your hashref will be indexed for searching and written to the GNUpod
database, but otherwise ignored. The predefined keys that are safe to set using
the hashref form of this method are:

=over 4

=item * artist

=item * album

=item * title

=item * songnum

=item * songs

=item * cdnum

=item * cds

=item * composer

=item * year

=item * genre

=back

Custom keys may be anything, so long as they don't conflict with any of the
predefined keys returned from L<"get_song">. Setting any other keys returned from
C<get_song> results in undefined behavior.

=head2 get_dup

    $duplicate = $ipod->get_dup($file);

Given a filename, returns the song id of any songs believed to be duplicates of
this song. Returns "undef" if no duplicates are found. You may use this
function to double-check two songs reported to be duplicates.

=head2 rm_song

    $ipod->rm_song($id);
    $ipod->rm_song(@ids);

Remove a song from the iPod. Takes one or more arguments, which are the id
numbers of the songs to be removed. (You can find the id numbers of songs using
the C<search> method.) Returns the number of songs successfully removed.

=head2 get_song

    my $song_info = $ipod->get_song($id);

Get information about a song. Takes one or more arguments, which are the id
numbers of songs. Returns a hash reference (or a list of hash references) with
the following keys, some of which may be undef:

=over 4

=item * id

=item * artist

=item * album

=item * title

=item * songnum

=item * songs

=item * cdnum

=item * cds

=item * composer

=item * year

=item * genre

=item * fdesc: A brief description of the file type

=item * filesize

=item * bitrate

=item * time: Playing time in milliseconds

=item * srate: The frequency in hertz

=item * playcount

=item * patht: The iPod-formatted path. To get a path in local filesystem format, use L<"get_path">.

=item * orig_path: The path to the file on the local filesystem. This key may not be available or accurate, depending on when and how this file was added to the database.

=back

As of version 1.2, all of the values of this hash are actually Unicode::String
objects. This probably will not matter because Unicode::String objects are
properly overloaded for stringification. However, if you have other data not in
Unicode, you may want to use the proper method from L<"Unicode::String"> to get
the data in the encoding you're expecting.

=head2 get_path

    $path = $ipod->get_path($id);

Get a path formatted by local filesystem conventions. Takes a list of ids as
arguments, returns a list of paths to the songs with those ids. If
C<mountpoint> isn't set, returns undef.

B<BUG WARNING>: If you try to get the path of a song that was added while
C<move_files> was false, you will probably get garbage.

=head2 search

    my @ids = $ipod->search(artist => 'Bob Dylan', title => 'watchtower', nocase => 1);

Search for songs on the iPod. The argument to this function is a hash of key =>
value pairs that give attributes that the returned songs will match. You may
search on any of the keys that appear in the hashref returned from C<get_song>
(listed above). You may specify multiple keys, in which case the songs returned
must match ALL of the values specified. By default, searches are regexes, which
means that searching for C<< artist => 'Cure' >> will return songs labeled
'Cure', 'The Cure', 'Cure, The', and 'Cured!' You may also use regex
metacharacters in your values, like C<< title => '[Tt]he' >>, or even
precompiled regexes created with qr//. A list of id numbers is returned, which
can be used with C<get_song> to get the complete information about a song.

You may also alter the behavior of the search by using special hash keys.
These keys are:

=over 4

=item * exact

Only return songs that match the given terms EXACTLY. This tests using C<eq>
instead of a regular expression, and so is much faster.

=item * nocase

Perform a case-insensitive search. This is not mutually exclusive with
C<exact>; using both of them searches for things that are identical except with
regard to case.

=item * nometachar

Ignore regular expression metacharacters in the values given. (Redundant when
used with C<exact>.)

=back

The search results are returned to you sorted by Artist > Album > Cdnum >
Songnum > Title.

=head2 all_songs

    my @songs = $ipod->all_songs;

Return a list of the id's all of the song ids on the iPod.

=head2 add_pl

    $ipod->add_pl($name, @songs);

Adds a playlist to the iPod. The first argument to this function should be the
name of the playlist to be added, and the remaining arguments either the id's
of the songs in that playlist or a hash reference. If you give a hash reference
as one of the arguments, the hash should consistof key => value pairs just like
ones you would pass to L<"search">. When you do this, the ids of the songs
matching your search terms will be inserted into the playlist when you call
L<"write_itunes">, similar to what happens when you use smartplaylist in
iTunes.

For example, the following creates a playlist with the songs numbered 3, 7, and
15:

    $ipod->add_pl("playlist 1", 3, 7, 15);

This example creates a playlist with song 3, all songs with the artist 'foo',
and then song 15:

    $ipod->add_pl("playlist 2", 3, { artist => 'foo' }, 15);

=head2 get_pl

    my $pl = $ipod->get_pl($name);
    my @pls = $ipod->get_pl(@names);

Gets an array reference to the playlist given by C<$name>, or C<undef> if no
such playlist exists. The elements of the array reference are the same as the
arguments given to L<"add_pl">, either id numbers or hash references which can
be passed to L<"search"> to get id numbers. To find out what a playlist will
look like when all of the hash references are expanded, use L<"render_pl">.

=head2 render_pl

    my @ids = $ipod->render_pl($name);

Get a list of the songs in playlist C<$name> after all of the hash references
in that playlist are expanded. This will give you exactly the songs as they
will appear when you call L<"write_itunes">.

=head2 all_pls

    @pls = $ipod->all_pls;

Returns an array of the names of all playlists currently in the iPod.

=head2 rm_pl

    $ipod->rm_pl($name);
    $ipod->rm_pl(@names);

Removes a playlist from the ipod. Returns the number of playlists actually deleted.

=head2 get_spl

    my $spl = $ipod->get_spl($name);
    my @spls = $ipod->get_spl(@names);

Gets a hash reference describing the smartplaylist given by C<$name>, or
C<undef> if no such smartplaylist exists. The format of the hash reference
returned is not documented and should not be touched.

=head1 NOTES

The GNUpod XML file is expected to be encoded in UTF-8. Other encodings will
probably work as well (UTF-16 has been tried successfully), but Your Mileage
May Vary.

Playlists that contain <add /> elements that don't have id attributes, <regex
/> elements, or <iregex /> elements may produce songs in a different order than
the order produced by the GNUpod script mktunes.pl. This is because mktunes.pl
simply adds matching songs to the playlist in the order that it finds them,
while this module sorts them by artist, album, cdnum, tracknum, and title. What
the module does is better :).

=head1 TODO

Catch up with new development on GNUpod, ensure compatibility with all iPod
formats.

=head1 BUGS

Smartplaylist support is untested, so it's entirely possible that this module
will munge your smartplaylists (though it tries not to).

Turning C<move_files> on and off during the life of an object may have strange
side effects. If you only set it once at the beginning of the script, you'll be
safe.

=head1 AUTHOR

Original GNUpod scripts by Adrian Ulrich <F<pab at blinkenlights.ch>>.
Adaptation for CPAN, much code rewriting, and expansion by JS Bangs
<F<jaspax@cpan.org>>. Patch for MP4 files by Masanori Hara.

=head2 HELP WANTED

For the past few years, the only development on this module has been from
bugfixes sent by other people. This is because I no longer have an iPod (gave
it to my brother) or the time to work on the module (graduated from college and
got a real job). If you have both of these things, you might want to take over
as primary maintainer for this module. There is a lot of work that could be
done, catching up with recent development in the GNUpod project and exploiting
features of the newer iPods. If you're interested, drop me a line at the email
address given above.

=head1 VERSION

v. 1.24, October 25, 2008.

=head1 LICENSE

The GNUpod scripts are released under the GNU Public License (GPL). This module
adaptation is released under the same terms as Perl itself (a conjunction of
the GPL and the Artistic License).

iTunes and iPod are trademarks of Apple. This module is neither written nor
supported by Apple.

=cut
