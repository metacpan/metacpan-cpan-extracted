package Lingua::EN::BioLemmatizer;

# See the include pod documentation below for description
# and licensing information.

our $VERSION = 1.002; 

use 5.010;
use utf8;
use strict;
use warnings;
use warnings FATAL => "utf8";

use Carp;

use Scalar::Util qw(blessed reftype openhandle);
use IO::Handle;
use IPC::Open2 qw(open2);

########################################################################
########################################################################
########################################################################
#
# procedural interface
#
########################################################################
########################################################################
########################################################################

use base "Exporter";
our @EXPORT_OK = qw(biolemma parse_response);

sub biolemma($;$) {
    croak "no arguments" 	if @_ == 0;
    croak "too many arguments" 	if @_  > 2;
    croak "string args only"	if grep { ref() } @_;
    state $server = __PACKAGE__ -> new();
    return $server->get_biolemma(@_);
} 

# 
# Input examples:
#   "crisis NNS PennPOS"
#   "xyzzy NONE NONE"
#   "broken j-vvn NUPOS||break VBN PennPOS||break vvn NUPOS"
#   "name vvz NUPOS||name VBZ PennPOS||name NNS PennPOS||name n2 NUPOS"
#   "my po11 NUPOS||i png11 NUPOS||mine n1 NUPOS"
#   "i pno11 NUPOS"
#   "name NN PennPOS||name VBP PennPOS||name vvi NUPOS||name n1 NUPOS||name vvb NUPOS"
#   "crisis NN PennPOS||crisis n1 NUPOS"
#   "those d NUPOS"

sub parse_response($) {
    croak "no arguments" 	if @_ == 0;
    croak "too many arguments" 	if @_  > 1;
    my($string) = @_;
    my @retlist = map { [split] } split /\Q||/, $string;
    return wantarray() ? @retlist : \@retlist;
} 

########################################################################
########################################################################
########################################################################
#
# object-oriented interface
#
########################################################################
########################################################################
########################################################################

# constructor for Lingua::EN::BioLemmatizer class
#
# Don't have to worry about leaking the pair of file descriptors we
# allocate because Perl guarantees deterministic resource management,
# so the IO::Handle destructor will correctly close and deallocate
# them when it fires eventually fires.
sub new {
    croak "expected args" if @_ == 0;

    my $invocant = shift();
    if (ref($invocant)) {
	if (blessed($invocant)) { 
	    croak "constructor invoked as object method";
	} else {
	    croak "constructor called as function with unblessed ref argument";
	} 
    } 

    croak "unexpected args" if @_;

    my $self = {
	CHILD_PID 	=> undef,
	INTO_BIOLEMM 	=> undef,
	FROM_BIOLEMM 	=> undef,
	JAVA_PATH	=>   __PACKAGE__ -> java_path,
	JAVA_ARGS	=> [ __PACKAGE__ -> java_args ],
	JAR_PATH	=>   __PACKAGE__ -> jar_path,
	JAR_ARGS	=> [ __PACKAGE__ -> jar_args ],
	LEMMA_CACHE	=> { },
    };

    bless($self, $invocant);

    # XXX: not sure what this is supposed to mean
    if ($ENV{JAVA_HOME}) {
	carp "warning: JAVA_HOME environment variable ignored";
    }

    my @args = $self->command_args();

    my $kidpid = open2(my $pipe_from, my $pipe_into, @args)
		    // croak "can't start double-ended pipe: $!";

    for my $fh ($pipe_from, $pipe_into) {
	binmode($fh, "utf8") || croak "can't binmode($fh, 'utf8'): $!";
    } 

    $self->{CHILD_PID} = $kidpid;
    $self->{INTO_BIOLEMM} = $pipe_into;
    $self->{FROM_BIOLEMM} = $pipe_from;

    $self->_skip_interactive_header();

    return $self;
} 

sub DESTROY {
    my $self = shift();
    return unless ref $self;
    return unless $self;
    my $pid = $self->child_pid;
    return unless $pid;
    close $self->into_biolemmer();
    close $self->from_biolemmer();
    kill TERM => $pid; 
    waitpid($pid, 0);
} 

# getters/setters for Lingua::EN::BioLemmatizer objects
#

# only object getter allowed
sub child_pid {
    my $self = shift();
    croak "object method called as class method" unless ref $self;
    croak "readonly method called with arguments" if @_;
    return $self->{CHILD_PID};
}

# only object getter allowed
sub into_biolemmer {
    my $self = shift();
    croak "object method called as class method" unless ref $self;
    croak "readonly method called with arguments" if @_;
    return $self->{INTO_BIOLEMM};
}

# only object getter allowed
sub from_biolemmer {
    my $self = shift();
    croak "object method called as class method" unless ref $self;
    croak "readonly method called with arguments" if @_;
    return $self->{FROM_BIOLEMM};
}

# only object getter allowed
sub lemma_cache {
    my $self = shift();
    croak "object method called as class method" unless ref $self;
    croak "readonly method called with arguments" if @_;
    return $self->{LEMMA_CACHE};
}

# dual method: object getter or class getter/setter
sub java_path {
    state $_Java_Path = "java";
    my $self = shift();
    if (ref $self) {
	croak "readonly method called with arguments" if @_;
	return $self->{JAVA_PATH};
    } 
    croak "expected no more than 1 argument" if @_ > 1;
    $_Java_Path = $_[0] if @_;
    return $_Java_Path;
}

# dual method: object getter or class getter/setter
sub jar_path {
    state $_Jar_Path = $ENV{BIOLEMMATIZER} || "biolemmatizer-core-1.0-jar-with-dependencies.jar";
    my $self = shift();
    if (ref $self) {
	croak "readonly method called with arguments" if @_;
	return $self->{JAR_PATH};
    } 
    $_Jar_Path = $_[0] if @_;
    ## unless (-e $_Jar_Path) { carp "cannot access $_Jar_Path: $!"; } 
    return $_Jar_Path;
}

# dual method: object getter or class getter/setter
sub java_args {
    state $_Java_Args = [ "-Xmx1G", "-Dfile.encoding=utf8" ],
    my $self = shift();
    if (ref $self) {
	croak "readonly method called with arguments" if @_;
	return wantarray() ? @{ $self->{JAVA_ARGS} } : $self->{JAVA_ARGS};
    } 

    if (@_ == 1) {
	my $arg = shift();
	if (ref($arg)) {
	    croak "unexpected non-arrayref arg" unless ref($arg) eq "ARRAY";
	    $_Java_Args = $arg;
	} 
	else {
	    $_Java_Args = [ $arg ];
	} 
    } 
    elsif (@_ > 1) {
	croak "unexpected ref arg" if grep { ref() } @_;
	$_Java_Args = [ @_ ];
    } 
    else {
	# FALLTHROUGH
    } 

    return wantarray() ? @{ $_Java_Args } : $_Java_Args;
}

# dual method: object getter or class getter/setter
sub jar_args {
    state $_Jar_Args = [ "-t" ],
    my $self = shift();
    if (ref $self) {
	croak "readonly method called with arguments" if @_;
	return wantarray() ? @{ $self->{JAR_ARGS} } : $self->{JAR_ARGS};
    } 

    if (@_ == 1) {
	my $arg = shift();
	if (ref($arg)) {
	    croak "unexpected non-arrayref arg" unless ref($arg) eq "ARRAY";
	    $_Jar_Args = $arg;
	} 
	else {
	    $_Jar_Args = [ $arg ];
	} 
    } 
    elsif (@_ > 1) {
	croak "unexpected ref arg" if grep { ref() } @_;
	$_Jar_Args = [ @_ ];
    } 
    else {
	# FALLTHROUGH
    } 

    return wantarray() ? @{ $_Jar_Args } : $_Jar_Args;
}

########################################################################

#################
# other methods
#################

# dual class/object method
sub command_args {
    my $invocant = shift();
    croak "unexpected args" if @_;

    my @args = (
	$invocant->java_path,
	$invocant->java_args,
	"-jar",
	$invocant->jar_path,
	$invocant->jar_args,
    );

    return wantarray() ? (@args) : "@args";
} 

# object method only, not class method
sub get_biolemma {
    my $self = shift();
    croak "object method called as class method" unless ref $self;

    my($orig, $pos);

    given(scalar(@_)) {
	when (2) { ($orig, $pos) = @_ }
	when (1) { ($orig)       = @_ }
	when (0) { croak "expected 1 or 2 args" }
	default  { croak "too many args" }
    } 

    my $cache_ref = $self->lemma_cache;

    my $string  = $orig;
       $string .= " $pos" 	if $pos;

    # This funny "||=" move (sometimes called the "orkish maneuver" 
    # == "OR-cache maneuver") loads cache only if that slot previously
    # false, then returns whatever is there.
    #
    return $cache_ref->{$string} ||= $self->_handle_request($string);
} 

# private object method only, not class method
sub _handle_request {
    croak "don't call private methods" unless caller eq __PACKAGE__; 
    my $self = shift();
    croak "object method called as class method" unless ref $self;
    croak "expected just one arg" unless @_ == 1;

    my($request) = @_;

    $request =~ s/\R+\z//;   # remove any trailing linebreaks 
			     # lest a blank line kill server

    {
	local $SIG{PIPE} = sub { croak "biolemmatizer pipe broke" };
	print { $self->into_biolemmer } $request, "\n";  
    }

    my $response = $self->from_biolemmer->getline()
		 // croak "no return string from biolemmatizer";

    $response =~ s/\R+\z//;   
    return $response;
} 

# private object method to skip the noisy preamble strings
# that it spits out when the process is first started up.
# The exact header is the five lines following, without the ##:

## =========================================================
## =========================================================
## =========================================================
## Running BioLemmatizer....
## Running BioLemmatizer in interactive mode. Please type a word to be lemmatized with an optional part-of-speech, e.g. "run" or "run NN"

sub _skip_interactive_header {
    croak "don't call private methods" unless caller eq __PACKAGE__; 
    my $self = shift();
    croak "object method called as class method" unless ref $self;
    croak "expected no args" unless @_ == 0;

    my $fh = $self->from_biolemmer();

    # NB: these are blockings reads.

    # three lines of equal signs
    for (1..3) {
	croak "unexpected preamble: no ===" unless <$fh> =~ /^===/;
    } 
    # then two lines of starting with this
    for (1..2) {
	croak "unexpected preamble: no greeting" unless <$fh> =~ /^Running BioLemmatizer/;
    } 
}


# last "1;" is so that "use" and "require"
# consider the module properly intialized
#
1;    # don't delete this!

__END__

=encoding utf8

=head1 NAME

Lingua::EN::BioLemmatizer - Perl interface to the University of Colorado's BioLemmatizer

=head1 SYNOPSIS

Procedural summary:

    use Lingua::EN::BioLemmatizer qw(biolemma);
    print biolemma("phyla"), "\n";
    print biolemma("phyla", "NNS"), "\n";

    use Lingua::EN::BioLemmatizer qw(biolemma parse_response);
    my @triples = parse_response(biolemma("phyla"));

Object-Oriented summary:

    use Lingua::EN::BioLemmatizer;
    my $server = new Lingua::EN::BioLemmatizer;
    my $answer = $server->get_biolemma("phyla");
    my $answer = $server->get_biolemma("phyla", "NNS");

    use Lingua::EN::BioLemmatizer;
    my $server = new Lingua::EN::BioLemmatizer qw(parse_response);
    my @triples = parse_response( $server->get_biolemma("phyla") );

=head1 DESCRIPTION

Perl module to interface with the University of Colorado's BioLemmatizer
code.  Both a procedural and an OO interface are supported.  Tested with
Perl v5.10, v5.12, and v5.14.  Will not work on earlier Perl versions, 
but should work with later ones.

To use this module, you must first download the BioLemmatizer jarfile
from L<http://biolemmatizer.sourceforge.net>, and then set the environment
variable  C<BIOLEMATIZER> to the path of that jarfile.  You also need
a working Java installation.  See the SourceForge documentation for
any details about the BioLemmatizer itself.

=head2 Procedural Interface

The procedural interface is an easy front-end to the underlying
object interface.  Its advantage is simplicity.  Its disadvantage
is that the resources associated with the remote server, including
filehandles and a lemma cache, will be held onto forever.  Use
the OO interface if you want normal destructor behavior to take
care of that for you.

=over

=item $lemma = biolemma(STRING)

Returns the raw (unparsed) response from the BioLemmatizer server
for the given string.  Use C<parse_response> to parse this.

=item @triples = parse_response(STRING)

=item $aref = parse_response(STRING)

Parses response into an array of triples as subarrays.
In scalar context, returns array ref to this array.

For example, given an input of:

    "name vvz NUPOS||name VBZ PennPOS||name NNS PennPOS||name n2 NUPOS"

the list-context return works like this:

    @list_of_triples = (
      ["name", "vvz", "NUPOS"],
      ["name", "VBZ", "PennPOS"],
      ["name", "NNS", "PennPOS"],
      ["name", "n2", "NUPOS"],
    );

and the scalar context-return works like this:

    $ref_to_triples = [
      ["name", "vvz", "NUPOS"],
      ["name", "VBZ", "PennPOS"],
      ["name", "NNS", "PennPOS"],
      ["name", "n2", "NUPOS"],
    ];


=back

=head2 Object Interface

=over

=item new()

Class constructor; must be called as a class method.  Takes no arguments.
To configure object to take non-default strings, first make class method
calls to C<java_path>, C<java_arg>, C<jar_path>, or C<jar_arg> with the new
strings as arguments.

=item get_biolemma(I<STRING>)

Returns response from BioLemmatizer server when given a request of C<I<STRING>>.

=item command_args()

Returns all args used to start server, 
either as an list in list context 
or else as one string in scalar context.
Used as an object method, returns whatever value was extant when object was constructed.
Used as a class method, returns current defaults.

=item java_path

Returns the current path to Java, which is "java" by default;
can be reset by calling as a class method with a new path
before a constructor is called.
Used as an object method, returns whatever value was extant when object was constructed.

=item jar_path

Returns the current path to the BioLemmatizer jar file, which is
"BioLemmatizer_interactive.jar" by default; can be reset by
calling as a class method with a new path before a constructor
is called.
Used as an object method, returns whatever value was extant when object was constructed.

=item java_args

Returns any extra args passed to the Java program, either as 
a list in list context or as an array ref in scalar context.
Default is C<("-Xmx1G", "-Dfile.encoding=utf8")> but this
can be reset by calling as a class method with new arguments
before a constructor is called.
Used as an object method, returns whatever value was extant when object was constructed.

=item jar_args

Returns any final args passed after the jar file, either as a list in list
context or as an array ref in scalar context.  Default is C<("-t")> but
this can be reset by calling as a class method with new arguments before a
constructor is called.  
Used as an object method, returns whatever value was extant when object was constructed.

=item child_pid()

Returns the pid of the BioLemmatizer server.  Could be used to inspect the
process status.

=item into_biolemmer()

(INTERNAL API) Returns the filehandle for writing to the BioLemmatizer server.

=item from_biolemmer()

(INTERNAL API) Returns the filehandle for reading from the BioLemmatizer server.

=item lemma_cache()

(INTERNAL API) Returns the hash ref used to cache the mapping of strings to lemmas.

=back

=head1 EXAMPLES

Procedural example:

    use Lingua::EN::BioLemmatizer qw(biolemma);

    my @words = qw(these broken pieces are phyla grandchildren);
    my @pairs = ("lives NNS", "lives VBZ");

    for my $word (@words, @pairs) {
	say "$word => ", biolemma($word);
    } 

OO example:

    use Lingua::EN::BioLemmatizer;

    my @words = qw(these broken pieces are phyla grandchildren);
    my @pairs = ("lives NNS", "lives VBZ");

    # scope for private variable
    {
	my $server = new Lingua::EN::BioLemmatizer;

	for my $word (@words, @pairs) {
	    say "$word => ", $server->get_biolemma($word);
	}
    }
    # server goes out of scope, so gets destroyed

=head1 ENVIRONMENT

The following environment variables are used by this module:

=over

=item BIOLEMMATIZER

If set, holds the path to the BioLemmatizer jarfile.  If 
unset, the jarfile used defaults to the file
F<./biolemmatizer-core-1.0-jar-with-dependencies.jar>
in the process's current working directory.

=back 

=head1 BUGS

None known.

=head1 RELEASE HISTORY

=over 

=item April 18, 2012

Initial public release.

=back

=head1 AUTHOR

Tom Christiansen <I<tchrist@perl.com>>

=head1 COPYRIGHT AND LICENCE

Copyright 2012 Tom Christiansen.

This program is free software; you may redistribute it 
and/or modify it under the same terms as Perl itself.
