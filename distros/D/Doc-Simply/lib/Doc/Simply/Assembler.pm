package Doc::Simply::Assembler;

=head1 NAME

Doc::Simply::Assembler - Assemble line and block comments into blocked content

=head1 DESCRIPTION

Doc::Simple::Assembler::assembler will iterate through each given comment and do the following:

    1. Combining multiple contiguous lines into a single block
    2. Preserving existing blocks

The result will be a series of blocks, each containing a list of lines.

In addition, it will normalize the content by stripping the first 1 to 2 spaces (if present) and removing a leading '*' (if present).

=cut

use Any::Moose;
use Doc::Simply::Carp;

has normalizer => qw/is ro lazy_build 1 isa CodeRef/;
sub _build_normalizer {
    return sub {
        s/^( ?\*)?\s{0,1}//; $_;
    }
}

sub assemble {
    my $self = shift;
    my $comments = shift;

    my (@blocks, @block);
    my $normalizer = $self->normalizer;

    for my $comment (@$comments) {
        my ($type, $content) = @$comment;
        my @content = split m/\n/, $content;
        if ($type eq "line") {
            @content = map { $normalizer->($_) } @content;
            push @block, @content;
        }
        else {
            push @blocks, [ @block ] if @block;
            undef @block;
            # Normalize leading whitespace
            my $shortest;
            for (@content) {
                m/^(\s*)\S/ or next;
                $shortest = length $1 unless defined $shortest;
                $shortest = length $1 if $shortest > length $1;
            }
            for (@content) {
                m/^(\s*)\S/ or next;
                $_ = substr $_, $shortest;
            }
            @content = map { $normalizer->($_) } @content;
            push @blocks, [ @content ];
        }
    }

    push @blocks, \@block if @block;

    return \@blocks;
}

1;

__END__

    my (@extract, %state);
EXTRACT:    
    for my $line (@source) {

        if ($line) {
            local $_ = $line;
            if ($filter->($_)) {
                $line = $_;
            }
            else {
                undef $line;
            }
        }

        unless ($line) {
            delete $state{collect};
            next EXTRACT;
        }
        
#        no warnings 'uninitialized';

        my (%line, $head, $body);
        {
            local $_ = $line;
            ($head, $body) = $matcher->($line);
            if ($head) {
                %line = (head => $head);
                $line{body} = $body if defined $body && length $body;
            }
            else {
                next EXTRACT unless $state{collect};
                $body = $line;
                %line = (body => $body);
            }
        }

        unless ($state{collect}) {
            $line{begin} = 1;
        }

        if ($head && $head =~ m/^cut\b/i) {
            delete $state{collect};
        }
        else {
            $state{collect} = 1;
        }

        push @extract, \%line;

    }

    return @extract;
}
