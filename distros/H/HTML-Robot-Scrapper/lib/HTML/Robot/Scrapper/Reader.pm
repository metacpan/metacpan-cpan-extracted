package HTML::Robot::Scrapper::Reader;
use Moose::Role;

=head1 SYNOPSIS

The base of your reader.

=head1 DESCRIPTION

Reader:

Reader is described as the this that will read (parse) the information (pages).

So the reader parses documents. The reader holds all the logic used to crawl a web page.. it knows all the rules to get the content transformed into objects.

After the reader makes its job, it is suposed to pass the information into the Writer, which will then write to a file or write over a network, etc.

   ____________                   __________                   ___________
   | Internet | <<=============== | Reader |                   |  Writer |
   |__________| ===============>> |________| ===============>> |_________|
                reader requests                                 The Writer:
                information and                                 - saves
                parse.Then send                                 - send email
                to the Writer                                   - save stats

=head1 ATTRIBUTES

=head2 robot

=cut

has robot => ( is => 'rw' );

=head2 passed_key_values

*** will be renamed to request_storage or something like that.

holds values that are passed between pages navigation.

ie: im collecting data for an object, and, there is some stuff on page#1 and some other stuff on page#2 and #3. Then i can use passed_key_values to pass keys and values to my next page.

=cut

has passed_key_values => ( is => 'rw' );

=head2 headers

holds the current session headers

=cut

has headers           => ( is => 'rw' );

=head1 METHODS

=head2 append

shortcut for $self->robot->queue->append

=cut

sub append {
    my ( $self ) = shift;
    $self->robot->queue->append( @_ );
}

=head2 prepend

shortcut for $self->robot->queue->prepend

=cut

sub prepend {
    my ( $self ) = shift;
    $self->robot->queue->prepend( @_ );
}

=head2 current_page

shortcut for $self->robot->queue->prepend

=cut

sub current_page {
    my ( $self ) = shift;
    $self->robot->useragent->current_page( @_ );
}

=head2 tree

shortcut for $self->robot->parser->tree

=cut

sub tree {
    my ( $self ) = @_;
    return $self->robot->parser->tree;
}

=head2 xml

shortcut for $self->robot->parser->xml

=cut

sub xml {
    my ( $self ) = @_;
    return $self->robot->parser->xml;
}

1;
