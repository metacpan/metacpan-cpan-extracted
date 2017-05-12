package Email::Store::NamedEntity;
use 5.006;
use strict;
use warnings;
our $VERSION = '1.3';
use Email::Store::DBI;
use base 'Email::Store::DBI';
use Email::Store::Mail;


Email::Store::NamedEntity->table("named_entity");
Email::Store::NamedEntity->columns(All => qw/id mail thing description score/);
Email::Store::NamedEntity->columns(Primary => qw/id/);
Email::Store::NamedEntity->has_a(mail => "Email::Store::Mail");
Email::Store::Mail->has_many( named_entities => "Email::Store::NamedEntity" );



sub on_store_order { 80 }

sub on_store {
    my ($self, $mail) = @_;
    my $simple = $mail->simple;
    require Lingua::EN::NamedEntity;

    foreach my $e (Lingua::EN::NamedEntity::extract_entities($simple->body)) 
    { 

        my $class = $e->{class};
        my $score = $e->{scores}->{$class} || 0;
        Email::Store::NamedEntity->create({
            mail => $mail->id,
            thing => $e->{entity},
            description => $class,
            score => $score,
        });
    }
}

sub on_gather_plucene_fields_order { 80 }

# Bet you weren't expecting that!
sub on_gather_plucene_fields {
    my ($self, $mail, $hash) = @_;

    my %topics;
    foreach my $e ($mail->named_entities) {
        push @{$topics{lc($e->description)}}, lc($e->thing);
    }

    foreach my $key (keys %topics) {
        $hash->{$key} = join ' ', @{$topics{$key}};
    }

}

=head1 NAME

Email::Store::NamedEntity - Provides a list of named entities for an email

=head1 SYNOPSIS

Remember to create the database table:

    % make install
    % perl -MEmail::Store="..." -e 'Email::Store->setup'

And now:

    foreach my $e ($mail->named_entities) {
        print $e->thing," which is a ", $e->description,"(score=",$e->score(),")\n";
    }

=head1 DESCRIPTION

C<Named entities> is the NLP jargon for proper nouns which represent people, 
places, organisations, and so on. Clearly this is useful meta data to extract 
from a body of emails.

This extension for C<Email::Store> adds the C<named_entity> table, and exports
the C<named_entities> method to the C<Email::Store::Mail> class which returns 
a list of C<Email::Store::NamedEntity> objects.

A C<Email::Store::NamedEntity> object has three fields -

=over 4
    
=item thing

The entity we've extracted e.g "Bob Smith" or "London" w

=item description 

What class of entity it is e.g "person", "organisation" or "place" 

=item score

How likely like it is to be that class.

=back

C<Email::Store::NamedEntity> will also attempt to index each field
so that if you ahve the C<Email::Store::Plucene> module installed 
then you could search using something like

    place:London


=head1 SEE ALSO

L<Email::Store::Mail>, L<Lingua::EN::NamedEntity>.

=head1 AUTHOR

Simon Wistow, C<simon@thegestalt.org>

This module is distributed under the same terms as Perl itself.

=cut

1;
__DATA__
CREATE TABLE IF NOT EXISTS named_entity (
    id int AUTO_INCREMENT NOT NULL PRIMARY KEY,
    mail varchar(255),                                                 
    thing varchar(255),                                                         
    description varchar(60),                                                    
    score float(4,2)
);
