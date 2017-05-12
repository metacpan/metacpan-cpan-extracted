# Mail::MboxParser - object-oriented access to UNIX-mailboxes
#
# Copyright (C) 2001  Tassilo v. Parseval
# This program is free software; you can redistribute it and/or 
# modify it under the same terms as Perl itself.

# Version: $Id: MboxParser.pm,v 1.54 2002/03/01 09:34:39 parkerpine Exp $

package Mail::MboxParser;

require 5.004;

use base 'Mail::MboxParser::Base';

# ----------------------------------------------------------------

=head1 NAME

Mail::MboxParser - read-only access to UNIX-mailboxes

=head1 SYNOPSIS

    use Mail::MboxParser;

    my $parseropts = {
        enable_cache    => 1,
        enable_grep     => 1,
        cache_file_name => 'mail/cache-file',
    };
    my $mb = Mail::MboxParser->new('some_mailbox', 
                                    decode     => 'ALL',
                                    parseropts => $parseropts);

    # -----------
    
    # slurping
    for my $msg ($mb->get_messages) {
        print $msg->header->{subject}, "\n";
        $msg->store_all_attachments(path => '/tmp');
    }

    # iterating
    while (my $msg = $mb->next_message) {
        print $msg->header->{subject}, "\n";
        # ...
    }

    # we forgot to do something with the messages
    $mb->rewind;
    while (my $msg = $mb->next_message) {
        # iterate again
        # ...
    }

    # subscripting one message after the other
    for my $idx (0 .. $mb->nmsgs - 1) {
        my $msg = $mb->get_message($idx);
    }

=head1 DESCRIPTION

This module attempts to provide a simplified access to standard UNIX-mailboxes.
It offers only a subset of methods to get 'straight to the point'. More
sophisticated things can still be done by invoking any method from MIME::Tools
on the appropriate return values.

Mail::MboxParser has not been derived from Mail::Box and thus isn't acquainted
with it in any way. It, however, incorporates some invaluable hints by the
author of Mail::Box, Mark Overmeer.

=head1 METHODS

See also the section ERROR-HANDLING much further below.

More to that, see the relevant manpages of Mail::MboxParser::Mail,
Mail::MboxParser::Mail::Body and Mail::MboxParser::Mail::Convertable for a
description of the methods for these objects.

=cut

use strict;
use Mail::MboxParser::Mail;
use File::Temp qw/tempfile/;
use Symbol;
use Carp;
use IO::Seekable;

use base qw(Exporter);
use vars qw($VERSION @EXPORT @ISA);
$VERSION	= "0.55";
@EXPORT		= qw();
@ISA		= qw(Mail::MboxParser::Base); 

use constant 
    HAVE_MSGPARSER => eval { require Mail::Mbox::MessageParser; 1 } || 0;
    
my $from_date   = qr/^From (.*)\d{4}\015?$/;
my $empty_line  = qr/^\015?$/;

# ----------------------------------------------------------------

=over 4

=item B<new(mailbox, options)>

=item B<new(scalar-ref, options)>

=item B<new(array-ref, options)>

=item B<new(filehandle, options)>

This creates a new MboxParser-object opening the specified 'mailbox' with
either absolute or relative path. 

new() can also take a reference to a variable containing the mailbox either as
one string (reference to a scalar) or linewise (reference to an array), or a
filehandle from which to read the mailbox.

The following option(s) may be useful. The value in brackets below the key is
the default if none given.

    key:      | value:     | description:
    ==========|============|===============================
    decode    | 'NEVER'    | never decode transfer-encoded
    (NEVER)   |            | data
              |------------|-------------------------------
              | 'BODY'     | will decode body into a human-
              |            | readable format
              |------------|-------------------------------
              | 'HEADER'   | will decode header fields if
              |            | any is encoded
              |------------|-------------------------------
              | 'ALL'      | decode any data
    ==========|============|===============================
    uudecode  | 1          | enable extraction of uuencoded
    (0)       |            | attachments in MIME::Parser
              |------------|-------------------------------
              | 0          | uuencoded attachments are
              |            | treated as plain body text
    ==========|============|===============================
    newline   | 'UNIX'     | UNIXish line-endings 
    (AUTO)    |            | ("\n" aka \012)
              |------------|-------------------------------
              | 'WIN'      | Win32 line-endings
              |            | ("\n\r" aka \012\015)
              |------------|-------------------------------
              | 'AUTO'     | try to do autodetection
              |------------|-------------------------------
              | custom     | a user-given value for totally
              |            | borked mailboxes
    ==========|============|===============================
    oldparser | 1          | uses the old (and slower) 
    (0)       |            | parser (but guaranteed to show
              |            | the old behaviour)
              |------------|-------------------------------
              | 0          | uses Mail::Mbox::MessageParser
    ==========|============|===============================
    parseropts|            | see "Specifying parser opts"
              |            | below
    ==========|============|===============================

The I<newline> option comes in handy if you have a mbox-file that happens to
not conform to the rules of your operating-system's character semantics one way
or another. One such scenario: You are using the module under Win but
deliberately have mailboxes with UNIX-newlines (or the other way round). If you
do not give this option, 'AUTO' is assumed and some basic tests on the mailbox
are performed. This autoedection is of course not capable of detecting cases
where you use something like '#DELIMITER' as line-ending. It can as to yet only
distinguish between UNIX and Win32ish newlines. You may be lucky and it even
works for Macintoshs. If you have more extravagant wishes, pass a costum value:

    my $mb = new Mail::MboxParser ("mbox", newline => '#DELIMITER');

You can't use regexes here since internally this relies on the $/ var
($INPUT_RECORD_SEPERATOR, that is).
    
When passing either a scalar-, array-ref or \*STDIN as first-argument, an
anonymous tmp-file is created to hold the data. This procedure is hidden away
from the user so there is no need to worry about it. Since a tmp-file acts just
like an ordinary mailbox-file you don't need to be concerned about loss of data
or so once you have been walking through the mailbox-data. No data will be lost
and it'll all be fine and smooth.

=back

=head2 Specifying parser options

When available, the module will use C<Mail::Mbox::MessageParser> to do the
parsing. To get the most speed out of it, you can tweak some of its options.
Arguably, you even have to do that in order to make it use caching. Options for
the parser are given via the I<parseropts> switch that expects a reference to a
hash as values. The values you can specify are:

=over 8

=item enable_cache

When set to a true value, caching is used B<but only> if you gave
I<cache_file_name>. There is no default value here!

=item cache_file_name

The file used for caching. This option is mandatory if I<enable_cache> is true.

=item enable_grep

When set to a true value (which is the default), the extern grep(1) is used to
speed up parsing. If your system does not provide a usable grep implementation,
it silently falls back to the pure Perl parser.

=back

When the module was unable to create a C<Mail::Mbox::MessageParser> object, it
will fall back to the old parser in the hope that the construction of the
object then succeeds.

=cut

sub init (@) {
    my ($self, @args) = @_;

    if (@args == 0) {
        croak <<EOC;
Error: open needs either a filename, a filehande (as glob-ref) or a 
(scalar/array)-referece variable as first argument.
EOC
    }
		
    # we need odd number of arguments
    if ((@args % 2) == 0) { 
	croak <<EOC;
Error: open() can never have an even number of arguments. 
See 'perldoc Mail::MboxParser' on how to call it.
EOC
    }
    $self->open(@args);     

    $self;
}

# ----------------------------------------------------------------

=over 4

=item B<open(source, options)>

Takes exactly the same arguments as new() does just that it can be used to
change the characteristics of a mailbox on the fly.

=back

=cut

sub open (@) {
    my ($self, @args) = @_;
    
    local *_;

    my $source 	= shift @args;
    
    $self->{CONFIG} = { @args };	
    $self->{CURR_POS} = 0;

    my ($file_name, $old_filepos);
    
    # supposedly a filename
    if (! ref $source) {	
	if (! -f $source) {
	    croak <<EOC;
Error: The filename you passed to open() does not refer to an existing file
EOC
	}
	my $handle = gensym;
	open $handle, "<$source" or
	    croak "Error: Could not open $source for reading: $!";
	$self->{READER} = $handle;
	$file_name = $source;
    }

    # a filehandle
    elsif (ref $source eq 'GLOB' && seek $source, 0, SEEK_CUR) { 
	$old_filepos = tell $source;
	$self->{READER} = $source;
    }
    
    # else
    else {
	(my $fh, $file_name) = tempfile(UNLINK => 1) or croak <<EOC;
Error: Could not create temporary file. This is very weird ($!).
EOC
	if    (ref $source eq 'SCALAR') 	{ print $fh ${$source} }
	elsif (ref $source eq 'ARRAY')  	{ print $fh @{$source} }
	elsif (ref $source eq 'GLOB') 	  	{ print $fh $_ while <$source> }
	seek $fh, 0, SEEK_SET;
	$self->{READER} = $fh;
    }

    if ($self->{CONFIG}->{oldparser} or ! HAVE_MSGPARSER 
        or ! defined $file_name) {
        binmode $self->{READER};
        local $^W = 0;
        *get_messages   = \&get_messages_old;
        *get_message    = \&get_message_old;
        *next_message   = \&next_message_old;
        
        $self->{CONFIG}->{join_string} = "";
    } else {
        local $^W = 0;
        *get_messages   = \&get_messages_new;
        *get_message    = \&get_message_new;
        *next_message   = \&next_message_new;

        $self->{CONFIG}->{join_string} = "\n";
        # check sanity of arguments and capabilities of system:
        # clean options accordingly
        my $opts = delete($self->{CONFIG}->{parseropts}) || {enable_grep => 1};
        $opts->{enable_grep} = 1 if ! exists $self->{enable_grep};

        if ($opts->{enable_grep}) {
            eval { require Mail::Mbox::MessageParser::Grep };
            delete $opts->{enable_grep} if $@;
        }
        if ($opts->{enable_cache}) {
            delete $opts->{enable_cache} if ! exists $opts->{cache_file_name};
            eval { require Mail::Mbox::MessageParser::Cache };
            delete $opts->{enable_cache} if $@;
        }

        Mail::Mbox::MessageParser::SETUP_CACHE( 
            { file_name => $opts->{cache_file_name} }
        ) if $opts->{enable_cache};
       
        $opts->{enable_cache} ||= 0;
        $opts->{file_handle} = $self->{READER};
        $opts->{file_name} = $file_name;
        if (not ref($self->{PARSER} = Mail::Mbox::MessageParser->new($opts))) {
	    # when Mail::Mbox::MessageParser object could not be created,
	    # try to fall back to the old parser
	    my %opt = @args;
	    $opt{ oldparser } = 1;
	    delete $opt{ parseropts };
	    # $source could be a GLOB which we need to rewind
	    # if it isn't, the BLOCK-eval should catch it.
	    eval { seek $source, $old_filepos, SEEK_SET };
	    return Mail::MboxParser->new($source, %opt);
	}
    } 

    # do line-ending stuff
    if (! exists $self->{CONFIG}->{newline}) {
        $self->{CONFIG}->{newline} = 'AUTO';
    }
    
    my $nl = $self->{CONFIG}->{newline};
    if    ($nl eq 'UNIX') { $self->{NL} = "\012" }
    elsif ($nl eq 'WIN')  { $self->{NL} = "\015\012" }
    elsif ($nl eq 'AUTO') { $self->{NL} = $self->_detect_nl }
    else                  { $self->{NL} = $nl }
    $Mail::MboxParser::Mail::NL = $self->{NL};

    seek $self->{READER}, 0, SEEK_SET if ! $self->{PARSER};
    return;
}

# ----------------------------------------------------------------

=over 4

=item B<get_messages>

Returns an array containing all messages in the mailbox respresented as
Mail::MboxParser::Mail objects. This method is _minimally_ quicker than
iterating over the mailbox using C<next_message> but eats much more memory.
Memory-usage will grow linearly for each new message detected since this method
creates a huge array containing all messages. After creating this array, it
will be returned.

=back

=cut

sub get_messages_new() {
    my $self = shift;

    my $nl = $self->{NL};
    my @messages;
    my $p = $self->parser;
    $p->reset;

    while (! $p->end_of_file) {
        my $mailref = $p->read_next_email;
        my ($header, $body) = split /$nl$nl/, $$mailref, 2;
        push @messages, 
            Mail::MboxParser::Mail->new([ split(/$nl/, $header), '' ],
                                        [ split /$nl/, $body ],
                                       $self->{CONFIG});
    }
    $p->reset;
    return @messages;
}
    
sub get_messages_old() {
    my $self = shift;

    local $/ = $self->{NL};

    my ($in_header, $in_body) = (0, 0);
    my $header;
    my (@header, @body);
    my $h = $self->{READER};

    my $got_header;

    my @messages;

    seek $h, 0, SEEK_SET; 
    local *_;
    while (<$h>) {

	# entering header
	if (!$in_body && /$from_date/) {
	    ($in_header, $in_body) = (1, 0);
	    $got_header = 0;
	}
	# entering body
	if ($in_header && /$empty_line/) { 
	    ($in_header, $in_body) = (0, 1);
	    $got_header = 1; 
	}

	# just before entering next mail-header or running
	# out of data, store message in Mail-object
	if ((/$from_date/ || eof) && $got_header) {
            push @body, $_ if eof; # don't forget last line!!
	    my $m = Mail::MboxParser::Mail->new([ @header ], [ @body ], $self->{CONFIG});
	    push @messages, $m;
	    ($in_header, $in_body) = (1, 0);
	    undef $header;
	    (@header, @body) = ();
	    $got_header = 0;
	}
	if ($_) {
	    push @header, $_ if $in_header && !$got_header; 
	    push @body, $_   if $in_body   &&  $got_header;
	}		
    }
	
    if (exists $self->{CONFIG}->{decode}) {
	$Mail::MboxParser::Mail::Config->{decode} = $self->{CONFIG}->{decode};
    }
    return @messages;
}

# ----------------------------------------------------------------

=over 4

=item B<get_message(n)>

Returns the n-th message (first message has index 0) in a mailbox. Examine
C<$mb-E<gt>error> which contains an error-string if the message does not exist.
In this case, C<get_message> returns undef.

=back

=cut

sub get_message_new($) {
    my ($self, $num) = @_;
    my $oldpos = tell $self->{READER};
    my $msg = $self->get_message_old($num);
    seek $self->{READER}, $oldpos, SEEK_SET;
    return $msg;
}

sub get_message_old($) {
    my ($self, $num) = @_;
    
    local $/ = $self->{NL};
    
    $self->reset_last;
    $self->make_index if ! exists $self->{MSG_IDX};

    my $tmp_idx = $self->current_pos;
    my $pos     = $self->get_pos($num);
    
    if (my $err = $self->error) {
        $self->set_pos($tmp_idx); 
        $self->{LAST_ERR} = $err;
        return;
    }

    $self->set_pos($pos);
    my $msg = $self->next_message_old;
    $self->set_pos($tmp_idx);
    return $msg;
}

# ----------------------------------------------------------------

=over 4

=item B<next_message>

This lets you iterate over a mailbox one mail after another. The great
advantage over C<get_messages> is the very low memory-comsumption. It will be
at a constant level throughout the execution of your script. Secondly, it
almost instantly begins spitting out Mail::MboxParser::Mail-objects since it
doesn't have to slurp in all mails before returing them.

=back

=cut

sub next_message_new() {
    my $self = shift;
    $self->reset_last;
    my $p = $self->parser;

    return undef if ref(\$p) eq 'SCALAR' or $p->end_of_file;

    seek $self->{READER}, $self->{CURR_POS}, SEEK_SET;
    my $nl = $self->{NL};
    my $mailref = $p->read_next_email;
    my ($header, $body) = split /$nl$nl/, $$mailref, 2;
    my $msg     = Mail::MboxParser::Mail->new([ split(/$nl/, $header), '' ],
                                              [ split /$nl/, $body ],
                                              $self->{CONFIG});
    $self->{CURR_POS} = $p->offset + $p->length;
    return $msg;   
}

sub next_message_old() {
    my $self = shift;
    $self->reset_last;

    local $/ = $self->{NL};

    my $h    = $self->{READER};

    my ($in_header, $in_body) = (0, 0);
    my $header;
    my (@header, @body);

    my $got_header = 0;

    seek $h, $self->{CURR_POS}, SEEK_SET;

    # we need to force join_string to "" here because
    # this method is also invoked by get_message_new():
    my %newopts = %{ $self->{CONFIG} };
    $newopts{ join_string } = '';

    local *_;
    while (<$h>) { 

	$got_header = 1 if eof($h) || /$empty_line/ and $in_header;

	if (/$from_date/ || eof $h) {
	    push @body, $_ if eof $h;
	    if (! $got_header) {
		($in_header, $in_body) = (1, 0);
	    }
	    else {
		$self->{CURR_POS} = tell($h) - length;
		return Mail::MboxParser::Mail->new(\@header, \@body, \%newopts);
	    }
	}

	if (/$empty_line/ && $got_header) {
	    ($in_header, $in_body) = (0, 1); 
	    $got_header = 1;
	}

	push @header, $_ if $in_header;
	push @body,   $_ if $in_body; 
        
    }
}

# ----------------------------------------------------------------

=over 4

=item B<set_pos(n)>

=item B<rewind>

=item B<current_pos>

These three methods deal with the position of the internal filehandle backening
the mailbox. Once you have iterated over the whole mailbox using
C<next_message> MboxParser has reached the end of the mailbox and you have to
do repositioning if you want to iterate again. You could do this with either
C<set_pos> or C<rewind>.

    $mb->rewind;  # equivalent to
    $mb->set_pos(0);

C<current_pos> reveals the current position in the mailbox and can be used to
later return to this position if you want to do tricky things. Mark that
C<current_pos> does *not* return the current line but rather the current
character as returned by Perl's tell() function.
    
    my $last_pos;
    while (my $msg = $mb->next_message) {
        # ...
        if ($msg->header->{subject} eq 'I was looking for this') {
            $last_pos = $mb->current_pos;
            last; # bail out here and do something else
        }
    }
    
    # ...
    # ...
    
    # now continue where we stopped:
    $mb->set_pos($last_pos)
    while (my $msg = $mb->next_message) {
        # ...
    }

B<WARNING: > Be very careful with these methods when using the parser of
C<Mail::Mbox::MessageParser>. This parser maintains its own state and you
shouldn't expect it to always be in sync with the state of C<Mail::MboxParser>.
If you need some finer control over the parsing, better consider to use the
public interface as described in L<the manpage of
Mail::Mbox::MessageParser|Mail::Mbox::MessageParser>. Use C<parser()> to get
the underlying parser object.

This however may expose you to the same problems turned around:
C<Mail::MboxParser> may loose its sync with its parser when you do that. 

Therefore: Just avoid any of the above for now and wait till
C<Mail::Mbox::MessageParser> has a stable interface.

=back

=cut

sub set_pos($) { 
    my ($self, $pos) = @_;
    $self->reset_last;
    $self->{CURR_POS} = $pos;
}

# ----------------------------------------------------------------

sub rewind() { 
    my $self = shift;
    $self->reset_last;
    $self->set_pos(0); 
}

# ----------------------------------------------------------------

sub current_pos() { 
    my $self = shift;
    $self->reset_last;
    return $self->{CURR_POS};
}

# ----------------------------------------------------------------

=over 4

=item B<make_index>

You can force the creation of a message-index with this method. The
message-index is a mapping between the index-number of a message (0 ..
$mb->nmsgs - 1) and the byte-position of the filehandle. This is usually done
automatically for you once you call C<get_message> hence the first call for a
particular message will be a little slower since the message-index first has to
be built. This is, however, done rather quickly. 

You can have a peek at the index if you are interested. The following produces
a nicely padded table (suitable for mailboxes up to 9.9999...GB ;-).
    
    $mb->make_index;
    for (0 .. $mb->nmsgs - 1) {
        printf "%5.5d => %10.10d\n", 
                $_, $mb->get_pos($_);
    }   

=back

=cut

sub make_index() {
    my $self = shift;

    local $/ = $self->{NL};
    
    $self->reset_last;
    my $h    = $self->{READER};
    
    seek $h, 0, SEEK_SET;
    
    my $c = 0;

    local *_;
    while (<$h>) {
        $self->{MSG_IDX}->{$c} = tell($h) - length, $c++ 
            if /$from_date/;
    }
    seek $h, 0, SEEK_SET;
} 

# ----------------------------------------------------------------

=over 4

=item B<get_pos(n)>

This method takes the index-number of a certain message within the mailbox and
returns the corresponding position of the filehandle that represents that start
of the file.

It is mainly used by C<get_message()> and you wouldn't really have to bother
using it yourself except for statistical purpose as demonstrated above along
with B<make_index>.

=back

=cut

sub get_pos($) {
    my ($self, $num) = @_;
    $self->reset_last;
    if (exists $self->{MSG_IDX}) { 
        if (! exists $self->{MSG_IDX}{$num}) {
            $self->{LAST_ERR} = "$num: No such message";
        }
        return $self->{MSG_IDX}{$num} 
    }
    else { return }
}

# ----------------------------------------------------------------

=over 4

=item B<nmsgs>

Returns the number of messages in a mailbox. You could naturally also call
get_messages in scalar-context, but this one wont create new objects. It just
counts them and thus it is much quicker and wont eat a lot of memory.

=back

=cut

sub nmsgs() {
    my $self = shift;

    local $/ = $self->{NL};

    if (not $self->{READER}) { return "No mbox opened" }
    if (not $self->{NMSGS}) {
	my $h = $self->{READER};
	seek $h, 0, SEEK_SET;
	local *_;
	while (<$h>) {
	    $self->{NMSGS}++ if /$from_date/;
	}
    }
    return $self->{NMSGS} || 0;
}	

# ----------------------------------------------------------------

=over 4

=item B<parser>

Returns the bare C<Mail::Mbox::MessageParser> object. If no such object exists
returns C<undef>.

You can use this method to check whether the module actually uses the old or
new parser. If C<parser> returns a false value, it is using the old parsing
routines.

=back

=cut

sub parser { shift->{PARSER} }

# ----------------------------------------------------------------

sub _detect_nl {
    
    my $self = shift;
    my $h = $self->{READER};
    my $newline;
    
    seek $h, 0, SEEK_SET;
    while (sysread $h, (my $c), 1) {
        if (ord($c) == 13) {
            $newline = "\015";        
            sysread $h, (my $next), 1;
            $newline .= "\012" if ord($next) == 10;
            last;
        }
        elsif (ord($c) == 10) {
            $newline = "\012";
            last;
        }
    }
    return $newline;
}

# ----------------------------------------------------------------

sub DESTROY {
	my $self = shift;
	$self->{NMSGS} = undef;
	close $self->{READER} if defined $self->{READER};
}

# ----------------------------------------------------------------

1;		

__END__

=head2 METHODS SHARED BY ALL OBJECTS

=over 4

=item B<error>

Call this immediately after one of the methods above that mention a possible
error-message. 

=item B<log>

Sort of internal weirdnesses are recorded here. Again only the last event is
saved.

=back

=head1 ERROR-HANDLING

Mail::MboxParser provides a mechanism for you to figure out why some methods
did not function as you expected. There are four classes of unexpected
behavior:

=over 4

=item B<(1) bad arguments >

In this case you called a method with arguments that did not make sense, hence
you confused Mail::MboxParser. Example:

  $mail->store_entity_body;           # wrong, needs two arguments
  $mail->store_entity_body(0);        # wrong, still needs one more

In any of the above two cases, you'll get an error message and your script will
exit. The message will, however, tell you in which line of your script this
error occured.

=item B<(2) correct arguments but...>

Consider this line:

  $mail->store_entity_body(50, \*FH); # could be wrong

Obviously you did call store_entity_body with the correct number of arguments.
That's good because now your script wont just exit. Unfortunately, your program
can't know in advance whether the particular mail ($mail) has a 51st entity.

So, what to do?

Just be brave: Write the above line and do the error-checking afterwards by
calling $mail->error immediately after store_entity_body:

	$mail->store_entity_body(50, *\FH);
	if ($mail->error) {
		print "Oups, something wrong:", $mail->error;
	}

In the description of the available methods above, you always find a remark
when you could use $mail->error. It always returns a string that you can print
out and investigate any further.

=item B<(3) errors, that never get visible>

Well, they exist. When you handle MIME-stuff a lot such as attachments etc.,
Mail::MboxParser internally calls a lot of methods provided by the MIME::Tools
package. These work splendidly in most cases, but the MIME::Tools may fail to
produce something sensible if you have a very queer or even screwed up mailbox.

If this happens you might find information on that when calling $mail->log.
This will give you the more or less unfiltered error-messages produced by
MIME::Tools.

My advice: Ignore them! If there really is something in $mail->log it is either
because you're mails are totally weird (there is nothing you can do about that
then) or these errors are smoothly catched inside Mail::MboxParser in which
case all should be fine for you.

=item B<(4) the apocalyps>

If nothing seems to work the way it should and $mail->error is empty, then the
worst case has set in: Mail::MboxParser has a bug.

Needless to say that there is any way to get around of this. In this case you
should contact and I'll examine that.

=back

=head1 CAVEATS

I have been working hard on making Mail::MboxParser eat less memory and as
quick as possible. Due to that, two time and memory consuming matters are now
called on demand. That is, parsing out the MIME-parts and turning the raw
header into a hash have become closures.

The drawback of that is that it may get inefficient if you often call 

 $mail->header->{field}

In this case you should probably save the return value of $mail->header (a
hashref) into a variable since each time you call it the raw header is parsed.

On the other hand, if you have a mailbox of, say, 25MB, and hold each header of
each message in memory, you'll quickly run out of that. So, you can now choose
between more performance and more memory.

This all does not happen if you just parse a mailbox to extract one
header-field (eg. subject), work with that and exit. In this case it will need
both less memory and is still considerably quicker. :-)

=head1 BUGS

Some mailers have a fancy idea of how a "To: "- or "Cc: "-line should look. I
have seen things like:

	To: "\"John Doe"\" <john.doe@example.com>

The splitting into name and email, however, does still work here, but you have
to remove these silly double-quotes and backslashes yourself.

The way of counting the messages and detecting them now complies to RFC 822.
This is, however, no guarentee that it all works seamlessly. There are just so
many mailboxes that get screwed up by mal-formated mails.

=head1 TODO

Apart from new bugs that almost certainly have been introduced with this
release, following things still need to be done:

=over 4

=item Transfer-Encoding

Still, only quoted-printable encoding is correctly handled.

=item Tests

Clean-up of the test-scripts is desperately needed. Now they represent rather
an arbitrary selection of tested functions. Some are tested several times while
others don't show up at all in the suits.

=back 

=head1 THANKS

Thanks to a number of people who gave me invaluable hints that helped me with
Mail::Box, notably Mark Overmeer for his hints on more object-orientedness.

Kenn Frankel (kenn AT kenn DOT cc) kindly patched the broken split-header
routine and added get_field().

David Coppit for making me aware of C<Mail::Mbox::MessageParser> and designing
it the way I needed to make it work for my module.

=head1 VERSION

This is version 0.55.

=head1 AUTHOR AND COPYRIGHT

Tassilo von Parseval <tassilo.von.parseval@rwth-aachen.de>

Copyright (c)  2001-2005 Tassilo von Parseval. 
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<MIME::Entity>

L<Mail::MboxParser::Mail>, L<Mail::MboxParser::Mail::Body>, L<Mail::MboxParser::Mail::Convertable>

L<Mail::Mbox::MessageParser>

=cut
