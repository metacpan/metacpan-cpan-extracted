package Drogo::MultiPart;
use strict;
use IO::File;

=head1 MODULE

Drogo::MultiPart

=head1 METHODS

=over 4

=cut

=item process

Processes request's multipart data.

=cut

sub tmpfilename { join('-', 'drogomp', $$, time) }

sub process
{
    my $server = shift;
    my $fh     = $server->input;

    # rewind
    $fh->seek(0, 0);

    my $tmpdir = $server->variable('tmpdir') ||  '/tmp';

    # all parts
    my @request_parts;

    # instance
    my %request_part;

    # grab first line
    my $key_line = $fh->getline;
    $key_line =~ s/\s//g;

    my @header;
    my $in_header   = 1;
    my $last_line   = '';

    while (my $line = $fh->getline)
    {
        # write from buffer

        if ($line =~ /^$key_line/)
        {
            # write final line
            $last_line =~ s/[\r\n]$//g;

            if ($request_part{fh})
            {
                $request_part{fh}->print($last_line);
            }
            else
            {
                $request_part{data} .= $last_line;
            }

            # process last record
            if ($request_part{fh})
            {
                # stop writing
                close($request_part{fh});

                $request_part{size} = -s $request_part{tmp_file};

                # open for reading only
                open($request_part{fh}, '<' . $request_part{tmp_file});
            }

            push @request_parts, { %request_part };

            # reset request_part
            $in_header    = 1;
            @header       = ();
            %request_part = ();
            $last_line    = '';

            next;
        }
        elsif (not $in_header)
        {
            # if we are not in the header and we're not in a new section, write the line!
            if ($request_part{fh})
            {
                $request_part{fh}->print($last_line);
            }
            else
            {
                $request_part{data} .= $last_line;
            }
        }

        if ($in_header)
        {
            # strip newlines
            $line =~ s/[\r\n]//g;

            if ($line eq '')
            {
                # we're not in the header anymore
                $in_header = 0;

                # process header and open file
                my $name;
                my $filename;
                my $is_file = 0;
                for my $h_line (@header)
                {
                    $name     = $1 if $h_line =~ /name=["'](.*?)["']/;
                    $filename = $1 if $h_line =~ /filename=["'](.*?)["']/;
                    $is_file  = 1  if $h_line =~ /filename=/;
                }

                # define info in request part
                $request_part{name} = $name;

                if ($is_file)
                {
                    $request_part{filename} = $filename;
                    $request_part{tmp_file} = $tmpdir . '/' . tmpfilename();
                    $request_part{fh} = IO::File->new('> ' . $request_part{tmp_file});
                }
                else
                {
                    $request_part{data} = '';
                }

                next;
            }

            push @header, $line;
        }
        else
        {
            $last_line = $line;
        }
    }

    return \@request_parts;
}

=head1 AUTHORS

Bizowie <http://bizowie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Bizowie

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
