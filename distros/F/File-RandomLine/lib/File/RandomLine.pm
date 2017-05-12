use 5.006;
use strict;
use warnings;

package File::RandomLine;
# ABSTRACT: Retrieve random lines from a file
our $VERSION = '0.20'; # VERSION

use Carp;

# Required modules
use Want 'howmany';



sub new {
	my ($class, $filename, $args) = @_;
    croak "new requires a filename parameter" unless $filename;
    my $algo = $args->{algorithm} || q{};
    croak "unknown algorithm '$algo'" if $algo && $algo !~ /fast|uniform/i;
    open(my $fh, "<", $filename) or croak "Can't read $filename";
    my $line_index = lc $algo eq 'uniform' ? _index_file($fh) : undef ;
    my $filesize = -s $fh;
    my $self = { 
        fh => $fh, 
        line_index => $line_index, 
        line_count => $line_index ? scalar @$line_index : undef,
        filesize => $filesize 
    };
    return bless( $self, ref($class) ? ref($class) : $class );
}
	
#--------------------------------------------------------------------------#
# _index_file
#--------------------------------------------------------------------------#

sub _index_file {
    my ($fh) = @_;
    my @index;
    while (! eof $fh) {
        push @index, tell $fh;
        <$fh>;
    }
    return \@index;
}

#--------------------------------------------------------------------------#
# next()
#--------------------------------------------------------------------------#


sub next {
	my ($self,$n) = @_;
    #  behavior copied from File::Random
    if (!defined($n) and wantarray) {
        $n = howmany();
        $n ||= 1;
    }
    unless (!defined($n) or $n =~ /^\d+$/) {
        croak "Number of random_lines should be a positive integer, not '$n'";
    }
    carp "Strange call to File::Random->next(): 0 random lines requested"
        if defined($n) and $n == 0;
    $n ||= 1;
    my @sample;
    while (@sample < $n) {
        push @sample, $self->{line_index} ? $self->_uniform : $self->_fast;
    }
    chomp @sample;
    return wantarray ? @sample : shift @sample;
}


#--------------------------------------------------------------------------#
# Fast Algorithm
#--------------------------------------------------------------------------#

sub _fast {
    my $self = shift;
    my $fh = $self->{fh};
    seek($fh,int(rand($self->{filesize})),0);
    <$fh>; # skip this fragment of a line
    seek($fh,0,0) if eof $fh; # wrap if hit EOF
    return scalar <$fh>; # get the next line
}

#--------------------------------------------------------------------------#
# Uniform Algorithm
#--------------------------------------------------------------------------#

sub _uniform {
    my $self = shift;
    my $fh = $self->{fh};
    my $start = $self->{line_index}[int(rand($self->{line_count}))];
    seek($fh,$start,0);
    return scalar <$fh>; # get the next line
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

File::RandomLine - Retrieve random lines from a file

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  # Fast but biased randomness
  use File::RandomLine;
  my $rl = File::RandomLine->new('/var/log/messages');
  print $rl->next;
  print join("\n",$rl->next(3));
  
  # Slow but uniform randomness
  $rl = File::RandomLine->new('/var/log/messages', {algorithm=>"uniform"});

=head1 DESCRIPTION

This module provides a very fast random-access algorithm to retrieve random
lines from a file.  Lines are not retrieved with uniform probability, but
instead are weighted by the number of characters in the previous line, due to
the nature of the algorithm. Lines are most random when all lines are about
the same length.  For log file sampling or quote/fortune generation, this
should be "random enough".  Note -- when getting multiple lines, this module
resamples with replacement, so duplicate lines are possible.  Users will need
to check for duplication on their own if this is not desired.

The algorithm is as follows:

=over

=item *

Seek to a random location in the file

=item *

Read and discard the line fragment found

=item *

Read and return the next line, or the first line if we've reached the end
of the file

=item *

Repeat until the requested number of random lines have been found

=back

This module provides some similar behavior to L<File::Random>, but the
random access algorithm is much faster on large files.  (E.g., it runs
nearly instantaneously even on 100+ MB log files.)

This module also provides an optional, slower algorithm that returns random lines
with uniform probability.

=head1 METHODS

=head2 new

 $rl = File::RandomLine->new( "filename" );
 $rl = File::RandomLine->new( "filename", { algorithm => "uniform" } );

Returns a new File::RandomLine object for the given filename.  The filename
must refer to a readable file.  A hash reference may be provided as an 
optional second argument to specify an algorithm to use.  Currently supported
algorithms are "fast" (the default) and "uniform".  Under "uniform", the 
module indexes the entire file before selecting random lines with true uniform
probability for each line.  This can be significantly slower on large files.

=head2 next

 $line = $rl->next();
 @lines = $rl->next(5);
 ($line1, $line2, $line3) = $rl->next();

Returns one or more lines from the file.  Without parameters, returns a
single line if called in scalar context.  With a positive integer parameter, 
returns a list with the specified number of lines.  C<next> also has some 
magic if called in list context with a finite length list of l-values and 
will return the proper number of lines.  

=head1 ACKNOWLEDGMENTS

Concept and code for "magic" behavior in array context taken from 
L<File::Random> by Janek Schleicher.

=head1 SEE ALSO

=over 4

=item *

L<File::Random>

=item *

L<Re^2: selecting N random lines from a file in one pass|http://perlmonks.thepen.com/417065.html>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/file-randomline/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/file-randomline>

  git clone git://github.com/dagolden/file-randomline.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
