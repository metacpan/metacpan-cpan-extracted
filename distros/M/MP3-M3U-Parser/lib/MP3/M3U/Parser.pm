package MP3::M3U::Parser;
$MP3::M3U::Parser::VERSION = '2.33';
use strict;
use warnings;
use base qw( MP3::M3U::Parser::Export );
use Carp qw( croak );
use MP3::M3U::Parser::Constants;

my %LOADED;

sub new {
    # -parse_path -seconds -search -overwrite
    my($class, @args) = @_;
    my %o    = @args % 2 ? () : @args; # options
    my $self = {
        _M3U_         => [], # for parse()
        TOTAL_FILES   =>  0, # Counter
        TOTAL_TIME    =>  0, # In seconds
        TOTAL_SONGS   =>  0, # Counter
        AVERAGE_TIME  =>  0, # Counter
        ACOUNTER      =>  0, # Counter
        ANON          =>  0, # Counter for SCALAR & GLOB M3U
        INDEX         =>  0, # index counter for _M3U_
        EXPORTF       =>  0, # Export file name counter for anonymous exports
        seconds       => $o{'-seconds'}    || EMPTY_STRING, # format or get seconds.
        search_string => $o{'-search'}     || EMPTY_STRING, # search_string
        parse_path    => $o{'-parse_path'} || EMPTY_STRING, # mixed list?
        overwrite     => $o{'-overwrite'}  ||            0, # overwrite export file if exists?
        encoding      => $o{'-encoding'}   || EMPTY_STRING, # leave it to export() if no param
        expformat     => $o{'-expformat'}  || EMPTY_STRING, # leave it to export() if no param
        expdrives     => $o{'-expdrives'}  || EMPTY_STRING, # leave it to export() if no param
    };
    my $s = $self->{search_string};
    if ( $s && length $s < MINIMUM_SEARCH_LENGTH ) {
        croak 'A search string must be at least three characters long';
    }
    bless  $self, $class;
    return $self;
}

sub parse {
    my($self, @files) = @_;

    foreach my $file ( @files ) {
        $self->_parse_file(
            ref $file ? $file
                      : do {
                            my $new = $self->_locate_file( $file );
                            croak "$new does not exist" if ! -e $new;
                            $new;
                        }
        );
    }

    # Average time of all the parsed songs:
    my($ac, $tt)          = ( $self->{ACOUNTER}, $self->{TOTAL_TIME} );
    $self->{AVERAGE_TIME} = ($ac && $tt) ? $self->_seconds( $tt / $ac ) : 0;
    return defined wantarray ? $self : undef;
}

sub _check_parse_file_params {
    my($self, $file) = @_;

    my $ref = ref $file;
    if ( $ref && $ref ne 'GLOB' && $ref ne 'SCALAR' ) {
        croak "Unknown parameter of type '$ref' passed to parse()";
    }

    my $cd;
    if ( ! $ref ) {
        my @tmp = split m{[\\/]}xms, $file;
        ($cd = pop @tmp) =~ s{ [.] m3u }{}xmsi;
    }

    my $this_file = $ref ? 'ANON'.$self->{ANON}++ : $self->_locate_file($file);

    $self->{'_M3U_'}[ $self->{INDEX} ] = {
        file  => $this_file,
        list  => $ref ? $this_file : ($cd || EMPTY_STRING),
        drive => DEFAULT_DRIVE,
        data  => [],
        total => 0,
    };

    $self->{TOTAL_FILES} += 1; # Total lists counter

    my($fh, @fh);
    if ( $ref eq 'GLOB' ) {
        $fh = $file;
    }
    elsif ( $ref eq 'SCALAR' ) {
        @fh = split m{\n}xms, ${$file};
    }
    else {
        # Open the file to parse:
        require IO::File;
        $fh = IO::File->new;
        $fh->open( $file, '<' ) or croak "I could't open '$file': $!";
    }
    return $ref, $fh, @fh;
}

sub _validate_m3u {
    my($self, $next, $ref, $file) = @_;
    PREPROCESS: while ( my $m3u = $next->() ) {
        # First line is just a comment. But we need it to validate
        # the file as a m3u playlist file.
        chomp $m3u;
        last PREPROCESS if $m3u =~ RE_M3U_HEADER;
        croak $ref ? "The '$ref' parameter does not contain valid m3u data"
                   : "'$file' is not a valid m3u file";
    }
    return;
}

sub _iterator {
    my($self, $ref, $fh, @fh) = @_;
    return $ref eq 'SCALAR' ? sub { return shift @fh } : sub { return <$fh> };
}

sub _extract_path {
    my($self, $i, $m3u, $device_ref, $counter_ref) = @_;

    if ( $m3u =~ RE_DRIVE_PATH  ||
         $m3u =~ RE_NORMAL_PATH ||
         $m3u =~ RE_PARTIAL_PATH
        ) {
        # Get the drive and path info.
        my $path   = $1;
        $i->[PATH] = $self->{parse_path} eq 'asis' ? $m3u : $path;
        if ( ${$device_ref} eq DEFAULT_DRIVE && $m3u =~ m{ \A (\w:) }xms ) {
            ${$device_ref} = $1;
        }
        ${ $counter_ref }++;
    }
    return;
}

sub _extract_artist_song {
    my($self, $i) = @_;
    # Try to extract artist and song info
    # and remove leading and trailing spaces
    # Some artist names can also have a "-" in it.
    # For this reason; require that the data has " - " in it.
    # ... but the spaces can be one or more.
    # So, things like "artist-song" does not work...
    my($artist, @xsong) = split m{\s{1,}-\s{1,}}xms, $i->[ID3] || $i->[PATH];
    if ( $artist ) {
        $artist = $self->_trim( $artist );
        $artist =~ s{.*[\\/]}{}xms; # remove path junk
        $i->[ARTIST] = $artist;
    }
    if ( @xsong ) {
        my $song = join q{-}, @xsong;
        $song = $self->_trim( $song );
        $song =~ s{ [.] [a-zA-Z0-9]+ \z }{}xms; # remove extension if exists
        $i->[SONG] = $song;
    }
    return;
}

sub _initialize {
    my($self, $i);
    foreach my $CHECK ( 0..MAXDATA ) {
        $i->[$CHECK] = EMPTY_STRING if ! defined $i->[$CHECK];
    }
    return;
}

sub _parse_file {
    # supports disk files, scalar variables and filehandles (typeglobs)
    my($self, $file)   = @_;
    my($ref, $fh, @fh) = $self->_check_parse_file_params( $file );
    my $next           = $self->_iterator( $ref, $fh, @fh );

    $self->_validate_m3u( $next, $ref, $file );

    my $dkey   =  $self->{_M3U_}[ $self->{INDEX} ]{data};  # data key
    my $device = \$self->{_M3U_}[ $self->{INDEX} ]{drive}; # device letter

    # These three variables are used when there is a '-search' parameter.
    # long: total_time, total_songs, total_average_time
    my($ttime,$tsong,$taver) = (0,0,0);
    my $index = 0; # index number of the list array
    my $temp_sec;  # must be defined outside

    RECORD: while ( my $m3u = $next->() ) {
        chomp $m3u;
        next if ! $m3u; # Record may be blank if it is not a disk file.
        $#{$dkey->[$index]} = MAXDATA; # For the absence of EXTINF line.
        # If the extra information exists, parse it:
        if ( $m3u =~ RE_INF_HEADER ) {
            my($j, $sec, @song);
            ($j ,@song) = split m{\,}xms, $m3u;
            ($j ,$sec)  = split m{:}xms, $j;
            $temp_sec   = $sec;
            $ttime     += $sec;
            $dkey->[$index][ID3] = join q{,}, @song;
            $dkey->[$index][LEN] = $self->_seconds($sec || 0);
            $taver++;
            next RECORD; # jump to path info
        }

        my $i = $dkey->[$index];
        $self->_extract_path(        $i, $m3u, $device, \$tsong );
        $self->_extract_artist_song( $i );
        $self->_initialize(          $i );

        # If we are searching something:
        if ( $self->{search_string} ) {
            my $matched = $self->_search( $i->[PATH], $i->[ID3] );
            if ( $matched ) {
                $index++; # if we got a match, increase the index
            }
            else {
                # if we didnt match anything, resize these counters ...
                $tsong--;
                $taver--;
                $ttime -= $temp_sec;
                delete $dkey->[$index]; # ... and delete the empty index
            }
        }
        else {
            $index++; # If we are not searching, just increase the index
        }
    }

    $fh->close if ! $ref;
    return $self->_set_parse_file_counters( $ttime, $tsong, $taver );
}

sub _set_parse_file_counters {
    my($self, $ttime, $tsong, $taver) = @_;

    # Calculate the total songs in the list:
    my $k = $self->{_M3U_}[ $self->{INDEX} ];
    $k->{total} = @{ $k->{data} };

    # Adjust the global counters:
    $self->{TOTAL_FILES}-- if $self->{search_string} && $k->{total} == 0;
    $self->{TOTAL_TIME}  += $ttime;
    $self->{TOTAL_SONGS} += $tsong;
    $self->{ACOUNTER}    += $taver;
    $self->{INDEX}++;

    return $self;
}

sub reset { ## no critic (ProhibitBuiltinHomonyms)
    # reset the object
    my $self   = shift;
    my @zeroes = qw(
        TOTAL_FILES
        TOTAL_TIME
        TOTAL_SONGS
        AVERAGE_TIME
        ACOUNTER INDEX
    );

    foreach my $field ( @zeroes ) {
        $self->{ $field } = 0;
    }

    $self->{_M3U_} = [];

    return defined wantarray ? $self : undef;
}

sub result {
    my $self = shift;
    return(wantarray ? @{$self->{_M3U_}} : $self->{_M3U_});
}

sub _locate_file {
    require File::Spec;
    my $self = shift;
    my $file = shift;
    if ($file !~ m{[\\/]}xms) {
        # if $file does not have a slash in it then it is in the cwd.
        # don't know if this code is valid in some other filesystems.
        require Cwd;
        $file = File::Spec->catfile( Cwd::getcwd(), $file );
    }
    return File::Spec->canonpath($file);
}

sub _search {
    my($self, $path, $id3) = @_;
    return 0 if !$id3 && !$path;
    my $search = quotemeta $self->{search_string};
    # Try a basic case-insensitive match:
    return 1 if $id3 =~ /$search/xmsi || $path =~ /$search/xmsi;
    return 0;
}

sub _is_loadable {
    my($self, $module) = @_;
    return 1 if $LOADED{ $module };
    local $^W;
    local $@;
    local $!;
    local $^E;
    local $SIG{__DIE__};
    local $SIG{__WARN__};
    my $eok = eval qq{ require $module; 1; };
    return 0 if $@ || !$eok;
    $LOADED{ $module } = 1;
    return 1;
}

sub _escape {
    my $self = shift;
    my $text = shift || return EMPTY_STRING;
    if ( $self->_is_loadable('HTML::Entities') ) {
        return HTML::Entities::encode_entities_numeric( $text );
    }
    # fall-back to lame encoder
    my %escape = qw(
        &    &amp;
        "    &quot;
        <    &lt;
        >    &gt;
    );
    $text =~ s/ \Q$_\E /$escape{$_}/xmsg foreach keys %escape;
    return $text;
}

sub _trim {
    my($self, $s) = @_;
    $s =~ s{ \A \s+    }{}xmsg;
    $s =~ s{    \s+ \z }{}xmsg;
    return $s;
}

sub info {
    # Instead of direct accessing to object tables, use this method.
    my $self = shift;
    my $tt   = $self->{TOTAL_TIME};
    return
        songs   => $self->{TOTAL_SONGS},
        files   => $self->{TOTAL_FILES},
        ttime   => $tt ? $self->_seconds( $tt ) : 0,
        average => $self->{AVERAGE_TIME} || 0,
        drive   => [ map { $_->{drive} } @{ $self->{_M3U_} } ],
    ;
}

sub _seconds {
    # Format seconds if wanted.
    my $self = shift;
    my $all  = shift;
    return '00:00' if ! $all;
    my $ok   = $self->{seconds} eq 'format' && $all !~ m{:}xms;
    return $all if ! $ok;
    $all = $all / MINUTE_MULTIPLIER;
    my $min = int $all;
    my $sec = sprintf '%02d', int( MINUTE_MULTIPLIER * ($all - $min) );
    my $hr;
    if ( $min > MINUTE_MULTIPLIER ) {
        $all = $min / MINUTE_MULTIPLIER;
        $hr  = int $all;
        $min = int( MINUTE_MULTIPLIER * ($all - $hr) );
    }
    $min = sprintf q{%02d}, $min;
    return $hr ? "$hr:$min:$sec" : "$min:$sec";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MP3::M3U::Parser

=head1 VERSION

version 2.33

=head1 SYNOPSIS

    use MP3::M3U::Parser;
    my $parser = MP3::M3U::Parser->new( %options );
    
    $parser->parse(
        \*FILEHANDLE,
        \$scalar,
        '/path/to/playlist.m3u',
    );
    my $result = $parser->result;
    my %info   = $parser->info;
    
    $parser->export(
        -format   => 'xml',
        -file     => '/path/mp3.xml',
        -encoding => 'ISO-8859-9',
    );
    
    $parser->export(
        -format   => 'html',
        -file     => '/path/mp3.html',
        -drives   => 'off',
    );
    
    # convert all m3u files to individual html files.
    foreach ( <*.m3u> ) {
        $parser->parse( $_ )->export->reset;
    }
    
    # convert all m3u files to one big html file.
    foreach ( <*.m3u> ) {
        $parser->parse( $_ );
    }
    $parser->export;

=head1 DESCRIPTION

B<MP3::M3U::Parser> is a parser for M3U mp3 playlist files. It also 
parses the EXTINF lines (which contains id3 song name and time) if 
possible. You can get a parsed object or specify a format and export 
the parsed data to it. The format can be B<xml> or B<html>.

=head2 Methods

=head3 B<new>

The object constructor. Takes several arguments like:

=over 4

=item C<-seconds>

Format the seconds returned from parsed file? if you set this to the value 
C<format>, it will convert the seconds to a format like C<MM:SS> or C<H:MM:SS>.
Else: you get the time in seconds like; I<256> (if formatted: I<04:15>).

=item C<-search>

If you don't want to get a list of every song in the m3u list, but want to get 
a specific group's/singer's songs from the list, set this to the string you want 
to search. Think this "search" as a parser filter.

Note that, the module will do a *very* basic case-insensitive search. It does 
dot accept multiple words (if you pass a string like "michael beat it", it will 
not search every word seperated by space, it will search the string
"michael beat it" and probably does not return any results -- it will not match 
"michael jackson - beat it"), it does not have a boolean search support, etc.
If you want to do something more complex, get the parsed tree and use it in
your own search function, or subclass this module and write your own C<_search>
method (notice the underscore in the method name). See the tests for a
subclassing example.

=item C<-parse_path>

The module assumes that all of the songs in your M3U lists are (or were: 
the module does not check the existence of them) on the same drive. And it 
builds a seperate data table for drive names and removes that drive letter 
(if there is a drive letter) from the real file path. If there is no drive 
letter (eg: under linux there is no such thing, or you saved m3u file into 
the same volume as your mp3s), then the drive value is 'CDROM:'.

So, if you have a mixed list like:

   G:\a.mp3
   F:\b.mp3
   Z:\xyz.mp3

set this parameter to 'C<asis>' to not to remove the drive letter from the real 
path. Also, you "must" ignore the drive table contents which will still contain 
a possibly wrong value; C<export> does take the drive letters from the drive
tables. So, you can not use the drive area in the exported xml (for example).

B<Note:> you probably want to set this parameter to 'C<asis>' on a non-Windows
machine.

=item C<-overwrite>

Same as the C<-overwrite> option in L<export|/export> but C<new> sets this 
C<export> option globally.

=item C<-encoding>

Same as the C<-encoding> option in L<export|/export> but C<new> sets this 
C<export> option globally.

=item C<-expformat>

Same as the C<-format> option in L<export|/export> but C<new> sets this 
C<export> option globally.

=item C<-expdrives>

Same as the C<-drives> option in L<export|/export> but C<new> sets this 
C<export> option globally.

=back

=head3 B<parse>

It takes a list of arguments. The list can include file paths, 
scalar references or filehandle references. You can mix these 
types. Module interface can handle them correctly.

   open FILEHANDLE, ...
   $parser->parse(\*FILEHANDLE);

or with new versions of perl:

   open my $fh, ...
   $parser->parse($fh);

   my $scalar = "#EXTM3U\nFoo - bar.mp3";
   $parser->parse(\$scalar);

or

   $parser->parse("/path/to/some/playlist.m3u");

or

   $parser->parse("/path/to/some/playlist.m3u",\*FILEHANDLE,\$scalar);

Note that globs and scalars are passed as references.

Returns the object itself.

=head3 B<result>

Must be called after C<parse>. Returns the result set created from
the parsed data(s). Returns the data as an array or arrayref.

   $result = $parser->result;
   @result = $parser->result;

Data structure is like this:

   $VAR1 = [
             {
               'drive' => 'G:',
               'file' => '/path/to/mylist.m3u',
               'data' => [
                           [
                             'mp3\Singer - Song.mp3',
                             'Singer - Song',
                             232,
                             'Singer',
                             'Song'
                           ],
                           # other songs in the list
                         ],
               'total' => '3',
               'list' => 'mylist'
             },
             # other m3u list
           ];

Each playlist is added as a hashref:

   $pls = {
           drive => "Drive letter if available",
           file  => "Path to the parsed m3u or generic name if GLOB/SCALAR",
           data  => "Songs in the playlist",
           total => "Total number of songs in the playlist",
           list  => "name of the list",
   }

And the C<data> key is an AoA:

   data => [
            ["MP3 PATH INFO", "ID3 INFO","TIME","ARTIST","SONG"],
            # other entries...
            ]

You can use the Data::Dumper module to see the structure yourself:

   use Data::Dumper;
   print Dumper $result;

=head3 B<info>

You must call this after calling L<parse|/parse>. It returns an info hash 
about the parsed data.

   my %info = $parser->info;

The keys of the C<%info> hash are:

   songs   => Total number of songs
   files   => Total number of lists parsed
   ttime   => Total time of the songs 
   average => Average time of the songs
   drive   => Drive names for parsed lists

Note that the 'drive' key is an arrayref, while others are strings. 

   printf "Drive letter for first list is %s\n", $info{drive}->[0];

But, maybe you do not want to use the C<$info{drive}> table; see C<-parse_path> 
option in L<new|/new>.

=head3 B<export>

Exports the parsed data to a format. The format can be C<xml> or C<html>. 
The HTML File' s style is based on the popular mp3 player B<WinAmp>' s 
HTML List file. Takes several arguments:

=over 4

=item C<-file>

The full path to the file you want to write the resulting data. 
If you do not set this parameter, a generic name will be used.

=item C<-format>

Can be C<xml> or C<html>. Default is C<html>.

=item C<-encoding>

The exported C<xml> file's encoding. Default is B<ISO-8859-1>. 
See L<http://www.iana.org/assignments/character-sets> for a list. 
If you don't define the correct encoding for xml, you can get 
"not well-formed" errors from the xml parsers. This value is 
also used in the meta tag section of the html file.

=item C<-drives>

Only required for the html format. If set to C<off>, you will not 
see the drive information in the resulting html file. Default is 
C<on>. Also see C<-parse_path> option in L<new|/new>.

=item C<-overwrite>

If the file to export exists on the disk and you didn't set this 
parameter to a true value, C<export> will die with an error.

If you set this parameter to a true value, the named file will be 
overwritten if already exists. Use carefully.

Has no effect if you use C<-toscalar> option.

=item C<-toscalar>

With the default configuration, C<export> method will dump the 
exported data to a disk file, but you can alter this behaviour 
if you pass this parameter with a reference to a scalar.

   $parser->export(-toscalar => \$dumpvar);
   # then do something with $dumpvar

=back

Returns the object itself.

=head3 B<reset>

Resets the parser object and returns the object itself. Can be usefull 
when exporting to html.

   $parser->parse($fh       )->export->reset;
   $parser->parse(\$scalar  )->export->reset;
   $parser->parse("file.m3u")->export->reset;

Will create individual files while this code

   $parser->parse($fh       )->export;
   $parser->parse(\$scalar  )->export;
   $parser->parse("file.m3u")->export;

creates also individual files but, file2 content will include 
C<$fh> + C<$scalar> data and file3 will include 
C<$fh> + C<$scalar> + C<file.m3u> data.

=head2 Subclassing

You may want to subclass the module to implement a more advanced
search or to change the HTML template.

To override the default search method create a C<_search> method 
in your class and to override the default template create a C<_template> 
method in your class.

See the tests in the distribution for examples.

=head2 Error handling

Note that, if there is an error, the module will die with that error. So, 
using C<eval> for all method calls can be helpful if you don't want to die:

    my $eval_ok = eval {
       $parser->parse( @list );
       1;
    }
    die "Parser error: $@" if $@ || !$eval_ok;

As you can see, if there is an error, you can catch this with C<eval> and 
access the error message with the special Perl variable C<$@>.

=head1 NAME

MP3::M3U::Parser - MP3 playlist parser.

=head1 EXAMPLES

See the tests in the distribution for example codes. If you don't have 
the distro, you can download it from CPAN.

=head2 TIPS

=over 4

=item B<Winamp>

(For v2.80) If you don't see any EXTINF lines in 
your saved M3U lists, open preferences, go to "Options", set "Read titles on" 
to "B<Display>", add songs to your playlist and scroll down/up in the playlist 
window until you see all songs' time infos. If you don't do this, you'll get 
only the file names or only the time infos for the songs you have played.
Because, to get the time info, winamp must read/scan the file first.

=item B<Naming M3U Files>

Give your M3U files unique names and put them into the same directory. This way, 
you can have an easy maintained archive.

=back

=head1 CAVEATS

HTML and XML escaping is limited to these characters: 
E<amp> E<quot> E<lt> E<gt> B<unless> you have C<HTML::Entities> installed.

=head1 SEE ALSO

L<HTML::Entities>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
