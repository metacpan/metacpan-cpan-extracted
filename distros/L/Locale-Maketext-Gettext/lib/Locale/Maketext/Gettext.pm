# Locale::Maketext::Gettext - Joins the gettext and Maketext frameworks

# Copyright (c) 2003-2021 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.
# First written: 2003/4/23

package Locale::Maketext::Gettext;
use 5.008;
use strict;
use warnings;
use base qw(Locale::Maketext Exporter);
our ($VERSION, @EXPORT, @EXPORT_OK);
$VERSION = 1.32;
@EXPORT = qw(read_mo);
@EXPORT_OK = @EXPORT;
# Prototype declaration
sub read_mo($);

use Encode qw(encode decode FB_DEFAULT);
use File::Spec::Functions qw(catfile);
no strict qw(refs);

our (%CACHE, $REREAD_MO, $MO_FILE);
%CACHE = qw();
$REREAD_MO = 0;
$MO_FILE = "";
our (@SYSTEM_LOCALEDIRS);
@SYSTEM_LOCALEDIRS = qw(/usr/share/locale /usr/lib/locale
    /usr/local/share/locale /usr/local/lib/locale);

# Set or retrieve the output encoding
sub encoding : method {
    local ($_, %_);
    my $self;
    ($self, $_) = @_;
    
    # This is not a static method
    return if ref($self) eq "";
    
    # Set the output encoding
    if (@_ > 1) {
        if (defined $_) {
            $self->{"ENCODING"} = $_;
        } else {
            delete $self->{"ENCODING"};
        }
        $self->{"USERSET_ENCODING"} = $_;
    }
    
    # Return the encoding
    return exists $self->{"ENCODING"}? $self->{"ENCODING"}: undef;
}

# Specify the encoding used in the keys
sub key_encoding : method {
    local ($_, %_);
    my $self;
    ($self, $_) = @_;
    
    # This is not a static method
    return if ref($self) eq "";
    
    # Set the encoding used in the keys
    if (@_ > 1) {
        if (defined $_) {
            $self->{"KEY_ENCODING"} = $_;
        } else {
            delete $self->{"KEY_ENCODING"};
        }
    }
    
    # Return the encoding
    return exists $self->{"KEY_ENCODING"}? $self->{"KEY_ENCODING"}: undef;
}

# Initialize the language handler
sub new : method {
    local ($_, %_);
    my ($self, $class);
    $class = ref($_[0]) || $_[0];
    $self = bless {}, $class;
    $self->subclass_init;
    $self->init;
    return $self;
}

# Initialize at the subclass level, so that it can be
#   inherited by calling $self->SUPER:subclass_init
sub subclass_init : method {
    local ($_, %_);
    my ($self, $class);
    $self = $_[0];
    $class = ref($self);
    # Initialize the instance lexicon
    $self->{"Lexicon"} = {};
    # Initialize the LOCALEDIRS registry
    $self->{"LOCALEDIRS"} = {};
    # Initialize the MO timestamp
    $self->{"REREAD_MO"} = $REREAD_MO;
    # Initialize the DIE_FOR_LOOKUP_FAILURES setting
    $self->{"DIE_FOR_LOOKUP_FAILURES"} = 0;
    $self->SUPER::fail_with($self->can("failure_handler_auto"));
    # Initialize the ENCODE_FAILURE setting
    $self->{"ENCODE_FAILURE"} = FB_DEFAULT;
    # Initialize the MO_FILE value of this instance
    $self->{"MO_FILE"} = "";
    ${"$class\::MO_FILE"} = "" if !defined ${"$class\::MO_FILE"};
    # Find the locale name, for this subclass
    $self->{"LOCALE"} = $class;
    $self->{"LOCALE"} =~ s/^.*:://;
    $self->{"LOCALE"} =~ s/(_)(.*)$/$1 . uc $2/e;
    # Map i_default to C
    $self->{"LOCALE"} = "C" if $self->{"LOCALE"} eq "i_default";
    # Set the category.  Currently this is always LC_MESSAGES
    $self->{"CATEGORY"} = "LC_MESSAGES";
    # Default key encoding is US-ASCII
    $self->{"KEY_ENCODING"} = "US-ASCII";
    return;
}

# Bind a text domain to a locale directory
sub bindtextdomain : method {
    local ($_, %_);
    my ($self, $DOMAIN, $LOCALEDIR);
    ($self, $DOMAIN, $LOCALEDIR) = @_;
    
    # This is not a static method
    return if ref($self) eq "";
    
    # Return null for this rare case
    return if   !defined $LOCALEDIR
                && !exists ${$self->{"LOCALEDIRS"}}{$DOMAIN};
    
    # Register the DOMAIN and its LOCALEDIR
    ${$self->{"LOCALEDIRS"}}{$DOMAIN} = $LOCALEDIR if defined $LOCALEDIR;
    
    # Return the registry
    return ${$self->{"LOCALEDIRS"}}{$DOMAIN};
}

# Set the current text domain
sub textdomain : method {
    local ($_, %_);
    my ($self, $class, $DOMAIN, $LOCALEDIR, $mo_file);
    ($self, $DOMAIN) = @_;
    
    # This is not a static method
    return if ref($self) eq "";
    # Find the class name
    $class = ref($self);
    
    # Return the current domain
    return $self->{"DOMAIN"} if !defined $DOMAIN;
    
    # Set the timestamp of this read in this instance
    $self->{"REREAD_MO"} = $REREAD_MO;
    # Set the current domain
    $self->{"DOMAIN"} = $DOMAIN;
    
    # Clear it
    $self->{"Lexicon"} = {};
    %{"$class\::Lexicon"} = qw();
    $self->{"MO_FILE"} = "";
    ${"$class\::MO_FILE"} = "";
    
    # The format is "{LOCALEDIR}/{LOCALE}/{CATEGORY}/{DOMAIN}.mo"
    # Search the system locale directories if the domain was not
    # registered yet
    if (!exists ${$self->{"LOCALEDIRS"}}{$DOMAIN}) {
        undef $mo_file;
        foreach $LOCALEDIR (@SYSTEM_LOCALEDIRS) {
            $_ = catfile($LOCALEDIR, $self->{"LOCALE"},
                $self->{"CATEGORY"}, "$DOMAIN.mo");
            if (-f $_ && -r $_) {
                $mo_file = $_;
                last;
            }
        }
        # Not found at last
        return $DOMAIN if !defined $mo_file;
    
    # This domain was registered
    } else {
        $mo_file = catfile(${$self->{"LOCALEDIRS"}}{$DOMAIN},
            $self->{"LOCALE"}, $self->{"CATEGORY"}, "$DOMAIN.mo");
    }
    
    # Record it
    ${"$class\::MO_FILE"} = $mo_file;
    $self->{"MO_FILE"} = $mo_file;
    
    # Read the MO file
    # Cached
    if (!$self->_is_using_cache($mo_file)) {
        my ($enc, @stats, $mtime, $size);
        # Read it
        %_ = read_mo($mo_file);
        
        # Successfully read
        if (scalar(keys %_) > 0) {
            # Decode it
            # Find the encoding of that MO file
            if ($_{""} =~ /^Content-Type: text\/plain; charset=(.*)$/im) {
                $enc = $1;
            # Default to US-ASCII
            } else {
                $enc = "US-ASCII";
            }
            # Set the current encoding to the encoding of the MO file
            $_{$_} = decode($enc, $_{$_}) foreach keys %_;
        }
        
        # Cache them
        @stats = stat $mo_file;
        if (@stats > 0) {
            ($mtime, $size) = @stats[9,7];
        } else {
            ($mtime, $size) = (undef, undef);
        }
        $CACHE{$mo_file} = {
                "Lexicon"   => {%_},
                "encoding"  => $enc,
                "mtime"     => $mtime,
                "size"      => $size,
            };
    }
    
    # Respect the existing output encoding
    if (defined $CACHE{$mo_file}->{"encoding"}) {
        $self->{"MO_ENCODING"} = $CACHE{$mo_file}->{"encoding"};
    } else {
        delete $self->{"MO_ENCODING"};
    }
    # Respect the MO file encoding unless there is a user preference
    if (!exists $self->{"USERSET_ENCODING"}) {
        if (exists $self->{"MO_ENCODING"}) {
            $self->{"ENCODING"} = $self->{"MO_ENCODING"};
        } else {
            delete $self->{"ENCODING"};
        }
    }
    $self->{"Lexicon"} = $CACHE{$mo_file}->{"Lexicon"};
    %{"$class\::Lexicon"} = %{$CACHE{$mo_file}->{"Lexicon"}};
    $self->clear_isa_scan;
    
    return $DOMAIN;
}

# Return whether we are using our cache.
sub _is_using_cache : method {
    local ($_, %_);
    my ($self, $mo_file, @stats, $mtime, $size);
    ($self, $mo_file) = @_;
    
    # NO if we do not have such a cache.
    return undef unless exists $CACHE{$mo_file};
    
    @stats = stat $mo_file;
    # The MO file does not exist previously.
    if (!defined $CACHE{$mo_file}->{"mtime"}
        || !defined $CACHE{$mo_file}->{"size"}) {
        # Use the cache if the MO file still does not exist.
        return (@stats == 0);
    
    # The MO file exists previously.
    } else {
        # Use the cache if the MO file did not change.
        ($mtime, $size) = @stats[9,7];
        return $mtime == $CACHE{$mo_file}->{"mtime"}
                && $size == $CACHE{$mo_file}->{"size"};
    }
}

# Encode after maketext
sub maketext : method {
    local ($_, %_);
    my ($self, $key, @param, $class, $keyd);
    ($self, $key, @param) = @_;
    
    # This is not a static method - NOW
    return if ref($self) eq "";
    # Find the class name
    $class = ref($self);
    
    # MO file should be re-read
    if ($self->{"REREAD_MO"} < $REREAD_MO) {
        $self->{"REREAD_MO"} = $REREAD_MO;
        defined($_ = $self->textdomain) and $self->textdomain($_);
    }
    
    # If the instance lexicon is changed.
    # Maketext uses a class lexicon.  We have to copy the instance
    #   lexicon into the class lexicon.  This is slow.  Mass memory
    #   copy sucks.  Avoid create several language handles for a
    #   single localization subclass whenever possible.
    # Maketext uses class lexicon in order to track the inheritance.
    #   It is hard to change it.
    if (${"$class\::MO_FILE"} ne $self->{"MO_FILE"}) {
        ${"$class\::MO_FILE"} = $self->{"MO_FILE"};
        %{"$class\::Lexicon"} = %{$self->{"Lexicon"}};
    }
    
    # Decode the source text
    $keyd = $key;
    $keyd = decode($self->{"KEY_ENCODING"}, $keyd, $self->{"ENCODE_FAILURE"})
        if exists $self->{"KEY_ENCODING"} && !Encode::is_utf8($key);
    # Maketext
    $_ = $self->SUPER::maketext($keyd, @param);
    # Output to the requested encoding
    if (exists $self->{"ENCODING"}) {
        $_ = encode($self->{"ENCODING"}, $_, $self->{"ENCODE_FAILURE"});
    # Pass through the empty/invalid lexicon
    } elsif (   scalar(keys %{$self->{"Lexicon"}}) == 0
                && exists $self->{"KEY_ENCODING"}
                && !Encode::is_utf8($key)) {
        $_ = encode($self->{"KEY_ENCODING"}, $_, $self->{"ENCODE_FAILURE"});
    }
    
    return $_;
}

# Maketext with context
sub pmaketext : method {
    local ($_, %_);
    my ($self, $context, $key, @param);
    ($self, $context, $key, @param) = @_;
    # This is not a static method - NOW
    return if ref($self) eq "";
    # This is actually a wrapper to the maketext() method
    return $self->maketext("$context\x04$key", @param);
}

# Subroutine to read and parse the MO file
#   Refer to gettext documentation section 8.3
sub read_mo($) {
    local ($_, %_);
    my ($mo_file, $len, $FH, $content, $tmpl);
    $mo_file = $_[0];
    
    # Avoid being stupid
    return unless -f $mo_file && -r $mo_file;
    # Read the MO file
    $len = (stat $mo_file)[7];
    open $FH, $mo_file   or return;  # GNU gettext never fails!
    binmode $FH;
    defined($_ = read $FH, $content, $len)
                        or return;
    close $FH           or return;
    
    # Find the byte order of the MO file creator
    $_ = substr($content, 0, 4);
    # Little endian
    if ($_ eq "\xde\x12\x04\x95") {
    	$tmpl = "V";
    # Big endian
    } elsif ($_ eq "\x95\x04\x12\xde") {
        $tmpl = "N";
    # Wrong magic number.  Not a valid MO file.
    } else {
        return;
    }
    
    # Check the MO format revision number
    $_ = unpack $tmpl, substr($content, 4, 4);
    # There is only one revision now: revision 0.
    return if $_ > 0;
    
    my ($num, $offo, $offt);
    # Number of messages
    $num = unpack $tmpl, substr($content, 8, 4);
    # Offset to the beginning of the original messages
    $offo = unpack $tmpl, substr($content, 12, 4);
    # Offset to the beginning of the translated messages
    $offt = unpack $tmpl, substr($content, 16, 4);
    %_ = qw();
    for ($_ = 0; $_ < $num; $_++) {
        my ($len, $off, $stro, $strt);
        # The first word is the length of the message
        $len = unpack $tmpl, substr($content, $offo+$_*8, 4);
        # The second word is the offset of the message
        $off = unpack $tmpl, substr($content, $offo+$_*8+4, 4);
        # Original message
        $stro = substr($content, $off, $len);
        
        # The first word is the length of the message
        $len = unpack $tmpl, substr($content, $offt+$_*8, 4);
        # The second word is the offset of the message
        $off = unpack $tmpl, substr($content, $offt+$_*8+4, 4);
        # Translated message
        $strt = substr($content, $off, $len);
        
        # Hash it
        $_{$stro} = $strt;
    }
    
    return %_;
}

# Method to purge the lexicon cache
sub reload_text : method {
    local ($_, %_);
    
    # Purge the text cache
    %CACHE = qw();
    $REREAD_MO = time;
    
    return;
}

# A wrapper to the fail_with() of Locale::Maketext, in order
#   to record the preferred failure handler of the user, so that
#   die_for_lookup_failures() knows where to return to.
sub fail_with : method {
    local ($_, %_);
    my $self;
    ($self, $_) = @_;
    
    # This is not a static method
    return if ref($self) eq "";
    
    # Set the current setting
    if (@_ > 1) {
        if (defined $_) {
            $self->{"USERSET_FAIL"} = $_;
            $self->SUPER::fail_with($_) if $self->{"DIE_FOR_LOOKUP_FAILURES"};
        } else {
            delete $self->{"USERSET_FAIL"};
            delete $self->{"fail"} if $self->{"DIE_FOR_LOOKUP_FAILURES"};
        }
    }
    
    # Return the current setting
    return exists $self->{"USERSET_FAIL"}? $self->{"USERSET_FAIL"}: undef;
}

# Whether we should die for lookup failure
#   The default is no.  GNU gettext never fails.
sub die_for_lookup_failures : method {
    local ($_, %_);
    my $self;
    ($self, $_) = @_;
    
    # This is not a static method
    return if ref($self) eq "";
    
    # Set the current setting
    if (@_ > 1) {
        if ($_) {
            $self->{"DIE_FOR_LOOKUP_FAILURES"} = 1;
            if (exists $self->{"USERSET_FAIL"}) {
                $self->{"fail"} = $self->{"USERSET_FAIL"};
            } else {
                delete $self->{"fail"};
            }
        } else {
            $self->SUPER::fail_with($self->can("failure_handler_auto"));
            $self->{"DIE_FOR_LOOKUP_FAILURES"} = 0;
        }
    }
    
    # Return the current setting
    return exists $self->{"DIE_FOR_LOOKUP_FAILURES"}?
        $self->{"DIE_FOR_LOOKUP_FAILURES"}: undef;
}

# What to do if the text is out of your output encoding
#   Refer to Encode on possible values of this check
sub encode_failure : method {
    local ($_, %_);
    my $self;
    ($self, $_) = @_;
    
    # This is not a static method
    return if ref($self) eq "";
    
    # Specify the action used in the keys
    $self->{"ENCODE_FAILURE"} = $_ if @_ > 1;
    
    # Return the encoding
    return $self->{"ENCODE_FAILURE"} if exists $self->{"ENCODE_FAILURE"};
    return undef;
}

# Our local version of failure_handler_auto(),
#   Copied and rewritten from Locale::Maketext, with bug#33938 patch applied.
#   See https://github.com/Perl/perl5/issues/7767
sub failure_handler_auto : method {
    local ($_, %_);
    my ($self, $key, @param, $r);
    ($self, $key, @param) = @_;
    
    # This is not a static method
    return if ref($self) eq "";
    
    # Remove the context
    # We assume there is no one using EOF either in the context or message.
    # That does not work in GNU gettext, anyway.
    $key =~ s/^[^\x04]*\x04//;
    
    $self->{"failure_lex"} = {} if !exists $self->{"failure_lex"};
    ${$self->{"failure_lex"}}{$key} = $self->_compile($key)
        if !exists ${$self->{"failure_lex"}}{$key};
    $_ = ${$self->{"failure_lex"}}{$key};
    
    # A scalar result
    return $$_ if ref($_) eq "SCALAR";
    return $_ unless ref($_) eq "CODE";
    # A compiled subroutine
    {
        local $SIG{"__DIE__"};
        $r = eval {
            $_ = &$_($self, @param);
            return 1;
        };
    }
    
    # If we make it here, there was an exception thrown in the
    #  call to $value, and so scream:
    if (!defined $r) {
        $_ = $@;
        # pretty up the error message
        s<\s+at\s+\(eval\s+\d+\)\s+line\s+(\d+)\.?\n?>
            <\n in bracket code [compiled line $1],>s;
        Carp::croak "Error in maketexting \"$key\":\n$_ as used";
    }
    
    # OK
    return $_;
}

return 1;

__END__

=head1 NAME

Locale::Maketext::Gettext - Joins the gettext and Maketext frameworks

=head1 SYNOPSIS

In your localization class:

  package MyPackage::L10N;
  use base qw(Locale::Maketext::Gettext);
  return 1;

In your application:

  use MyPackage::L10N;
  $LH = MyPackage::L10N->get_handle or die "What language?";
  $LH->bindtextdomain("mypackage", "/home/user/locale");
  $LH->textdomain("mypackage");
  $LH->maketext("Hello, world!!");

If you want to have more control to the detail:

  # Change the output encoding
  $LH->encoding("UTF-8");
  # Stick with the Maketext behavior on lookup failures
  $LH->die_for_lookup_failures(1);
  # Flush the MO file cache and re-read your updated MO files
  $LH->reload_text;
  # Set the encoding of your maketext keys, if not in English
  $LH->key_encoding("Big5");
  # Set the action when encode fails
  $LH->encode_failure(Encode::FB_HTMLCREF);

Use Locale::Maketext::Gettext to read and parse the MO file:

  use Locale::Maketext::Gettext;
  %Lexicon = read_mo($mo_file);

=head1 DESCRIPTION

Locale::Maketext::Gettext joins the GNU gettext and Maketext
frameworks.  It is a subclass of L<Locale::Maketext(3)|Locale::Maketext/3>
that follows the way GNU gettext works.  It works seamlessly, I<both
in the sense of GNU gettext and Maketext>.  As a result, you I<enjoy
both their advantages, and get rid of both their problems, too.>

You start as a usual GNU gettext localization project:  Work on
PO files with the help of translators, reviewers and Emacs.  Turn
them into MO files with F<msgfmt>.  Copy them into the appropriate
locale directory, such as
F</usr/share/locale/de/LC_MESSAGES/myapp.mo>.

Then, build your Maketext localization class, with your base class
changed from L<Locale::Maketext(3)|Locale::Maketext/3> to
Locale::Maketext::Gettext.  That is all.

=head1 METHODS

=over

=item $LH->bindtextdomain(DOMAIN, LOCALEDIR)

Register a text domain with a locale directory.  Returns C<LOCALEDIR>
itself.  If C<LOCALEDIR> is omitted, the registered locale directory
of C<DOMAIN> is returned.  This method always success.

=item $LH->textdomain(DOMAIN)

Set the current text domain.  Returns the C<DOMAIN> itself.  If
C<DOMAIN> is omitted, the current text domain is returned.  This
method always success.

=item $text = $LH->maketext($key, @param...)

Lookup the $key in the current lexicon and return a translated
message in the language of the user.  This is the same method in
L<Locale::Maketext(3)|Locale::Maketext/3>, with a wrapper that
returns the text message C<encode>d according to the current
C<encoding>.  Refer to L<Locale::Maketext(3)|Locale::Maketext/3> for
the maketext plural notation.

=item $text = $LH->pmaketext($context, $key, @param...)

Lookup the $key in a particular context in the current lexicon and
return a translated message in the language of the user.   Use
"--keyword=pmaketext:1c,2" for the xgettext utility.

=item $LH->language_tag

Retrieve the language tag.  This is the same method in
L<Locale::Maketext(3)|Locale::Maketext/3>.  It is readonly.

=item $LH->encoding(ENCODING)

Set or retrieve the output encoding.  The default is the same
encoding as the gettext MO file.  You can specify C<undef>, to return
the result in unencoded UTF-8.

=item $LH->key_encoding(ENCODING)

Specify the encoding used in your original text.  The C<maketext>
method itself is not multibyte-safe to the _AUTO lexicon.  If you are
using your native non-English language as your original text and you
are having troubles like:

Unterminated bracket group, in:

Then, specify the C<key_encoding> to the encoding of your original
text.  Returns the current setting.

B<WARNING:> You should always use US-ASCII text keys.  Using
non-US-ASCII keys is always discouraged and is not guaranteed to
be working.

=item $LH->encode_failure(CHECK)

Set the action when encode fails.  This happens when the output text
is out of the scope of your output encoding.  For example, output
Chinese into US-ASCII.  Refer to L<Encode(3)|Encode/3> for the
possible values of this C<CHECK>.  The default is C<FB_DEFAULT>,
which is a safe choice that never fails.  But part of your text may
be lost, since that is what C<FB_DEFAULT> does.  Returns the current
setting.

=item $LH->die_for_lookup_failures(SHOULD_I_DIE)

Maketext dies for lookup failures, but GNU gettext never fails.
By default Lexicon::Maketext::Gettext follows the GNU gettext
behavior.  But if you are Maketext-styled, or if you need a better
control over the failures (like me :p), set this to 1.  Returns the
current setting.

Note that lookup failure handler you registered with fail_with() only
work when die_for_lookup_failures() is enabled.  if you disable
die_for_lookup_failures(), maketext() never fails and lookup failure
handler will be ignored.

=item $LH->reload_text

Purge the MO text cache.  It purges the MO text cache from the base
class Locale::Maketext::Gettext.  The next time C<maketext> is
called, the MO file will be read and parse from the disk again.  This
is used when your MO file is updated, but you cannot shutdown and
restart the application.  For example, when you are a virtual host on
a mod_perl-enabled Apache, or when your mod_perl-enabled Apache is too
vital to be restarted for every update of your MO file, or if you
are running a vital daemon, such as an X display server.

=back

=head1 FUNCTIONS

=over

=item %Lexicon = read_mo($mo_file);

Read and parse the MO file.  Returns the read %Lexicon.  The returned
lexicon is in its original encoding.

If you need the meta information of your MO file, parse the entry
C<$Lexicon{""}>.  For example:

  /^Content-Type: text\/plain; charset=(.*)$/im;
  $encoding = $1;

C<read_mo()> is exported by default, but you need to C<use
Locale::Maketext::Gettext> in order to use it.  It is not exported
from your localization class, but from the Locale::Maketext::Gettext
package.

=back

=head1 NOTES

B<WARNING:> do not try to put any lexicon in your language subclass.
When the C<textdomain> method is called, the current lexicon will be
B<replaced>, but not appended.  This is to accommodate the way
C<textdomain> works.  Messages from the previous text domain should
not stay in the current text domain.

An essential benefit of this Locale::Maketext::Gettext over the
original L<Locale::Maketext(3)|Locale::Maketext/3> is that: 
I<GNU gettext is multibyte safe,> but Perl source is not.  GNU gettext
is safe to Big5 characters like \xa5\x5c (Gong1).  But if you follow
the current L<Locale::Maketext(3)|Locale::Maketext/3> document and
put your lexicon as a hash in the source of a localization subclass,
you have to escape bytes like \x5c, \x40, \x5b, etc., in the middle
of some natural multibyte characters.  This breaks these characters
in halves.  Your non-technical translators and reviewers will be
presented with unreadable mess, "Luan4Ma3".  Sorry to say this, but
it is weird for a localization framework to be not multibyte-safe.
But, well, here comes Locale::Maketext::Gettext to rescue.  With
Locale::Maketext::Gettext, you can sit back and relax now, leaving
all this mess to the excellent GNU gettext framework.

The idea of Locale::Maketext::Gettext came from
L<Locale::Maketext::Lexicon(3)|Locale::Maketext::Lexicon/3>, a great
work by Autrijus.  But it has several problems at that time (version
0.16).  I was first trying to write a wrapper to fix it, but finally
I dropped it and decided to make a solution towards
L<Locale::Maketext(3)|Locale::Maketext/3> itself.
L<Locale::Maketext::Lexicon(3)|Locale::Maketext::Lexicon/3> should be
fine now if you obtain a version newer than 0.16.

Locale::Maketext::Gettext also solved the problem of lack of the
ability to handle the encoding in
L<Locale::Maketext(3)|Locale::Maketext/3>.  I implement this since
this is what GNU gettext does.  When %Lexicon is read from MO files
by C<read_mo()>, the encoding tagged in gettext MO files is used to
C<decode> the text into the internal encoding of Perl.  Then, when
extracted by C<maketext>, it is C<encode>d by the current
C<encoding> value.  The C<encoding> can be set at run time, so
that you can run a daemon and output to different encoding
according to the language settings of individual users, without
having to restart the application.  This is an improvement to the
L<Locale::Maketext(3)|Locale::Maketext/3>, and is essential to
daemons and C<mod_perl> applications.

You should trust the encoding of your gettext MO file.  GNU gettext
C<msgfmt> checks the illegal characters for you when you compile your
MO file from your PO file.  The encoding form your MO files are
always good.  If you try to output to a wrong encoding, part of your
text may be lost, as C<FB_DEFAULT> does.  If you do not like this
C<FB_DEFAULT>, change the failure behavior with the method
C<encode_failure>.

If you need the behavior of auto Traditional Chinese/Simplified
Chinese conversion, as GNU gettext smartly does, do it yourself with
L<Encode::HanExtra(3)|Encode::HanExtra/3>, too.  There may be a
solution for this in the future, but not now.

If you set C<textdomain> to a domain that is not C<bindtextdomain> to
specific a locale directory yet, it will try search system locale
directories.  The current system locale directory search order is:
/usr/share/locale, /usr/lib/locale, /usr/local/share/locale,
/usr/local/lib/locale.  Suggestions for this search order are
welcome.

B<NOTICE:> I<MyPackage::L10N::en-E<gt>maketext(...) is not available
anymore,> as the C<maketext> method is no more static.  That is a
sure result, as %Lexicon is imported from foreign sources
dynamically, but not statically hardcoded in Perl sources.  But the
documentation of L<Locale::Maketext(3)|Locale::Maketext/3> does not
say that you can use it as a static method anyway.  Maybe you were
practicing this before.  You had better check your existing code for
this.  If you try to invoke it statically, it returns C<undef>.

C<dgettext> and C<dcgettext> in GNU gettext are not implemented.
It is not possible to temporarily change the current text domain in
the current design of Locale::Maketext::Gettext.  Besides, it is
meaningless.  Locale::Maketext is object-oriented.  You can always
raise a new language handle for another text domain.  This is
different from the situation of GNU gettext.  Also, the category
is always C<LC_MESSAGES>.  Of course it is.  We are gettext and
Maketext.

Avoid creating different language handles with different
textdomain on the same localization subclass.  This currently
works, but it violates the basic design of 
L<Locale::Maketext(3)|Locale::Maketext/3>.  In
L<Locale::Maketext(3)|Locale::Maketext/3>, %Lexicon is saved as a
class variable, in order for the lexicon inheritance system to work.
So, multiple language handles to a same localization subclass shares
a same lexicon space.  Their lexicon space clash.  I tried to avoid
this problem by saving a copy of the current lexicon as an instance
variable, and replacing the class lexicon with the current instance
lexicon whenever it is changed by another language handle instance.
But this involves large scaled memory copy, which affects the
performance seriously.  This is discouraged.  You are advised to use
a single textdomain for a single localization class.

The C<key_encoding> is a workaround, not a solution.  There is no
solution to this problem yet.  You should avoid using non-English
language as your original text.  You will get yourself into trouble
if you mix several original text encodings, for example, joining
several pieces of code from programmers all around the world, with
their messages written in their own language and encodings.  Solution
suggestions are welcome.

C<pgettext> in GNU gettext is implemented as C<pmaketext>, in order
to look up the text message translation in a particular context.
Thanks to the suggestion from Chris Travers.

=head1 BUGS

GNU gettext never fails.  I tries to achieve it as long as possible.
The only reason that maketext may die unexpectedly now is
"Unterminated bracket group".  I cannot get a better solution to it
currently.  Suggestions are welcome.

You are welcome to fix my English.  I have done my best to this
documentation, but I am not a native English speaker after all. ^^;

=head1 SEE ALSO

L<Locale::Maketext(3)|Locale::Maketext/3>,
L<Locale::Maketext::TPJ13(3)|Locale::Maketext::TPJ13/3>,
L<Locale::Maketext::Lexicon(3)|Locale::Maketext::Lexicon/3>,
L<Encode(3)|Encode/3>, L<bindtextdomain(3)|bindtextdomain/3>,
L<textdomain(3)|textdomain/3>.  Also, please refer to the official GNU
gettext manual at L<https://www.gnu.org/software/gettext/manual/>.

=head1 AUTHOR

imacat <imacat@mail.imacat.idv.tw>

=head1 COPYRIGHT

Copyright (c) 2003-2021 imacat. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut
