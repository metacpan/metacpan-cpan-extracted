package Email::Store;
use 5.006;
use strict;
use warnings;
require Email::Store::DBI;
use UNIVERSAL::require;
use vars qw(%only $VERSION);

$VERSION = '0.24';

sub import { 
    shift; 

    my $caller = caller();
    my %args   = ( search_path => [ "Email::Store" ] );

    if ( defined $_[0] && ref($_[0]) eq 'HASH' ) {
            my $opts = shift;
            if (exists $opts->{'only'}) {
                $only{"Email::Store::$_"} = 1 for @{$opts->{'only'}};
                $args{'only'} = [ keys %only ];                
            }
    } 

    require Module::Pluggable::Ordered;
    Module::Pluggable::Ordered->import(%args);

    Email::Store::DBI->import(@_);

    for my $class (Email::Store->plugins) {
        $class->require;
        $only{$class} = 1;
    }
}

sub setup {
    my $self    = shift;
    my $verbose = shift || 0;
    for my $class ($self->plugins()) {
        next unless $only{$class};
        $class->require or next;

        if ($class->can("run_data_sql")) {
            warn "Setting up database in $class\n" if $verbose;
            local $SIG{__WARN__} = sub {}; # No really, shut up
            $class->run_data_sql ;
        }
    }
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Email::Store - Framework for database-backed email storage

=head1 SYNOPSIS

  use Email::Store 'dbi:mysql:mailstore';
  Email::Store->setup; # Do this once

  Email::Store::Mail->store( $rfc822 );
  Email::Store::Mail->retrieve( $msgid );
  
  ...

=head1 DESCRIPTION

C<Email::Store> is the ideal basis for any application which needs to
deal with databases of email: archiving, searching, or even storing mail
for implementing IMAP or POP3 servers.

C<Email::Store> itself is a very lightweight framework, meaning it does
not provide very much functionality itself; in effect, it is merely a
L<Class::DBI> interface to a database schema which is designed for
storing email. Incidentally, if you don't know much about C<Class::DBI>,
you're going to need to in order to get much out of this.

Despite its minimalist nature, C<Email::Store> is incredibly powerful.
Its power comes from its extensibility, through plugin modules and hooks
which allow you to add new database tables and concepts to the system,
and so access the mail store from a "different direction". In a sense,
C<Email::Store> is a blank canvas, onto which you can pick and choose
(or even write!) the plugins which you want for your application.

For instance, the core C<Email::Store::Entity> plugin module addresses
the idea of "people" in the email universe, allowing you to search for
mails to or from particular people; (despite their changing names or
email addresses) C<Email::Store::Thread> interfaces C<Email::Store> to
C<Mail::Thread> allowing you to navigate mails by their position in a
mail thread; the planned non-core C<Email::Store::Plucene> module plugs
into the indexing process and stores information about emails in a
Plucene search index for quick retrieval later, and so on.

=head1 OPTIONS

The generic way to use C<Email::Store> is 

    use Email::Store 'dbi:mysql:mailstore';

However you can also pass a has ref in as the first argument.

This hash ref can contain arbitary key/value pairs however the
only ones currently supported are B<only> and B<except> which 
both take an array ref of plugin names. B<only> means that 
C<Email::Store> will only load those plugins and B<except> means
it will load everything except those.


    use Email::Store { only => [ "Email::Store::Mail" ] }, 'dbi:mysql:mailstore';


=head1 Core C<Email::Store> modules

To get you started with a useful database, C<Email::Store> provides a
few core plugin modules which comprise the basics of a mailstore. Each
of the modules provides one or more database tables, representing
important concepts in the email world, and one or more relationships
between these concepts and the other tables in the system. It's a little
less complicated than that, as we'll see when we go through each module
in turn. Here is a quick summary of what the core modules do:

=over 3

=item C<Email::Store::Mail>

This is, in a sense, the plugin of plugins. C<Email::Store::Mail>
encapsulates individual email messages. Its C<store> method is the means
in which emails are indexed and enter the mailstore. B<How> this storing
is done, however, is influenced by all the other plugins.

=item C<Email::Store::List>

C<List> is one of the easiest plugins to understand. To our concept of
the B<mail>, it adds the concept of a B<mailing list>. 

C<Email::Store::List> hooks into the indexing process and examines a
mail to see if it came via a mailing list; if so, it associates the mail
with one or more lists. This means you can ask a mail object for its
C<lists>, and a list object for its C<posts>. Because of this, instead
of looking at messages by their message ID, you can start by looking for
a mailing list you're interested in and then navigate to the messages
you want.

=item C<Email::Store::Date>

This adds the C<date> method to a C<mail> object, returning a C<Time::Piece>
representing the date of the email. It also provides various searches for
mails between epoch times and for years, months and days.

=item C<Email::Store::Entity>

C<Entity> is the most fundamental of the plugins but (or perhaps,
"thus") the most complex. This module adds the concept of an
B<addressing>, which abstracts out the From, To, Cc and Bcc headers of
an email. A "To" header, for instance, says that the mail is addressed
to a particular B<name> and B<address>, but C<Email::Store::Entity> also
provides the potential for associating different names and addresses
with the concept of an B<entity>, a unique individual. That is, not all
mails addressed to the name "Simon Cozens" are to me (due to the
existence of multiple Simon Cozenses in the world) but all mails to
C<.*@simon-cozens.org> are, despite their being multiple email addresses
which match that pattern.

If that has you confused, (and believe me, it has me confused) ignore the
"entity" bit and know that you can navigate from names, addresses and
the intersection of the two, to emails involving them. More details in
L<Email::Store::Entity> as you'd expect.

=item C<Email::Store::Attachment>

As you might be able to guess, this adds the concept of an
B<attachment>. It also ambushes the indexing process, and strips all the
MIME attachments off an email, placing them in the attachments table. It
then quietly slips the de-MIMEd email back into the mail table, and now
you can ask a mail for its C<attachments>.

=back

All these modules have some degree of POD, so you should consult them
for more details on the interface that they provide. Over time, there
will be additional modules that you can install from CPAN.

=head1 USAGE

When you use C<Email::Store>, you should pass a DBI connection string to
its C<use> statement:

    use Email::Store 'dbi:SQLite:dbname=mailstore.db';

In order to create the tables used by the plugin modules, you should
then say

    Email::Store->setup;

You should do this on the initial set-up of your database, and then
again on installing any additional plugin modules, to create the new
tables they want to use. Note that this does not retroactively index
existing mail with the new functions provided by the modules you've just
installed! - a C<reindex> method is planned, but is not there yet.

It should be noted that passing in an optional true value to setup will
cause it to be verbose about what it's doing.

This is all the functionality that C<Email::Store> itself provides. See
the documentation to the various plugins for their public interface,
chiefly L<Email::Store::Mail>.

=head1 THE PLUGIN SYSTEM

If you want to write your own plugins, you will need to know how the
plugin system works.

The first thing to note is that when C<Email::Store> indexes a mail,
whether for the first time or when it re-indexes a mail it's seen
before, it loads up all the modules it can find under the
C<Email::Store::*> hierarchy. Additionally, when
C<Email::Store-E<gt>setup> is called, all the C<Email::Store::*> modules
are required. So, to register your new plugin, all you need to do is
call it C<Email::Store::>I<something> and put it in Perl's include path
in the usual way.

Each plugin module should be a self-contained description of some
concepts, the database schema that encapsulates them, their
relationship to the rest of the system, and any hooks or additional
functionality provided.

Let us write a very simple plugin as a first example. This will
introduce the concept of a B<mail annotation>, an open-ended space where
we can store "sticky notes" which relate to a particular email. We'll
call the plugin C<Email::Store::Annotation>, and we start by putting the
following in F<Email/Store/Annotation.pm>:

    package Email::Store::Annotation;
    use base 'Email::Store::DBI';

This makes us a C<Class::DBI>-based package. Next we need to do the
usual C<Class::DBI> thing and ddeclare our table and columns:

    Email::Store::Annotation->table("mail_annotation");
    Email::Store::Annotation->columns(All => qw/id mail content/);

Next we declare how this fits into the rest of the world: an
C<Email::Store::Mail> has many C<annotations>:

    Email::Store::Mail->has_many(annotations => "Email::Store::Annotation");

Annotations are something that the utility which uses C<Email::Store>
is going to create, modify and delete manually; we can hardly
auto-generate a user-defined annotation when a mail is indexed, so we
don't need to define any hooks into the indexing process. In fact, this
is all the code we need to write, so we end the package in the usual
way:

    1;

If we did need to hook into a different part of C<Email::Store>, we'd
have to use L<Module::Pluggable::Ordered>'s plugin mechanism. See
L<Email::Store::Mail> for the hooks provided and how to hook into them.

But where does this C<mail_annotation> table come from? How does
C<Email::Store> know how to create it? The answer comes when we put the
schema into the C<__DATA__> section: C<Email::Store-E<gt>setup> reads
all the C<DATA> sections for the plugins that it finds, and executes
them as SQL in the database. As pretty much every database's SQL is
subtly different, the schema should be written in MySQL's SQL and
C<Email::Store> will magically translate it for the database in use:

    __DATA__
    CREATE TABLE IF NOT EXISTS mail_annotation (
        id INTEGER auto_increment NOT NULL PRIMARY KEY,
        mail INTEGER,
        content TEXT
    );

With this module complete and installed, an C<Email::Store> user can now
say:

    my $mail = Email::Store::Mail->retrieve( $msg_id );
    $mail->add_to_annotations({ content => "I like this mail" });
    print "Things I know about this mail:\n";
    print $_->content, "\n" for $mail->annotations;

The really big advantage of this architecture is that everything about a
concept and its relationship to the mailstore is encapsulated in a
single file and can be dropped in and out at will, without disturbing
the rest of the code. This is fantastic extensibility. C<Email::Store>
does not need to define a schema of every single table you might
possibly need up front, but everything is modularised.

The really big disadvantage is that the interface of one part of the
system, such as C<Email::Store::Mail> isn't collected in one place, but
gets added to by pretty much every other plugin that gets loaded up. If
you look in the C<Email::Store::Mail> POD you'll see nothing about
the C<add_to_annotations> method that we've just called.

However, since every plugin should document its interface thoroughly and
its relationship to other parts of the system, this should not really be
a problem for end-users.

=head1 SEE ALSO

Understanding L<Class::DBI> is fundamental to using C<Email::Store>.

The core modules: L<Email::Store::Mail>, L<Email::Store::List>,
L<Email::Store::Entity>, L<Email::Store::Thread>,
L<Email::Store::Attachment>. Please do read through their documentation
to see the whole of the C<Email::Store> API.

Any other C<Email::Store::*> modules you find on CPAN.

L<Module::Pluggable::Ordered> is the pluggable hooks system used
throughout C<Email::Store>. Those developing additional modules might
want to look at its documentation to understand how to hook into the
indexing, reindexing and other processes.

=head1 AUTHOR

The original author is Simon Cozens, E<lt>simon@cpan.orgE<gt>
Currently maintained by Simon Wistow E<lt>simon@thegestalt.orgE<gt>

=head1 SUPPORT

This module is part of the Perl Email Project - http://pep.kwiki.org/

There is a mailing list at pep@perl.org (subscribe at pep-subscribe@perl.org) 
and an archive available at http://nntp.perl.org/group/pep.php


=head1 CREDITS

Many of the ideas (although none of the code) for this package were
taken from my work on a project called Twingle, for a company called
Kasei. While I was at Kasei, I did a lot of thinking about handling
email, storing it, analyzing it and presenting it on the web; I left the
company with all that knowledge in my head, and wrote C<Email::Store>
with the knowledge and tools that I acquired. Thanks to Kasei for the
experience that I gained there and the good grace they've shown as I
release C<Email::Store>.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
