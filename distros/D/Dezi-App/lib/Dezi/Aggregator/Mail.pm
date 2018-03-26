package Dezi::Aggregator::Mail;
use Moose;
extends 'Dezi::Aggregator';
with 'Dezi::Role';

use Carp;
use Data::Dump qw( dump );
use Search::Tools::XML;
use Mail::Box::Manager;

our $VERSION = '0.015';

my $XMLer = Search::Tools::XML->new();

=pod

=head1 NAME

Dezi::Aggregator::Mail - crawl a mail box

=head1 SYNOPSIS

    use Dezi::Aggregator::Mail;

    my $aggregator =
        Dezi::Aggregator::Mail->new(
            indexer => Dezi::Indexer::Native->new()
        );

    $aggregator->indexer->start;
    $aggregator->crawl('path/to/my/maildir');
    $aggregator->indexer->finish;


=head1 DESCRIPTION

Dezi::Aggregator::Mail is a Dezi::Aggregator
subclass designed for providing full-text search for your email.

Dezi::Aggregator::Mail uses Mail::Box, available from CPAN.

=head1 METHODS

Since Dezi::Aggregator::Mail inherits from Dezi::Aggregator,
read the Dezi::Aggregator docs first.
Any overridden methods are documented here.

=head2 BUILD

Internal method only.

Adds the special C<mail> MetaName to the Config object before
opening indexer.

=cut

sub BUILD {
    my $self = shift;

    if ( $self->indexer ) {

        # add top-level metaname
        $self->config->MetaNameAlias('swishdefault mail');

        my @meta = qw(
            url
            id
            subject
            date
            size
            from
            to
            cc
            bcc
            type
            part
        );

        $self->config->MetaNames(@meta);
        $self->config->PropertyNames(@meta);

        # save all body text in the swishdescription property for excerpts
        $self->config->StoreDescription('XML* <body>');

    }

}

# basic flow:
# recurse through maildir, get all messages,
# convert each message to xml, create Doc object and call index()

=head2 crawl( I<path_to_maildir> )

Create index.

Returns number of emails indexed.

=cut

sub crawl {
    my $self    = shift;
    my $maildir = shift or croak "maildir required";
    my $manager = Mail::Box::Manager->new;

    $self->{count} = 0;

    my $folder = $manager->open(
        folderdir => $maildir,
        folder    => '=',
        extract   => 'ALWAYS'
    ) or croak "can't open $maildir";

    $self->_process_folder($folder);

    $folder->close( write => 'NEVER' );

    return $self->{count};
}

sub _addresses {
    return join( ', ', map { ref($_) ? $_->format : $_ } @_ );
}

sub _process_folder {
    my $self = shift;
    my $folder = shift or croak "folder required";

    my @subs    = sort $folder->listSubFolders;
    my $indexer = $self->indexer;

    for my $sub (@subs) {
        my $subf = $folder->openSubFolder($sub);

        warn "searching $sub\n" if $self->verbose;

        foreach my $message ( $subf->messages ) {
            my $doc = $self->get_doc( $sub, $message );
            $indexer->process($doc);
            $self->_increment_count;
        }

        $self->_process_folder($subf);

        $subf->close( write => 'NEVER' );
    }

}

sub _filter_attachment {
    my $self    = shift;
    my $msg_url = shift or croak "message url required";
    my $attm    = shift or croak "attachment object required";

    my $type     = $attm->body->mimeType->type;
    my $filename = $attm->body->dispositionFilename;
    my $content  = $attm->decoded . '';                # force stringify

    if ( $self->swish_filter_obj->can_filter($type) ) {

        my $f = $self->swish_filter_obj->convert(
            document     => \$content,
            content_type => $type,
            name         => $filename,
        );

        if (   !$f
            || !$f->was_filtered
            || $f->is_binary )    # is is_binary necessary?
        {
            warn "skipping $filename in message $msg_url - filtering error\n";
            return '';
        }

        $content = ${ $f->fetch_doc };
    }

    return join( '',
        '<title>',  $XMLer->escape($filename),
        '</title>', $XMLer->escape($content) );

}

=head2 get_doc( I<folder>, I<Mail::Message> )

Extract data and content from I<Mail::Message> in I<folder> and return
doc_class() object.

=cut

sub get_doc {
    my $self    = shift;
    my $folder  = shift or croak "folder required";
    my $message = shift or croak "mail meta required";

    # >head->createFromLine;
    my %meta = (
        url => join( '.', $folder, $message->messageId ),
        id  => $message->messageId,
        subject => $message->subject || '[ no subject ]',
        date    => $message->timestamp,
        size    => $message->size,
        from    => _addresses( $message->from ),
        to      => _addresses( $message->to ),
        cc      => _addresses( $message->cc ),
        bcc     => _addresses( $message->bcc ),
        type    => $message->contentType,
    );

    my @parts = $message->parts;

    for my $part (@parts) {
        push(
            @{ $meta{parts} },
            $self->_filter_attachment( $meta{url}, $part )
        );
    }

    my $title = $meta{subject};

    my $xml = $self->_mail2xml( $title, \%meta );

    my $doc = $self->doc_class->new(
        content => $xml,
        url     => $meta{url},
        modtime => $meta{date},
        parser  => 'XML*',
        type    => 'application/xml',
        data    => \%meta
    );

    return $doc;
}

sub _mail2xml {
    my $self  = shift;
    my $title = shift;
    my $meta  = shift;

    my $xml
        = "<mail>"
        . "<swishtitle>"
        . $XMLer->utf8_safe($title)
        . "</swishtitle>"
        . "<head>";

    for my $m ( sort keys %$meta ) {

        if ( $m eq 'parts' ) {

            $xml .= '<body>';
            for my $part ( @{ $meta->{$m} } ) {
                $xml .= '<part>';
                $xml .= $part;
                $xml .= '</part>';
            }
            $xml .= '</body>';
        }
        else {
            $xml .= $XMLer->start_tag($m);
            $xml .= $XMLer->escape( $meta->{$m} );
            $xml .= $XMLer->end_tag($m);
        }
    }

    $xml .= "</head></mail>";

    return $xml;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>karpet@dezi.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-app at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::App

You can also look for information at:

=over 4

=item * Website

L<http://dezi.org/>

=item * IRC

#dezisearch at freenode

=item * Mailing list

L<https://groups.google.com/forum/#!forum/dezi-search>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<https://metacpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2015 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://dezi.org/>, L<http://swish-e.org/>, L<http://lucy.apache.org/>

