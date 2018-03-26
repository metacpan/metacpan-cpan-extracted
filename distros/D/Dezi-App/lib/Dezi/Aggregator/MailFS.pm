package Dezi::Aggregator::MailFS;
use Moose;
extends 'Dezi::Aggregator::FS';
use Path::Class ();
use Dezi::Aggregator::Mail;    # delegate doc creation
use Carp;
use Data::Dump qw( dump );

our $VERSION = '0.015';

=pod

=head1 NAME

Dezi::Aggregator::MailFS - crawl a filesystem of email messages

=head1 SYNOPSIS

 use Dezi::Aggregator::MailFS;
 my $fs = Dezi::Aggregator::MailFS->new(
        indexer => Dezi::Indexer->new
    );

 $fs->indexer->start;
 $fs->crawl( $path_to_mail );
 $fs->indexer->finish;

=head1 DESCRIPTION

Dezi::Aggregator::MailFS is a subclass of Dezi::Aggregator::FS
that expects every file in a filesystem to be an email message.
This class is useful for crawling a file tree like those managed by ezmlm.

B<NOTE:> This class will B<not> work with personal email boxes
in the Mbox format. It might work with maildir format, but that is
coincidental. Use Dezi::Aggregator::Mail to handle your personal
email box. Use this class to handle mail archives as with a mailing list.

=cut

=head1 METHODS

See Dezi::Aggregator::FS. Only new or overridden methods are documented
here.

=cut

=head2 BUILD

Internal constructor method.

=cut

sub BUILD {
    my $self = shift;

    # cache a Mail aggregator to use its get_doc method
    $self->{_mailer} = Dezi::Aggregator::Mail->new(
        indexer => $self->indexer,
        verbose => $self->verbose,
        debug   => $self->debug,
    );

    return $self;
}

=head2 file_ok( I<full_path> )

Like the parent class method, but ignores file extension, assuming
that all files are email messages.

Returns the I<full_path> value if the file is ok for indexing;
returns 0 if not ok.

=cut

sub file_ok {
    my $self      = shift;
    my $full_path = shift;
    my $stat      = shift;

    $self->debug and warn "checking file $full_path\n";

    return 0 if $full_path =~ m![\\/](\.svn|RCS)[\\/]!; # TODO configure this.

    $stat ||= [ stat($full_path) ];
    return 0 unless -r _;
    return 0 if -d _;
    if (    $self->ok_if_newer_than
        and $self->ok_if_newer_than >= $stat->[9] )
    {
        return 0;
    }
    return 0
        if ( $self->_apply_file_rules($full_path)
        && !$self->_apply_file_match($full_path) );

    $self->debug and warn "  $full_path -> ok\n";
    if ( $self->verbose & 4 ) {
        local $| = 1;    # don't buffer
        print "crawling $full_path\n";
    }

    return $full_path;
}

=head2 get_doc( I<url> )

Overrides parent class to delegate the creation of the
Dezi::Indexer::Doc object to Dezi::Aggregator::Mail->get_doc().

Returns a Dezi::Indexer::Doc object.

=cut

around 'get_doc' => sub {
    my $super_method = shift;
    my $self         = shift;

    # there's some wasted overhead here in creating a
    # Dezi::Indexer::Doc 2x. But we're optimizing here for
    # developer time...

    # mostly a slurp convenience
    my $doc = $self->$super_method(@_);

    #carp "first pass for raw doc: " . dump($doc);

    # get the "folder"
    my $folder = Path::Class::file( $doc->url )->dir;

    # now convert the buffer to an email message
    my $msg = Mail::Message->read( \$doc->content );

    # and finally convert to the Dezi::Indexer::Doc we intend to return
    my $mail = $self->{_mailer}->get_doc( $folder, $msg );

    # reinstate original url from filesystem
    $mail->url( $doc->url );

    #carp "second pass for mail doc: " . dump($mail);

    return $mail;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2015 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://swish-e.org/>
