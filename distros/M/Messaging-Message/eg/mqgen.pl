#!/usr/bin/perl
#+##############################################################################
#                                                                              #
# File: mqgen.pl                                                               #
#                                                                              #
# Description: Message::Queue Generator                                        #
#                                                                              #
#-##############################################################################

# $Id: mqgen.pl,v 1.3 2013/07/30 10:27:07 c0ns Exp $

#
# used modules
#

use strict;
use warnings qw(FATAL all);
use Getopt::Long qw(GetOptions);
use Messaging::Message::Generator qw();
use Messaging::Message::Queue qw();
use No::Worries::Die qw(handler dief);
use Pod::Usage qw(pod2usage);

#
# global variables
#

our(%Option, @MGO);

#
# randomness options
#

sub rndopt ($) {
    my($value) = @_;
    my(%opt);

    if ($value == 0) {
        %opt = ();
    } elsif ($value == 1) {
        %opt = (
            "text"         => "0-1",
            "body-length"  => "0-1024",
            "body-entropy" => "1-2",
        );
    } elsif ($value == 2) {
        %opt = (
            "text"                 => "0-1",
            "body-length"          => "0-1024",
            "body-entropy"         => "1-3",
            "header-count"         => "2^6",
            "header-name-length"   => "10-20",
            "header-name-entropy"  => "1",
            "header-name-prefix"   => "rnd-",
            "header-value-length"  => "20-40",
            "header-value-entropy" => "0-3",
        );
    } else {
        dief("unsupported randomness: %s", $value);
    }
    return(%opt);
}

#
# initialization
#

sub init () {
    $| = 1;
    $Option{count} = 1;
    $Option{randomness} = 0;
    $Option{type} = "DQS";
    @MGO = qw(text header-count);
    push(@MGO, map("body-$_", qw(length entropy)));
    push(@MGO, map("header-name-$_", qw(prefix length entropy)));
    push(@MGO, map("header-value-$_", qw(prefix length entropy)));
    Getopt::Long::Configure(qw(posix_default no_ignore_case));
    GetOptions(\%Option, map("$_=s", @MGO),
        "count|c=i",
        "help|h|?",
        "manual|m",
        "randomness|r=i",
        "type|t=s",
    ) or pod2usage(2);
    pod2usage(1) if $Option{help};
    pod2usage(exitstatus => 0, verbose => 2) if $Option{manual};
    pod2usage(2) unless @ARGV == 1;
}

#
# generation
#

sub generate () {
    my(%opt, $mq, $mg);

    # create the message queue
    %opt = ();
    $opt{type} = $Option{type};
    $opt{path} = $ARGV[0];
    $mq = Messaging::Message::Queue->new(%opt);
    # create the message generator
    %opt = rndopt($Option{randomness});
    foreach my $name (@MGO) {
        $opt{$name} = $Option{$name} if defined($Option{$name});
    }
    $mg = Messaging::Message::Generator->new(%opt);
    # generate and store the messages
    while ($Option{count}-- > 0) {
        $mq->add_message($mg->message());
    }
}

#
# just do it ;-)
#

init();
generate();

__END__

=head1 NAME

mqgen - Message::Queue Generator

=head1 SYNOPSIS

B<mqgen> [I<OPTIONS>] PATH

=head1 DESCRIPTION

Create a message queue and add the requested number of randomly
generated messages.

=head1 OPTIONS

=over

=item B<--count>, B<-c> I<INTEGER>

generate this number of messages (default: 1)

=item B<--help>, B<-h>, B<-?>

show some help

=item B<--manual>, B<-m>

show this manual

=item B<--randomness>, B<-r> 0|1|2

set default options based on randomness (default: 0)

=item B<--type>, B<-t> C<DQS>|C<DQN>

set the type of the message queue (default: C<DQS>)

=item B<--text> I<STRING>

integer specifying if the body is text string (as opposed to binary
string) or not; supported values are C<0> (never text), C<1> (always
text) or C<0-1> (randomly text or not)

=item B<--body-length> I<STRING>

integer specifying the length of the body

=item B<--body-entropy> I<STRING>

integer specifying the entropy of the body

=item B<--header-count> I<STRING>

integer specifying the number of header fields

=item B<--header-name-prefix> I<STRING>

string to prepend to each header field name

=item B<--header-name-length> I<STRING>

integer specifying the length of each header field name (prefix not
included)

=item B<--header-name-entropy> I<STRING>

integer specifying the entropy of each header field name

=item B<--header-value-prefix> I<STRING>

string to prepend to each header field value

=item B<--header-value-length> I<STRING>

integer specifying the length of each header field value (prefix not
included)

=item B<--header-value-entropy> I<STRING>

integer specifying the entropy of each header field value

=back

=head1 SEE ALSO

L<Messaging::Message>,
L<Messaging::Message::Generator>,
L<Messaging::Message::Queue>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2011-2021
