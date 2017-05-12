package Mail::Miner;

use 5.006;
use strict;
use warnings;
use Carp;

#require Exporter;
use Mail::Miner::Assets;
use UNIVERSAL::require;

eval {
require Mail::Miner::DBI;
require Mail::Miner::Attachment;
require Mail::Miner::Asset;
require Mail::Miner::Mail;
};

use MIME::Parser;

#our @EXPORT_OK = ( );
#our @EXPORT = qw( );
our $VERSION = '2.7';
our %recognisers;

# Find all Mail::Miner::Recogniser modules
use File::Spec::Functions qw(:DEFAULT splitdir);

sub import { 
    my ($class, @modules) = @_;
    local $_=$_; # Breaking $_ considered evil
    for (@modules) {
        eval "require $_";
        die $@ if $@;
    }
    return if @modules;

my @files = grep length, map { glob(catfile($_,"*.pm"))  }
            grep { -d $_ }
            map { my $path = $_;
                  catdir($path, "Mail", "Miner", "Recogniser"),
            }
            exists $INC{"blib.pm"} ? grep {/blib/} @INC :
            @INC;
my %seen;
@files = grep {
    my $key = $_;
    $key =~ s|.*Mail/Miner/Recogniser||;
     !$seen{$key}++
    } @files;


my @dummy = @files;
for my $x (@dummy) {
    require $x; # No need for import.
}

}
sub modules { sort keys %recognisers };

sub plugins { map { $recognisers{$_}{keyword} => $_ } modules() };
our $parser = new MIME::Parser;
$parser->output_to_core(1);
# Preloaded methods go here.

1;

__END__

=head1 NAME

Mail::Miner - Store and retrieve Useful Information from mail

=head1 DESCRIPTION

I'm very forgetful, and I tend to rely on my email as a surrogate
memory. This is great until you get over 200M of email and can't
actually find anything any more. You tend to remember things like "the
phone number I need is in a message from Frank around September last
year" or "someone sent me a JPG in a message about Tina". This doesn't
really help you find the mail in most mail clients, though.

This is where Mail::Miner comes in. It's a generic system for extracting
useful information for an email message, storing the information and the
message, and allowing both to be extracted through a complex search in
the future.

=head1 ARCHITECTURE

The principle components of C<Mail::Miner> are the database, the base
modules, I<assets> and I<recognisers>. Let's look at each of these
first, then we'll see how they all fit together.

=head2 Database

The database schema is provided in F<miner.sql>; naturally, you'll need
to create this database according to the schema, and give yourself
appropriate permission to the tables. You may or may not need to alter
the DBI connect string at the top of F<DBI.pm> too. Be warned that
C<Mail::Miner> only supports Postgresql, as it's the only free database
to offer subselects.

Those were the database installation instructions. Huh.

=head2 Base modules

The base modules don't do very much. C<Mail::Miner>, the module, does
nothing at all, in fact, other than load up the other modules and
provide this documentation. C<Mail::Miner::Message> provides basic
functions for dealing with messages, and C<Mail::Miner::Attachment> does
the same thing for attachments. C<Mail::Miner::Assets> provides some
functions which are useful for other modules which manipulate assets. So
what are assets?

=head2 Assets

C<Mail::Miner> is Very Stupid. It cares very little about a message; all
it really needs to know are what attachments it has, what content the
body has, who sent it and what the subject was. In fact, it doesn't
really need to care about the last two, but they're used so often, it's
convenient to.

Everything else that C<Mail::Miner> finds out about a mail is an
B<asset>. For instance, a very trivial asset is the date it was sent. A
more complex asset could be the fact that it looks like it contains a
phone number, and what the phone number is.

=head2 Recognisers

So how does C<Mail::Miner> acquire these assets? There are a class of
plug-in I<recogniser> modules that get handed a mail message, and store
information about them. These are installed just like any other Perl
module, and C<Mail::Miner> automatically detects them and passes them
emails. How does this happen?

=head1 Operation

C<Mail::Miner> has two distinct phases of operation: getting data into
the database, and getting it back out again.

The first stage happens when a mail is delivered. C<Mail::Audit> users
can use C<Mail::Audit::Miner>, and C<procmail> users can use the
supplied utility C<mm_process> to process the message - be warned that
these will rewrite the message, so C<procmail> should use it as a pipe
and then continue delivery.

So, a mail comes in, and C<mm_process> or C<Mail::Audit> farms it off to
C<Mail::Miner::Message::process()>. This does two things with it: it
creates an entry in the database for the mail, and then it strips
non-text attachments, flattening the mail to a single piece of text. All
attachments are replaced by text like the following:

    [ image/jpeg attachment foo.jpg detached - use
        mm --detach 12345
      to recover ]

(Note that cutting-and-pasting that central line onto a shell prompt
will dump F<foo.jpg> into your current directory.)

Next, C<process> loads up all the C<Mail::Miner::*> modules it can find
in the Perl module search path, and calls their C<process> subroutine
too, if one exists. This allows them to locate and store any assets they
consider important. After this, the final message, possibly modified by
the various C<process> subroutines, gets written out for delivery.

Here endeth the processing phase.

The next phase is the user-initiated query phase. This is what happens
when you call C<mm> from the command-line. The plugins register keywords
that they can act as filters for. For instance, the
C<Mail::Miner::Recogniser::Date> recognizer module registers that it can
handle the C<--dated> command line option. If C<mm> sees C<--dated> on
the command line, it'll pass the option to
C<Mail::Miner::Recogniser::Date>'s C<search> subroutine, which picks out
the messages which match the search query. If a recognizer doesn't
register a C<search> subroutine, we look for assets belonging to that
recognizer which match a regular expression search for the search term.

That's basically how C<Mail::Miner> works. Have fun with it.

=head1 AUTHOR

Simon Cozens

=head1 SEE ALSO

L<Mail::Audit>, L<Mail::Miner::Mail>, L<Mail::Miner::Attachment>,
L<Mail::Miner::Asset>.

