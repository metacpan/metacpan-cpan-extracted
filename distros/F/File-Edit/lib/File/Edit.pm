package File::Edit;
use Mojo::Base -base;
use Path::Tiny qw/path/;
use Carp;
our $VERSION = '0.0.4';

has 'file';
has 'found';        # Line numbers of found lines. ArrayRef.
has '_lines';       # Text in the form of lines. ArrayRef.
has '_line_re';     # Regex for _find_one

sub new {
    @_ > 1
        ? $_[0]->SUPER::new({ file  => path($_[1]),
                              _lines  => [path($_[1])->lines],
                              found => [] })
        : $_[0]->SUPER::new
}
sub text {
    my ($self, $text) = @_;

    $text =~ s/\n/\nx-x/g;
    $self->{_lines} = [split('x-x',$text)];

    return $self;
}
sub replace {
    my ($o, $orig, $repstr) = @_;

    # Replaces one line
    $o->_find_one($orig)
      ->_replace_found($repstr);

    return $o;
}
sub get_block {
    my ($o, %opt) = @_;

    return $o->_find_block($opt{from},$opt{to})
             ->_found_lines;
}
sub save {
    my ($o, $file) = @_;

    if ($file) {
        path($file)->spew(join('',@{$o->_lines}));
    } else {
        $o->file->spew(join('',@{$o->_lines}));
    }

    return $o;
}

sub _find_block {
    my ($o, $begin_re, $end_re) = @_;
    my $in_block   = 0;     # True if line is in block
    my $line_begin = -1;    # First line num of found block. -1 if not found
    my $line_end   = -1;    # Last line num of found block. -1 if not found

    foreach my $n (0 .. $#{$o->_lines}) {
        if (!$in_block) {
            if ($o->_lines->[$n] =~ $begin_re) {
                $line_begin = $n;
                $in_block = 1;
            }
        } else {
            if ($o->_lines->[$n] =~ $end_re) {
                $line_end = $n;
                $in_block = 0;
                last;
            }
        }
    }

    # Error if block not found
    croak "Block not found." if $line_begin == -1 or $line_end == -1;

    $o->found([$line_begin, $line_end]);

    return $o;
}
sub _found_lines {
    my ($o) = @_;

    return [@{$o->_lines}[$o->found->[0] .. $o->found->[1]]];
}

sub _find_one {
    my ($o, $line_re) = @_;
    my $n = 0;

    # Init search result
    $o->found([]);
    $line_re = ref $line_re eq 'Regexp' ? $line_re : _qre($line_re);
    $o->_line_re($line_re);

    foreach my $l (@{$o->_lines}) {
        push @{$o->found}, $n if $l =~ $line_re;
        $n++;
    }

    # Error if more than one line found
    croak "Multiple lines found: ".join(', ',@{$o->found})
        if scalar(@{$o->found}) > 1;

    # Error if more than one line found
    croak "Line not found."
        if scalar(@{$o->found}) == 0;

    return $o;
}
sub _replace_found {
    # Replaces all lines found (line numbers in $o->found)
    my ($o, $repstr) = @_;

    my $line_re = $o->_line_re;     # s// does not work with $o-> notation

    foreach my $n (@{$o->found}) {
        $o->_lines->[$n] =~ s/$line_re/$repstr/;
    }

    return $o;
}
sub _qre {  ## ($string) :> regex
    my $quoted = quotemeta(shift);
    return qr/$quoted/;
}


=head1 NAME

File::Edit - A naive, probably buggy, file editor.

=head1 VERSION

Version 0.0.4

=cut
=head1 SYNOPSIS

    use File::Edit;

    # Replace string in file
    File::Edit->new('build.gradle')
              ->replace('minSdkVersion 16', 'minSdkVersion 21')
              ->save()
              ;

    # Edit text, save to file
    File::Edit->new()
              ->text("  minSdkVersion 16\n  targetSdkVersion 29")
              ->replace('minSdkVersion 16', 'minSdkVersion 21')
              ->save('build.gradle')
              ;

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 METHODS

=head2 new

    my $fe = File::Edit->new("some_file.txt");

    Reads in a file for editing.

=head2 text

    my $fe = File::Edit->new()->text(some_text);

    Reads in some text for editing.

=head2 replace

    $fe->replace($old, $new);

    Replace the $old portion of a single line with $new.

=head2 save

    my $fe = File::Edit->new("some_file.txt");
    $fe->save();                # Saves to "some_file.txt"
    $fe->save("other.txt")      # Saves to "other.txt"

=head1 AUTHOR

Hoe Kit CHEW, C<< <hoekit at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-edit at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Edit>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Edit


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Edit>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/File-Edit>

=item * Search CPAN

L<https://metacpan.org/release/File-Edit>

=back


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Hoe Kit CHEW.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of File::Edit
