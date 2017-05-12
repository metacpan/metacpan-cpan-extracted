package ETLp::File::Read;

use MooseX::Declare;

=head1 NAME

ETLp::File::Read - Open a file and read a line when requested

=head1 SYNOPSIS

    use ETLp::File::Read;

    my $fh = ETLp::File::Read->new(
        filename => "/data/comit/final.csv",
    );
    
    while (my $line = $fh->get_line) {
        print $fh->line_counter() .": " . $line, "\n";
    };
    
=cut

class ETLp::File::Read with ETLp::Role::Config {
    use ETLp::Exception;
    use File::LocalizeNewlines;
    has 'filename'  => (is => 'ro', isa => 'Str',  required => 1);
    has 'directory' => (is => 'ro', isa => 'Str',  required => 0);
    has 'localize'  => (is => 'ro', isa => 'Bool', required => 0, default => 0);
    has 'skip'      => (is => 'ro', isa => 'Int', required => 0, default => 0);

=head1 METHODS

=head2 new

Create a File object.

Parameters

Hash or hashref consisting of

    * directory: optional. The directory where the file resides
    * filename: required. Name of the file to be opened. Requires full path
      to the file is the directory is not supplied
    * localize: optional. Whether to localize line endings.

Returns

    * a ETLp::File::Read object
    
=head2 line_counter

Return the line number last read from the file

Parameters

    None

Returns

    A postive integer
    
=cut

    method line_counter {
        return $self->{_line_counter};
    }

=head2 get_line

gets the next line from the file.

Parameters

    None
    
Returns

    A line's content. The Record separator (EOL character) is removed
    
=cut

    method get_line {
        my $fh   = $self->{_fh};
        my $line = <$fh>;
        if ($line) {
            chomp $line;
            $self->{_line_counter}++;
        } else {
            return;
        }

        # Skip header rows if required.
        if ($self->line_counter <= $self->skip) {
            $self->logger->debug(
                'Skipping line. Counter now ' . $self->line_counter);
            return $self->get_line;
        }

        return $line;
    }
    
    method BUILD {
    
        my $filename = $self->filename;
    
        if ($self->directory) {
            $filename = $self->directory . '/' . $filename;
        }
        
        $self->logger->debug("Filename: $filename");
    
        if ($self->localize) {
            my $localize      = File::LocalizeNewlines->new;
            my $num_localized = $localize->localize($filename);
        }
        
        $self->logger->debug("Skip: ". $self->skip);
        
        open(my $fh, "<", $filename)
          || ETLpException->throw(error => "Cannot open $filename: $!");
        $self->{_fh}           = $fh;
        $self->{_line_counter} = 0;
    
    }

}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application
    
=cut
