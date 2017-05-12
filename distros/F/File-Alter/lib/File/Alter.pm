package File::Alter;

use strict;
use base 'IO::String';
use IO::File;
use Carp;
use Params::Check qw[allow];

use vars qw[$VERSION];

$VERSION = '0.01';

### readline() vs <> doesn't DWIM
### mailed p5p at July 25, 2005 12:55:41 PM CEST
# As it seems, it calls the builtin readline() on <>, 
# rather than the class' readline():
# 
#     BEGIN { *CORE::GLOBAL::readline = sub { 2 }; }
#     sub X::readline { 1 };
#     $x = bless {}, 'X';
#     print "rl ". $x->readline . $/;
#     print "<> ". <$x> . $/;
#     rl 1
#     <> 2

use vars qw[$LINENUMBER $LINE]; 

=head1 NAME

File::Alter

=head2 SYNOPSIS

    use File::Alter;
    
    $fh = File::Alter->new( "filename.txt" );
    
    $fh->insert( 3 => "new text\n" );   # insert text on line 3

    $fh->remove( 7 );                   # remove line 7
    $fh->remove( '$LINE =~ /foo/' );    # remove the line if 
                                        # it matches 'foo'

    $fh->alter( qr/2/, 'TWO' );         # replace all occurrences of 
                                        # 2 by TWO
    $fh->alter( a => 'b', '$e == 4');   # replace all a by b if 
                                        # $e equals 4

    $str = $fh->as_string;              # returns the buffer as string

    ### global variables you can use in conditions
    $File::Alter::LINE                  # contents of the current line
    $File::Alter::LINENUMBER            # line number of the current line

=head2 DESCRIPTION

C<File::Alter> allows in memory manipulation of a file's contents.
The modified buffer will B<NOT> be written back to the file at any
point! This is useful if you want to massage read-only files, or files
you do not wish to alter, before they are read or used by an application.

C<File::Alter> inherits directly from C<IO::String> adding it's own 
methods. This means that any method that is supported by C<IO::String> 
is supported by C<File::Alter>.

=head1 METHODS

=head2 $fh = File::Alter->new( FILENAME );

Creates a new C<File::Alter> filehandle object. The arguments get passed
straight to C<IO::String::new>, so even more complicated strings are 
accepted. Please note though that opening a file for writing makes no
sense, as you're only able to modify the files contents in memory, without
writing it to disk.

=cut


sub new {
    my $class = shift;
    my @args  = @_ or return;

    my $fh = IO::File->new( @args ) or (
        carp( "Could not create new filehandle from args '@args': $!" ),
        return
    );

    my $self = __PACKAGE__->SUPER::new( do { local $/; <$fh> } );
    
    return $self;
}

=head2 $string = $fh->as_string;

Returns the stringified version of the internal buffer

=cut

sub as_string { 
    my $self = shift; 
    my $pos  = $self->pos;
    
    $self->setpos(0);
    my $str = do { local $/; <$self> }; 
    
    $self->setpos( $pos );
    
    return $str;
}

=head2 $bool = $fh->insert( $line => $text );

Inserts the given text at linenumber C<$line>. This text can be multiline
if desired, as it's a plain insert. That means that if you want this
text to be on it's own line, you should add a newline to it.

=cut

sub insert {
    my $self = shift or return;

    $self->_edit( insert => @_ );
}

=head2 $bool = $fh->alter( $find => $replace, [$condition] );

Looks on a per-line basis for the string specified by C<$find> and tries
to replace that with C<$replace>. Note that C<$find> can be a C<qr//> 
object if you so desire.

If you specify a condition, the substitute will only be attempted if the
condition evaluates to C<true>. You can use some of C<File::Alter>'s 
global variables to make conditions based on line numbers and contents;
see the C<GLOBAL VARIABLES> section for details.

=cut

sub alter {
    my $self = shift or return;

    $self->_edit( alter => @_ );
}

=head2 $bool = $fh->remove( $line | $condition );

Removes a line based on either line number or condition.

If you specify a condition, the remove will only be done if the
condition evaluates to C<true>. You can use some of C<File::Alter>'s 
global variables to make conditions based on line numbers and contents;
see the C<GLOBAL VARIABLES> section for details.

=cut

sub remove {
    my $self = shift or return;
    
    $self->_edit( remove => @_ );
}

sub _edit {
    my $self = shift;
    my $type = shift;
    
    unless( allow( $type, [qw|alter insert remove|] ) ) {
        carp( "Unknown type '$type' -- can not comply" ),
        return
    };
    
    
    ### first, reset the position to 0
    $self->setpos(0);

    ### $. is actually not the line number, but the amount of times
    ### you've read a line from a filehandle
    local $LINENUMBER;
    
    my ($buf);

    if( $type eq 'alter' ) {
        my $find    = shift or return;
        my $replace = shift or return;
        my $cond    = shift || 1;
        
        while( $LINE = <$self> ) {
            eval { $LINE =~ s/$find/$replace/ } if eval $cond;
            $buf .= $LINE;
        }
    
    } elsif ( $type eq 'insert' ) {
        my $line = shift or return;
        my $text = shift; return unless defined $text;


        while( $LINE = <$self> ) {
            $buf .= $text if ++$LINENUMBER eq $line;
            $buf .= $LINE;
        }
    } elsif ( $type eq 'remove' ) {
        my $line; my $cond;
        
        $_[0] !~ /\D/ ? $line = $_[0] : $cond = $_[0];

        while( $LINE = <$self> ) {
            ++$LINENUMBER;
        
            if( ($line and $line eq $LINENUMBER) or
                ($cond and eval $cond )
            ) {
                next;
            }
            
            $buf .= $LINE;
        }
    }
    
    ### we changed stuff from the FH... we need to truncate it to 0
    ### and reprint the buffer to make sure there's no trailing garbage
    $self->truncate(0);

    ### set to 0, so to print at the beginning
    $self->setpos(0);
    $self->print( $buf );
    
    $self->setpos(0);

    return 1;
}

=head1 GLOBAL VARIABLES

=head2 $File::Alter::LINE

Contains the contents of the current line being read. You can use this
in a condition if you wish to only have it apply relative to a certain
line number. For example:

    $fh->remove( '$LINE =~ /foo/ or $LINE =~ /bar/' );
    
To remove all lines that contain C<foo> or C<bar>.

=head2 $File::Alter::LINENUMBER

Containts the current line number of the file being read. You can use 
this in a condition if you wish to only have it apply relative to a certain
line number. For example:

    $fh->remove( '$LINENUMBER > 20 and $LINENUMBER < 30' );
    
To remove all lines between 20 and 30.

=head1 CAVEATS

=head2 Filehandle position always reset to C<0> after modification

As we're modifying the filehandle on every C<alter>, C<insert> and
C<replace>, we can not be certain that the position the last C<read>
was from is still correct (especially since the position is in bytes),
nor can we be sure it's desirable.

So, after every alteration of the in memory string using above mentioned
methods, the file's position is set to C<0>, so any read will start again
at the beginning of the file

=head2 use $File::Alter::LINENUMBER rather than $.

C<$.> isn't actually C<the current line number of the last active 
filehandle> but the amount of times a line has been read from the last
active filehandle.

This is a subtle but important difference, seeing when you loop over a
file as a whole, and then read the first line again, C<$.> would hold
C<lines in the file + 1> rather than C<1>.

C<$File::Alter::LINENUMBER> does what you expect here and would hold C<1>.

=head1 AUTHOR

This module by
Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 COPYRIGHT

This module is
copyright (c) 2005 Jos Boumans E<lt>kane@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.

=cut


1;
