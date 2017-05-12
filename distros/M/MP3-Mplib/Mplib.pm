package MP3::Mplib;

use 5.005003;
use strict;
use Errno;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION $AUTOLOAD);

@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MP3::Mplib ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

@EXPORT = qw(
	MP_EERROR
	MP_EFCOMPR
	MP_EFENCR
	MP_EFNF
	MP_EVERSION
    ISO_8859_1
    UTF16
    UTF16BE
    UTF8
);

%EXPORT_TAGS = ( 
    'constants' => [ qw(
        MP_ALBUM
        MP_ARTIST
        MP_COMMENT
        MP_EERROR
        MP_EFCOMPR
        MP_EFENCR
        MP_EFNF
        MP_EVERSION
        MP_GENRE
        MP_TITLE
        MP_TRACK
        MP_YEAR), @EXPORT ],
    'functions' => [ qw(
        get_header
        get_tag
        get_id3v2_header
        set_tag
        delete_tags
        clean_up
        dump_structure), @EXPORT ],
    );
    
$EXPORT_TAGS{ 'all' } = [ @{ $EXPORT_TAGS{'constants'} },
                          @{ $EXPORT_TAGS{'functions'} },
                          @EXPORT ];

@EXPORT_OK = ( @{ $EXPORT_TAGS{'constants'} },
               @{ $EXPORT_TAGS{'functions'} } );


$VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
        if ($!{EINVAL}) {
            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        }
        else {
            croak "Your vendor has not defined MP3::Mplib macro $constname";
        }
    }
    
    {   no strict 'refs';
	    *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

bootstrap MP3::Mplib $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

=head1 NAME

MP3::Mplib - Speedy access to id3v1 and id3v2 tags

=head1 SYNOPSIS

    use MP3::Mplib;

    my $mp3 = MP3::Mplib->new("/path/to/file.mp3");
    my $v1tag = $mp3->get_v1tag;
    my $v2tag = $mp3->get_v2tag;
    
    while (my ($key, $val) = each %$v1tag) {
        print "$key: $val\n";
    }
    
    while (my ($key, $val) = each %$v2tag) {
        ...
    }

    $mp3->add_to_v2tag( { TYER => 2002 } );

=head1 DESCRIPTION

MP3::Mplib is a wrapper around Stefan Podkowinski's mplib written in C. It combines the best of both worlds: C's speed and Perl's nice object-orientedness. Note that B<MP3::Mplib> ships with its own version of mplib (currently 1.0.1).

There is no sophistaced class hierarchy. You simply create a B<MP3::Mplib> object. Each method either returns a native Perl data-structure or takes one. Bang. That's it.

=head1 METHODS

=over 4

=item B<new(file)>

Constructor that takes a filename as only argument.

    my $mp3_object = MP3::Mplib->new("file.mp3");

=back

=cut

sub new {
    my ($class, $file) = @_;
    $class = ref($class) || $class;
    my $self =  {   _mp_file        => $file,
                    _mp_id3v1       => undef,
                    _mp_id3v2       => undef, 
                    _mp_header      => undef, 
                    _mp_v2header    => undef,}; 
    bless $self => $class;
}

=pod

=over 4

=item B<header>

Returns a hash-ref to the mpeg-header.

    my $mpeg_header = $mp3->header;
    print $mpeg_header->{bitrate}, "\n";
    ...

The hash-ref contains the following fields:

=over 8

=item * I<syncword>        (integer)

=item * I<version>         (string)

=item * I<layer>           (string)

=item * I<protbit>         (boolean)

=item * I<bitrate>         (string)

=item * I<samplingfreq>    (string)

=item * I<padbit>          (boolean)

=item * I<privbit>         (boolean)

=item * I<mode>            (string)

=item * I<mode_ext>        (boolean)

=item * I<copyright>       (boolean)

=item * I<originalhome>    (boolean)

=item * I<emphasis>        (boolean)

=back

=back

Z<>

=cut

sub header { 
    my $self = shift;
    return ($self->{_mp_header} ||= get_header($self->{_mp_file}));
}

=pod

=over 4

=item B<get_v1tag>

Returns the id3v1 tag as a hash-ref.

    my $tag = $mp3->get_v1tag;
    print $tag->{title}, "\n";

The hash-ref contains the following fields:

=over 8

=item * I<artist>

=item * I<title>

=item * I<album>

=item * I<genre>

=item * I<track>

=item * I<year>

=item * I<comment>

=back

=back

Z<>

=cut

sub get_v1tag {
    my $self = shift;
    return ($self->{_mp_id3v1} ||= get_tag($self->{_mp_file}, 1) 
                               || { } );
}

=pod

=over 4

=item B<get_v2tag>

Returns the id3v2 tag as a hash-ref.

    my $tag = $mp3->get_v2tag;
    print $tag->{TIT1}, "\n";

The hash-ref returned can contain up to 74 fields. All but the "COMM" and "WXXX" field have a single value if present. 

The "COMM" field is the id3v2-equivalent of the 'comment' tag and contains three sub-categories:

=over 8

=item * I<text>

The actual comment as an arbitrarily long text.

=item * I<short>

A short description of the comment.

=item * I<lang>

The language of the comment as 3-byte string, e.g. "ENG" for English or "GER" for German.

=back

The "WXXX" field looks like this:

=over 8

=item * I<url>

The URL that is referenced.

=item * I<description>

An additional description.

=back

=back

Example:

    my $tag = $mp3->get_v2tag;
    if (exists $tag->{COMM}) {
        print "Language: $tag->{COMM}->{lang}\n";
        print "Short:    $tag->{COMM}->{short}\n";
        print "Text:     $tag->{COMM}->{text}\n";        
    }

=cut

sub get_v2tag {
    my $self = shift;
    return ($self->{_mp_id3v2} ||= get_tag($self->{_mp_file}, 2) 
                               || { } );
}

=pod

=over 4

=item B<get_v2header>

Returns a hash-ref to the id3v2 header. This can contain the following fields:

=over 8

=item * I<ver_minor>

The 'x' as in 2.x.1

=item * I<ver_revision>

The 'x' as in 2.3.x

=item * I<unsync>

=item * I<experimental>

=item * I<footer>

=item * I<total_tag_size>

=item * I<extended_header>

A reference to the extended header if present.

=back

The extended header has the following fields:

=over 8

=item * I<size>

=item * I<flag_bytes>

=item * I<no_flag_bytes>

=item * I<is_update>

=item * I<crc_data_present>

=item * I<crc_data_length>

=item * I<crc_data>

=item * I<restrictions>

=item * I<restrictions_data_length>

=item * I<restrictions_item_data>

=back

Since the extended header field only exists when the MP3 file has such a header, check for existance before accessing it:

    my $header = $mp3->get_v2header;
    if (exists $header->{extended_header}) {
        print $header->{extended_header}->{size}, "\n";
        ...
    }

=back

=cut

sub get_v2header {
    my $self = shift;
    return ($self->{_mp_v2header} ||= get_id3v2_header($self->{_mp_file}) 
                                  || { } );
}

=pod

=over 4

=item B<set_v1tag(tag, [encoding])>

Sets the id3v1-tag. If there was no such tag previously, it is created. An existing one is replaced.

It takes one obligatory argument, namely a reference to a hash. This hash has the keys described in C<get_v1tag()>.

'encoding' is an optional argument that determines the character encoding used for the data. It is either of the constants ISO_8859_1, UTF16, UTF16BE or UTF8. If none is given, ISO_8859_1 is used.

    $mp3->set_v1tag( { title     => 'Help',
                       artist    => 'The Beatles',
                       track     => 1,
                       year      => 1966,
                       genre     => 'Oldies',
                       comment   => 'A Beatles-song', }, &UTF16 );

Returns a true value on success, false otherwise. In this case, check C<$mp3-E<gt>error>.

=back

=cut
                          
sub set_v1tag {
    my ($self, $tag, $enc) = @_;
    
    croak "MP3::Mplib::set_v1tag expects a hash-ref as first argument"
       if ref $tag ne 'HASH';
       
    if (set_tag($self->{_mp_file}, 1, $tag, $enc || &ISO_8859_1)) {
        # forces re-parsing on next get_v1header
        undef $self->{_mp_id3v1};
        return 1;
    }
    return;
}

=pod

=over 4

=item B<add_to_v1tag(tag, [encoding])>

Adds (or rather merges) 'tag' with the currently existing id3v1-tag. Existing fields are replaced. Use this to add a field to an already existing tag. 'tag' is meant to be a hash-reference:

    $mp3->add_to_v1tag( { TITLE => 'some title',
                          ALBUM => 'some album', } );

Returns a true value on success, false otherwise in which case you should check C<$mp3-E<gt>error>.

=back

=cut

sub add_to_v1tag {
    my ($self, $tag, $enc) = @_;
    
    croak "MP3::Mplib::add_to_v1tag expects a hash-ref as first argument"
        if ref $tag ne 'HASH';
        
    my %old_tag = %{ $self->get_v1tag };

    if (set_tag($self->{_mp_file}, 1, 
                { %old_tag, %$tag }, $enc || &ISO_8859_1)) {
        undef $self->{_mp_id3v1};
        return 1;
    }
    return;
}
           
=pod

=over 4

=item B<set_v2tag(tag, [encoding])>

Sets the id3v2 tag. This has the same semantics as C<set_v1tag>, so read its description first.

It differs in that id3v2 tags have different field names. They are always four ccharacter long uppercased strings. Since there are 74 of them, their explanation is not included in here. Please see the specifications at B<http://www.id3.org/>.

A number of fields are special in that they don't just take one value. You can pass a hash-ref to them instead:

=over 8

=item * I<COMM> [comment field]

Possible fields are I<'text'>, I<'short'> and I<'lang'>. I<'lang'> is always a three character upper-case string. When just an ordinary string is passed, this will become I<'text'>. I<'short'> will be left empty in this case and I<'lang'> is set to 'ENG'.

=item * I<WXXX> [used defined link frame]

Possible fields are I<'url'> and I<'description'>. The content of I<'url'> has to be a ISO-8859-1 encoded string regardless of which 'encoding' you passed to C<set_v2tag>. When just an ordinary string is passed, this will become I<'url'>. I<'description'> will remain empty in this case.

=back

Further examples:

    my $tag = { TIT2 => 'Help',
                COMM => { lang  => 'ENG',
                          text  => 'Long comment ...',
                          short => 'short description', },
                WXXX => 'http://www.beatles.com',
                TEXT => 'Paul McCartney', # the text writer
                TPE1 => 'Paul McCartney', # the lead performer
                TPE2 => 'The Beatles',    # the band
                ..., };
    $mp3->set_v2header($tag);

In the above, the I<'WXXX'> could have also looked like this:

    WXXX => { url         => 'http://www.beatles.com',
              description => 'a webpage', },

or somesuch.

This method has the same return values as C<set_v1tag>.

=back

=cut

sub set_v2tag {
    my ($self, $tag, $enc) = @_;
    
    croak "MP3::Mplib::set_v2tag expects a hash-ref as first argument"
        if ref $tag ne 'HASH';
        
    if (set_tag($self->{_mp_file}, 2, $tag, $enc || &ISO_8859_1)) {
        # forces re-parsing on next get_v2header
        undef $self->{_mp_id3v2};
        return 1;
    }
    return;
}

=pod

=over 4

=item B<add_to_v2tag>

The id3v2 equivalent to C<add_to_v1tag>. It has the same semantics, both regarding the arguments it gets as well as its return value.

=back

=cut

sub add_to_v2tag {
    my ($self, $tag, $enc) = @_;
    croak "MP3::Mplib::add_to_v2tag expects a hash-ref as first argument"
        if ref $tag ne 'HASH';

    my %oldtag = %{ $self->get_v2tag };

    if (set_tag($self->{_mp_file}, 2, 
                { %oldtag, %$tag }, $enc || &ISO_8859_1)) {
        undef $self->{_mp_id3v2};
        return 1;
    }
    return;
}
    
    
=pod

=over 4

=item B<del_v1tag>

Deletes the id3v2 tag from the file.

=back

=cut

sub del_v1tag {
    my $self = shift;
    if (delete_tags($self->{_mp_file}, 1)) {
        undef $self->{_mp_id3v1};
        return 1;
    }
    return 0;    
}

=pod

=over 4

=item B<del_v2tag>

Deletes the id3v2 tag. Correctly speaking, it deletes I<all> id3v2 tags in the file. But since B<MP3::Mplib> does not allow access to particular id3v2 tags this distinction should not matter.

=back

=cut

sub del_v2tag {
    my $self = shift;
    if (delete_tags($self->{_mp_file}, 2)) {
        undef $self->{_mp_id3v2};
        return 1;
    }
    return 0;
}

=pod

=over 4

=item B<clean_up>

Some MP3s may have a very extensive id3v2-tag with some fields showing up several times. If you don't like that, use this method to wipe out all but the first frame of each type.

This method doesn't return anything meaningful since it never fails.

=back

=cut

sub clean_up {
    my $self = shift;
    _clean_up($self->{_mp_file});
    return 1;
}

=pod

=over 4

=item B<dump_structure>

Mainly used as a debugging tool (or if you are just curious to peek at all the tags and fields present in an MP3), this method dumps the tag-structure of the MP3 to STDOUT.

This method doesn't return anything meaningful since it never fails.

=back

=cut

sub dump_structure {
    my $self = shift;
    _dump_structure($self->{_mp_file});
    return 1;
}

=pod

=over 4

=item B<error>

As always, things can get wrong on certain operations. The statement that did not perform as expected always returns a false value in which case this functions returns a reference to a hash that you can inspect further. Keys of the hash are field names of an id3-tag while the corresponding values are set to an error-code (see L<MP3::Mplib/Error Codes>). 

There is a special key: I<mp_file> relates to the file rather than to an individual tag-field. This might be set when you try to write a new tag on a read-only file.

Note that C<error> can be called either as instance-method, class-method or function:

    my %err = $mp3->error;
    my %err = MP3::Mplib->error;
    my %err = MP3::Mplib::error();

It is not exported so you have to qualify it when calling it as function.

=back

=cut

sub error { return { split /\034/, $MP3::Mplib::Error || '' } }

=head1 EXPORTS

=head2 Default exports

B<MP3::Mplib> exports a couple of constants by default. If you don't want them, include the module in your scripts like this:

    use MP3::Mplib ();

Please note that each of these constants has to be called as subroutine, either with empty trailing paranteses or a leading ampersand:

    my $c = ISO_8859_1; # NOT OK!

    # instead:
    
    my $c = &ISO_8859_1; 
    # or
    my $c = ISO_8859_1();

=over 4

=item B<Encodings>

=over 8

=item * I<ISO_8859_1>

=item * I<UTF16>

=item * I<UTF16BE>

=item * I<UTF8>

=back

Z<>

=item B<Error codes>

=over 8

=item * I<MP_EERROR>

This is a non-specific error code that is - according to the mplib.h - returned under circumstances that cannot happen. :-)

=item * I<MP_EFNF>

The specified field does not exist in the tag.

=item * I<MP_EFCOMPR>

The value for this field has been compressed and can thus not be retrieved.

=item * I<MP_EFENCR>

The value for this field has been encrypted and can thus not be retrieved.

=item * I<MP_EVERSION>

Tag has a version set that is not supported by the library.

=back

=back

=head2 Optional exports

B<MP3::Mplib> has a couple of tags you can import:

    use MP3::Mplib qw(:constants)
    use MP3::Mplib qw(:functions)
    use MP3::Mplib qw(:all)

=over 4

=item B<:constants>

This exports additional constants used for identifying id3v1 tag fields. These are integers so you B<cannot> use them as hash-keys for C<set_v1header> or get C<get_v1header>!

=over 8

=item * I<MP_ARTIST>

=item * I<MP_TITLE>

=item * I<MP_ALBUM>

=item * I<MP_GENRE>

=item * I<MP_COMMENT>

=item * I<MP_YEAR>

=item * I<MP_TRACK>

=back

Z<>

=item B<:functions>

Seven functions are exported by this tag. Use those when you want the functional interface:

=over 8

=item * I<get_header>

=item * I<get_tag>

=item * I<get_id3v2_header>

=item * I<set_tag>

=item * I<delete_tags>

=item * I<clean_up>

=item * I<dump_structure>

=back

For a description see L<FUNCTIONS>.

=back

=head1 FUNCTIONS

When using the functional interface, you are using directly the functions defined through XS code. All of them have a prototype so that you can safely omit the parens when using them.

=over 4

=item B<get_header $file>

Returns a hash-ref to the mpeg-header. Fields are described under C<header> in L<"METHODS">.

=item B<get_tag $file, $version>

Returns a hash-ref to the id3-tag for the given C<$file>. C<$version> must either be 1 or 2.

Returns undef if no tag of the specified C<$version> has been found.

=item B<get_id3v2_header $file>

Returns a hash-ref to the id3v2-header for the given C<$file>. Fields are described under C<get_v2header> in L<"METHODS">.

=item B<set_tag $file, $version, $tag, [$enc]>

Sets the tag of C<$version> for C<$file> to C<$tag> which has to be a hash-reference. C<$enc> is optional but if given has to be one of the constants described under "Encodings" in L<"EXPORTS">. It defaults to C<ISO_8859_1>.

Returns a true value on success, false otherwise. Check C<MP3::Mplib::error()> in this case.

=item B<delete_tags $file, $version>

Deletes all tags of C<$version> in C<$file>. 

Returns a true value on success false otherwise. Currently C<MP3::Mplib::error()> is B<not> set when this functions fails.

=item B<clean_up $file>

Cleans up the id3v2-tag of C<$file>. See C<clean_up> in L<"METHODS"> for details.

=item B<dump_structure $file>

Dumps the tag-structure of C<$file> to STDOUT. See C<dump_structure> in L<"METHODS"> for details.

=back

=head1 PLATFORMS

=over 4

=item B<Operating systems>

My development environment is a Debian box. In theory I should have access to some Solaris machines in my university but forgot my login. That means it's currently just tested under Linux.

I'd be grateful for anyone sending me remarks how well (or even at all) this module works on his/her machine. If someone is using ActiveState under Windows and did in fact install it succesfully I'd be even happier to hear about that. Perhaps this person would even be so kind to help me packing up a PPM package or even become the Windows-maintainer. Since I am lacking VisualC I am closed out here.

=item B<Perl versions and compilers>

I've tested it with the following compilers and Perl versions:

=over 8

=item * gcc 2.95.4 / Perl 5.005_03

=item * gcc 2.95.4 / Perl 5.6.1 

=item * gcc 3.0.4  / Perl 5.8.0 

=back

=back

=head1 KNOWN BUGS

The underlying C library is incomplete with respect to parsing id3v2 tags. This is ok with simple tags, like all the I<Txxx> frames. It is not so ok with more complicated ones, such as I<WXXX>. I contacted mplib's author with a request for adding missing functionality. The mplib's author said that they might be added at some other time.

Currently, some missing functionality has been added by me (notably support for I<WXXX>).

The current object-oriented interface could be considered a bug. There is only the C<MP3::Mplib> object and no separate objects for id3v1- or id3v2-tags. Adding those, however, would require additions to the XS-portion of this module. Read: A lot of additional work.

=head1 TODO

Well, see L<"KNOWN BUGS">.

=over 4

=item B<Missing functionality from mplib>

Some functionality from the mplib hasn't yet been incorporated into this library:

=over 8

=item * I<mp_convert_to_v1(id3_tag* tag)>

Converts an id3v2-tag into an id3v1-tag.

=item * I<mp_convert_to_v2(id3_tag* tag)>

Vice versa.

=item * I<mp_is_valid_v1_value(int field, char* value)>

Does some checks on an id3v1 field value. Oddly enough, there is no equivalent for id3v2 fields in the library.

=back

=item B<Additional functionality>

I would like to have support for the I<APIC> frame (attached picture). Something like the following would be nice:

    $mp3->attach($file, $description);

Probably much more, but I am in modest-mode right now.

=item B<Error handling>

Always an issue with me. Each object should have its own error reporting mechanism.

=item B<Tests>

No tests yet for functional interface, nor for the header access.

=back

=head1 VERSION

This document describes version 0.02.

=head1 AUTHOR AND COPYRIGHT

Tassilo v. Parseval <tassilo.von.parseval@rwth-aachen.de>

Copyright (c)  2002-2004 Tassilo von Parseval.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

B<http://www.id3.org/> for the id3 specifications.

B<http://mplib.sourceforge.net/> if you want to visit mplib's home.

=cut

1;

__END__
