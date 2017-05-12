package Log::JSON;
use Moose;
use MooseX::Types::Path::Class;

use Carp;
use DateTime;
use English;
use JSON;
use Path::Class::File;

our $VERSION = '0.001'; # VERSION

has 'date' => ( is => 'ro', isa => 'Bool', default => 1 );

has 'file' => (
    is      => 'ro',
    isa     => 'Path::Class::File',
    required => 1,
    coerce  => 1,
);

has 'remove_newlines' => ( is => 'ro', isa => 'Bool', default => 1 );

sub BUILD {
    my $self = shift;
    $self->file->dir->mkpath;
    $self->file->touch;
}

sub log {
    my $self = shift;
    my %data = @_;

    $data{__date} = DateTime->now . ""
        if $self->date;

    #                     sort keys
    my $json = JSON->new->canonical->encode( \%data );

    if ( $self->remove_newlines ) {
        $json =~ s/\n//g;
        $json =~ s/\r//g;
    }

    my $fh = $self->file->open('>>');
    print $fh $json . "\n";
    $fh->close;
}

# ABSTRACT: Log data to a file as JSON


1;

__END__
=pod

=encoding utf-8

=head1 NAME

Log::JSON - Log data to a file as JSON

=head1 SYNOPSIS

    use Log::JSON;
    my $logger = Log::JSON->new(
        file            => '/path/errorlog.json', # required
        date            => 1, # optional
        remove_newlines => 1, # optional
    );
    $logger->log(a => 1, b => 2);
    # '/path/errorlog.json' now contains: 
    # {"__date":"2010-03-28T23:15:52Z","a":1,"b":1}

=head1 DESCRIPTION

This module logs a hash to a file as JSON.  The keys are printed in sorted order.  

Often log files have several raw numbers and strings whose meaning is not
immediately clear.  With JSON formatted text in your log files, a human can
open the file and quickly decipher the content because each piece of
information is labeled.

Using JSON also means log files are easy to parse and the data structures can
be easily revived.

=head1 ATTRIBUTES

=head2 date

Adds an __date field to your json.  The '__' part ensures the date is the first
information logged to each line when the keys are sorted.

=head2 file

The name of the file to log data to

=head2 remove_newlines

This boolean is set to true by default.  It means your json data structures
will be logged entirely on one line.

=head1 METHODS

=head2 log(%hash)

Appends %hash to a file as JSON.  The keys are sorted when the hash is converted to JSON.

=head1 BUGS

This should probably should have been a Log::Dispatch plugin.

=head1 SEE ALSO

L<Log::Message::Structured>, L<Log::Structured>, L<Log::Sprintf>

=head1 THANKS

Thanks to Foxtons Ltd for providing the opportunity to write and release the
original version of this module.

=for Pod::Coverage BUILD

=head1 AUTHOR

Eric Johnson <cpan at iijo dot org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Eric Johnson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

