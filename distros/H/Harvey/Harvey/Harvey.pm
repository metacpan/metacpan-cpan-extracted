package Harvey;
use 5.006;
use strict;
use warnings;
use Harvey::Word;
use Harvey::Verb;

our $VERSION = '1.02';

sub new {
    my $class = shift;
    my $self = {};

    bless ($self,$class);

    return $self;
}

#####################################################
#
# This version of the dialog routine is designed to make it easy
# to test the parsing of verb structures using the Verb module.
# Enter simple sentences with no punctuation or caps.
#
#####################################################

sub dialog() {
    my $L; # string containing sentence
    my @A; # array of word string
    my $B; # reference to array of word objects
    my $K; # individual word strings from @A
    my $V; # reference for the verb object
    my $adverbs;

    print "Enter sentences for test parsing.\n";
    print "Use simple sentence structures with one subject\n";
    print "and one verb.  Use lower case only and skip\n";
    print "punctuation:  e.g. i can always go to the store\n";
    print "\n";

    # prompt
    print ": ";

    # get a line
    while ($L = <>) {

        # trim \n
        chomp $L;

        # quit with normal exits
        if ($L =~ /^(q|quit|Q|QUIT|bye)$/) { exit }

        # split words into an array
        @A = split " ",$L;

        # clean out the @$B array
        @{$B} = ();

        # load @$B with word objects
        foreach $K (@A) { 
            push @{$B}, Word->new($K);
        }

        # make a verb object using the @$B array
        $V = Verb->new($B);

        # show the tense information
        print $V->complete_tense,"\n";

        # show adverbs if they exist
        $adverbs = $V->show_adverbs();
        if ($adverbs ne "") { print $adverbs,"\n" }
        if ($V->statement()) { print "This is a statement\n" }
        if ($V->question()) { print "This is a question\n" }
        if ($V->command()) { print "This is a command\n" }
        print "Verb pattern from left is: ",dec2bin($V->used),"\n";
        print "Persons (3pl,2pl,1pl,3sing,2sing,1sing): ",dec2bin($V->persons),"\n";

        # prompt again
        print "\n: ";
    }
}


#############################################################
#
# Handle one sentence at a time, return results, let remote
# program handle the dialog.
#
#############################################################

sub rdialog() {

    my ($self,$L) = @_;

    # $L is a string of words to process

    my @A; # array of word string
    my $B; # reference to array of word objects
    my $K; # individual word strings from @A
    my $V; # reference for the verb object
    my $adverbs;

    # trim \n
    chomp $L;

    # quit with normal exits
    if ($L =~ /^(q|quit|Q|QUIT|bye)$/) { exit }

    # split words into an array
    @A = split " ",$L;

    # clean out the @$B array
    @{$B} = ();

    # load @$B with word objects
    foreach $K (@A) { 
        push @{$B}, Word->new($K);
    }

    # make a verb object using the @$B array
    $V = Verb->new($B);

    # show the tense information
    $L = $V->complete_tense."\n";

    # show adverbs if they exist
    $adverbs = $V->show_adverbs();
    if ($adverbs ne "") { $L .= $adverbs."\n" }
    if ($V->statement()) { $L .= "This is a statement\n" }
    if ($V->question()) { $L .= "This is a question\n" }
    if ($V->command()) { $L .= "This is a command\n" }
    $L .= "Verb pattern from left is: ".dec2bin($V->used)."\n";
    $L .= "Persons (3pl,2pl,1pl,3sing,2sing,1sing): ".dec2bin($V->persons)."\n";

    # return result
    return $L;
}

sub bin2dec {		# 1.01
	return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

sub dec2bin {		# 1.01
	return unpack("B32", pack("N",shift));
}


1;
__END__

=head1 NAME

Harvey::Harvey - Simple dialog module for testing parsings.

=head1 SYNOPSIS

  use Harvey::Harvey;

  my $H = Harvey->new();
  $H->dialog(); # starts a dialog for working with verb parsings

  This module provides a simple dialog interface for testing the 
  parsing qualities of Verb.pm.

=head1 DESCRIPTION

  new - constructor.

  dialog - starts a dialog.  Put in sentences in lower case and no 
    punctuation.  Hit return to see the parsed verb and other info.
    Q quits the dialog.  

  rdialog - takes a sentence as an argument and returns parsing info.
    Leaves the dialog handling up to the calling program.

=head2 EXPORT

None by default.

=head1 AUTHOR

Chris Meyer, <lt>chris@mytechs.com<gt>

=head1 COPYWRITE

  Copywrite (c) 2002, Chris Meyer.  All rights reserved.  This is 
  free software and can be used under the same terms as Perl itself.

=head1 VERSION 

  1.01

=head1 RELATED LIBRARIES

  My heartfelt thanks to Adam Kilgarriff for his work on the BNC 
  (British National Corpus) which forms the basis for the word.db.
  I have added and massaged it a bit, but I would never have gotten
  this far without it.  The BNC can be visited at
  http://www.itri.brighton.ac.uc/~Adam.Kilgarriff/bnc-readme.html.

=head1 DATA LOCATION

  Harvey uses algorithms AND data to work.  The program looks for 
  a file called 'system.dat' in the startup directory.  In this file
  it looks for a line that reads 'path=your_path', where your_path
  is the directory where the data resides.  

=head1 INSTALATION NOTES

  Install modules in this order, Word.pm, Verb.pm and then Harvey.pm.
  Place the data files (noun.txt, verb.txt, adjective.txt, adverb.txt,
  word.txt and word.db) in a data directory and create a file
  called system.dat in your working directory to point to the data 
  (see DATA LOCATION).  

L<perl>.

=cut
